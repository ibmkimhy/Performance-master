#!/bin/bash
###############################################################################
# Licensed Materials - Property of IBM.
# Copyright IBM Corporation 2018, 2019. All Rights Reserved.
# U.S. Government Users Restricted Rights - Use, duplication or disclosure
# restricted by GSA ADP Schedule Contract with IBM Corp.
#
# Contributors:
#  IBM Corporation - initial API and implementation
###############################################################################

version="2.2.0 20201215"
DEBUG() {
	# 0 is always shown
	# 1 is always shown if any level of tracing is set
	# 2+ other
	#echo "1 $1, 2 $2"
	if [ $1 -eq $global_debug ] || [ $1 -eq '0' ] || [[ $global_debug -gt '0' && $1 -eq '1' ]] ; then
		echo -e "`date` debug $1: $2"
	fi
}
INITIALIZE() {
global_debug=0
setup_csv=""
setup_perf1=""
all_nodes=0
non_workers_only=0
worker_node_count=0
total_mem=0
total_mem_current=0
total_mem_request=0
total_mem_limit=0
total_mem_unrequested=0
total_cpu=0
total_cpu_current=0
total_cpu_request=0
total_cpu_limit=0
total_cpu_unrequested=0
total_pods_running=0
output_log=/dev/null
command="kubectl"
adm=""
notop=""
}
PRINT_MESSAGE() {
	echo -ne "$@" 2>&1 | tee -a ${output_log}
}
USAGE() {
	echo "version $version"
	echo "Use this script to display information on kubernetes resource requests and limits at the node level."
	echo "Flags: $0 "
	echo "   [ --oc ]                   Use the openshift \"oc\" command instead of \"kubectl\" to gather information."
	echo "   [ --no_top ]                Skip gathering the current usage and only display requests and limits (default is include the current usage)"
	echo "   [ --all-nodes ]            Show information on non-worker systems too (default is only workers)"
	echo "   [ --non-workers-only ]     Show information on non-worker systems only (default is only workers)"
	echo "   [ --csv ]                  Send output to a .csv file in addition to stdout.  Default is only stdout."
	echo
	echo "Example, show resources for worker nodes:"
	echo "$0 "
	echo "Example, show resources for non-worker nodes:"
	echo "$0 --non-workers-only"
	echo "Example, show resources for all nodes:"
	echo "$0 --all-nodes"
	echo
	exit 0

}
PARSE_ARGS() {
ARGC=$#
while [ $ARGC != 0 ] ; do
	if [ "$1" == "-n" ] || [ "$1" == "-N" ] ; then
		ARG="-N"
	else
		ARG=`echo $1 | tr .[a-z]. .[A-Z].`
	fi
	case $ARG in
		"--DEBUG")  #
			global_debug=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--ALL-NODES")  #
			all_nodes=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--NON-WORKERS-ONLY")  #
			non_workers_only=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--OC")  #
			command="oc"; adm="adm"; shift 1; ARGC=$(($ARGC-1)) ;;
		"--CSV")  #
			setup_csv=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--PERF1")  #
			setup_csv=1; setup_perf1=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--NO_TOP")  #
			notop=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--HELP")  #
			USAGE ; exit 0;;
		*)
			echo "Argument \"$ARG\" not known, exiting...\n"
			USAGE
			exit 1 ;;
    esac
done
}
SETUP_CSV() {
if [ -n "${setup_csv}" ] ; then
	date=`date +"%Y%m%d.%H%M"`
	if [ -z "${environment_name}" ] ; then
		environment_name=`$command cluster-info | grep master | awk '{ print $6 }' | cut -d '.' -f 2-9 | cut -d ':' -f 1`
	fi
	if [ -z "${environment_name}" ] ; then
		DEBUG 0 "Could not find environment name from \`oc cluster-info\`."
		DEBUG 0 "This name is used for the csv file name."
		DEBUG 0 "Please provide a name with the \"--env <name>\" flag."
		exit 0
	fi
	if [ -n "${setup_perf1}" ] ; then
		dir="/perf1/perfdata/ocp_nodes/${environment_name}/"
		mkdir -p $dir
	fi
	output_log="${dir}nodes.resources.${environment_name}.${namespace}.${date}.csv"
	DEBUG 1 "output_log: $output_log"
	rm -rf $output_log
fi
}
FORMAT_CSV() {
if [ -n "${setup_csv}" ] ; then
	if [ -f "${output_log}" ]; then
		sed -r -i 's/\|\s+//g' $output_log
		sed -r -i 's/,\s+/,/g' $output_log
		sed -r -i 's/\s+,/,/g' $output_log
		chmod 766 $output_log
	fi
fi
}

