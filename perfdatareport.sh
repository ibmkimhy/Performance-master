#!/bin/bash
################################################
# Wrapper for the perfdata.pl
# tool that generates a summary
# report for a particular process.
#
# In addition to writing a summary
# report to stdout, this script
# creates a summary csv file in the 
# current working directory. The file is
# named:
#  - component-baseline.csv if a file
#    with this name does not exist.
#
#  - component-summary.csv if
#    component-baseline.csv already exists.
#
# Requirements:
# perfdata.pl is assumed to be installed on
# the system as /usr/perfdata/perfdata.pl
#
# Arguments:
# $1 - component id (as defined in perfdata.pl)
# $2 - start time 
# $3 - end time
#
# start time and endtime can be calculated
# and passed to this script as follows:
# start_time=`date +"%Y%m%d.%H%M"`
##################################################

component="$1"

start_time="$2"

# Adjust the end time to ensure that the full
# interval is used for the performance report
# (i.e. add another minute to the end time). 
end_time=`echo "$3" | awk '{printf "%.4f", $1 + 0.0001}'`

current_dir=`pwd`
tmpsummary_csv_file="${component}-tmpsummary.csv"
tmpdetail_csv_file="${component}-tmpdetail.csv"

# Call perfdata to generate a summary report
/usr/perfdata/perfdata.pl ${component} start ${start_time} end ${end_time} small_screen csv csv_dir ${current_dir} csv_summary_file ${tmpsummary_csv_file} csv_detail_file ${tmpdetail_csv_file} | grep -e Process -e 'CPU Core' -e Threads -e 'RSS (KB)' -e Disk | grep -v "System Wide" | cut -c 60-

# Create a baseline or summary csv version of the report
report="${component}-baseline.csv"
if [ -f "$report" ] ; then
        report="${component}-summary.csv"
fi

cat ${tmpsummary_csv_file} | grep -e Process -e 'CPU Core' -e Threads -e 'RSS (KB)' -e Disk | grep -v "System Wide" > ${report}

# Cleanup 
rm ${tmpsummary_csv_file}
rm ${tmpdetail_csv_file}
