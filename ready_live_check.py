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
from math import sqrt
import json
import re
import json
import logging
import argparse
import textwrap

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error
from scipy import stats
from scipy.stats import kurtosis, skew

def init():
    #formatter = lambda prog: argparse.HelpFormatter(prog,max_help_position=12)
    #formatter_class=formatter,
    global parser
    parser = argparse.ArgumentParser( prog='ready_live_check.py', description=textwrap.dedent('''\
    Checks the Readiness and Liveness of the pods and containers
    '''), 
    epilog=textwrap.dedent('''\
    Example: 
    ready_live_check.py --filename promTest1 --loglevel more'''))
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
        help=("Name of the results file Ex: ocp_cluster_2"),
        required=True
    )
    keyParser.add_argument(
        "--namespace", 
        default="",
        help=("Target specific namespace"),
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

def readContainerNames():
    os.system('echo ""> /perf1/temp/Names.txt')
    os.system('echo ""> /perf1/temp/raw_live_ready.txt')
    if len(arg.namespace) == 0:
        os.system("oc get pods -o=jsonpath='{range .items[*]}{.metadata.name}"+ '{","}' + "{.spec.containers[*].name}"+ '{","}'+ "{.metadata.namespace}" + '{"' + repr('\n')[1:-1] + '"}' +"{end}' >> /perf1/temp/Names.txt")
    elif arg.namespace  == 'A' or arg.namespace  == 'a' or arg.namespace  == 'all' or arg.namespace  == 'All':
        os.system("oc get pods -A -o=jsonpath='{range .items[*]}{.metadata.name}"+ '{","}' + "{.spec.containers[*].name}"+ '{","}' + "{.metadata.namespace}" + '{"' + repr('\n')[1:-1] + '"}' +"{end}' >> /perf1/temp/Names.txt")
    else:
        name_space = arg.namespace
        name_space = name_space.split(',')
        for space in name_space:
            check_namespace = os.popen('oc get pods -n ' + space).read()
            compare = str('No resources found in ' + space +' namespace.')

            if int(len(check_namespace)) != 0:
                os.system("oc get pods -n " + space +" -o=jsonpath='{range .items[*]}{.metadata.name}"+ '{","}' + "{.spec.containers[*].name}"+ '{","}' + "{.metadata.namespace}" + '{"' + repr('\n')[1:-1] + '"}' +"{end}' >> /perf1/temp/Names.txt")
            else:
                print(space+ ": namespace Don't have Pods or you input an incorrect namespace")

def grabRawLiveandReady():
    names = open("/perf1/temp/Names.txt", "r").readlines()[1:]

    
    for pod in names:
        consoles = re.split(' |,|\n', pod)
        cmd = ' '.join(consoles)
        print("Running: " + consoles[0])
        os.system('echo 1 ' + cmd + ">> /perf1/temp/raw_live_ready.txt")
        if len(arg.namespace) == 0:
            os.system('oc describe po ' + str(consoles[0]) + ' | egrep "Liveness|Readiness"' +  " >> /perf1/temp/raw_live_ready.txt")
        else: 
            os.system('oc describe po ' + str(consoles[0]) + ' -n ' + str(consoles[-2]) + '| egrep "Liveness|Readiness"' +  " >> /perf1/temp/raw_live_ready.txt")
        os.system('echo "stop" >> /perf1/temp/raw_live_ready.txt')

def parseRawFile():
    names = open("/perf1/temp/raw_live_ready.txt", "r").readlines()[1:]

    pod_ns = []
    pod_name=[]
    pod_container=[]

    pod_Liveness_delay=[]
    pod_Liveness_timeout=[] 
    pod_Liveness_period=[] 
    pod_Liveness_success=[] 
    pod_Liveness_failure=[]


    pod_Readiness_delay=[]
    pod_Readiness_timeout=[] 
    pod_Readiness_period=[] 
    pod_Readiness_success=[] 
    pod_Readiness_failure=[]

    save = []

    quantity_Live= 0
    quantity_Ready= 0

    for num,pod in enumerate(names):
        pod = pod.split()
        if pod[0] == 'No' and pod[1] == 'resources':
            continue
        elif pod[0] == 'stop':
            quantity_Live= 0
            quantity_Ready= 0
            for name in save:
                if name[0] == '1':
                    quantity_cont = len(name[2:-1])
                elif name[0] == 'Liveness:':
                    quantity_Live = quantity_Live + 1
                elif name[0] == 'Readiness:':
                    quantity_Ready = quantity_Ready + 1

            for name in save:
                if len(save[1:]) == 0:
                    for i in range(0, len(name[2:-1])):
                        pod_name.append(name[1])
                        pod_ns.append(name[-1])
                        pod_Liveness_delay.append("NONE VALUE")
                        pod_Liveness_timeout.append("NONE VALUE")
                        pod_Liveness_period.append("NONE VALUE")
                        pod_Liveness_success.append("NONE VALUE")
                        pod_Liveness_failure.append("NONE VALUE")
                        pod_Readiness_delay.append("NONE VALUE")
                        pod_Readiness_timeout.append("NONE VALUE")
                        pod_Readiness_period.append("NONE VALUE")
                        pod_Readiness_success.append("NONE VALUE")
                        pod_Readiness_failure.append("NONE VALUE")

                    pod_container = pod_container + name[2:-1]

                elif name[0] == '1':
                    for i in range(0, len(name[2:-1])):
                        pod_name.append(name[1])
                        pod_ns.append(name[-1])
                    pod_container = pod_container + name[2:-1]

                    if (quantity_cont) > (quantity_Live):
                        for i in range(0, quantity_cont-quantity_Live):
                            pod_Liveness_delay.append("NONE VALUE")
                            pod_Liveness_timeout.append("NONE VALUE")
                            pod_Liveness_period.append("NONE VALUE")
                            pod_Liveness_success.append("NONE VALUE")
                            pod_Liveness_failure.append("NONE VALUE")
                    if (quantity_cont) > (quantity_Ready):
                        for i in range(0, quantity_cont-quantity_Ready):
                            pod_Readiness_delay.append("NONE VALUE")
                            pod_Readiness_timeout.append("NONE VALUE")
                            pod_Readiness_period.append("NONE VALUE")
                            pod_Readiness_success.append("NONE VALUE")
                            pod_Readiness_failure.append("NONE VALUE")

                if name[0] == 'Liveness:' or name[0] == 'Readiness:':
                    if name[0] == 'Liveness:':
                        not_in_name = ' '.join(name[:-1])
                        for cont in name[:-1]:
                            if "delay=" in cont:
                                pod_Liveness_delay.append(''.join(i for i in cont if i.isdigit()))
                            elif "timeout=" in cont and '-timeout=' not in cont:
                                pod_Liveness_timeout.append(''.join(i for i in cont if i.isdigit()))
                            elif "period=" in cont:
                                pod_Liveness_period.append(''.join(i for i in cont if i.isdigit()))
                            elif "success=" in cont:
                                pod_Liveness_success.append(''.join(i for i in cont if i.isdigit()))
                            elif "failure=" in cont:
                                pod_Liveness_failure.append(''.join(i for i in cont if i.isdigit()))
                        if "delay=" not in not_in_name:
                            pod_Liveness_delay.append("NONE VALUE")
                        if "timeout=" not in not_in_name:
                            pod_Liveness_timeout.append("NONE VALUE")
                        if "period=" not in not_in_name:
                            pod_Liveness_period.append("NONE VALUE")
                        if "success=" not in not_in_name:
                            pod_Liveness_success.append("NONE VALUE")
                        if "failure=" not in not_in_name:
                            pod_Liveness_failure.append("NONE VALUE")

                    elif name[0] == 'Readiness:':
                        not_in_name = ' '.join(name[:-1])
                        for cont in name[:-1]:
                            if "delay=" in cont:
                                pod_Readiness_delay.append(''.join(i for i in cont if i.isdigit()))
                            elif "timeout=" in cont and '-timeout=' not in cont:
                                pod_Readiness_timeout.append(''.join(i for i in cont if i.isdigit()))
                            elif "period=" in cont:
                                pod_Readiness_period.append(''.join(i for i in cont if i.isdigit()))
                            elif "success=" in cont:
                                pod_Readiness_success.append(''.join(i for i in cont if i.isdigit()))
                            elif "failure=" in cont:
                                pod_Readiness_failure.append(''.join(i for i in cont if i.isdigit()))
                        if "delay=" not in not_in_name:
                            pod_Readiness_delay.append("NONE VALUE")
                        if "timeout=" not in not_in_name:
                            pod_Readiness_timeout.append("NONE VALUE")
                        if "period=" not in not_in_name:
                            pod_Readiness_period.append("NONE VALUE")
                        if "success=" not in not_in_name:
                            pod_Readiness_success.append("NONE VALUE")
                        if "failure=" not in not_in_name:
                            pod_Readiness_failure.append("NONE VALUE")
            save = []
        else:
            save.append(pod)

    df = pd.DataFrame()
    df['Namespace'] = pod_ns
    df['Pod'] = pod_name
    df['Container'] = pod_container
    df['Live Delay'] = pod_Liveness_delay
    df['Live Timeout'] = pod_Liveness_timeout
    df['Live Period'] = pod_Liveness_period
    df['Live Success'] = pod_Liveness_success
    df['Live Failure'] = pod_Liveness_failure

    df['Ready Delay'] = pod_Readiness_delay
    df['Ready Timeout'] = pod_Readiness_timeout
    df['Ready Period'] = pod_Readiness_period
    df['Ready Success'] = pod_Readiness_success
    df['Ready Failure'] = pod_Readiness_failure

    if '.csv' not in str(arg.filename):
        arg.filename = arg.filename + 'Results_.csv'
    print("Parsing Done. Script is in: " + arg.filename + 'Results_.csv')
    df.to_csv(arg.filename, index=False)

def main():
    print("Creating a raw file to check Pods and container names")
    readContainerNames()

    print("Grabing Raw information on Liveness and Readiness")
    grabRawLiveandReady()

    print("Parsing to get Liveness and Readiness information")
    parseRawFile()

if __name__ == "__main__":
    init()
    main()
    exit()