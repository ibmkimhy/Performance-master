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
import xlrd
import argparse
import matplotlib
matplotlib.use("Agg")

plt.rcParams.update({'figure.max_open_warning': 0})
#pip3.8 install xlrd==1.2.0


parser = argparse.ArgumentParser( prog='parsingGraph.py', description=textwrap.dedent('''\
    Prometheus Data Graphing. Used for graphing and analyzing Prometheus data.
    '''), 
    epilog=textwrap.dedent('''\
    Example: 
    ./parsingGraph.py /path/to/prometheus/data.xlsx'''))

parser.print_help()
if len(sys.argv) <= 1:
    print("Please enter a path")
    exit()

# Input is the File name (File to be Read)
# Code is to extract the path
pathname = os.path.dirname(sys.argv[1])
mainRead = os.path.abspath(pathname) + '/'

# Path to create Files
nameofFile = str(sys.argv[1])
pngFiles=mainRead+ str(nameofFile.split('/')[-1]) + '_PNGFiles/'

CPU_PNG=pngFiles+"CPU_PNG/"
Memory_PNG=pngFiles+"Memory_PNG/"

NoUsageCPU=pngFiles+"NoUsageCPU/"
NoUsageMEMORY=pngFiles+"NoUsageMEMORY/"

CpuUsageHigh=pngFiles+"CpuUsageHigh/"
MemUsageHigh=pngFiles+"MemUsageHigh/"

# Input "File Name" 
# Creation of Files
def create_files(file_name):
    condition= os.path.isdir(file_name)
    if not (condition):
        os.mkdir(file_name)

# Parameters: 
'''
    Resource is a dataframe that create the line plot 
    Label is a string name to create the labels on Graph

    title: Name of the Graph 
    label_y: Label of Y axis 
    Resource_Req: Plotting CPU/MEM Request
    Resource_Lim: Plotting CPU/MEM Limits
    Resource_Third: Plotting CPU/WSS
    Resource_Fourth: Plotting CPUr/RSS
    Resource_Fifth: Plotting CPU_Usr/Cache
    Resource_Sixth: Plotting CPU_Sys/MemUse

    *Same concept with the labels


'''

def line_graph(title,label_y,Resources,labels,path):

    # Chart Configuration
    fig = plt.figure(figsize=[20, 14])
    
    fig_line = ['-','--','-.',':','-','--']
    fig_color = ['blue','red','black','purple','green','brown']
    print("Creating PNG for " + str(title))
    for num,resource in enumerate(Resources):
        if str(labels[num]) == 'cpuReq':
            save = resource.mean()
            
        elif str(labels[num]) == 'memReq':
            save = resource.mean()
            
        elif str(labels[num]) == 'CPUr':
            if resource.mean() <= 0.01:
                path = PathNoUsageCPU
                
            elif resource.mean() >= save*.80 :
                path = CpuUsageHigh
        
        elif str(labels[num]) == 'memUse':            
            if resource.mean() <= 0:
                path = PathNoUsageMEMORY
            
            elif resource.mean() >= save*.80 :
                path = MemUsageHigh

        resource.plot(color=fig_color[num], linestyle=fig_line[num],linewidth=2, markersize=12, label=labels[num])
    
    # Chart Configuration
    plt.style.use('bmh')
    plt.ylim(ymin = -.01)
    plt.xlim(xmin = -2,xmax =len(resource)+2)
    plt.title(title)
    plt.ylabel(label_y)
    plt.xlabel('Intervals x amount of s/m/h')
    plt.xticks(rotation = 45)
    plt.legend(loc = "upper right")
    message = path + title + ".png"
    fig.savefig(message, bbox_inches='tight')
    plt.close('all')

# Search Container type and save it to a file 
def container_type(arr):
    value = []
    for name in arr:
        value.append('oc rsh ' + str(name.split()[1][1:-1]) + ' -c ' + str(name.split()[2]) + "ps -ef --sort=-pcpu | awk 'NR>=2 && NR<=2' | sed 's/.*/\0" + name.split()[0] + str(name.split()[1][1:-1]) +"/'")
    value = np.array(value)
    value = np.unique(value)
    for cmd in value:
        os.system(cmd)
        
def cpu_mem_sorting(df,cpumem,path):
    arr_Val = []
    arr_label = []
    
    if 'pod_detail' in nameofFile:
        pos = 2
        save_first = df.columns[0].split()[pos]
    elif 'pod_sum' in nameofFile:
        pos = 1 
        save_first = df.columns[0].split()[pos]
    elif 'container_detail' in nameofFile:
        pos = 3
        save_first = df.columns[0].split()[pos]
    elif 'container_sum' in nameofFile:
        pos = 3 
        save_first = df.columns[0].split()[pos]
    else:
        print("Program not available for this workload")
        exit()
    
    for num,name in enumerate(df.columns):
        full_name = name.split()
        
        if 'pod_detail' in nameofFile:
            name = str(full_name[0]) + ' ' + str(full_name[1])
        elif 'pod_sum' in nameofFile:
            name = str(full_name[0])  
        elif 'container_detail' in nameofFile:
            name = str(full_name[0]) + ' ' + str(full_name[1]) + ' ' + str(full_name[2])
        elif 'container_sum' in nameofFile:
            name = str(full_name[0]) + ' ' + str(full_name[1]) + ' ' + str(full_name[2])
        else:
            print("Program not available for this workload")
            exit()
            
        if full_name[pos] != save_first:
            arr_Val.append(df.iloc[:, [num]].squeeze())
            arr_label.append(full_name[pos])
            if name == df.columns[-1]:
                line_graph(name + ' ' + cpumem, cpumem,arr_Val,arr_label,path)
        else:
            if num != 0:
                line_graph(name + ' ' + cpumem, cpumem,arr_Val,arr_label,path)
            arr_Val = []
            arr_label = []
            arr_Val.append(df.iloc[:, [num]].squeeze())
            arr_label.append(full_name[pos])
# Main
def main():

    # File Creation 
    create_files(pngFiles)
    create_files(PathMemoryPNG)
    create_files(PathCPUPNG)
    create_files(PathNoUsageMEMORY)
    create_files(PathNoUsageCPU)
    create_files(CpuUsageHigh)
    create_files(MemUsageHigh)
    
    print("Reading Files")
    # Read File
    maindf = pd.ExcelFile(nameofFile)

    # Read CPU and Set Index
    df_CPUr = pd.read_excel(maindf, 'All-CPU')
    df_Memr = pd.read_excel(maindf, 'All-Mem')
    # Change NAN to 0 
    df_CPUr = df_CPUr.replace(np.nan, 0)
    df_Memr = df_Memr.replace(np.nan, 0)
    # Set index to Timestamp
    df_CPUr = df_CPUr.set_index('Timestamp')
    cpu_mem_sorting(df_CPUr,'Cores',PathCPUPNG)
    df_Memr = df_Memr.set_index('Timestamp')
    cpu_mem_sorting(df_Memr,'Memory',PathMemoryPNG)
        
    #container_type(df_CPUr.columns)

if __name__ == "__main__":    
    main()



