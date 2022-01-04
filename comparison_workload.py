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
from datetime import datetime
import shutil
import argparse
import matplotlib
import textwrap
import logging
matplotlib.use("Agg")

plt.rcParams.update({'figure.max_open_warning': 0})
#pip3.8 install xlrd==1.2.0

# Input "File Name"
# Creation of Files
def create_files(file_name):
    condition= os.path.isdir(file_name)
    if not (condition):
        os.mkdir(file_name)

def init():
    #formatter = lambda prog: argparse.HelpFormatter(prog,max_help_position=12)
    #formatter_class=formatter,
    global parser
    parser = argparse.ArgumentParser( prog='prometheus_comparison.py', description=textwrap.dedent('''\
    Compares two or more Prometheus summary files.  
    In the case of two provided comparisons, a difference is generated. 
    In the case of three or more provided comparisons, an average of the summaries is generate.
    The output is a spreadsheet, matching the format of the input summaries.
    '''), 
    epilog=textwrap.dedent('''\
    Example: 
    --dirs promTest1 promTest2 --n cp4waiops --loglevel more'''))
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
    requiredParser.add_argument(
        "--dirs", 
        nargs='+',
        help=("List of derectories with Prometheus exported summary(ies)"),
        required=True
    )
    requiredParser.add_argument(
        "--n",
        "--namespace",
        #action='append',
        #default=[],
        dest='namespace',
        help=("Namespace to compare summary data for"),
        required=True
    )
    requiredParser.add_argument(
        "--outputDir", 
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
def searchDirs():
    for dir in arg.dirs: 
        if not dir.endswith("/"):
            dir = dir + "/"
        logging.prog("Looking in dir " + dir )
        files = os.listdir(dir)
        for file in files:
            if arg.namespace in file and ".summary." in file and not file.startswith("~"):
                logging.more(" * " + str(file))
                summary_files.append(dir + file)
            else:
                logging.more("   " + str(file))
    x = 0
    logging.prog("Found " + str(len(summary_files)) + " matching files")
    for file in summary_files:
        x+=1
        logging.prog("Summary file " + str(x) + " " + str(file))
        excel_files.append(pd.read_excel(file))

def graph_comparison(multi_df,Pod_Name,name):

     # Finding out the biggest number for creating horizontal lines 
    biggest = 0 
    vert_line = 250 
    arr = multi_df.columns[1:]
    for i in arr:
        if biggest < max(multi_df[i].to_list()):
            biggest = max(multi_df[i].to_list())
    
    fig = multi_df.plot(x='Item',
        figsize=[40, 25],
        kind='bar',
        stacked=False,
        fontsize=20)
    plt.style.use('ggplot')
    plt.xlabel('Items', fontsize=25)
    plt.ylabel(name, fontsize=25)
    plt.xticks(fontsize= 25, rotation = 45)
    plt.legend(fontsize=25)
    plt.title(Pod_Name+ " "+ name,fontsize=35)
    plt.subplots_adjust(left = -0.4, top=1.4)
    
    while vert_line < biggest:
        plt.axhline(vert_line, linewidth=5, color='w')
        vert_line = vert_line + 250

    message = arg.outputDir + Pod_Name+ "_"+ name + ".png"
    fig.figure.savefig(message, bbox_inches='tight')
    logging.info("File created for for: " + Pod_Name+ "_"+ name)
    plt.close('all')

# Reading multiple files from a folder
def read_files():

    flag = True
    main_container = pd.DataFrame()
    for file in summary_files:
        maindf = pd.ExcelFile(file)
        # Read CPU and Set Index
        file = file.split('/')[-1]
        container = pd.read_excel(maindf, 'container_sum')
        container.insert(loc=0, column='Workload Name', value=file)
        if flag: 
            main_container = container
            flag = False
        else:
            frames = [main_container, container]
            main_container = pd.concat(frames)
    return main_container

def evaluation(container_list):

    # Delete duplicates
    unique_pods = container_list.Item.unique()
    quantity = len(unique_pods)
    percentage = 1
    # Divide them by Pods 
    for podname in unique_pods:
        pod_df = container_list.loc[container_list['Item'] == podname]
        pod_df = pod_df.T
        arr = pod_df.iloc[[0]].values.tolist()[0]
        pod_df = pod_df.iloc[2:]
        pod_df.index.name = 'Item'
        pod_df.columns = arr
        pod_df = pod_df.reset_index()

        graph_comparison(pod_df[pod_df['Item'].str.contains("int")],podname,"Count (Quantity)")
        graph_comparison(pod_df[pod_df['Item'].str.contains("cores")],podname,"CPU (Milicore)")
        graph_comparison(pod_df[pod_df['Item'].str.contains("ThrlSec")],podname,"ThrlSec (Seconds)")
        graph_comparison(pod_df[pod_df['Item'].str.contains("ThrlPct")],podname,"ThrlPct (Percentage)")
        graph_comparison(pod_df[pod_df['Item'].str.contains("Mi")],podname,"Memory (MB)")

        print("Creating PNGs for " + str(podname) + " || Percentage Completed: " + str(round(((percentage/quantity)* 100) , 2)) + '%')
        percentage = percentage + 1

def difference():
    logging.info("Running difference analysis against summary files")
    evaluation(read_files())
    print("File created is located in: " + arg.outputDir)
def average():
    logging.info("Running average analysis against summary files")
    evaluation(read_files())
def main():
    init()
    searchDirs()
    if arg.outputDir[-1] != '/':
        arg.outputDir = arg.outputDir + '/'
    create_files(arg.outputDir)
    if len(summary_files) < 2 : 
        logging.error("Only found " + str(len(summary_files)) + " file. 2 or more are required")
    elif len(summary_files) == 2 :
        difference()
    elif len(summary_files) > 2 :
        average()
main()
exit()