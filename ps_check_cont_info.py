#!/usr/bin/env python3
import numpy as np
import os
import re
import pandas as pd
import tarfile
import sys
import math
from scipy import stats
from scipy.stats import binom,poisson,uniform,norm
import matplotlib.pyplot as plt
import json
import logging
import argparse
import textwrap

def init():
    #formatter = lambda prog: argparse.HelpFormatter(prog,max_help_position=12)
    #formatter_class=formatter,
    global parser
    parser = argparse.ArgumentParser( prog='ps_check_cont_info.py', description=textwrap.dedent('''\
    Checks the Readiness and Liveness of the pods and containers
    '''), 
    epilog=textwrap.dedent('''\
    Example: 
    ps_check_cont_info.py --filename promTest1 --loglevel more'''))
    global keyParser
    keyParser = parser.add_argument_group('KEY arguments')
    global requiredParser
    requiredParser = parser.add_argument_group('REQUIRED arguments')
    setupParser()
    global arg 
    arg = parser.parse_args()
    setupLogging()
    global summary_files
    summary_files = []
    global excel_files
    excel_files = []
    
def setupParser():
    keyParser.add_argument(
        "--filename", 
        default="",
        help=("Directory to ouput the results to"),
        required=True
    )
    keyParser.add_argument(
        "--loglevel", 
        default="info",
        help=("Logging level: critical, error, warn, warning, info, prog, more, debug, verbose.  Default is info.")
    )