PERFORM_EVAL() {
	worker_node_count=$((${worker_node_count}+1))
	
	node_describe=`${command} describe node ${node}`
	
	node_resources=`echo "${node_describe}" | grep 'Allocatable' -A 5 -a | egrep 'cpu|memory' -a | tr "\n" ' ' | tr -s ' '`
	node_cpu_request=`echo "${node_describe}" | grep 'cpu ' -a | tail -1 | awk '{ print $2 }' `
	node_cpu_limit=`echo "${node_describe}" | grep 'cpu ' -a | tail -1 | awk '{ print $4 }' `
	node_mem_request_raw=`echo "${node_describe}" | grep 'memory ' -a | tail -1 | awk '{ print $2 }'`
	node_mem_limit_raw=`echo "${node_describe}" | grep 'memory ' -a | tail -1 | awk '{ print $4 }'`
	node_pods_running=`echo "${node_describe}" | grep 'Non-terminated Pods:' | awk '{ print $3 }' | sed -e 's/(//g'`
	
	if [ -z ${notop} ] ; then
		node_cpu_current_raw=`echo "$top" | grep "${node}" | awk '{ print $2 }'`
		node_mem_current_raw=`echo "$top" | grep "${node}" | awk '{ print $4 }'`
		if [ -z "${node_cpu_current_raw}" ] ; then
			node_cpu_current_raw=0
		fi
		if [ -z "${node_mem_current_raw}" ] ; then
			node_mem_current_raw=0
		fi
	fi
	
	node_cpu_raw=`echo ${node_resources} | awk '{ print $2 }'`
	if [[ "${node_cpu_raw}" =~ "m" ]] ; then
		node_cpu_allocatable=`echo ${node_cpu_raw} | sed 's/[^0-9]*//g'`
	else
		node_cpu_allocatable=$((${node_cpu_raw}*1000))
	fi

	node_mem_raw=`echo ${node_resources} | awk '{ print $4 }'`
	node_mem_allocatable=`echo ${node_mem_raw} | sed 's/[^0-9]*//g'`
	if [[ "${node_mem_raw}" =~ "Ki" ]] ; then
		node_mem_allocatable=$((${node_mem_allocatable}/1024))
	elif [[ "${node_mem_raw}" =~ "Mi" ]] ; then
		node_mem_allocatable=${node_mem_allocatable}
	elif [[ "${node_mem_raw}" =~ "Gi" ]] ; then
		node_mem_allocatable=$((${node_mem_allocatable}*1024))
	else
		node_mem_allocatable=$((${node_mem_allocatable}/1024/1024))
	fi

	if [[ "${node_cpu_request}" =~ "m" ]] ; then
		node_cpu_request=`echo ${node_cpu_request} | sed 's/[^0-9]*//g'`
	else
		node_cpu_request=$((${node_cpu_request}*1000))
	fi

	node_mem_request=`echo ${node_mem_request_raw} | sed 's/[^0-9]*//g'`
	if [[ "${node_mem_request_raw}" =~ "Ki" ]] ; then
		node_mem_request=$((${node_mem_request}/1024))
	elif [[ "${node_mem_request_raw}" =~ "Mi" ]] ; then
		node_mem_request=${node_mem_request}
	elif [[ "${node_mem_request_raw}" =~ "Gi" ]] ; then
		node_mem_request=$((${node_mem_request}*1024))
	else
		node_mem_request=$((${node_mem_request}/1024/1024))
	fi

	if [[ "${node_cpu_limit}" =~ "m" ]] ; then
		node_cpu_limit=`echo ${node_cpu_limit} | sed 's/[^0-9]*//g'`
	else
		node_cpu_limit=$((${node_cpu_limit}*1000))
	fi

	node_mem_limit=`echo ${node_mem_limit_raw} | sed 's/[^0-9]*//g'`
	if [[ "${node_mem_limit_raw}" =~ "Ki" ]] ; then
		node_mem_limit=$((${node_mem_limit}/1024))
	elif [[ "${node_mem_limit_raw}" =~ "Mi" ]] ; then
		node_mem_limit=${node_mem_limit}
	elif [[ "${node_mem_limit_raw}" =~ "Gi" ]] ; then
		node_mem_limit=$((${node_mem_limit}*1024))
	else
		node_mem_limit=$((${node_mem_limit}/1024/1024))
	fi
	
	
	if [ -z ${notop} ] ; then
		if [ -n "${node_cpu_current_raw}" ] ; then
			if [[ "${node_cpu_current_raw}" =~ "m" ]] ; then
				node_cpu_current=`echo ${node_cpu_current_raw} | sed 's/[^0-9]*//g'`
			else
				node_cpu_current=$((${node_cpu_current_raw}*1000))
			fi
		else
			node_cpu_current=0
		fi
		
		if [ -n "${node_mem_current_raw}" ] ; then
			node_mem_current=`echo ${node_mem_current_raw} | sed 's/[^0-9]*//g'`
			if [[ "${node_mem_current_raw}" =~ "Ki" ]] ; then
				node_mem_current=$((${node_mem_current}/1024))
			elif [[ "${node_mem_current_raw}" =~ "Mi" ]] ; then
				node_mem_current=${node_mem_current}
			elif [[ "${node_mem_current_raw}" =~ "Gi" ]] ; then
				node_mem_current=$((${node_mem_current}*1024))
			else
				node_mem_current=$((${node_mem_current}/1024/1024))
			fi
		else
			node_mem_current=0
		fi
	fi
	
	node_cpu_unrequested=$((${node_cpu_allocatable}-${node_cpu_request}))
	node_mem_unrequested=$((${node_mem_allocatable}-${node_mem_request}))

	total_mem=$((${total_mem}+${node_mem_allocatable}))
	total_mem_request=$((${total_mem_request}+${node_mem_request}))
	total_mem_limit=$((${total_mem_limit}+${node_mem_limit}))
	total_mem_unrequested=$((${total_mem_unrequested}+${node_mem_unrequested}))
	total_cpu=$((${total_cpu}+${node_cpu_allocatable}))
	total_cpu_request=$((${total_cpu_request}+${node_cpu_request}))
	total_cpu_limit=$((${total_cpu_limit}+${node_cpu_limit}))
	total_cpu_unrequested=$((${total_cpu_unrequested}+${node_cpu_unrequested}))
	total_pods_running=$((${total_pods_running}+${node_pods_running}))
	
	if [ -z ${notop} ] ; then
		total_cpu_current=$((${total_cpu_current}+${node_cpu_current}))
		total_mem_current=$((${total_mem_current}+${node_mem_current}))
	fi
	
	
	string=`printf "%-45s %11s, %12s, %12s, %12s, %12s, %12s,  |  %12s, %12s, %12s, %12s, %12s," "${node}," "${node_pods_running}" "${node_mem_current}" "${node_mem_request}" "${node_mem_unrequested}" "${node_mem_limit}" "${node_mem_allocatable}" "${node_cpu_current}" "${node_cpu_request}" "${node_cpu_unrequested}" "${node_cpu_limit}" "${node_cpu_allocatable}"`
	PRINT_MESSAGE "${string}\n"
	worker_node_list="${worker_node_list}${node} "

}
PRINT_HEADER(){
	string=`printf "%-45s %11s, %12s, %12s, %12s, %12s, %12s,  |  %12s, %12s, %12s, %12s, %12s," "," "" "Mem (Mi)" "Mem (Mi)" "Mem (Mi)" "Mem (Mi)" "Mem (Mi)" "CPU (m)" "CPU (m)" "CPU (m)" "CPU (m)" "CPU (m)"`
	PRINT_MESSAGE "${string}\n"
	string=`printf "%-45s %11s, %12s, %12s, %12s, %12s, %12s,  |  %12s, %12s, %12s, %12s, %12s," "Node," "Pods" "Used" "Requested" "Unrequested" "Limit" "Total" "Used" "Requested" "Unrequested" "Limit" "Total"`
	PRINT_MESSAGE "${string}\n"
	
}
PRINT_TOTAL(){

	PRINT_MESSAGE "\n"
	string=`printf "%-45s %11s, %12s, %12s, %12s, %12s, %12s,     %12s, %12s, %12s, %12s, %12s," "Environment Totals," "${total_pods_running}" "${total_mem_current}" "${total_mem_request}" "${total_mem_unrequested}" "${total_mem_limit}" "${total_mem}" "${total_cpu_current}" "${total_cpu_request}" "${total_cpu_unrequested}" "${total_cpu_limit}" "${total_cpu}"`
	PRINT_MESSAGE "${string}\n\n"
}

GET_WORKER_NODE_LIST() {
if [ -z "${all_node_list}" ] ; then
	PRINT_HEADER
	all_node_list=`${command} get nodes | grep -v NAME | awk '{ print $1 }' | sort -V | tr "\n" ' ' | tr -s ' '`
	
	if [ -z ${notop} ] ; then
		top=`${command} ${adm} top nodes`
	fi
	for node in ${all_node_list} ; do
		describe=`${command} describe node ${node} 2> /dev/null`
		NoSchedule=`echo ${describe} | grep NoSchedule`
		if [ -z "${NoSchedule}" ] ; then
			is_worker=1
		else
			is_worker=0
		fi

		if [[ $all_nodes -eq '1' ]] ; then
			PERFORM_EVAL
		elif [[ $is_worker -eq '1' ]] && [[ $non_workers_only -eq '0' ]] ; then
			PERFORM_EVAL
		elif [[ $is_worker -eq '0' ]] && [[ $non_workers_only -eq '1' ]] ; then
			PERFORM_EVAL
		fi
		
		
	done
	PRINT_TOTAL
fi
}


INITIALIZE
PARSE_ARGS "$@"
SETUP_CSV
GET_WORKER_NODE_LIST
FORMAT_CSV