def setupLogging():
    logging.PROG = 19
    logging.addLevelName(logging.PROG, "PROG")
    logging.Logger.prog = lambda inst, msg, *args, **kwargs: inst.log(logging.PROG, msg, *args, **kwargs)
    logging.prog = lambda msg, *args, **kwargs: logging.log(logging.PROG, msg, *args, **kwargs)
    
    logging.MORE = 15
    logging.addLevelName(logging.MORE, "MORE")
    logging.Logger.more = lambda inst, msg, *args, **kwargs: inst.log(logging.MORE, msg, *args, **kwargs)
    logging.more = lambda msg, *args, **kwargs: logging.log(logging.MORE, msg, *args, **kwargs)
    
    logging.VERBOSE = 5
    logging.addLevelName(logging.VERBOSE, "VERBOSE")
    logging.Logger.verbose = lambda inst, msg, *args, **kwargs: inst.log(logging.VERBOSE, msg, *args, **kwargs)
    logging.verbose = lambda msg, *args, **kwargs: logging.log(logging.VERBOSE, msg, *args, **kwargs)
    
    levels = {
        'critical': logging.CRITICAL,
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'prog': logging.PROG,
        'more': logging.MORE,
        'debug': logging.DEBUG,
        'verbose': logging.VERBOSE
    }
    level = levels.get(arg.loglevel.lower())
    logging.basicConfig(stream=sys.stdout, level=level, format='%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    #logger = logging.getLogger(__name__)
    logging.info("logging level: " + str(level))

def create_files(file_name):
    condition= os.path.isdir(file_name)
    if not (condition):
        os.mkdir(file_name)

def readContainerNames():
    os.system("echo ''> /perf1/temp/prove_info.txt")
    os.system("echo ''> /perf1/temp/probeinv.sh")
    os.system("oc get pods -o=jsonpath='{range .items[*]}{.metadata.name}"+ '{","}' + "{.spec.containers[*].name}" + '{"' + repr('\n')[1:-1] + '"}' +"{end}' > /perf1/temp/Names.txt")

def creating_bash():
    f = open("/perf1/temp/probeinv.sh", "a")
    f.write("x=$(oc rsh $1 ps axww opid,etime,cmd) \n")
    f.write("\n")
    f.write("if [ $? == 0 ] \n")
    f.write("then\n")
    f.write('   echo "@" $1  >> /perf1/temp/prove_info.txt \n')
    f.write("   echo Running: $1 \n")
    f.write("   oc rsh $1 ps axww opid,etime,cmd >> /perf1/temp/prove_info.txt \n")
    f.write("   echo stop >> /perf1/temp/prove_info.txt \n")
    f.write("else \n")
    f.write("echo Value Not Found: $1 \n")
    f.write("fi \n")
    f.write(" \n")
    f.write("sleep 5 \n")

def grabRawLiveandReady():
    names = open("/perf1/temp/Names.txt", "r").readlines()

    print("echo Start Test")
    print("echo ''")
    for num,po in enumerate(names):
        consoles = re.split(' |,', po[:-1])
        os.system("bash /perf1/temp/probeinv.sh " + consoles[0])

def parseRawFile():
    names = open("/perf1/temp/prove_info.txt", "r").readlines()[1:]

    for num,space in enumerate(names):
        if space == '\n':
            names.pop(num)

    pod_name=[]
    pod_container_type = []

    pod_XmS = []
    pod_XmX = []

    save = []

    merge_type = []
    merge_xmx = []
    merge_xms = []

    for num,pod in enumerate(names):
        pod = pod.split()
        if pod[0] == 'stop':
            if len(save) == 1:
                print("Pod: " + save[0][1] + " did't provide information")
            else:
                for name in save:
                    if name[0] == '@':
                        pod_name.append(name[1])
                        pod = name[1]
                    elif str(name[0]).isdecimal() and name[2] != 'ps':
                        fill_list = ' '.join(name)
                        if 'python' in fill_list:
                            merge_type.append('Python')
                        elif 'java' in fill_list:
                            merge_type.append('Java')
                        elif 'npm' in fill_list:
                            merge_type.append('npm')
                        elif 'node' in fill_list:
                            merge_type.append('Node')
                        elif 'postgres' in fill_list:
                            merge_type.append('postgres')
                        elif 'js' in fill_list:
                            merge_type.append('js')
                        elif 'coreutils' in fill_list:
                            merge_type.append('coreutils')
                        elif 'bash' in fill_list or '.sh' in fill_list or '/sh' in fill_list or name[2] == 'sh':
                            merge_type.append('bash')
                        elif 'kubectl' in fill_list:
                            merge_type.append('kubernetes')
                        elif 'stolon'in fill_list:
                            merge_type.append('Stolon')
                        elif 'kamel 'in fill_list:
                            merge_type.append('Kamel')
                        elif 'nginx' in fill_list:
                            merge_type.append('nginx') 
                        elif 'couchdb' in fill_list:
                            merge_type.append('couchdb')
                        elif 'grafana' in fill_list:
                            merge_type.append('grafana')
                        elif 'redis' in fill_list:
                            merge_type.append('redis')
                        elif 'runc' in fill_list:
                            merge_type.append('runc')
                        elif 'slapd' in fill_list:
                            merge_type.append('slapd')
                        else:
                            print('Command not in script for:', pod)

                        if 'Xms' in fill_list:
                            res = fill_list.split('Xms', maxsplit=1)[-1].split(maxsplit=1)[0]
                            merge_xms.append(res)


                        if 'Xmx' in fill_list:
                            res = fill_list.split('Xmx', maxsplit=1)[-1].split(maxsplit=1)[0]
                            merge_xmx.append(res)

                if len(merge_xmx) == 0:
                    pod_XmX.append(np.nan)
                else:
                    x = merge_xmx[0]

                    if len(str(x)) > 5:
                        x = int(x)/100000
                        
                    elif x[-1] == 'm' or x[-1] == 'M':
                        x = int(x[:-1])
                        
                    elif x[-1] == 'g' or x[-1] == 'G':
                        x = int(x[:-1])*1000000

                    pod_XmX.append(x)

                if len(merge_xms) == 0:
                    pod_XmS.append(np.nan)
                else:
                    x = merge_xms[0]

                    if len(str(x)) > 9:
                        x = int(x)/100000
                        
                    elif x[-1] == 'm' or x[-1] == 'M':
                        x = int(x[:-1])
                        
                    elif x[-1] == 'g' or x[-1] == 'G':
                        x = int(x[:-1])*1000000

                    pod_XmS.append(merge_xms[0])


                if len(merge_type) == 0:
                    pod_container_type.append(np.nan)
                else:
                    pod_container_type.append((' '.join(merge_type)))
            save = []
            merge_type = []
            merge_xmx = []
            merge_xms = []
        else:
            save.append(pod)

    df = pd.DataFrame()
    df['Pod'] = pod_name
    df['Container Type'] = pod_container_type

    df['XMS'] = pod_XmS
    df['XMX'] = pod_XmX


    df = df.drop_duplicates(subset='Pod', keep="first")
    df = df.reset_index()
    df.to_csv(arg.filename + '_Info_of_Probes.csv', index=False)
    print("File is on " + arg.filename + '_Info_of_Probes.csv')

def main():
    create_files('/perf1/temp/')
    print("Creating a raw file to check Pods and container names")
    readContainerNames()
    creating_bash()

    print("Grabing Raw information on Liveness and Readiness")
    grabRawLiveandReady()

    print("Parsing to get Liveness and Readiness information")
    parseRawFile()


if __name__ == "__main__":
    init()
    main()
    exit()