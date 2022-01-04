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

version="3.0.0.1 20211216"
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
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
INIT_ALL_STATS
CSV_DATE=`date +"%Y%m%d.%H%M"`
CSV_DIR=""
setup_csv=0
setup_perf1=0
global_debug=0
namespace_count=0
namespace_list=""
show_summary_only=0
show_total_only=0
show_details=""
whole_cpu=""
command="oc"
cp4waiops_namespace_name="cp4waiops"
adm="adm"
namespace=""
include=""
exclude=""
stateful="cassandra|mongo|couch|datalayer|kafka|zookeeper|elasticsearch"
nodes=""
show_pod_results=0
show_container_results=1
output_log="/dev/null"
report_log=""
show_only_running=0
print_pod_groups=0
print_pods=1
parser_version=""
previous_pod_name_short=""
sum_pod_groups=0
sum_file_name=""
report=0
}
INIT_POD_STATS() {
container_number=0
pod_zeros=0
pod_cpu_current=0
pod_cpu_request=0
pod_cpu_limit=0
pod_mem_current=0
pod_mem_request=0
pod_mem_limit=0
unset container_print_string
IFS=$' ' 
}
INIT_NAMESPACE_STATS() {
INIT_POD_GROUPS
INIT_CATEGORIES
INIT_SUB_CATEGORIES
namespace_total_cpu_current=0
namespace_total_cpu_request=0
namespace_total_cpu_limit=0
namespace_total_mem_current=0
namespace_total_mem_request=0
namespace_total_mem_limit=0
namespace_total_pod_count=0
namespace_total_container_count=0
namespace_total_zeros=0

namespace_running_cpu_current=0
namespace_running_cpu_request=0
namespace_running_cpu_limit=0
namespace_running_mem_current=0
namespace_running_mem_request=0
namespace_running_mem_limit=0
namespace_running_pod_count=0
namespace_running_container_count=0
namespace_running_zeros=0

namespace_stopped_cpu_current=0
namespace_stopped_cpu_request=0
namespace_stopped_cpu_limit=0
namespace_stopped_mem_current=0
namespace_stopped_mem_request=0
namespace_stopped_mem_limit=0
namespace_stopped_pod_count=0
namespace_stopped_container_count=0
namespace_stopped_zeros=0

namespace_replica_cpu_current=0
namespace_replica_cpu_request=0
namespace_replica_cpu_limit=0
namespace_replica_mem_current=0
namespace_replica_mem_request=0
namespace_replica_mem_limit=0
namespace_replica_pod_count=0
namespace_replica_container_count=0
namespace_replica_zeros=0
namespace_stateful_cpu_current=0
namespace_stateful_cpu_request=0
namespace_stateful_cpu_limit=0
namespace_stateful_mem_current=0
namespace_stateful_mem_request=0
namespace_stateful_mem_limit=0
namespace_stateful_pod_count=0
namespace_stateful_container_count=0
namespace_stateful_zeros=0
namespace_daemon_cpu_current=0
namespace_daemon_cpu_request=0
namespace_daemon_cpu_limit=0
namespace_daemon_mem_current=0
namespace_daemon_mem_request=0
namespace_daemon_mem_limit=0
namespace_daemon_pod_count=0
namespace_daemon_container_count=0
namespace_daemon_zeros=0
namespace_job_cpu_current=0
namespace_job_cpu_request=0
namespace_job_cpu_limit=0
namespace_job_mem_current=0
namespace_job_mem_request=0
namespace_job_mem_limit=0
namespace_job_pod_count=0
namespace_job_container_count=0
namespace_job_zeros=0
namespace_configmap_cpu_current=0
namespace_configmap_cpu_request=0
namespace_configmap_cpu_limit=0
namespace_configmap_mem_current=0
namespace_configmap_mem_request=0
namespace_configmap_mem_limit=0
namespace_configmap_pod_count=0
namespace_configmap_container_count=0
namespace_configmap_zeros=0
namespace_node_cpu_current=0
namespace_node_cpu_request=0
namespace_node_cpu_limit=0
namespace_node_mem_current=0
namespace_node_mem_request=0
namespace_node_mem_limit=0
namespace_node_pod_count=0
namespace_node_container_count=0
namespace_node_zeros=0
namespace_catalog_cpu_current=0
namespace_catalog_cpu_request=0
namespace_catalog_cpu_limit=0
namespace_catalog_mem_current=0
namespace_catalog_mem_request=0
namespace_catalog_mem_limit=0
namespace_catalog_pod_count=0
namespace_catalog_container_count=0
namespace_catalog_zeros=0
namespace_unspecified_cpu_current=0
namespace_unspecified_cpu_request=0
namespace_unspecified_cpu_limit=0
namespace_unspecified_mem_current=0
namespace_unspecified_mem_request=0
namespace_unspecified_mem_limit=0
namespace_unspecified_pod_count=0
namespace_unspecified_container_count=0
namespace_unspecified_zeros=0
namespace_count=$(($namespace_count+1))
}
INIT_ALL_STATS() {

all_total_cpu_current=0
all_total_cpu_request=0
all_total_cpu_limit=0
all_total_mem_current=0
all_total_mem_request=0
all_total_mem_limit=0
all_total_pod_count=0
all_total_container_count=0
all_total_zeros=0

all_running_cpu_current=0
all_running_cpu_request=0
all_running_cpu_limit=0
all_running_mem_current=0
all_running_mem_request=0
all_running_mem_limit=0
all_running_pod_count=0
all_running_container_count=0
all_running_zeros=0

all_stopped_cpu_current=0
all_stopped_cpu_request=0
all_stopped_cpu_limit=0
all_stopped_mem_current=0
all_stopped_mem_request=0
all_stopped_mem_limit=0
all_stopped_pod_count=0
all_stopped_container_count=0
all_stopped_zeros=0

all_replica_cpu_current=0
all_replica_cpu_request=0
all_replica_cpu_limit=0
all_replica_mem_current=0
all_replica_mem_request=0
all_replica_mem_limit=0
all_replica_pod_count=0
all_replica_container_count=0
all_replica_zeros=0
all_stateful_cpu_current=0
all_stateful_cpu_request=0
all_stateful_cpu_limit=0
all_stateful_mem_current=0
all_stateful_mem_request=0
all_stateful_mem_limit=0
all_stateful_pod_count=0
all_stateful_container_count=0
all_stateful_zeros=0
all_daemon_cpu_current=0
all_daemon_cpu_request=0
all_daemon_cpu_limit=0
all_daemon_mem_current=0
all_daemon_mem_request=0
all_daemon_mem_limit=0
all_daemon_pod_count=0
all_daemon_container_count=0
all_daemon_zeros=0
all_job_cpu_current=0
all_job_cpu_request=0
all_job_cpu_limit=0
all_job_mem_current=0
all_job_mem_request=0
all_job_mem_limit=0
all_job_pod_count=0
all_job_container_count=0
all_job_zeros=0
all_configmap_cpu_current=0
all_configmap_cpu_request=0
all_configmap_cpu_limit=0
all_configmap_mem_current=0
all_configmap_mem_request=0
all_configmap_mem_limit=0
all_configmap_pod_count=0
all_configmap_container_count=0
all_configmap_zeros=0
all_node_cpu_current=0
all_node_cpu_request=0
all_node_cpu_limit=0
all_node_mem_current=0
all_node_mem_request=0
all_node_mem_limit=0
all_node_pod_count=0
all_node_container_count=0
all_node_zeros=0
all_catalog_cpu_current=0
all_catalog_cpu_request=0
all_catalog_cpu_limit=0
all_catalog_mem_current=0
all_catalog_mem_request=0
all_catalog_mem_limit=0
all_catalog_pod_count=0
all_catalog_container_count=0
all_catalog_zeros=0
all_unspecified_cpu_current=0
all_unspecified_cpu_request=0
all_unspecified_cpu_limit=0
all_unspecified_mem_current=0
all_unspecified_mem_request=0
all_unspecified_mem_limit=0
all_unspecified_pod_count=0
all_unspecified_container_count=0
all_unspecified_zeros=0
}

USAGE() {
echo "version $version"
echo "Use this script to display information on kubernetes resource requests, limits, and current utilization."
echo "Flags: $0 "
echo "   [ --namespace <namespace> ]     Specify the namespace to display resource information about. Default is the current namespace."
echo "   [ --all-namespaces ]            Show information for all namespaces. Default is the current namespace."
echo "   [ --nodes <\"node or nodes\"> ]   Specify the node or nodes to include results from.  Use quotes to surround a space or comma delimited list. Default is all nodes."
echo "   [ --oc ]                        Use the OpenShift \"oc\" command to gather information. Default"
echo "   [ --kubectl ]                   Use the Kubernetes \"oc\" command to gather information."
echo "   [ --include <\"regex|regex\"> ]   Filter your results to only include pods matching the regular expression(s) specified."
echo "   [ --exclude <\"regex|regex\"> ]   Filter your results to not include pods matching the regular expression(s) specified."
echo "   [ --pod_totals ]                Include the total usage for the pods, along with the individual containers.  Default is only containers."
echo "   [ --only_pods ]                 Only show the information for pods, not the containers.  Default is to show the containers."
echo "   [ --group_pods_single ]         Include the per pod/container summary details in addition to the individual details.  Default is only show individual pods/containers."
echo "   [ --group_pods_sum ]            Include the total pod/container group details in addition to the individual details.  Sum the total usage, instead of per pod/container.  Default is only show individual pods/containers."
echo "   [ --only_group_pods_single ]    Only show the per pod/container summary details.  Default is only show individual pods/containers."
echo "   [ --only_group_pods_sum ]       Only show the total pod/container group details.  Sum the total usage, instead of per pod/container.  Default is only show individual pods/containers."
echo "   [ --whole_cpu ]                 Displays in whole CPU cores.  Default is millicores(m)."
echo "   [ --only_total ]                Only displays the total for the namespace(s).  Default is show details and totals."
echo "   [ --only_summary ]              Only displays the summary and totals for the namespace(s).  Default is show details and totals."
echo "   [ --only_running ]              Only displays the pods that are running.  Default is show all pods."
echo "   [ --csv ]                       Send output to a .csv file in addition to stdout.  Default is only stdout."
echo "   [ --dir <\"dir_name\"> ]          Directory location to send output to a .csv file to, in addition to stdout.  Default is only stdout."
echo "   [ --env <name>]                 Specify the environment name for the csv file.  Default is the url host taken from \"oc cluster-info\"."
echo
echo "example:"
echo "$0 --namespace management-monitoring"
echo "$0 --namespace management-monitoring --nodes \"1.2.3.4 1.2.3.5\""
echo "$0 --namespace management-monitoring --nodes \"1.2.3.4 1.2.3.5\" --include \"cassandra\""
echo
echo "Codes: R = ReplicaSet"
echo "       S = StatefulSet"
echo "       D = DaemonSet"
echo "       J = Job"
echo "       M = ConfigMap"
echo "       N = Node"
echo "       C = CatalogSource"
echo "       ? = Unspecified Kind"
echo "An \"X\" folling the code signifies the pod is not in a \"Running\" state."
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
		"--OLD_PARSER")  #
			parser_version=0; shift 1; ARGC=$(($ARGC-1)) ;;
		"--NEW_PARSER")  #
			parser_version=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--OC")  #
			command="oc"; adm="adm"; shift 1; ARGC=$(($ARGC-1)) ;;
		"--KUBECTL")  #
			command="kubectl"; adm=""; shift 1; ARGC=$(($ARGC-1)) ;;
		"--INCLUDE")  #
			include="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--EXCLUDE")  #
			exclude="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--NODE")  #
			nodes="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--NODES")  #
			nodes="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"-N")  #
			namespaces="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--NAMESPACE")  #
			namespaces="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--NAMESPACES")  #
			namespaces="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--ALL-NAMESPACES")  #
			namespaces="--all-namespaces"; shift 1; ARGC=$(($ARGC-1)) ;;
		"--WHOLE_CPU")  #
			whole_cpu=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--WHOLE_CPUS")  #
			whole_cpu=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--CSV")  #
			setup_csv=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--DIR")  #
			CSV_DIR=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--PERF1")  #
			setup_csv=1; setup_perf1=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ENV")  #
			environment_name_long=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--CP4WAIOPS")  #
			cp4waiops_namespace_name=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--TAG")  #
			file_name_tag="."$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--POD_TOTALS")  #
			show_pod_results=1; show_container_results=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_PODS")  #
			show_pod_results=1; show_container_results=0; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_CONTAINERS")  #
			show_container_results=1; show_pod_results=0; shift 1; ARGC=$(($ARGC-1)) ;;
		"--INCLUDE_CONTAINERS")  #
			show_container_results=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_SUMMARY")  #
			show_summary_only=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_TOTAL")  #
			show_total_only=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_TOTALS")  #
			show_total_only=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--GROUP_PODS_SINGLE")  #
			print_pod_groups=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--GROUP_PODS_SUM")  #
			print_pod_groups=1; sum_pod_groups=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_GROUP_PODS_SINGLE")  #
			print_pod_groups=1; print_pods=0; shift 1; ARGC=$(($ARGC-1)) ;;
		"--REPORT")  #
			print_pod_groups=1; show_pod_results=1; show_container_results=1; print_pods=0; report=1; setup_csv=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_GROUP_PODS_SUM")  #
			print_pod_groups=1; print_pods=0; sum_pod_groups=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--NOT_RUNNING")  #
			show_only_running=""; shift 1; ARGC=$(($ARGC-1)) ;;
		"--ONLY_RUNNING")  #
			show_only_running=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--SHOW-DETAILS")  #
			show_details=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--HELP")  #
			USAGE; exit 0 ;;
		*)
			DEBUG 0 "Argument \"$ARG\" not known, exiting...\n"
			USAGE; exit 1 ;;
    esac
done

if [ -z "${namespaces}" ] ; then
	if [ "${command}" == "oc" ] ; then
		namespaces=`$command project | cut -d '"' -f 2`		
	else
		namespaces=`$command config view --minify --output 'jsonpath={..namespace}'`
	fi
fi
}
CHECK_VERSION() {
if [ -z "${parser_version}" ] ; then 
	version=`${command} version`
	if [ "${command}" == "kubectl" ] ; then
		parser_version=`echo "$version" | grep Client | grep -o "GitVersion:\"[^\"]*\"" | egrep '1.19|1.2[0-9]' | wc -l`
	elif [ "${command}" == "oc" ] ; then
		parser_version=`echo "$version" | grep Client | egrep ' 4.[6-9]'| wc -l `
	else
		DEBUG 0 "Unrecognized command \"$command\""
		exit 1
	fi
	DEBUG 1 "Selected parser_version $parser_version"
fi
workers_count=`$command get nodes | egrep "worker|compute" | wc -l`

}
SETUP_CSV() {
DEBUG 12 "SETUP_CSV"
if [ ${setup_csv} -eq '1' ] ; then
	#FORMAT_CSV
	if [ -z "${environment_name_long}" ] ; then
		environment_name_long=`$command cluster-info | grep Kubernetes | awk '{ print $NF }' | cut -d '.' -f 2-9 | cut -d ':' -f 1`
	fi
	if [ -z "${environment_name_long}" ] ; then
		DEBUG 0 "Could not find environment name from \`$environment_name_long cluster-info\`."
		DEBUG 0 "This name is used for the csv file name."
		DEBUG 0 "Please provide a name with the \"--env <name>\" flag."
		exit 1
	fi
	environment_name_short=`echo "${environment_name_long}" | cut -d '.' -f 1`
	if [ -n "${CSV_DIR}" ] ; then
		mkdir -p $CSV_DIR
	elif [ ${setup_perf1} -eq '1' ] ; then
		CSV_DIR="/perf1/perfdata/ocp_resources/${environment_name_long}/${CSV_DATE}"
		mkdir -p $CSV_DIR
	else 
		CSV_DIR="."
	fi
	if [ "${sum_pod_groups}" -eq '1' ] ; then
		sum_file_name="_sum"
	fi
	output_log="${CSV_DIR}/${namespace}${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
	rm -rf $output_log
	if [ ${report} -eq '1' ] ; then
		total_report_log="${CSV_DIR}/1-totals${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		kubetype_report_log="${CSV_DIR}/2-kubetype${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		category_report_log="${CSV_DIR}/3-category${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		subcategory_report_log="${CSV_DIR}/4-subcategory${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		namespace_pod_report_log="${CSV_DIR}/5-pod-${namespace}${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		namespace_container_report_log="${CSV_DIR}/6-container-${namespace}${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		report_log=$output_log
		output_log="/dev/null"		
		DEBUG 12 "report_log: $report_log"
		DEBUG 12 "total_report_log: $total_report_log"
	else
		DEBUG 12 "output_log: $output_log"		
	fi
fi
}
FORMAT_CSV() {
DEBUG 12 "FORMAT_CSV"
if [ ${setup_csv} -eq '1' ] ; then
	if [ ${report} -eq '1' ] ; then
		output_log=$report_log
	fi
	if [ -f "${output_log}" ]; then
		DEBUG 1 "Formatting $output_log"
		sed -r -i 's/,\s+/,/g' $output_log
		sed -r -i 's/\s+,/,/g' $output_log
		cat $output_log | egrep 'Node Name|,,,or,|Namespace,' > $output_log.temp
		cat $output_log | egrep ",1 Total,,," >> $output_log.temp
		cat $output_log | egrep ",2 Kubernetes Type,,," >> $output_log.temp
		cat $output_log | egrep ",3 Category,,," >> $output_log.temp
		cat $output_log | egrep ",4 Sub Category,,," >> $output_log.temp
		cat $output_log | egrep -v "Node Name|,,,or,|Namespace,|,1 Total,,,|,2 Kubernetes Type,,,|,3 Category,,,|,4 Sub Category,,,"  >> $output_log.temp
		mv $output_log.temp $output_log
		chmod 766 $output_log
		
		if [ ${report} -eq '1' ] && [ ${namespace_count} -gt '1' ] ; then
			DEBUG 12 "namespace_number $namespace_number"
			if [ ${namespace_number} -eq '1' ] ; then
				cat $output_log | egrep 'Node Name|,,,or,|Namespace,' | sed 's/Pod Name/Title/g' > $total_report_log
				cat $output_log | egrep 'Node Name|,,,or,|Namespace,' | sed 's/Pod Name/Title/g' > $kubetype_report_log
				cat $output_log | egrep 'Node Name|,,,or,|Namespace,' | sed 's/Pod Name/Title/g' > $category_report_log
				cat $output_log | egrep 'Node Name|,,,or,|Namespace,' | sed 's/Pod Name/Title/g' > $subcategory_report_log
			fi
			cat $output_log | egrep 'Node Name|,,,or,|Namespace,' > $namespace_pod_report_log
			cat $output_log | egrep 'Node Name|,,,or,|Namespace,' > $namespace_container_report_log
			
			cat $output_log | egrep ",1 Total,,," >> $total_report_log
			cat $output_log | egrep ",2 Kubernetes Type,,," >> $kubetype_report_log
			cat $output_log | egrep ",3 Category,,," >> $category_report_log
			cat $output_log | egrep ",4 Sub Category,,," >> $subcategory_report_log
			
			cat $output_log | egrep ",T |,P " >> $namespace_pod_report_log
			cat $output_log | egrep ",P |,C " >> $namespace_container_report_log
			
		fi
	else
		DEBUG 1 "Log $output_log does not exist!!!"
	fi
fi
}

GET_ALL_NAMESPACES() {
	#namespaces=`oc get projects | grep -v 'DISPLAY NAME' | awk '{ print $1 }'`
	namespaces=`$command get projects | grep -v 'DISPLAY NAME' | awk '{ print $1 }'`
}
GET_PODS() {
	DEBUG 2 "GET_PODS"
	# IMPORTANT 
	# This is where we get all of the data for all pods for the namespace
	# They are separated by commas, so be careful adding new paths that might include commas
	# Parsed in PARSE_CONTAINER_STATS
	if [ -n "${exclude}" ] ; then
		pods=`${command} get pods -n ${namespace} -o=jsonpath='{range .items[*]}{.metadata.name}{","}{.spec.containers[*].name}{","}{.status.hostIP}{","}{.status.phase}{","}{.metadata.ownerReferences[*].kind}{","}{.metadata.namespace}{","}{.metadata.annotations.productMetric}{","}{.spec.containers[*].resources}{","}{"\n"}{end}' 2>/dev/null | egrep "${include}" | egrep -v "${exclude}"`
	else
		pods=`${command} get pods -n ${namespace} -o=jsonpath='{range .items[*]}{.metadata.name}{","}{.spec.containers[*].name}{","}{.status.hostIP}{","}{.status.phase}{","}{.metadata.ownerReferences[*].kind}{","}{.metadata.namespace}{","}{.metadata.annotations.productMetric}{","}{.spec.containers[*].resources}{","}{"\n"}{end}' 2>/dev/null | egrep "${include}"`
	fi
	#if [ "${namespace}" == "${cp4waiops_namespace_name}" ]; then
	#	if [ "${include}" == "" ] || [[ "${include}" =~ "learn" ]] ; then
	#		has_learner=`echo "${pods}" | grep learner | wc -l`
	#		if [ ${has_learner} -eq '0' ] ; then
	#			learner_string='learnergenerated-601f4f19-9bf4-4c18-5772-5cdd9ea08205-0,load-data load-model store-results store-logs learner coordinator,10.22.42.141,Running,StatefulSet,cp4waiops,{"limits":{"cpu":"200m","memory":"536870912"},"requests":{"cpu":"100m","memory":"268435456"}} {"limits":{"cpu":"200m","memory":"536870912"},"requests":{"cpu":"100m","memory":"268435456"}} {"limits":{"cpu":"200m","memory":"536870912"},"requests":{"cpu":"100m","memory":"268435456"}} {"limits":{"cpu":"200m","memory":"536870912"},"requests":{"cpu":"100m","memory":"268435456"}} {"limits":{"cpu":"2","memory":"15762603376","nvidia.com/gpu":"0"},"requests":{"cpu":"2","memory":"15762603376","nvidia.com/gpu":"0"}} {"limits":{"cpu":"200m","memory":"536870912"},"requests":{"cpu":"100m","memory":"268435456"}},'
	#			DEBUG 1 "Adding learner_string"
	#			learner_subcategory_extra=" Generated"
	#			pods=`echo -e "${pods}\n${learner_string}"`
	#		else
	#			learner_subcategory_extra=""
	#			DEBUG 1 "Pods already has a learner pod"
	#		fi
	#	fi
	#fi
	statefulsets=`echo "$pods" | grep StatefulSet`
	non_statefulsets=`echo "$pods" | grep -v StatefulSet`
}
GET_TOP() {
	DEBUG 2 "GET_TOP"
	top=`${command} ${adm} top pods --containers -n ${namespace} | sort -k 1 -k 2 | grep -v "NAME" | awk '{ print $1","$2","$3","$4 }'`
	if [ -z "${top}" ] ; then
		echo "\`${command} ${adm} top pods --containers -n ${namespace}\` not working"
		exit 1
	fi
}
PARSE_CONTAINER_STATS() {
	DEBUG 2 "pod_name: $pod_name"
	DEBUG 2 "container_name: $container_name"
	container_number=$(($container_number+1))
	cpu_current=`echo "$top" | grep "${pod_name}," | grep ",${container_name}," | cut -d ',' -f 3 | sed 's/[^0-9]*//g'`
	mem_current=`echo "$top" | grep "${pod_name}," | grep ",${container_name}," | cut -d ',' -f 4 | sed 's/[^0-9]*//g'`
	container_zeros=0

	if [ -n "${show_details}" ] ; then
		# proc_comm=`${command} exec $pod_name -c $container_name -- ps w -eo rss,comm 2>/dev/null | sort -k 1 -n | tail -1 | sed -e 's/^[ \t]*//g' | cut -d ' ' -f 2-999`
		# if [[ -z $proc_comm ]] ; then
		# 	DEBUG 11 "ps is missing in container ${container_name} in pod ${pod_name}"
		# 	proc_comm=""
		# 	proc_args=""
		# 	xms=""
		# 	xmx=""
		# else 
		# 	proc_args=`${command} exec $pod_name -c $container_name -- ps w -eo rss,args 2>/dev/null | sort -k 1 -n | tail -1 | sed -e 's/^[ \t]*//g' | cut -d ' ' -f 2-999`
		# 	proc_args=`echo \"${proc_args}\"`
		# 	xms=`echo ${proc_args} | grep -o Xms[0-9]*[A-Za-z]*`
		# 	xmx=`echo ${proc_args} | grep -o Xmx[0-9]*[A-Za-z]*`
		# fi
		proc_comm=`${command} exec $pod_name -c $container_name -- bash -c 'biggest_pid=1; biggest_rss=0; for pid in \`ls /proc/ | grep [0-9]\` ; do if [ -f /proc/$pid/statm ] ; then RSS=\`cat /proc/$pid/statm | cut -d " " -f 2\` ; fi ; if [ $RSS -gt $biggest_rss ] ; then biggest_rss=$RSS ; biggest_pid=$pid; fi; done; cat /proc/$biggest_pid/comm'  | tr '\000' ' '`
		proc_args=`${command} exec $pod_name -c $container_name -- bash -c 'biggest_pid=1; biggest_rss=0; for pid in \`ls /proc/ | grep [0-9]\` ; do if [ -f /proc/$pid/statm ] ; then RSS=\`cat /proc/$pid/statm | cut -d " " -f 2\` ; fi ; if [ $RSS -gt $biggest_rss ] ; then biggest_rss=$RSS ; biggest_pid=$pid; fi; done; cat /proc/$biggest_pid/cmdline'  | tr '\000' ' '`
		proc_args=`echo \"${proc_args//\"/\"\"}\"`
		xms=`echo ${proc_args} | grep -o Xms[0-9]*[A-Za-z]*`
		xmx=`echo ${proc_args} | grep -o Xmx[0-9]*[A-Za-z]*`
		DEBUG 12 "${command} exec $pod_name -c $container_name -- ps w -eo rss,comm | sort -k 1 -n | tail -1 | awk '{ print \$2 }'"
		DEBUG 12 "Container Process Short: $proc_comm"
		DEBUG 12 "Container Process Full: $proc_args"

		contInfo=`${command} get pod ${pod_name} -o=jsonpath='{.spec.containers[?(@.name=="'${container_name}'")].env}{";"}{.spec.containers[?(@.name=="'${container_name}'")].livenessProbe}{";"}{.spec.containers[?(@.name=="'${container_name}'")].readinessProbe}'`
		DEBUG 11 "${command} get pod ${pod_name} -o=jsonpath='{.spec.containers[?(@.name=="'"'${container_name}'"'")].env}{"'";"'"}{.spec.containers[?(@.name=="'"'${container_name}'"'")].livenessProbe}{"'";"'"}{.spec.containers[?(@.name=="'"'${container_name}'"'")].readinessProbe}'"
		envVar=`echo "${contInfo}}" | cut -d ';' -f 1`
		envVar=`echo \"${envVar//\"/\"\"}\"`
		livenessProbe=`echo "${contInfo}}" | cut -d ';' -f 2`
		readinessProbe=`echo "${contInfo}" | cut -d ';' -f 3`
		DEBUG 11 "Environment Variables: $envVar"
		DEBUG 11 "Liveness Probe: $livenessProbe"
		DEBUG 11 "Readiness Probe: $readinessProbe"

		failureThresh_l=`echo "$livenessProbe" | grep -o "\"failureThreshold\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		initDelay_l=`echo "$livenessProbe" | grep -o "\"initialDelaySeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		period_l=`echo "$livenessProbe" | grep -o "\"periodSeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		successThresh_l=`echo "$livenessProbe" | grep -o "\"successThreshold\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		timeout_l=`echo "$livenessProbe" | grep -o "\"timeoutSeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`

		failureThresh_r=`echo "$readinessProbe" | grep -o "\"failureThreshold\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		initDelay_r=`echo "$readinessProbe" | grep -o "\"initialDelaySeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		period_r=`echo "$readinessProbe" | grep -o "\"periodSeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		successThresh_r=`echo "$readinessProbe" | grep -o "\"successThreshold\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`
		timeout_r=`echo "$readinessProbe" | grep -o "\"timeoutSeconds\":[^},]*" | cut -d ':' -f 2 | sed -e 's/"//g'`

		es_request_raw=`echo $requests | grep -o "\"ephemeral-storage\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
		DEBUG 3 "es_request_raw:  ${es_request_raw}"
		es_request=`echo ${es_request_raw} | sed 's/[^0-9]*//g'`
		if [ -z "${es_request}" ] ; then
			es_request=0
			container_zeros=$(($container_zeros+1))
		fi
		if [[ "${es_request_raw}" =~ "Ki" ]] ; then
			es_request=$((${es_request}/1024))
		elif [[ "${es_request_raw}" =~ "Mi" ]] ; then
			es_request=${es_request}
		elif [[ "${es_request_raw}" =~ "Gi" ]] ; then
			es_request=$((${es_request}*1024))
		elif [[ "${es_limit_raw}" =~ "K" ]] ; then
			es_request=$((${es_request}*953674/1000000000))
		elif [[ "${es_request_raw}" =~ "M" ]] ; then
			es_request=$((${es_request}*953674/1000000))
		elif [[ "${es_request_raw}" =~ "G" ]] ; then
			es_request=$((${es_request}*953674/1000))
		else #bytes
			es_request=$((${es_request}/1024/1024))
		fi

		es_limit_raw=`echo "$limits" | grep -o "\"ephemeral-storage\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
		DEBUG 3 "es_limit_raw:  ${es_limit_raw}"
		es_limit=`echo ${es_limit_raw} | sed 's/[^0-9]*//g'`
		if [ -z "${es_limit}" ] ; then
			es_limit=0
			container_zeros=$(($container_zeros+1))
		fi
		if [[ "${es_limit_raw}" =~ "Ki" ]] ; then
			es_limit=$((${es_limit}/1024))
		elif [[ "${es_limit_raw}" =~ "Mi" ]] ; then
			es_limit=${es_limit}
		elif [[ "${es_limit_raw}" =~ "Gi" ]] ; then
			es_limit=$((${es_limit}*1024))
		elif [[ "${es_limit_raw}" =~ "K" ]] ; then
			es_limit=$((${es_limit}*953674/1000000000))
		elif [[ "${es_limit_raw}" =~ "M" ]] ; then
			es_limit=$((${es_limit}*953674/1000000))
		elif [[ "${es_limit_raw}" =~ "G" ]] ; then
			es_limit=$((${es_limit}*953674/1000))
		else #bytes
			es_limit=$((${es_limit}/1024/1024))
		fi	
	fi

	# THIS IS BROKEN
	# Something with the spacing changed in a kube update
	# This part still works: oc get pod aiops-topology-cassandra-0 -o=jsonpath='{.spec.containers[?(@.name=="aiops-topology-cassandra")].env}'
	
#	if [ -n "${show_heap}" ] ; then
#		env_variables=`${command} get pod $pod_name -o jsonpath="{.spec.containers[?(@.name==\"$container_name\")].env}" | tr -s '[[:space:]]' '\n'`
#		DEBUG 9 "env_variables $env_variables"
#		heap=`echo "$env_variables" | egrep 'HEAP_SIZE|NODE_HEAP_SIZE_MB|Xmx' -B1 -A1 | egrep 'value:|Xmx' | cut -d ':' -f 2 | tr "\n" ' ' | tr -s ' ' | sed -e 's/[ \t]*$//g'`
#		heap=`echo "${heap},"`
#		cache_size=`echo "$env_variables" | egrep 'KAIROSDB_ROW_KEY_CACHE_SIZE' -B1 -A1 | egrep 'value:' | cut -d ':' -f 2 | tr "\n" ' ' | tr -s ' ' | sed -e 's/[ \t]*$//g'`
#	fi
#	if [ -n "${cache_size}" ] ; then
#		cache_size=`echo "Row key cache ${cache_size}"`
#	fi
#	DEBUG 9 "heap $heap"
#	DEBUG 9 "cache_size $cache_size"
	
	if [ $parser_version = 1 ] ; then
		limits=`echo $resources | cut -d ' '  -f ${container_number} | grep -o "limits[^}]*}"`
		requests=`echo $resources | cut -d ' '  -f ${container_number} | grep -o "requests[^}]*}"`
		DEBUG 3 "limits $limits"
		DEBUG 3 "requests $requests"
	fi
	
	# IMPORTANT
	# Here is where the comma separated values are parsed from the pod results.  
	if [ $parser_version = 1 ] ; then
		mem_request_raw=`echo $requests | grep -o "\"memory\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
	else
		mem_request_raw=`echo "$resources" | head -${container_number} | tail -1 | grep -o 'requests:map\[[^]]*\]' | grep -o 'memory:[^ ]*' | cut -d ':' -f 2`
	fi
	DEBUG 3 "mem_request_raw:  ${mem_request_raw}"
	mem_request=`echo ${mem_request_raw} | sed 's/[^0-9]*//g'`
	if [ -z "${mem_request}" ] ; then
		mem_request=0
		container_zeros=$(($container_zeros+1))
	fi
	if [[ "${mem_request_raw}" =~ "Ki" ]] ; then
		mem_request=$((${mem_request}/1024))
	elif [[ "${mem_request_raw}" =~ "Mi" ]] ; then
		mem_request=${mem_request}
	elif [[ "${mem_request_raw}" =~ "Gi" ]] ; then
		mem_request=$((${mem_request}*1024))
	elif [[ "${mem_limit_raw}" =~ "K" ]] ; then
		mem_request=$((${mem_request}*953674/1000000000))
	elif [[ "${mem_request_raw}" =~ "M" ]] ; then
		mem_request=$((${mem_request}*953674/1000000))
	elif [[ "${mem_request_raw}" =~ "G" ]] ; then
		mem_request=$((${mem_request}*953674/1000))
	else #bytes
		mem_request=$((${mem_request}/1024/1024))
	fi
	
	if [ $parser_version = 1 ] ; then
		mem_limit_raw=`echo "$limits" | grep -o "\"memory\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
	else
		mem_limit_raw=`echo "$resources" | head -${container_number} | tail -1 | grep -o 'limits:map\[[^]]*\]' | grep -o 'memory:[^ ]*' | cut -d ':' -f 2`
	fi
	DEBUG 3 "mem_limit_raw:  ${mem_limit_raw}"
	mem_limit=`echo ${mem_limit_raw} | sed 's/[^0-9]*//g'`
	if [ -z "${mem_limit}" ] ; then
		mem_limit=0
		container_zeros=$(($container_zeros+1))
	fi
	if [[ "${mem_limit_raw}" =~ "Ki" ]] ; then
		mem_limit=$((${mem_limit}/1024))
	elif [[ "${mem_limit_raw}" =~ "Mi" ]] ; then
		mem_limit=${mem_limit}
	elif [[ "${mem_limit_raw}" =~ "Gi" ]] ; then
		mem_limit=$((${mem_limit}*1024))
	elif [[ "${mem_limit_raw}" =~ "K" ]] ; then
		mem_limit=$((${mem_limit}*953674/1000000000))
	elif [[ "${mem_limit_raw}" =~ "M" ]] ; then
		mem_limit=$((${mem_limit}*953674/1000000))
	elif [[ "${mem_limit_raw}" =~ "G" ]] ; then
		mem_limit=$((${mem_limit}*953674/1000))
	else #bytes
		mem_limit=$((${mem_limit}/1024/1024))
	fi	
	
	if [ $parser_version = 1 ] ; then
		cpu_request=`echo "$requests" | grep -o "\"cpu\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
	else
		cpu_request=`echo "$resources" | head -${container_number} | tail -1 | grep -o 'requests:map\[[^]]*\]' | grep -o 'cpu:[^ ]*' | cut -d ':' -f 2`
	fi
	DEBUG 3 "cpu_request:  ${cpu_request}"
	if [ -z "${cpu_request}" ] ; then
		cpu_request=0
		container_zeros=$(($container_zeros+1))
	fi
	if [[ "${cpu_request}" =~ "m" ]] ; then
		cpu_request=`echo ${cpu_request} | sed 's/[^0-9]*//g'`
	else
		cpu_request=$((${cpu_request}*1000))
	fi
		
	if [ $parser_version = 1 ] ; then
		cpu_limit=`echo "$limits" | grep -o "\"cpu\":\"[^},]*\"" | cut -d ':' -f 2 | sed -e 's/"//g'`	
	else
		cpu_limit=`echo "$resources" | head -${container_number} | tail -1 | grep -o 'limits:map\[[^]]*\]' | grep -o 'cpu:[^ ]*' | cut -d ':' -f 2`
	fi
	DEBUG 3 "cpu_limit:  ${cpu_limit}"
	if [ -z "${cpu_limit}" ] ; then
		cpu_limit=0
		container_zeros=$(($container_zeros+1))
	fi
	if [[ "${cpu_limit}" =~ "m" ]] ; then
		cpu_limit=`echo ${cpu_limit} | sed 's/[^0-9]*//g'`			
	elif [[ "${cpu_limit}" =~ "Gi" ]] ; then #Bug, should not be Gi
		cpu_limit=0			
	else
		cpu_limit=$((${cpu_limit}*1000))
	fi
	
	if [ -z "${cpu_current}" ] ; then
		cpu_current=0
	fi
	if [ -z "${mem_current}" ] ; then
		mem_current=0
	fi	
}
SUM_CONTAINER_STATS() {
#DEBUG 0 "SUM_CONTAINER_STATS"
	if [ ${print_pod_groups} -eq 1 ] ; then
		DEBUG 2 "Storing data for $container_name container_number $container_number" 
		container_name_array[$container_number]=$container_name
		if [ -z ${container_cpu_current_sum_array[container_number]} ] ; then
			container_cpu_current_sum_array[$container_number]=$cpu_current
		else
			container_cpu_current_sum_array[$container_number]=$(($cpu_current + ${container_cpu_current_sum_array[container_number]}))
		fi
		container_cpu_request_array[$container_number]=$cpu_request
		container_cpu_limit_array[$container_number]=$cpu_limit
		if [ -z ${container_mem_current_sum_array[container_number]} ] ; then
			container_mem_current_sum_array[$container_number]=$mem_current
		else
			container_mem_current_sum_array[$container_number]=$(($mem_current + ${container_mem_current_sum_array[container_number]}))
		fi
		container_mem_request_array[$container_number]=$mem_request
		container_mem_limit_array[$container_number]=$mem_limit

		container_proc_comm_array[$container_number]=$proc_comm
		container_proc_args_array[$container_number]=$proc_args
		container_xms_array[$container_number]=$xms
		container_xmx_array[$container_number]=$xmx

		container_envVar_array[$container_number]=$envVar
		
		container_failureThresh_l_array[$container_number]=$failureThresh_l
		container_initDelay_l_array[$container_number]=$initDelay_l
		container_period_l_array[$container_number]=$period_l
		container_successThresh_l_array[$container_number]=$successThresh_l
		container_timeout_l_array[$container_number]=$timeout_l

		container_failureThresh_r_array[$container_number]=$failureThresh_r
		container_initDelay_r_array[$container_number]=$initDelay_r
		container_period_r_array[$container_number]=$period_r
		container_successThresh_r_array[$container_number]=$successThresh_r
		container_timeout_r_array[$container_number]=$timeout_r

		container_es_request_array[$container_number]=$es_request
		container_es_limit_array[$container_number]=$es_limit
	fi
	
	pod_cpu_current=$((${pod_cpu_current}+${cpu_current}))
	pod_cpu_request=$((${pod_cpu_request}+${cpu_request}))
	pod_cpu_limit=$((${pod_cpu_limit}+${cpu_limit}))
	pod_mem_current=$((${pod_mem_current}+${mem_current}))
	pod_mem_request=$((${pod_mem_request}+${mem_request}))
	pod_mem_limit=$((${pod_mem_limit}+${mem_limit}))
	pod_zeros=$((${pod_zeros}+${container_zeros}))

	if [ ${category_number} -ne '9999' ] ; then
		if [ $container_number -eq '1' ] ; then category_pod_count_array[$category_number]=$((${category_pod_count_array[category_number]}+1)) ; fi		
		category_container_count_array[$category_number]=$((${category_container_count_array[category_number]}+1))
		category_zeros_array[$category_number]=$((${category_zeros_array[category_number]}+${container_zeros}))
		category_cpu_current_array[$category_number]=$((${category_cpu_current_array[category_number]}+${cpu_current}))
		category_cpu_request_array[$category_number]=$((${category_cpu_request_array[category_number]}+${cpu_request}))
		category_cpu_limit_array[$category_number]=$((${category_cpu_limit_array[category_number]}+${cpu_limit}))
		category_mem_current_array[$category_number]=$((${category_mem_current_array[category_number]}+${mem_current}))
		category_mem_request_array[$category_number]=$((${category_mem_request_array[category_number]}+${mem_request}))
		category_mem_limit_array[$category_number]=$((${category_mem_limit_array[category_number]}+${mem_limit}))
	fi
	if [ ${sub_category_number} -ne '9999' ] ; then
		if [ $container_number -eq '1' ] ; then sub_category_pod_count_array[$sub_category_number]=$((${sub_category_pod_count_array[sub_category_number]}+1)) ; fi		
		sub_category_container_count_array[$sub_category_number]=$((${sub_category_container_count_array[sub_category_number]}+1))
		sub_category_zeros_array[$sub_category_number]=$((${sub_category_zeros_array[sub_category_number]}+${container_zeros}))
		sub_category_cpu_current_array[$sub_category_number]=$((${sub_category_cpu_current_array[sub_category_number]}+${cpu_current}))
		sub_category_cpu_request_array[$sub_category_number]=$((${sub_category_cpu_request_array[sub_category_number]}+${cpu_request}))
		sub_category_cpu_limit_array[$sub_category_number]=$((${sub_category_cpu_limit_array[sub_category_number]}+${cpu_limit}))
		sub_category_mem_current_array[$sub_category_number]=$((${sub_category_mem_current_array[sub_category_number]}+${mem_current}))
		sub_category_mem_request_array[$sub_category_number]=$((${sub_category_mem_request_array[sub_category_number]}+${mem_request}))
		sub_category_mem_limit_array[$sub_category_number]=$((${sub_category_mem_limit_array[sub_category_number]}+${mem_limit}))
	fi
	
	if [ "${phase}" != "Running" ] ; then
		running="X"
		running_full="Stopped"
		namespace_stopped_cpu_current=$(($namespace_stopped_cpu_current+${cpu_current}))
		namespace_stopped_cpu_request=$(($namespace_stopped_cpu_request+${cpu_request}))
		namespace_stopped_cpu_limit=$(($namespace_stopped_cpu_limit+${cpu_limit}))
		namespace_stopped_mem_current=$(($namespace_stopped_mem_current+${mem_current}))
		namespace_stopped_mem_request=$(($namespace_stopped_mem_request+${mem_request}))
		namespace_stopped_mem_limit=$(($namespace_stopped_mem_limit+${mem_limit}))
		if [ $container_number -eq '1' ] ; then namespace_stopped_pod_count=$(($namespace_stopped_pod_count+1)) ; fi
		namespace_stopped_container_count=$(($namespace_stopped_container_count+1))
		namespace_stopped_zeros=$(($namespace_stopped_zeros+$container_zeros))
	else
		running=""
		running_full="Running"
		namespace_running_cpu_current=$(($namespace_running_cpu_current+${cpu_current}))
		namespace_running_cpu_request=$(($namespace_running_cpu_request+${cpu_request}))
		namespace_running_cpu_limit=$(($namespace_running_cpu_limit+${cpu_limit}))
		namespace_running_mem_current=$(($namespace_running_mem_current+${mem_current}))
		namespace_running_mem_request=$(($namespace_running_mem_request+${mem_request}))
		namespace_running_mem_limit=$(($namespace_running_mem_limit+${mem_limit}))
		if [ $container_number -eq '1' ] ; then namespace_running_pod_count=$(($namespace_running_pod_count+1)) ; fi
		namespace_running_container_count=$(($namespace_running_container_count+1))
		namespace_running_zeros=$(($namespace_running_zeros+$container_zeros))
	fi 
		
	namespace_total_cpu_current=$(($namespace_total_cpu_current+${cpu_current}))
	namespace_total_cpu_request=$(($namespace_total_cpu_request+${cpu_request}))
	namespace_total_cpu_limit=$(($namespace_total_cpu_limit+${cpu_limit}))
	namespace_total_mem_current=$(($namespace_total_mem_current+${mem_current}))
	namespace_total_mem_request=$(($namespace_total_mem_request+${mem_request}))
	namespace_total_mem_limit=$(($namespace_total_mem_limit+${mem_limit}))
	if [ $container_number -eq '1' ] ; then namespace_total_pod_count=$(($namespace_total_pod_count+1)) ; fi
	namespace_total_container_count=$(($namespace_total_container_count+1))
	namespace_total_zeros=$(($namespace_total_zeros+$container_zeros))
	if [ "${kind}" == "ReplicaSet" ] ; then
		kind_code="R${running}"
		kind_code_long="ReplicaSet"
		namespace_replica_cpu_current=$(($namespace_replica_cpu_current+${cpu_current}))
		namespace_replica_cpu_request=$(($namespace_replica_cpu_request+${cpu_request}))
		namespace_replica_cpu_limit=$(($namespace_replica_cpu_limit+${cpu_limit}))
		namespace_replica_mem_current=$(($namespace_replica_mem_current+${mem_current}))
		namespace_replica_mem_request=$(($namespace_replica_mem_request+${mem_request}))
		namespace_replica_mem_limit=$(($namespace_replica_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_replica_pod_count=$(($namespace_replica_pod_count+1))	; fi
		namespace_replica_container_count=$(($namespace_replica_container_count+1))	
		namespace_replica_zeros=$(($namespace_replica_zeros+$container_zeros))
	elif [ "${kind}" == "StatefulSet" ] ; then
		kind_code="S${running}"
		kind_code_long="StatefulSet"	
		namespace_stateful_cpu_current=$(($namespace_stateful_cpu_current+${cpu_current}))
		namespace_stateful_cpu_request=$(($namespace_stateful_cpu_request+${cpu_request}))
		namespace_stateful_cpu_limit=$(($namespace_stateful_cpu_limit+${cpu_limit}))
		namespace_stateful_mem_current=$(($namespace_stateful_mem_current+${mem_current}))
		namespace_stateful_mem_request=$(($namespace_stateful_mem_request+${mem_request}))
		namespace_stateful_mem_limit=$(($namespace_stateful_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_stateful_pod_count=$(($namespace_stateful_pod_count+1)) ; fi
		namespace_stateful_container_count=$(($namespace_stateful_container_count+1))	
		namespace_stateful_zeros=$(($namespace_stateful_zeros+$container_zeros))
	elif [ "${kind}" == "DaemonSet" ] ; then
		kind_code="D${running}"	
		kind_code_long="DaemonSet"	
		namespace_daemon_cpu_current=$(($namespace_daemon_cpu_current+${cpu_current}))
		namespace_daemon_cpu_request=$(($namespace_daemon_cpu_request+${cpu_request}))
		namespace_daemon_cpu_limit=$(($namespace_daemon_cpu_limit+${cpu_limit}))
		namespace_daemon_mem_current=$(($namespace_daemon_mem_current+${mem_current}))
		namespace_daemon_mem_request=$(($namespace_daemon_mem_request+${mem_request}))
		namespace_daemon_mem_limit=$(($namespace_daemon_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_daemon_pod_count=$(($namespace_daemon_pod_count+1)) ; fi
		namespace_daemon_container_count=$(($namespace_daemon_container_count+1))
		namespace_daemon_zeros=$(($namespace_daemon_zeros+$container_zeros))	
	elif [ "${kind}" == "Job" ] ; then
		kind_code="J${running}"	
		kind_code_long="Job"	
		namespace_job_cpu_current=$(($namespace_job_cpu_current+${cpu_current}))
		namespace_job_cpu_request=$(($namespace_job_cpu_request+${cpu_request}))
		namespace_job_cpu_limit=$(($namespace_job_cpu_limit+${cpu_limit}))
		namespace_job_mem_current=$(($namespace_job_mem_current+${mem_current}))
		namespace_job_mem_request=$(($namespace_job_mem_request+${mem_request}))
		namespace_job_mem_limit=$(($namespace_job_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_job_pod_count=$(($namespace_job_pod_count+1))	; fi
		namespace_job_container_count=$(($namespace_job_container_count+1))	
		namespace_job_zeros=$(($namespace_job_zeros+$container_zeros))
	elif [ "${kind}" == "ConfigMap" ] ; then
		kind_code="M${running}"
		kind_code_long="ConfigMap"	
		namespace_configmap_cpu_current=$(($namespace_configmap_cpu_current+${cpu_current}))
		namespace_configmap_cpu_request=$(($namespace_configmap_cpu_request+${cpu_request}))
		namespace_configmap_cpu_limit=$(($namespace_configmap_cpu_limit+${cpu_limit}))
		namespace_configmap_mem_current=$(($namespace_configmap_mem_current+${mem_current}))
		namespace_configmap_mem_request=$(($namespace_configmap_mem_request+${mem_request}))
		namespace_configmap_mem_limit=$(($namespace_configmap_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_configmap_pod_count=$(($namespace_configmap_pod_count+1)) ; fi
		namespace_configmap_container_count=$(($namespace_configmap_container_count+1))	
		namespace_configmap_zeros=$(($namespace_configmap_zeros+$container_zeros))
	elif [ "${kind}" == "Node" ] ; then
		kind_code="N${running}"
		kind_code_long="Node"	
		namespace_node_cpu_current=$(($namespace_node_cpu_current+${cpu_current}))
		namespace_node_cpu_request=$(($namespace_node_cpu_request+${cpu_request}))
		namespace_node_cpu_limit=$(($namespace_node_cpu_limit+${cpu_limit}))
		namespace_node_mem_current=$(($namespace_node_mem_current+${mem_current}))
		namespace_node_mem_request=$(($namespace_node_mem_request+${mem_request}))
		namespace_node_mem_limit=$(($namespace_node_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_node_pod_count=$(($namespace_node_pod_count+1)) ; fi	
		namespace_node_container_count=$(($namespace_node_container_count+1))	
		namespace_node_zeros=$(($namespace_node_zeros+$container_zeros))	
	elif [ "${kind}" == "CatalogSource" ] ; then
		kind_code="C${running}"	
		kind_code_long="CatalogSource"	
		namespace_catalog_cpu_current=$(($namespace_catalog_cpu_current+${cpu_current}))
		namespace_catalog_cpu_request=$(($namespace_catalog_cpu_request+${cpu_request}))
		namespace_catalog_cpu_limit=$(($namespace_catalog_cpu_limit+${cpu_limit}))
		namespace_catalog_mem_current=$(($namespace_catalog_mem_current+${mem_current}))
		namespace_catalog_mem_request=$(($namespace_catalog_mem_request+${mem_request}))
		namespace_catalog_mem_limit=$(($namespace_catalog_mem_limit+${mem_limit}))	
		if [ $container_number -eq '1' ] ; then namespace_catalog_pod_count=$(($namespace_catalog_pod_count+1)) ; fi	
		namespace_catalog_container_count=$(($namespace_catalog_container_count+1))	
		namespace_catalog_zeros=$(($namespace_catalog_zeros+$container_zeros))
	else 
		kind_code="?${running}"
		kind_code_long="Unknown"	
		namespace_unspecified_cpu_current=$(($namespace_unspecified_cpu_current+${cpu_current}))
		namespace_unspecified_cpu_request=$(($namespace_unspecified_cpu_request+${cpu_request}))
		namespace_unspecified_cpu_limit=$(($namespace_unspecified_cpu_limit+${cpu_limit}))
		namespace_unspecified_mem_current=$(($namespace_unspecified_mem_current+${mem_current}))
		namespace_unspecified_mem_request=$(($namespace_unspecified_mem_request+${mem_request}))
		namespace_unspecified_mem_limit=$(($namespace_unspecified_mem_limit+${mem_limit}))
		if [ $container_number -eq '1' ] ; then namespace_unspecified_pod_count=$(($namespace_unspecified_pod_count+1)) ; fi
		namespace_unspecified_container_count=$(($namespace_unspecified_container_count+1))		
		namespace_unspecified_zeros=$(($namespace_unspecified_zeros+$container_zeros))	
	fi
	if [ "${cost}" == "FREE" ] ; then
		kind_code="${kind_code},F"
	elif [ "${cost}" == "VIRTUAL_PROCESSOR_CORE" ] ; then
		kind_code="${kind_code},L"
	else
		kind_code="${kind_code},N"
	fi
}
SUM_NAMESPACE_STATS_TO_ALL() {

all_total_cpu_current=$(($namespace_total_cpu_current+$all_total_cpu_current))
all_total_cpu_request=$(($namespace_total_cpu_request+$all_total_cpu_request))
all_total_cpu_limit=$(($namespace_total_cpu_limit+$all_total_cpu_limit))
all_total_mem_current=$(($namespace_total_mem_current+$all_total_mem_current))
all_total_mem_request=$(($namespace_total_mem_request+$all_total_mem_request))
all_total_mem_limit=$(($namespace_total_mem_limit+$all_total_mem_limit))
all_total_pod_count=$(($namespace_total_pod_count+$all_total_pod_count))
all_total_container_count=$(($namespace_total_container_count+$all_total_container_count))
all_total_zeros=$(($namespace_total_zeros+$all_total_zeros))

all_running_cpu_current=$(($namespace_running_cpu_current+$all_running_cpu_current))
all_running_cpu_request=$(($namespace_running_cpu_request+$all_running_cpu_request))
all_running_cpu_limit=$(($namespace_running_cpu_limit+$all_running_cpu_limit))
all_running_mem_current=$(($namespace_running_mem_current+$all_running_mem_current))
all_running_mem_request=$(($namespace_running_mem_request+$all_running_mem_request))
all_running_mem_limit=$(($namespace_running_mem_limit+$all_running_mem_limit))
all_running_pod_count=$(($namespace_running_pod_count+$all_running_pod_count))
all_running_container_count=$(($namespace_running_container_count+$all_running_container_count))
all_running_zeros=$(($namespace_running_zeros+$all_running_zeros))

all_stopped_cpu_current=$(($namespace_stopped_cpu_current+$all_stopped_cpu_current))
all_stopped_cpu_request=$(($namespace_stopped_cpu_request+$all_stopped_cpu_request))
all_stopped_cpu_limit=$(($namespace_stopped_cpu_limit+$all_stopped_cpu_limit))
all_stopped_mem_current=$(($namespace_stopped_mem_current+$all_stopped_mem_current))
all_stopped_mem_request=$(($namespace_stopped_mem_request+$all_stopped_mem_request))
all_stopped_mem_limit=$(($namespace_stopped_mem_limit+$all_stopped_mem_limit))
all_stopped_pod_count=$(($namespace_stopped_pod_count+$all_stopped_pod_count))
all_stopped_container_count=$(($namespace_stopped_container_count+$all_stopped_container_count))
all_stopped_zeros=$(($namespace_stopped_zeros+$all_stopped_zeros))

all_replica_cpu_current=$(($namespace_replica_cpu_current+$all_replica_cpu_current))
all_replica_cpu_request=$(($namespace_replica_cpu_request+$all_replica_cpu_request))
all_replica_cpu_limit=$(($namespace_replica_cpu_limit+$all_replica_cpu_limit))
all_replica_mem_current=$(($namespace_replica_mem_current+$all_replica_mem_current))
all_replica_mem_request=$(($namespace_replica_mem_request+$all_replica_mem_request))
all_replica_mem_limit=$(($namespace_replica_mem_limit+$all_replica_mem_limit))
all_replica_pod_count=$(($namespace_replica_pod_count+$all_replica_pod_count))
all_replica_container_count=$(($namespace_replica_container_count+$all_replica_container_count))
all_replica_zeros=$(($namespace_replica_zeros+$all_replica_zeros))
all_stateful_cpu_current=$(($namespace_stateful_cpu_current+$all_stateful_cpu_current))
all_stateful_cpu_request=$(($namespace_stateful_cpu_request+$all_stateful_cpu_request))
all_stateful_cpu_limit=$(($namespace_stateful_cpu_limit+$all_stateful_cpu_limit))
all_stateful_mem_current=$(($namespace_stateful_mem_current+$all_stateful_mem_current))
all_stateful_mem_request=$(($namespace_stateful_mem_request+$all_stateful_mem_request))
all_stateful_mem_limit=$(($namespace_stateful_mem_limit+$all_stateful_mem_limit))
all_stateful_pod_count=$(($namespace_stateful_pod_count+$all_stateful_pod_count))
all_stateful_container_count=$(($namespace_stateful_container_count+$all_stateful_container_count))
all_stateful_zeros=$(($namespace_stateful_zeros+$all_stateful_zeros))
all_daemon_cpu_current=$(($namespace_daemon_cpu_current+$all_daemon_cpu_current))
all_daemon_cpu_request=$(($namespace_daemon_cpu_request+$all_daemon_cpu_request))
all_daemon_cpu_limit=$(($namespace_daemon_cpu_limit+$all_daemon_cpu_limit))
all_daemon_mem_current=$(($namespace_daemon_mem_current+$all_daemon_mem_current))
all_daemon_mem_request=$(($namespace_daemon_mem_request+$all_daemon_mem_request))
all_daemon_mem_limit=$(($namespace_daemon_mem_limit+$all_daemon_mem_limit))
all_daemon_pod_count=$(($namespace_daemon_pod_count+$all_daemon_pod_count))
all_daemon_container_count=$(($namespace_daemon_container_count+$all_daemon_container_count))
all_daemon_zeros=$(($namespace_daemon_zeros+$all_daemon_zeros))
all_job_cpu_current=$(($namespace_job_cpu_current+$all_job_cpu_current))
all_job_cpu_request=$(($namespace_job_cpu_request+$all_job_cpu_request))
all_job_cpu_limit=$(($namespace_job_cpu_limit+$all_job_cpu_limit))
all_job_mem_current=$(($namespace_job_mem_current+$all_job_mem_current))
all_job_mem_request=$(($namespace_job_mem_request+$all_job_mem_request))
all_job_mem_limit=$(($namespace_job_mem_limit+$all_job_mem_limit))
all_job_pod_count=$(($namespace_job_pod_count+$all_job_pod_count))
all_job_container_count=$(($namespace_job_container_count+$all_job_container_count))
all_job_zeros=$(($namespace_job_zeros+$all_job_zeros))
all_configmap_cpu_current=$(($namespace_configmap_cpu_current+$all_configmap_cpu_current))
all_configmap_cpu_request=$(($namespace_configmap_cpu_request+$all_configmap_cpu_request))
all_configmap_cpu_limit=$(($namespace_configmap_cpu_limit+$all_configmap_cpu_limit))
all_configmap_mem_current=$(($namespace_configmap_mem_current+$all_configmap_mem_current))
all_configmap_mem_request=$(($namespace_configmap_mem_request+$all_configmap_mem_request))
all_configmap_mem_limit=$(($namespace_configmap_mem_limit+$all_configmap_mem_limit))
all_configmap_pod_count=$(($namespace_configmap_pod_count+$all_configmap_pod_count))
all_configmap_container_count=$(($namespace_configmap_container_count+$all_configmap_container_count))
all_configmap_zeros=$(($namespace_configmap_zeros+$all_configmap_zeros))
all_node_cpu_current=$(($namespace_node_cpu_current+$all_node_cpu_current))
all_node_cpu_request=$(($namespace_node_cpu_request+$all_node_cpu_request))
all_node_cpu_limit=$(($namespace_node_cpu_limit+$all_node_cpu_limit))
all_node_mem_current=$(($namespace_node_mem_current+$all_node_mem_current))
all_node_mem_request=$(($namespace_node_mem_request+$all_node_mem_request))
all_node_mem_limit=$(($namespace_node_mem_limit+$all_node_mem_limit))
all_node_pod_count=$(($namespace_node_pod_count+$all_node_pod_count))
all_node_container_count=$(($namespace_node_container_count+$all_node_container_count))
all_node_zeros=$(($namespace_node_zeros+$all_node_zeros))
all_catalog_cpu_current=$(($namespace_catalog_cpu_current+$all_catalog_cpu_current))
all_catalog_cpu_request=$(($namespace_catalog_cpu_request+$all_catalog_cpu_request))
all_catalog_cpu_limit=$(($namespace_catalog_cpu_limit+$all_catalog_cpu_limit))
all_catalog_mem_current=$(($namespace_catalog_mem_current+$all_catalog_mem_current))
all_catalog_mem_request=$(($namespace_catalog_mem_request+$all_catalog_mem_request))
all_catalog_mem_limit=$(($namespace_catalog_mem_limit+$all_catalog_mem_limit))
all_catalog_pod_count=$(($namespace_catalog_pod_count+$all_catalog_pod_count))
all_catalog_container_count=$(($namespace_catalog_container_count+$all_catalog_container_count))
all_catalog_zeros=$(($namespace_catalog_zeros+$all_catalog_zeros))
all_unspecified_cpu_current=$(($namespace_unspecified_cpu_current+$all_unspecified_cpu_current))
all_unspecified_cpu_request=$(($namespace_unspecified_cpu_request+$all_unspecified_cpu_request))
all_unspecified_cpu_limit=$(($namespace_unspecified_cpu_limit+$all_unspecified_cpu_limit))
all_unspecified_mem_current=$(($namespace_unspecified_mem_current+$all_unspecified_mem_current))
all_unspecified_mem_request=$(($namespace_unspecified_mem_request+$all_unspecified_mem_request))
all_unspecified_mem_limit=$(($namespace_unspecified_mem_limit+$all_unspecified_mem_limit))
all_unspecified_pod_count=$(($namespace_unspecified_pod_count+$all_unspecified_pod_count))
all_unspecified_container_count=$(($namespace_unspecified_container_count+$all_unspecified_container_count))
all_unspecified_zeros=$(($namespace_unspecified_zeros+$all_unspecified_zeros))
}
INIT_POD_GROUPS() {
	replica_count=1
	container_number=0
	unset container_name_array
	unset container_cpu_current_sum_array
	unset container_cpu_request_array
	unset container_cpu_limit_array
	unset container_mem_current_sum_array
	unset container_mem_request_array
	unset container_mem_limit_array
	unset container_group_print_string
}
INIT_CATEGORIES() {
DEBUG 8 "INIT_CATEGORIES"
category_number="9999"
category_container_count_array=(0 0 0 0 0 0 0 0)
category_pod_count_array=(0 0 0 0 0 0 0 0)
category_zeros_array=(0 0 0 0 0 0 0 0)
category_cpu_current_array=(0 0 0 0 0 0 0 0)
category_cpu_request_array=(0 0 0 0 0 0 0 0)
category_cpu_limit_array=(0 0 0 0 0 0 0 0)
category_mem_current_array=(0 0 0 0 0 0 0 0)
category_mem_request_array=(0 0 0 0 0 0 0 0)
category_mem_limit_array=(0 0 0 0 0 0 0 0)
if [ "${namespace}" == "${cp4waiops_namespace_name}" ] ; then
category_name_array=(
"Other"
"IAF" 
"Bedrock" 
"ZEN"  
"AIMgr" 
"EvtMgr" )
else 
	category_name_array=("All")
fi
full_category_name=""
}
CATEGORY_CHECK() {
DEBUG 8 "CATEGORY_CHECK START"
category_number="9999"
#TODO - Change categories here:
case ${pod_name_short} in
#IAF
	*iaf*) 							category_number=1 ;; 
#Bedrock	
	*ibm-nginx*) 					category_number=2 ;; 
	*setup-nginx*) 					category_number=2 ;; 
	*ibm-common-service*) 			category_number=2 ;;  
#ZEN	
	*zen*) 							category_number=3 ;; 
	*translations*) 				category_number=3 ;; 
	*walkme-tours*) 				category_number=3 ;; 
	*usermgmt*) 					category_number=3 ;; 
	*create-secrets-job*) 			category_number=3 ;; 
#AIManager
	*aimanager*) 					category_number=4 ;; 
	*elasticsea-*) 					category_number=4 ;; 
	*strimz*) 						category_number=4 ;; 
	*learner*) 						category_number=4 ;; 
	*iam-*) 						category_number=4 ;; 
	*ibm-elasticsearch-operator*) 	category_number=4 ;; 
	*manageindicies*) 				category_number=4 ;; 
	*model*) 						category_number=4 ;; 
	*odl-event-processor*) 			category_number=4 ;; 
	*snow*) 						category_number=4 ;; 
	*jobmonitor*) 					category_number=4 ;; 
	*c-example*) 					category_number=4 ;;
	*couchdb-operator*) 			category_number=4 ;; 
	*redis-operator*) 				category_number=4 ;; 
	*postgreservice-operator*) 		category_number=4 ;; 
	*vault*) 						category_number=4 ;; 
	*connector*) 					category_number=4 ;; 
	*cp4waiops-eventprocesso*)		category_number=4 ;; 
	*vault-*)						category_number=4 ;; 
	*edge-*)						category_number=4 ;; 
	conn-*)							category_number=4 ;; 
	*cp4waiops-*)					category_number=4 ;; 
	*aiops*-ui*)					category_number=4 ;; 
	*aiops-*-user*)					category_number=4 ;; 
	*post-aiops*)					category_number=4 ;; 
	*post-aiops*)					category_number=4 ;; 
	*camel-k*) 						category_number=4 ;; 
	*scm-*) 						category_number=4 ;; 
	*connector-utils-controller*) 	category_number=4 ;; 
	*kong*) 						category_number=4 ;;
#Event Manager
	*ir-*) 							category_number=5 ;; 
	*aiops-topology*) 				category_number=5 ;; 
	*evtmanager*) 					category_number=5 ;; 
	*emgateway*) 					category_number=5 ;; 
	*asm*) 							category_number=5 ;; 
	*netcool*) 						category_number=5 ;; 
	*noi*) 							category_number=5 ;; 
	*cem*) 							category_number=5 ;;  
#Other
	*)								category_number=0 ;;
esac
if [ ${category_number} -gt ${#category_name_array[@]} ] ; then
	category_number=0
fi
SUB_CATEGORY_CHECK
full_category_name=""
sub_category_name=""
if [ ${category_number} -ne '9999'  ] ; then
	if [ ${sub_category_number} -ne '9999' ]  && [ -n "${sub_category_name_array[$sub_category_number]}" ] ; then
		DEBUG 20 "category_number: $category_number sub_category_number: $sub_category_number \"${sub_category_name_array[$sub_category_number]}\" \"${category_name_array[$category_number]}\" \"${category_name_array[$category_number]}\""
		if [ -n "${category_name_array[$category_number]}" ] ; then
			DEBUG 20 "sub_category_name_array[$sub_category_number]: ${sub_category_name_array[$sub_category_number]}"
			sub_category_name=`echo "${sub_category_name_array[$sub_category_number]}" | sed "s/${category_name_array[$category_number]} //g" | sed "s/${category_name_array[$category_number]}//g"`
		fi
		DEBUG 20 "sub_category_name: $sub_category_name"
		if [ -n "${sub_category_name}" ] ; then
			full_category_name=`echo " ${category_name_array[$category_number]} ${sub_category_name}" | sed -e 's/[ \t]*$//g'`
		else 
			full_category_name=`echo " ${category_name_array[$category_number]}" | sed -e 's/[ \t]*$//g'`			
		fi
		
		DEBUG 20 "End"
	else
		full_category_name=" ${category_name_array[$category_number]}"	
	fi	
fi
DEBUG 20 "full_category_name \"$full_category_name\" $category_number $sub_category_number"
DEBUG 8 "CATEGORY_CHECK END"
}
INIT_SUB_CATEGORIES() {
DEBUG 8 "INIT_SUB_CATEGORIES"
sub_category_number="9999"
sub_category_container_count_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_pod_count_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_zeros_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_cpu_current_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_cpu_request_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_cpu_limit_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_mem_current_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_mem_request_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
sub_category_mem_limit_array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

if [ "${namespace}" == "${cp4waiops_namespace_name}" ] ; then
sub_category_name_array=(
"Other"
"IAF ElasticSearch" #1
"IAF Kafka & ZK" #2
"Bedrock Nginx" #3
"ZEN" #4
""
""
""
""
""
"AIMgr EvtProc (Flink)" #10
""
"AIMgr Minio" #12
"AIMgr Postgres" #13
""
""
"AIMgr Learner${learner_subcategory_extra}" #16
"AIMgr CouchDB" #17
"AIMgr Redis" #18
""
"AIMgr AIO" #20
"AIMgr Modeltrain" #21
"AIMgr UI"  #22
"AIMgr Edge" #23
"AIMgr Vault" #24
"AIMgr CamelK" #25
"AIMgr Kong" #26
""
""
""
"" #30
""
""
""
"EvtMgr IR LC (Flink)" #34
"EvtMgr IR LC" #35
"EvtMgr IR Core" #36
"EvtMgr IR Analytics" #37
"EvtMgr Cassandra" #38
"EvtMgr Topology" #39
""
""
""
""
""
""
""
""
""
""
"" #50
)
else 
	sub_category_name_array=("All")
fi
}
SUB_CATEGORY_CHECK() {
DEBUG 8 "SUB_CATEGORY_CHECK START"
sub_category_number="9999"
#TODO - Change categories here:
case ${pod_name_short} in
#IAF
	*elastic-operator*) 				sub_category_number=1 ;; 
	*iaf-system-elasticsearch*) 		sub_category_number=1 ;; 
	*iaf-system-entity-operator*) 		sub_category_number=2 ;; 
	*iaf-system-kafka*) 				sub_category_number=2 ;; 
	*iaf-system-zookeeper*) 			sub_category_number=2 ;; 
#Bedrock	
	*ibm-common-service-operator*) 		sub_category_number=3 ;;
	*ibm-nginx*) 						sub_category_number=3 ;; 
	*setup-nginx*) 						sub_category_number=3 ;; 
#ZEN	
	*zen*) 								sub_category_number=4 ;;  
	*translations*) 					sub_category_number=4 ;; 
	*walkme-tours*) 					sub_category_number=4 ;; 
	*usermgmt*) 						sub_category_number=4 ;; 
	*iam-config-job*) 					sub_category_number=4 ;; 
	*create-secrets-job*) 				sub_category_number=4 ;; 
	
#AIManager		
	*cp4waiops-eventprocessor*)			sub_category_number=10 ;; 
	*minio*) 							sub_category_number=12 ;; 
	*postgres*) 						sub_category_number=13 ;; 
	*learner*) 							sub_category_number=16 ;; 
	*couchdb-operator*)					sub_category_number=17 ;;  
	*c-example-couchdb*)				sub_category_number=17 ;;
	*redis-operator*)					sub_category_number=18 ;;  
	*c-example-redis*)					sub_category_number=18 ;; 
	
	*aimanager-operator*) 				sub_category_number=20 ;;
	*aimanager-aio*) 					sub_category_number=20 ;; 
	model*) 							sub_category_number=21 ;; 
	*aiops*ui*)				 			sub_category_number=22 ;; 
	*post-aiops*)				 		sub_category_number=22 ;;  
#Connectors 
	*edge-*)							sub_category_number=23 ;;
	*vault-*)							sub_category_number=24 ;; 	
	*camel-k*) 							sub_category_number=25 ;; 
	*connector-controller*) 			sub_category_number=25 ;; 
	*connector-synchronizer*) 			sub_category_number=25 ;; 
	*scm-handlers*) 					sub_category_number=25 ;; 
	*snow-handlers*) 					sub_category_number=25 ;; 
#Kong	
	*kong*) 							sub_category_number=26 ;;	
	
			
	*ir-lifecycle-eventprocessor*)		sub_category_number=34 ;; 
	*ir-lifecycle-*)					sub_category_number=35 ;; 
	*ir-core-*)							sub_category_number=36 ;; 
	*ir-ai-operator-*)					sub_category_number=37 ;; 
	*ir-analytics-*)					sub_category_number=37 ;; 
	*aiops-topology-cassandra*)			sub_category_number=38 ;; 
	*asm-operator*) 					sub_category_number=39 ;; 
	*aiops-topology-*)					sub_category_number=39 ;; 	
	
#Other	
	*)									sub_category_number=0 ;;
esac
if [ ${sub_category_number} -gt ${#sub_category_name_array[@]} ] ; then
	sub_category_number=0
fi
DEBUG 8 "SUB_CATEGORY_CHECK END"
}
LOOP_PODS() {

ORIGINAL_IFS=$IFS
IFS=$'\n' 
for pod in $1 ; do 
	DEBUG 2
	DEBUG 2 "--------------------------------------------------------------------"
	DEBUG 2 "pod $pod"
	pod_name=`echo "$pod" | cut -d ',' -f 1`
	#pod_name_short=`echo "$pod_name" | sed -e 's/-[a-z0-9]\{9,10\}-[a-z0-9]\{5\}$//g' | sed -e 's/-[0-9]*$//g' | sed -e 's/-[a-z0-9]\{5\}$//g'`
	#pod_name_short=`echo "$pod_name" | sed -e 's/-[a-z0-9]\{8,10\}-[a-z0-9]\{5\}$//g' | sed -e 's/-[a-z0-9]\{5\}$//g' | sed -e 's/-[0-9]*$//g' `
	#Get a shorter name for grouping of pods, eg cassandra-0 cassandra-1 cassandra-2 becomes just cassandra
	pod_name_short=`echo "$pod_name"  | sed -e 's/-[a-z0-9]\{19,21\}-[0-9]-build$//g' | sed -e 's/-[a-z0-9]\{8,15\}$\|-[a-z0-9]\{8,10\}-[a-z0-9]\{5\}$\|-[a-z0-9]\{5\}$\|-[0-9]*$//g'`

	DEBUG 10 "pod_name       $pod_name"
	DEBUG 10 "pod_name_short                                                                         $pod_name_short"
	if [ "${pod_name_short}" == "${previous_pod_name_short}" ] ; then
		replica_count=$((${replica_count}+1))
		DEBUG 3 "Still on same pod group $pod_name_short, pod number ${replica_count}"		
	else 
		DEBUG 3 "New pod group $pod_name_short $category_number"
		PRINT_POD_GROUP
		namespace=`echo "${pod}" | cut -d ',' -f 6`
		CATEGORY_CHECK
	fi
	
	previous_pod_name_short=$pod_name_short
	containers=`echo "$pod" | cut -d ',' -f 2`
	node=`echo "${pod}" | cut -d ',' -f 3`
	if [ -n "${nodes}" ] ; then
		if [[ "${nodes}" != *"${node}"* ]] ; then
			continue
		fi
	fi
	phase=`echo "${pod}" | cut -d ',' -f 4`
	if [ "${phase}" != "Running" ] ; then
		if [ "${show_only_running}" == 1 ] ; then
			continue
		fi
	fi 
	kind=`echo "${pod}" | cut -d ',' -f 5`
	
	#Licensing
	cost=`echo "${pod}" | cut -d ',' -f 7`
	
	
	if [ $parser_version == '1' ] ; then
		resources=`echo "${pod}" | cut -d ',' -f 8-99 `
	else
		resources=`echo "${pod}" | cut -d ',' -f 8 | sed -e 's/ map\[/\nmap\[/g' `	
	fi
	DEBUG 3 "pod resources: $resources"
	
	INIT_POD_STATS
	#IMPORTANT
	for container_name in $containers ; do 
		PARSE_CONTAINER_STATS
		SUM_CONTAINER_STATS
		PRINT_CONTAINER
	done	
	
	container_count=`echo "$containers" | wc -w`
	PRINT_POD

	IFS=$'\n' 
done

PRINT_POD_GROUP
IFS=$ORIGINAL_IFS
}

PRINT_HEADER() {
DEBUG 12 "PRINT_HEADER"
print_in_csv=$1
printf "%s\n" "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
if [ ${show_summary_only} == 0 ] && [ ${show_total_only} == 0 ] ; then
	final_1="Node Name"
	final_2="or"
	final_3="Replica Count"
fi
if [ -n "${whole_cpu}" ] ; then
	cpu_label="Cores"
else	
	cpu_label="(m)"
fi
if [ ${report} -eq '1' ] && [ ${print_in_csv} -eq '1' ]; then
	echo "Namespace,Category,Sub Category,Pod Name,Container Name,Pod Count,Container Count,Report Row Type,Kubernetes Type,Running,Memory - Current % of Request,Memory - Current Total (Mi),Memory - Request Total (Mi),Memory - Limit Total (Mi),CPU - Current % of Request,CPU - Current Total ${cpu_label},CPU - Request Total ${cpu_label},CPU - Limit Total ${cpu_label},Memory - Current per Replica (Mi),Memory - Request per Replica (Mi),Memory - Limit per Replica (Mi),CPU - Current per Replica ${cpu_label},CPU - Request per Replica ${cpu_label},CPU - Limit per Replica ${cpu_label},Missing request or limit occurances,Ephemeral Storage Request (Mi),Ephemeral Storage Limit (Mi),Liveness Probe Failure Threshold,Liveness Probe Initial Delay (s),Liveness Probe Period (s),Liveness Probe Success Threshold,Liveness Probe Timeout (s),Readiness Probe Failure Threshold,Readiness Probe Initial Delay (s),Readiness Probe Period (s),Readiness Probe Success Threshold,Readiness Probe Timeout (s),Xms,Xmx,Process Name,Process Command,Environment Variables" > $report_log	
fi
if [ ${print_in_csv} -eq '1' ]; then
	if [ ${show_total_only} == 0 ] && [ -z ${show_details} ]; then
		printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %3s, %3s,\n" "Namespace," "Pods," "Containers," "$final_1 $final_2 $final_3" "Memory % Current" "Memory (Mi) Current" "Memory (Mi) Request" "Memory (Mi) Limit"  "CPU % Current" "CPU $cpu_label Current" "CPU $cpu_label Request" "CPU $cpu_label Limit" "Occurances of Zero" "Status Codes" "Free or Licensed" > $output_log
	elif [ ${show_total_only} == 0 ] && [ -n ${show_details} ] ; then
		printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %3s, %3s, %7s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s\n" "Namespace," "Pods," "Containers," "$final_1 $final_2 $final_3" "Memory % Current" "Memory (Mi) Current" "Memory (Mi) Request" "Memory (Mi) Limit"  "CPU % Current" "CPU $cpu_label Current" "CPU $cpu_label Request" "CPU $cpu_label Limit" "Occurances of Zero" "Status Codes" "Free or Licensed" "Ephemeral Storage Request (Mi)" "Ephemeral Storage Limit (Mi)" "Liveness Probe Failure Threshold" "Liveness Probe Initial Delay (s)" "Liveness Probe Period (s)" "Liveness Probe Success Threshold" "Liveness Probe Timeout (s)" "Readiness Probe Failure Threshold" "Readiness Probe Initial Delay (s)" "Readiness Probe Period (s)" "Readiness Probe Success Threshold" "Readiness Probe Timeout (s)" "Xms" "Xmx" "Process Name" "Process Command" "Environment Variables" > $output_log
	elif [ ${show_total_only} == 1 ] && [ -n ${show_details} ] ; then
		printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %3s, %3s, %7s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s\n" "Namespace," "Pods," "Containers," "" "Memory % Current" "Memory (Mi) Current" "Memory (Mi) Request" "Memory (Mi) Limit"  "CPU % Current" "CPU $cpu_label Current" "CPU $cpu_label Request" "CPU $cpu_label Limit" "Occurances of Zero" "Status Codes" "Free or Licensed" "Ephemeral Storage Request (Mi)" "Ephemeral Storage Limit (Mi)" "Liveness Probe Failure Threshold" "Liveness Probe Initial Delay (s)" "Liveness Probe Period (s)" "Liveness Probe Success Threshold" "Liveness Probe Timeout (s)" "Readiness Probe Failure Threshold" "Readiness Probe Initial Delay (s)" "Readiness Probe Period (s)" "Readiness Probe Success Threshold" "Readiness Probe Timeout (s)" "Xms" "Xmx" "Process Name" "Process Command" "Environment Variables"> $output_log	
	else
		printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %3s, %3s,\n" "Namespace," "Pods," "Containers," "" "Memory % Current" "Memory (Mi) Current" "Memory (Mi) Request" "Memory (Mi) Limit"  "CPU % Current" "CPU $cpu_label Current" "CPU $cpu_label Request" "CPU $cpu_label Limit" "Occurances of Zero" "Status Codes" "Free or Licensed" > $output_log
	fi
fi

if [ ${show_total_only} == 0 ] && [ -z ${show_details} ] ; then
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n"     ""           ",,"     ","           "$final_1" "Memory" "Memory" "Memory" "Memory" "CPU"  "CPU"         "CPU"         "CPU"         "0s" 
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n"     ""           ",,"     ","           "$final_2" "%"      "(Mi)"   "(Mi)"   "(Mi)"   "%"    "$cpu_label"  "$cpu_label"  "$cpu_label"  "" 
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n"     "Namespace", "Pods,"  "Containers," "$final_3" "Curr"   "Curr"   "Req"    "Limit"  "Curr" "Curr"        "Req"         "Limit"       "" 
elif [ ${show_total_only} == 0 ] && [ -n ${show_details} ] ; then
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n"     ""           ",,"     ","           "$final_1" "Memory" "Memory" "Memory" "Memory" "CPU"  "CPU"         "CPU"         "CPU"         "0s" "ES"    "ES"   "LP"     "LP"         "LP"	   "LP"     "LP"      "RP"     "RP"         "RP"	 "RP"     "RP"      ","   ","   ","       ","       ","
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n"     ""           ",,"     ","           "$final_2" "%"      "(Mi)"   "(Mi)"   "(Mi)"   "%"    "$cpu_label"  "$cpu_label"  "$cpu_label"  ""   "(Mi)"  "(Mi)" "Fail"   "(s)"  	  "(s)"	   "Succ"   "(s)"     "Fail"   "(s)"  	    "(s)"	 "Succ"   "(s)"     ","   ","   ","       "Process" "Environment"
	printf "%-35s %62s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n"     "Namespace", "Pods,"  "Containers," "$final_3" "Curr"   "Curr"   "Req"    "Limit"  "Curr" "Curr"        "Req"         "Limit"       ""   "Limit" "Req"  "Thresh" "Init Delay" "Period" "Thresh" "Timeout" "Thresh" "Init Delay" "Period" "Thresh" "Timeout" "Xms" "Xmx" "Process" "Command" "Variables"
elif [ ${show_total_only} == 1 ] && [ -n ${show_details} ] ; then
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n" ""           ""      ",,,"         "" "Memory" "Memory" "Memory" "Memory" "CPU"  "CPU"        "CPU"        "CPU"        "0s" "ES"   "ES"    "LP"     "LP"         "LP"	   "LP"     "LP"      "RP"     "RP"         "RP"	 "RP"     "RP"      ","   ","   ","       ","       ","
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n" ""           ""      ",,,"         "" "%"      "(Mi)"   "(Mi)"   "(Mi)"   "%"    "$cpu_label" "$cpu_label" "$cpu_label" ""   "(Mi)" "(Mi)"  "Fail"   "(s)"  	  "(s)"	   "Succ"   "(s)"     "Fail"   "(s)"  	    "(s)"	 "Succ"   "(s)"     ","   ","   ","       "Process" "Environment"
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %25s, %100s, %100s,\n" "Namespace," "Pods," "Containers," "" "Curr"   "Curr"   "Req"    "Limit"  "Curr" "Curr"       "Req"        "Limit"      ""   "Req"  "Limit" "Thresh" "Init Delay" "Period" "Thresh" "Timeout" "Thresh" "Init Delay" "Period" "Thresh" "Timeout" "Xms" "Xmx" "Process" "Command" "Variables"
else	
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" ""           ""      ",,,"         "" "Memory" "Memory" "Memory" "Memory" "CPU"  "CPU"        "CPU"        "CPU"        "0s" 
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" ""           ""      ",,,"         "" "%"      "(Mi)"   "(Mi)"   "(Mi)"   "%"    "$cpu_label" "$cpu_label" "$cpu_label" "" 
	printf "%-50s %11s %11s %15s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "Namespace," "Pods," "Containers," "" "Curr"   "Curr"   "Req"    "Limit"  "Curr" "Curr"       "Req"        "Limit"      "" 
fi
}
PRINT_CONTAINER() {
	if [ -z "${namespace}" ] ; then
		namespace="none"
	fi
	if [ "${mem_request}" -ne 0 ] ; then
		mem_current_percent=`echo "${mem_current} ${mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		mem_current_percent=""
	fi			
	if [ "${cpu_request}" -ne 0 ] ; then
		cpu_current_percent=`echo "${cpu_current} ${cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		cpu_current_percent=""
	fi
	
	if [ -n "${whole_cpu}" ] ; then	
		cpu_current_print=`echo "${cpu_current} 1000" | awk '{printf "%.2f", $1 / $2}'`
		cpu_request_print=`echo "${cpu_request} 1000" | awk '{printf "%.2f", $1 / $2}'`
		cpu_limit_print=`echo "${cpu_limit} 1000" | awk '{printf "%.2f", $1 / $2}'`
	else
		cpu_current_print=${cpu_current}
		cpu_request_print=${cpu_request}
		cpu_limit_print=${cpu_limit}
	fi
	
	if [ ${setup_csv} -eq '0' ] || [ ${report} -eq '1' ] ; then
		namespace_print=`echo "${namespace}${full_category_name}" | awk '{ print substr( $0, length($0)-33, length($0) ) }'`
		pod_name_print=`echo $pod_name | awk '{ print substr( $0, length($0)-59, length($0) ) }'`
		container_name_print=`echo $container_name | awk '{ print substr( $0, length($0)-42, length($0) ) }'`
	else
		namespace_print="${namespace}${full_category_name}"
		pod_name_print=$pod_name
		container_name_print=$container_name
	fi
	#DEBUG 0 "container_name_print $container_name_print"
	#IMPORTANT
	if [ -n "${show_details}" ] ; then
		container_print_string[${container_number}]=`printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, C$kind_code, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %19s, %100s, %100s\n" "$namespace_print," "$pod_name_print" "$container_name_print" "$node" "${mem_current_percent}" "${mem_current}" "${mem_request}" "${mem_limit}" "${cpu_current_print}" "${cpu_current_percent}" "${cpu_request_print}" "${cpu_limit_print}" "${container_zeros}" "${es_request}" "${es_limit}" "${failureThresh_l}" "${initDelay_l}" "${period_l}" "${successThresh_l}" "${timeout_l}" "${failureThresh_r}" "${initDelay_r}" "${period_r}" "${successThresh_r}" "${timeout_r}" "${xms}" "${xmx}" "${proc_comm}" "${proc_args}" "${envVar}"`
	else
		container_print_string[${container_number}]=`printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, C$kind_code,\n" "$namespace_print," "$pod_name_print" "$container_name_print" "$node" "${mem_current_percent}" "${mem_current}" "${mem_request}" "${mem_limit}" "${cpu_current_percent}" "${cpu_current_print}" "${cpu_request_print}" "${cpu_limit_print}" "${container_zeros}"`
	fi
	
}
PRINT_POD() {
if [ $print_pods -eq '1' ] ; then
	
	if [ "${mem_request}" -ne 0 ] ; then
		pod_mem_current_percent=`echo "${pod_mem_current} ${pod_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		pod_mem_current_percent=""
	fi			
	if [ "${cpu_request}" -ne 0 ] ; then
		pod_cpu_current_percent=`echo "${pod_cpu_current} ${pod_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		pod_cpu_current_percent=""
	fi
	
	if [ -n "${whole_cpu}" ] ; then		
		pod_cpu_current_print=`echo "$pod_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
		pod_cpu_request_print=`echo "$pod_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
		pod_cpu_limit_print=`echo "$pod_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
	else
		pod_cpu_current_print=${pod_cpu_current}
		pod_cpu_request_print=${pod_cpu_request}
		pod_cpu_limit_print=${pod_cpu_limit}
	fi
	if [ ${show_total_only} == 0 ] && [ ${show_summary_only} == 0 ] ; then
		if [ ${setup_csv} -eq '0' ] || [ ${report} -eq '1' ] ; then
			namespace_print=`echo "${namespace}${full_category_name}" | awk '{ print substr( $0, length($0)-33, length($0) ) }'`
			pod_name_print=`echo $pod_name | awk '{ print substr( $0, length($0)-59, length($0) ) }'`
			container_name_print=`echo $container_name | awk '{ print substr( $0, length($0)-42, length($0) ) }'`
		else
			namespace_print="${namespace}${full_category_name}"
			pod_name_print=$pod_name
			container_name_print=$container_name
		fi
		if [ ${container_count} -gt 1 ] ; then	
			if [ ${show_pod_results} -eq 1 ] ; then
				printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, P$kind_code,\n" "$namespace_print," "$pod_name_print" "POD_total_for_${container_count}_containers" "$node" "${pod_mem_current_percent}" "$pod_mem_current" "$pod_mem_request" "$pod_mem_limit" "${pod_cpu_current_percent}" "$pod_cpu_current_print" "$pod_cpu_request_print" "$pod_cpu_limit_print" "$pod_zeros" | tee -a $output_log
			fi
			if [ ${show_container_results} -eq 1 ] ; then
				for (( i=1; i<=${#container_print_string[@]}; i++ )); do
					echo "${container_print_string[$i]}" | tee -a $output_log
				done
			fi
		else 
			if [ -n "${show_details}" ] ; then 
				printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, P$kind_code, %4s, %5s, %6s, %10s, %6s, %6s, %7s, %6s, %10s, %6s, %6s, %7s, %15s, %15s, %19s, %100s, %100s,\n" "$namespace_print," "$pod_name_print" "$container_name_print" "$node" "${pod_mem_current_percent}" "$pod_mem_current" "$pod_mem_request" "$pod_mem_limit" "${pod_cpu_current_percent}" "$pod_cpu_current_print" "$pod_cpu_request_print" "$pod_cpu_limit_print" "$pod_zeros" "${es_request}" "${es_limit}" "${failureThresh_l}" "${initDelay_l}" "${period_l}" "${successThresh_l}" "${timeout_l}" "${failureThresh_r}" "${initDelay_r}" "${period_r}" "${successThresh_r}" "${timeout_r}" "${xms}" "${xmx}" "$proc_comm" "${proc_args}" "${envVar}" | tee -a $output_log
			else
				printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, P$kind_code,\n" "$namespace_print," "$pod_name_print" "$container_name_print" "$node" "${pod_mem_current_percent}" "$pod_mem_current" "$pod_mem_request" "$pod_mem_limit" "${pod_cpu_current_percent}" "$pod_cpu_current_print" "$pod_cpu_request_print" "$pod_cpu_limit_print" "$pod_zeros" | tee -a $output_log
			fi
		fi
	fi
fi
}
PRINT_POD_GROUP_LOOP_CONTAINERS() {
	pod_cpu_current=0
	pod_cpu_request=0
	pod_cpu_limit=0
	pod_mem_current=0
	pod_mem_request=0
	pod_mem_limit=0
	container_number=0
	i=1
	containers_count=${#container_name_array[@]}
	#DEBUG 0 "1 containers_count $containers_count"
	for container_name in "${container_name_array[@]}" ; do
		container_number=$(($container_number+1))
		if [ $sum_pod_groups -eq '0' ] ; then #Single container usage (default view for reports)
			container_mem_current_single=`echo "${container_mem_current_sum_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 / $2}'`
			container_mem_request_single=${container_mem_request_array[container_number]}
			container_mem_limit_single=${container_mem_limit_array[container_number]}
			
			container_cpu_current_single=`echo "${container_cpu_current_sum_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 / $2}'`
			container_cpu_request_single=${container_cpu_request_array[container_number]}
			container_cpu_limit_single=${container_cpu_limit_array[container_number]}
			
			container_mem_current=${container_mem_current_single}
			container_mem_request=${container_mem_request_single}
			container_mem_limit=${container_mem_limit_single}
			
			container_cpu_current=${container_cpu_current_single}
			container_cpu_request=${container_cpu_request_single}
			container_cpu_limit=${container_cpu_limit_single}
		fi
		if [ $sum_pod_groups -eq '1' ] || [ $report -eq '1' ] ; then #Multiple container usage, used to get the totals for all replicas
			container_mem_current_total=${container_mem_current_sum_array[container_number]}
			container_mem_request_total=`echo "${container_mem_request_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 * $2}'`
			container_mem_limit_total=`echo "${container_mem_limit_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 * $2}'`
				
			container_cpu_current_total=${container_cpu_current_sum_array[container_number]}
			container_cpu_request_total=`echo "${container_cpu_request_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 * $2}'`
			container_cpu_limit_total=`echo "${container_cpu_limit_array[container_number]} ${replica_count}" | awk '{printf "%d", $1 * $2}'`
			if [ $report -eq '0' ] ; then #If not doing the report, use the totals because you set sum_pod_groups
				container_mem_current=${container_mem_current_total}
				container_mem_request=${container_mem_request_total}
				container_mem_limit=${container_mem_limit_total}
				
				container_cpu_current=${container_cpu_current_total}
				container_cpu_request=${container_cpu_request_total}
				container_cpu_limit=${container_cpu_limit_total}
			fi
		fi
		if [ ${show_container_results} -eq 1 ] || [ ${container_number} -eq 1 ] ; then 			
			if [ "$container_mem_request" -ne 0 ] ; then
				container_mem_percent=`echo "${container_mem_current} ${container_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				container_mem_percent=""
			fi			
			if [ "$container_cpu_request" -ne 0 ] ; then
				container_cpu_percent=`echo "${container_cpu_current} ${container_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				container_cpu_percent=""
			fi
			
			if [ -n "${whole_cpu}" ] ; then		
				container_cpu_current_print=`echo "${container_cpu_current} 1000" | awk '{printf "%.2f", $1 / $2}'`
				container_cpu_request_print=`echo "${container_cpu_request} 1000" | awk '{printf "%.2f", $1 / $2}'`
				container_cpu_limit_print=`echo "${container_cpu_limit} 1000" | awk '{printf "%.2f", $1 / $2}'`
				if [ ${report} -eq '1' ] ; then
					container_cpu_current_total_print=`echo "${container_cpu_current_total} 1000" | awk '{printf "%.2f", $1 / $2}'`
					container_cpu_request_total_print=`echo "${container_cpu_request_total} 1000" | awk '{printf "%.2f", $1 / $2}'`
					container_cpu_limit_total_print=`echo "${container_cpu_limit_total} 1000" | awk '{printf "%.2f", $1 / $2}'`
				fi
			else
				container_cpu_current_print=${container_cpu_current}
				container_cpu_request_print=${container_cpu_request}
				container_cpu_limit_print=${container_cpu_limit}
				if [ ${report} -eq '1' ] ; then
					container_cpu_current_total_print=${container_cpu_current_total}
					container_cpu_request_total_print=${container_cpu_request_total}
					container_cpu_limit_total_print=${container_cpu_limit_total}
				fi
			fi	
			if [ ${setup_csv} -eq '0' ] || [ ${report} -eq '1' ] ; then
				namespace_print=`echo "${namespace}${full_category_name}" | awk '{ print substr( $0, length($0)-33, length($0) ) }'`
				previous_pod_name_short_print=`echo $previous_pod_name_short | awk '{ print substr( $0, length($0)-59, length($0) ) }'`
				previous_pod_name_short_report_print=${previous_pod_name_short}
				container_name_print=`echo $container_name | awk '{ print substr( $0, length($0)-42, length($0) ) }'`
			else
				namespace_print="${namespace}${full_category_name}"
				previous_pod_name_short_print=${previous_pod_name_short}
				container_name_print=${container_name}
			fi
			pod_count=${replica_count}
			container_count=${replica_count}
			if [ "${containers_count}" -gt '1' ] ; then
				current_type="C${kind_code}"
				pod_count=""
				if [ ${report} -eq '1' ] ; then
					report_row_type="C (container)"
					previous_pod_name_short_print=""
					#previous_pod_name_short_report_print=""
				fi
			else
				if [ ${report} -eq '1' ] ; then
					report_row_type="P (pod with single container)"
				fi
				current_type="P${kind_code}"			
			fi
			if [ ${report} -eq '1' ] ; then
				category_name_print=${category_name_array[$category_number]}
				sub_category_name_print=${sub_category_name_array[$sub_category_number]}
			if [ -n "${show_details}" ] ; then
					container_group_print_string_report[${container_number}]="${namespace},${category_name_print},${sub_category_name_print},${previous_pod_name_short_report_print},${container_name},${pod_count},${container_count},${report_row_type},${kind_code_long},${running_full},${container_mem_percent},${container_mem_current_total},${container_mem_request_total},${container_mem_limit_total},${container_cpu_percent},${container_cpu_current_total_print},${container_cpu_request_total_print},${container_cpu_limit_total_print},${container_mem_current},${container_mem_request},${container_mem_limit},${container_cpu_current_print},${container_cpu_request_print},${container_cpu_limit_print},${pod_zeros},${container_es_request_array[container_number]},${container_es_limit_array[container_number]},${container_failureThresh_l_array[container_number]},${container_initDelay_l_array[container_number]},${container_period_l_array[container_number]},${container_successThresh_l_array[container_number]},${container_timeout_l_array[container_number]},${container_failureThresh_r_array[container_number]},${container_initDelay_r_array[container_number]},${container_period_r_array[container_number]},${container_successThresh_r_array[container_number]},${container_timeout_r_array[container_number]},${container_xms_array[container_number]},${container_xmx_array[container_number]},${container_proc_comm_array[container_number]},${container_proc_args_array[container_number]},${container_envVar_array[container_number]},"
				else
					container_group_print_string_report[${container_number}]="${namespace},${category_name_print},${sub_category_name_print},${previous_pod_name_short_report_print},${container_name},${pod_count},${container_count},${report_row_type},${kind_code_long},${running_full},${container_mem_percent},${container_mem_current_total},${container_mem_request_total},${container_mem_limit_total},${container_cpu_percent},${container_cpu_current_total_print},${container_cpu_request_total_print},${container_cpu_limit_total_print},${container_mem_current},${container_mem_request},${container_mem_limit},${container_cpu_current_print},${container_cpu_request_print},${container_cpu_limit_print},${pod_zeros},"
				fi
			fi
			if [ -n "${show_details}" ] ; then
				container_group_print_string[${container_number}]=`printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, $current_type, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s, %3s,\n" "${namespace_print}," "${previous_pod_name_short_print}" "${container_name_print}" "${replica_count}" "${container_mem_percent}" "${container_mem_current}" "${container_mem_request}" "${container_mem_limit}" "${container_cpu_percent}" "${container_cpu_current_print}" "${container_cpu_request_print}" "${container_cpu_limit_print}" "$pod_zeros" "${container_proc_comm_array[container_number]}" "${container_es_request_array[container_number]}" "${container_es_limit_array[container_number]}" "${container_failureThresh_l_array[container_number]}" "${container_initDelay_l_array[container_number]}" "${container_period_l_array[container_number]}" "${container_successThresh_l_array[container_number]}" "${container_timeout_l_array[container_number]}" "${container_failureThresh_r_array[container_number]}" "${container_initDelay_r_array[container_number]}" "${container_period_r_array[container_number]}" "${container_successThresh_r_array[container_number]}" "${container_timeout_r_array[container_number]}" "${container_xms_array[container_number]}" "${container_xmx_array[container_number]}" "${container_proc_comm_array[container_number]}" "${container_proc_args_array[container_number]}" "${container_envVar_array[container_number]}"` 
			else
				container_group_print_string[${container_number}]=`printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, $current_type,\n" "${namespace_print}," "${previous_pod_name_short_print}" "${container_name_print}" "${replica_count}" "${container_mem_percent}" "${container_mem_current}" "${container_mem_request}" "${container_mem_limit}" "${container_cpu_percent}" "${container_cpu_current_print}" "${container_cpu_request_print}" "${container_cpu_limit_print}" "$pod_zeros"` 
			fi
		fi	
		pod_mem_current=$((${pod_mem_current}+${container_mem_current}))
		pod_mem_request=$((${pod_mem_request}+${container_mem_request}))
		pod_mem_limit=$((${pod_mem_limit}+${container_mem_limit}))	
		pod_cpu_current=$((${pod_cpu_current}+${container_cpu_current}))
		pod_cpu_request=$((${pod_cpu_request}+${container_cpu_request}))
		pod_cpu_limit=$((${pod_cpu_limit}+${container_cpu_limit}))
	done
}
PRINT_POD_GROUP_POD_SUMMARY() {
	if [ $container_number -gt 1 ] ; then	
		if [ "${pod_mem_request}" -ne 0 ] ; then
			pod_mem_percent=`echo "${pod_mem_current} ${pod_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			pod_mem_percent=""
		fi			
		if [ "${pod_cpu_request}" -ne 0 ] ; then
			pod_cpu_percent=`echo "${pod_cpu_current} ${pod_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			pod_cpu_percent=""
		fi
		if [ ${report} -eq '1' ] ; then
			pod_cpu_current_total=`echo "${pod_cpu_current} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
			pod_cpu_request_total=`echo "${pod_cpu_request} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
			pod_cpu_limit_total=`echo "${pod_cpu_limit} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
			
			pod_mem_current_total=`echo "${pod_mem_current} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
			pod_mem_request_total=`echo "${pod_mem_request} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
			pod_mem_limit_total=`echo "${pod_mem_limit} ${replica_count}" | awk '{printf "%.2f", $1 * $2}'`
		fi
		if [ -n "${whole_cpu}" ] ; then		
			pod_cpu_current_print=`echo "${pod_cpu_current} 1000" | awk '{printf "%.2f", $1 / $2}'`
			pod_cpu_request_print=`echo "${pod_cpu_request} 1000" | awk '{printf "%.2f", $1 / $2}'`
			pod_cpu_limit_print=`echo "${pod_cpu_limit} 1000" | awk '{printf "%.2f", $1 / $2}'`
			if [ ${report} -eq '1' ] ; then
				pod_cpu_current_total=`echo "${pod_cpu_current} 1000" | awk '{printf "%.2f", $1 / $2}'`
				pod_cpu_request_total=`echo "${pod_cpu_request} 1000" | awk '{printf "%.2f", $1 / $2}'`
				pod_cpu_limit_total=`echo "${pod_cpu_limit} 1000" | awk '{printf "%.2f", $1 / $2}'`			
			fi
		else
			pod_cpu_current_print=${pod_cpu_current}
			pod_cpu_request_print=${pod_cpu_request}
			pod_cpu_limit_print=${pod_cpu_limit}
		fi	
		if [ ${setup_csv} -eq '0' ] || [ ${report} -eq '1' ] ; then
			namespace_print=`echo "${namespace}${full_category_name}" | awk '{ print substr( $0, length($0)-33, length($0) ) }'`
			previous_pod_name_short_print=`echo $previous_pod_name_short | awk '{ print substr( $0, length($0)-57, length($0) ) }'`
			previous_pod_name_short_total_print=`echo "${previous_pod_name_short}_total" | awk '{ print substr( $0, length($0)-40, length($0) ) }'`
		else
			namespace_print="${namespace}${full_category_name}"
			previous_pod_name_short_print=$previous_pod_name_short
			previous_pod_name_short_total_print="${previous_pod_name_short}_total"
		fi
		current_type="T$kind_code"
		
		if [ ${report} -eq '1' ] ; then
			report_row_type="T (total for pod with multiple containers)"
			container_count_total=`echo "${replica_count} ${container_number}" | awk '{printf "%d", $1 * $2}'`
			category_name_print=${category_name_array[$category_number]}
			sub_category_name_print=${sub_category_name_array[$sub_category_number]}
			container_group_print_string_report[0]="${namespace},${category_name_print},${sub_category_name_print},${previous_pod_name_short_print},${previous_pod_name_short_total_print},${replica_count},${container_count_total},${report_row_type},${kind_code_long},${running_full},${pod_mem_percent},${pod_mem_current_total},${pod_mem_request_total},${pod_mem_limit_total},${pod_cpu_percent},${pod_cpu_current_total},${pod_cpu_request_total},${pod_cpu_limit_total},${pod_mem_current},${pod_mem_request},${pod_mem_limit},${pod_cpu_current_print},${pod_cpu_request_print},${pod_cpu_limit_print},${pod_zeros},"
		fi
		container_group_print_string[0]=`printf "%-35s %61s, %44s, %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s, ${current_type},\n" "${namespace_print}," "${previous_pod_name_short_print}" "${previous_pod_name_short_total_print}" "${replica_count}" "${pod_mem_percent}" "${pod_mem_current}" "${pod_mem_request}" "${pod_mem_limit}" "${pod_cpu_percent}" "${pod_cpu_current_print}" "${pod_cpu_request_print}" "${pod_cpu_limit_print}" "${pod_zeros}"`
		i=0		
	fi
}
PRINT_POD_GROUP() {
if [ "${container_number}" -gt 0 ] && [ ${print_pod_groups} -eq 1 ] ; then 
	DEBUG 2 "PRINT_POD_GROUP for $container_number containers in group $previous_pod_name_short"
	PRINT_POD_GROUP_LOOP_CONTAINERS

	PRINT_POD_GROUP_POD_SUMMARY
	
	if [ $container_number -gt 0 ] ; then 
		if [ ${show_container_results} -eq 0 ] ; then
			if [ $container_number -gt 1 ] ; then
				container_number=0
			else
				container_number=1
			fi
		fi
		while [ $i -le $container_number ] ; do
			if [ ${report} -eq '1' ] ; then
				echo "${container_group_print_string_report[$i]}" >> $report_log
			fi
			echo "${container_group_print_string[$i]}" | tee -a $output_log
			i=$(($i+1))
		done
	fi 
	INIT_POD_GROUPS
fi
}
PRINT_NAMESPACE_TOTALS() {
if [ ${show_total_only} == 0 ] ; then
	PRINT_HEADER 0
fi
if [ "${namespace_total_mem_request}" -ne 0 ] ; then
	namespace_total_mem_percent=`echo "${namespace_total_mem_current} ${namespace_total_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
else
	namespace_total_mem_percent=""
fi	
if [ "${namespace_total_cpu_request}" -ne 0 ] ; then
	namespace_total_cpu_percent=`echo "${namespace_total_cpu_current} ${namespace_total_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
else
	namespace_total_cpu_percent=""
fi	
if [ -n "${whole_cpu}" ] ; then		
	namespace_total_cpu_current_print=`echo "$namespace_total_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
	namespace_total_cpu_request_print=`echo "$namespace_total_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
	namespace_total_cpu_limit_print=`echo "$namespace_total_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
else	
	namespace_total_cpu_current_print=$namespace_total_cpu_current
	namespace_total_cpu_request_print=$namespace_total_cpu_request
	namespace_total_cpu_limit_print=$namespace_total_cpu_limit
fi
if [ ${show_total_only} == 0 ] ; then
	if [ ${namespace_replica_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then			
		if [ "${namespace_replica_mem_request}" -ne 0 ] ; then
			namespace_replica_mem_percent=`echo "${namespace_replica_mem_current} ${namespace_replica_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_replica_mem_percent=""
		fi	
		if [ "${namespace_replica_cpu_request}" -ne 0 ] ; then
			namespace_replica_cpu_percent=`echo "${namespace_replica_cpu_current} ${namespace_replica_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_replica_cpu_percent=""
		fi
		if [ -n "${whole_cpu}" ] ; then		
			namespace_replica_cpu_current_print=`echo "$namespace_replica_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_replica_cpu_request_print=`echo "$namespace_replica_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_replica_cpu_limit_print=`echo "$namespace_replica_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_replica_cpu_current_print=$namespace_replica_cpu_current
			namespace_replica_cpu_request_print=$namespace_replica_cpu_request
			namespace_replica_cpu_limit_print=$namespace_replica_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},ReplicaSet,,${namespace} - ReplicaSet,,$namespace_replica_pod_count,$namespace_replica_container_count,2 Kubernetes Type,,,${namespace_replica_mem_percent},$namespace_replica_mem_current,$namespace_replica_mem_request,$namespace_replica_mem_limit,${namespace_replica_cpu_percent},$namespace_replica_cpu_current_print,$namespace_replica_cpu_request_print,$namespace_replica_cpu_limit_print,,,,,,,$namespace_replica_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (ReplicaSet)," "$namespace_replica_pod_count," "$namespace_replica_container_count," "" "${namespace_replica_mem_percent}" "$namespace_replica_mem_current" "$namespace_replica_mem_request" "$namespace_replica_mem_limit" "${namespace_replica_cpu_percent}" "$namespace_replica_cpu_current_print" "$namespace_replica_cpu_request_print" "$namespace_replica_cpu_limit_print" "$namespace_replica_zeros" | tee -a $output_log
	fi
	if [ ${namespace_stateful_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then			
		if [ "${namespace_stateful_mem_request}" -ne 0 ] ; then
			namespace_stateful_mem_percent=`echo "${namespace_stateful_mem_current} ${namespace_stateful_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_stateful_mem_percent=""
		fi	
		if [ "${namespace_stateful_cpu_request}" -ne 0 ] ; then
			namespace_stateful_cpu_percent=`echo "${namespace_stateful_cpu_current} ${namespace_stateful_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_stateful_cpu_percent=""
		fi
		if [ -n "${whole_cpu}" ] ; then		
			namespace_stateful_cpu_current_print=`echo "$namespace_stateful_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_stateful_cpu_request_print=`echo "$namespace_stateful_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_stateful_cpu_limit_print=`echo "$namespace_stateful_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_stateful_cpu_current_print=$namespace_stateful_cpu_current
			namespace_stateful_cpu_request_print=$namespace_stateful_cpu_request
			namespace_stateful_cpu_limit_print=$namespace_stateful_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},StatefulSet,,${namespace} - Statefulset,,$namespace_stateful_pod_count,$namespace_stateful_container_count,2 Kubernetes Type,,,$namespace_stateful_mem_percent,$namespace_stateful_mem_current,$namespace_stateful_mem_request,$namespace_stateful_mem_limit,$namespace_stateful_cpu_percent,$namespace_stateful_cpu_current_print,$namespace_stateful_cpu_request_print,$namespace_stateful_cpu_limit_print,,,,,,,$namespace_stateful_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (StatefulSet)," "$namespace_stateful_pod_count," "$namespace_stateful_container_count," "" "$namespace_stateful_mem_percent" "$namespace_stateful_mem_current" "$namespace_stateful_mem_request" "$namespace_stateful_mem_limit" "$namespace_stateful_cpu_percent" "$namespace_stateful_cpu_current_print" "$namespace_stateful_cpu_request_print" "$namespace_stateful_cpu_limit_print" "$namespace_stateful_zeros" | tee -a $output_log
	fi
	if [ ${namespace_daemon_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_daemon_mem_request}" -ne 0 ] ; then
			namespace_daemon_mem_percent=`echo "${namespace_daemon_mem_current} ${namespace_daemon_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_daemon_mem_percent=""
		fi	
		if [ "${namespace_daemon_cpu_request}" -ne 0 ] ; then
			namespace_daemon_cpu_percent=`echo "${namespace_daemon_cpu_current} ${namespace_daemon_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_daemon_cpu_percent=""
		fi
		if [ -n "${whole_cpu}" ] ; then		
			namespace_daemon_cpu_current_print=`echo "$namespace_daemon_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_daemon_cpu_request_print=`echo "$namespace_daemon_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_daemon_cpu_limit_print=`echo "$namespace_daemon_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_daemon_cpu_current_print=$namespace_daemon_cpu_current
			namespace_daemon_cpu_request_print=$namespace_daemon_cpu_request
			namespace_daemon_cpu_limit_print=$namespace_daemon_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},DaemonSet,,${namespace} - DaemonSet,,$namespace_daemon_pod_count,$namespace_daemon_container_count,2 Kubernetes Type,,,$namespace_daemon_mem_percent,$namespace_daemon_mem_current,$namespace_daemon_mem_request,$namespace_daemon_mem_limit,$namespace_daemon_cpu_percent,$namespace_daemon_cpu_current_print,$namespace_daemon_cpu_request_print,$namespace_daemon_cpu_limit_print,,,,,,,$namespace_daemon_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (DaemonSet)," "$namespace_daemon_pod_count," "$namespace_daemon_container_count," "" "$namespace_daemon_mem_percent" "$namespace_daemon_mem_current" "$namespace_daemon_mem_request" "$namespace_daemon_mem_limit" "$namespace_daemon_cpu_percent" "$namespace_daemon_cpu_current_print" "$namespace_daemon_cpu_request_print" "$namespace_daemon_cpu_limit_print" "$namespace_daemon_zeros" | tee -a $output_log
		if [ $workers_count -ne '0' ] ; then
			namespace_daemon_per_worker_cpu_current=`echo "$namespace_daemon_cpu_current $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_cpu_request=`echo "$namespace_daemon_cpu_request $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_cpu_limit=`echo "$namespace_daemon_cpu_limit $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_mem_current=`echo "$namespace_daemon_mem_current $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_mem_request=`echo "$namespace_daemon_mem_request $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_mem_limit=`echo "$namespace_daemon_mem_limit $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_pod_count=`echo "$namespace_daemon_pod_count $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_container_count=`echo "$namespace_daemon_container_count $workers_count" | awk '{printf "%d", $1 / $2}'`
			namespace_daemon_per_worker_zeros=`echo "$namespace_daemon_zeros $workers_count" | awk '{printf "%d", $1 / $2}'`
			if [ "${namespace_daemon_per_worker_mem_request}" -ne 0 ] ; then
				namespace_daemon_per_worker_mem_percent=`echo "${namespace_daemon_per_worker_mem_current} ${namespace_daemon_per_worker_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				namespace_daemon_per_worker_mem_percent=""
			fi	
			if [ "${namespace_daemon_cpu_request}" -ne 0 ] ; then
				namespace_daemon_per_worker_cpu_percent=`echo "${namespace_daemon_per_worker_cpu_current} ${namespace_daemon_per_worker_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				namespace_daemon_per_worker_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				namespace_daemon_per_worker_cpu_current_print=`echo "$namespace_daemon_per_worker_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				namespace_daemon_per_worker_cpu_request_print=`echo "$namespace_daemon_per_worker_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				namespace_daemon_per_worker_cpu_limit_print=`echo "$namespace_daemon_per_worker_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else			
				namespace_daemon_per_worker_cpu_current_print=$namespace_daemon_per_worker_cpu_current
				namespace_daemon_per_worker_cpu_request_print=$namespace_daemon_per_worker_cpu_request
				namespace_daemon_per_worker_cpu_limit_print=$namespace_daemon_per_worker_cpu_limit
			fi
			if [ $report -eq '1' ] ; then
				echo "${namespace},DaemonSet per Worker,,${namespace} - DaemonSet per Worker,,$namespace_daemon_per_worker_pod_count,$namespace_daemon_per_worker_container_count,2 Kubernetes Type,,,$namespace_daemon_per_worker_mem_percent,$namespace_daemon_per_worker_mem_current,$namespace_daemon_per_worker_mem_request,$namespace_daemon_per_worker_mem_limit,$namespace_daemon_per_worker_cpu_percent,$namespace_daemon_per_worker_cpu_current_print,$namespace_daemon_per_worker_cpu_request_print,$namespace_daemon_per_worker_cpu_limit_print,,,,,,,$namespace_daemon_per_worker_zeros" >>$report_log
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s\n" "${namespace} (DaemonSet per Worker)," "$namespace_daemon_per_worker_pod_count," "$namespace_daemon_per_worker_container_count," "" "$namespace_daemon_per_worker_mem_percent" "$namespace_daemon_per_worker_mem_current" "$namespace_daemon_per_worker_mem_request" "$namespace_daemon_per_worker_mem_limit" "$namespace_daemon_per_worker_cpu_percent" "$namespace_daemon_per_worker_cpu_current_print" "$namespace_daemon_per_worker_cpu_request_print" "$namespace_daemon_per_worker_cpu_limit_print" "$namespace_daemon_per_worker_zeros" | tee -a $output_log
		fi
	fi
	if [ ${namespace_job_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_job_mem_request}" -ne 0 ] ; then
			namespace_job_mem_percent=`echo "${namespace_job_mem_current} ${namespace_job_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_job_mem_percent=""
		fi	
		if [ "${namespace_job_cpu_request}" -ne 0 ] ; then
			namespace_job_cpu_percent=`echo "${namespace_job_cpu_current} ${namespace_job_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_job_cpu_percent=""
		fi
		if [ -n "${whole_cpu}" ] ; then		
			namespace_job_cpu_current_print=`echo "$namespace_job_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_job_cpu_request_print=`echo "$namespace_job_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_job_cpu_limit_print=`echo "$namespace_job_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_job_cpu_current_print=$namespace_job_cpu_current
			namespace_job_cpu_request_print=$namespace_job_cpu_request
			namespace_job_cpu_limit_print=$namespace_job_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Job,,${namespace} - Job,,$namespace_job_pod_count,$namespace_job_container_count,2 Kubernetes Type,,,$namespace_job_cpu_percent,$namespace_job_mem_current,$namespace_job_mem_request,$namespace_job_mem_limit,$namespace_job_mem_percent,$namespace_job_cpu_current_print,$namespace_job_cpu_request_print,$namespace_job_cpu_limit_print,,,,,,,$namespace_job_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Job)," "$namespace_job_pod_count," "$namespace_job_container_count," "" "$namespace_job_cpu_percent" "$namespace_job_mem_current" "$namespace_job_mem_request" "$namespace_job_mem_limit" "$namespace_job_mem_percent" "$namespace_job_cpu_current_print" "$namespace_job_cpu_request_print" "$namespace_job_cpu_limit_print" "$namespace_job_zeros" | tee -a $output_log
	fi
	if [ ${namespace_configmap_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_configmap_mem_request}" -ne 0 ] ; then
			namespace_configmap_mem_percent=`echo "${namespace_configmap_mem_current} ${namespace_configmap_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_configmap_mem_percent=""
		fi	
		if [ "${namespace_configmap_cpu_request}" -ne 0 ] ; then
			namespace_configmap_cpu_percent=`echo "${namespace_configmap_cpu_current} ${namespace_configmap_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_configmap_cpu_percent=""
		fi
		if [ -n "${whole_cpu}" ] ; then		
			namespace_configmap_cpu_current_print=`echo "$namespace_configmap_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_configmap_cpu_request_print=`echo "$namespace_configmap_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_configmap_cpu_limit_print=`echo "$namespace_configmap_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_configmap_cpu_current_print=$namespace_configmap_cpu_current
			namespace_configmap_cpu_request_print=$namespace_configmap_cpu_request
			namespace_configmap_cpu_limit_print=$namespace_configmap_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},ConfigMap,,${namespace} - ConfigMap,,$namespace_configmap_pod_count,$namespace_configmap_container_count,2 Kubernetes Type,,,$namespace_configmap_mem_percent,$namespace_configmap_mem_current,$namespace_configmap_mem_request,$namespace_configmap_mem_limit,$namespace_configmap_cpu_percent,$namespace_configmap_cpu_current_print,$namespace_configmap_cpu_request_print,$namespace_configmap_cpu_limit_print,,,,,,,$namespace_configmap_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (ConfigMap)," "$namespace_configmap_pod_count," "$namespace_configmap_container_count," "" "$namespace_configmap_mem_percent" "$namespace_configmap_mem_current" "$namespace_configmap_mem_request" "$namespace_configmap_mem_limit" "$namespace_configmap_cpu_percent" "$namespace_configmap_cpu_current_print" "$namespace_configmap_cpu_request_print" "$namespace_configmap_cpu_limit_print" "$namespace_configmap_zeros" | tee -a $output_log
	fi
	if [ ${namespace_node_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then
		if [ "${namespace_node_mem_request}" -ne 0 ] ; then
			namespace_node_mem_percent=`echo "${namespace_node_mem_current} ${namespace_node_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_node_mem_percent=""
		fi	
		if [ "${namespace_node_cpu_request}" -ne 0 ] ; then
			namespace_node_cpu_percent=`echo "${namespace_node_cpu_current} ${namespace_node_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_node_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_node_cpu_current_print=`echo "$namespace_node_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_node_cpu_request_print=`echo "$namespace_node_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_node_cpu_limit_print=`echo "$namespace_node_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_node_cpu_current_print=$namespace_node_cpu_current
			namespace_node_cpu_request_print=$namespace_node_cpu_request
			namespace_node_cpu_limit_print=$namespace_node_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Node,,${namespace} - Node,,$namespace_node_pod_count,$namespace_node_container_count,2 Kubernetes Type,,,$namespace_node_mem_percent,$namespace_node_mem_current,$namespace_node_mem_request,$namespace_node_mem_limit,$namespace_node_cpu_percent,$namespace_node_cpu_current_print,$namespace_node_cpu_request_print,$namespace_node_cpu_limit_print,,,,,,,$namespace_node_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Node)," "$namespace_node_pod_count," "$namespace_node_container_count," "" "$namespace_node_mem_percent" "$namespace_node_mem_current" "$namespace_node_mem_request" "$namespace_node_mem_limit" "$namespace_node_cpu_percent" "$namespace_node_cpu_current_print" "$namespace_node_cpu_request_print" "$namespace_node_cpu_limit_print" "$namespace_node_zeros" | tee -a $output_log
	fi
	if [ ${namespace_catalog_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_catalog_mem_request}" -ne 0 ] ; then
			namespace_catalog_mem_percent=`echo "${namespace_catalog_mem_current} ${namespace_catalog_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_catalog_mem_percent=""
		fi	
		if [ "${namespace_catalog_cpu_request}" -ne 0 ] ; then
			namespace_catalog_cpu_percent=`echo "${namespace_catalog_cpu_current} ${namespace_catalog_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_catalog_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_catalog_cpu_current_print=`echo "$namespace_catalog_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_catalog_cpu_request_print=`echo "$namespace_catalog_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_catalog_cpu_limit_print=`echo "$namespace_catalog_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_catalog_cpu_current_print=$namespace_catalog_cpu_current
			namespace_catalog_cpu_request_print=$namespace_catalog_cpu_request
			namespace_catalog_cpu_limit_print=$namespace_catalog_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},CatalogSource,,${namespace} - CatalogSource,,$namespace_catalog_pod_count,$namespace_catalog_container_count,2 Kubernetes Type,,,$namespace_catalog_mem_percent,$namespace_catalog_mem_current,$namespace_catalog_mem_request,$namespace_catalog_mem_limit,$namespace_catalog_cpu_percent,$namespace_catalog_cpu_current_print,$namespace_catalog_cpu_request_print,$namespace_catalog_cpu_limit_print,,,,,,,$namespace_catalog_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (CatalogSource)," "$namespace_catalog_pod_count," "$namespace_catalog_container_count," "" "$namespace_catalog_mem_percent" "$namespace_catalog_mem_current" "$namespace_catalog_mem_request" "$namespace_catalog_mem_limit" "$namespace_catalog_cpu_percent" "$namespace_catalog_cpu_current_print" "$namespace_catalog_cpu_request_print" "$namespace_catalog_cpu_limit_print" "$namespace_catalog_zeros" | tee -a $output_log
	fi
	if [ ${namespace_unspecified_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_unspecified_mem_request}" -ne 0 ] ; then
			namespace_unspecified_mem_percent=`echo "${namespace_unspecified_mem_current} ${namespace_unspecified_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_unspecified_mem_percent=""
		fi	
		if [ "${namespace_unspecified_cpu_request}" -ne 0 ] ; then
			namespace_unspecified_cpu_percent=`echo "${namespace_unspecified_cpu_current} ${namespace_unspecified_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_unspecified_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_unspecified_cpu_current_print=`echo "$namespace_unspecified_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_unspecified_cpu_request_print=`echo "$namespace_unspecified_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_unspecified_cpu_limit_print=`echo "$namespace_unspecified_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_unspecified_cpu_current_print=$namespace_unspecified_cpu_current
			namespace_unspecified_cpu_request_print=$namespace_unspecified_cpu_request
			namespace_unspecified_cpu_limit_print=$namespace_unspecified_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Unspecified,,${namespace} - Unspecified,,$namespace_unspecified_pod_count,$namespace_unspecified_container_count,2 Kubernetes Type,,,$namespace_unspecified_mem_percent,$namespace_unspecified_mem_current,$namespace_unspecified_mem_request,$namespace_unspecified_mem_limit,$namespace_unspecified_cpu_percent,$namespace_unspecified_cpu_current_print,$namespace_unspecified_cpu_request_print,$namespace_unspecified_cpu_limit_print,,,,,,,$namespace_unspecified_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Unspecified)," "$namespace_unspecified_pod_count," "$namespace_unspecified_container_count," "" "$namespace_unspecified_mem_percent" "$namespace_unspecified_mem_current" "$namespace_unspecified_mem_request" "$namespace_unspecified_mem_limit" "$namespace_unspecified_cpu_percent" "$namespace_unspecified_cpu_current_print" "$namespace_unspecified_cpu_request_print" "$namespace_unspecified_cpu_limit_print" "$namespace_unspecified_zeros" | tee -a $output_log
	fi
	if [ ${namespace_stopped_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_stopped_mem_request}" -ne 0 ] ; then
			namespace_stopped_mem_percent=`echo "${namespace_stopped_mem_current} ${namespace_stopped_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_stopped_mem_percent=""
		fi	
		if [ "${namespace_stopped_cpu_request}" -ne 0 ] ; then
			namespace_stopped_cpu_percent=`echo "${namespace_stopped_cpu_current} ${namespace_stopped_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_stopped_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_stopped_cpu_current_print=`echo "$namespace_stopped_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_stopped_cpu_request_print=`echo "$namespace_stopped_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_stopped_cpu_limit_print=`echo "$namespace_stopped_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_stopped_cpu_current_print=$namespace_stopped_cpu_current
			namespace_stopped_cpu_request_print=$namespace_stopped_cpu_request
			namespace_stopped_cpu_limit_print=$namespace_stopped_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Not Running,,${namespace} - Not Running,,$namespace_stopped_pod_count,$namespace_stopped_container_count,2 Kubernetes Type,,,$namespace_stopped_mem_percent,$namespace_stopped_mem_current,$namespace_stopped_mem_request,$namespace_stopped_mem_limit,$namespace_stopped_cpu_percent,$namespace_stopped_cpu_current_print,$namespace_stopped_cpu_request_print,$namespace_stopped_cpu_limit_print,,,,,,,$namespace_stopped_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Not Running)," "$namespace_stopped_pod_count," "$namespace_stopped_container_count," "" "$namespace_stopped_mem_percent" "$namespace_stopped_mem_current" "$namespace_stopped_mem_request" "$namespace_stopped_mem_limit" "$namespace_stopped_cpu_percent" "$namespace_stopped_cpu_current_print" "$namespace_stopped_cpu_request_print" "$namespace_stopped_cpu_limit_print" "$namespace_stopped_zeros" | tee -a $output_log
	fi
	if [ ${namespace_running_pod_count} != 0 ] && [ ${namespace_stopped_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		if [ "${namespace_running_mem_request}" -ne 0 ] ; then
			namespace_running_mem_percent=`echo "${namespace_running_mem_current} ${namespace_running_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_running_mem_percent=""
		fi	
		if [ "${namespace_running_cpu_request}" -ne 0 ] ; then
			namespace_running_cpu_percent=`echo "${namespace_running_cpu_current} ${namespace_running_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_running_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_running_cpu_current_print=`echo "$namespace_running_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_running_cpu_request_print=`echo "$namespace_running_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_running_cpu_limit_print=`echo "$namespace_running_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else
			namespace_running_cpu_current_print=$namespace_running_cpu_current
			namespace_running_cpu_request_print=$namespace_running_cpu_request
			namespace_running_cpu_limit_print=$namespace_running_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Running,,${namespace} - Running,,$namespace_running_pod_count,$namespace_running_container_count,2 Kubernetes Type,,,$namespace_running_mem_percent,$namespace_running_mem_current,$namespace_running_mem_request,$namespace_running_mem_limit,$namespace_running_cpu_percent,$namespace_running_cpu_current_print,$namespace_running_cpu_request_print,$namespace_running_cpu_limit_print,,,,,,,$namespace_running_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Running)," "$namespace_running_pod_count," "$namespace_running_container_count," "" "$namespace_running_mem_percent" "$namespace_running_mem_current" "$namespace_running_mem_request" "$namespace_running_mem_limit" "$namespace_running_cpu_percent" "$namespace_running_cpu_current_print" "$namespace_running_cpu_request_print" "$namespace_running_cpu_limit_print" "$namespace_running_zeros" | tee -a $output_log
	fi
	if [ ${namespace_running_pod_count} != 0 ] && [ ${namespace_daemon_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
	
		namespace_running_minus_daemon_cpu_current=$(($namespace_running_cpu_current-$namespace_daemon_cpu_current))
		namespace_running_minus_daemon_cpu_request=$(($namespace_running_cpu_request-$namespace_daemon_cpu_request))
		namespace_running_minus_daemon_cpu_limit=$(($namespace_running_cpu_limit-$namespace_daemon_cpu_limit))
		namespace_running_minus_daemon_mem_current=$(($namespace_running_mem_current-$namespace_daemon_mem_current))
		namespace_running_minus_daemon_mem_request=$(($namespace_running_mem_request-$namespace_daemon_mem_request))
		namespace_running_minus_daemon_mem_limit=$(($namespace_running_mem_limit-$namespace_daemon_mem_limit))
		namespace_running_minus_daemon_pod_count=$(($namespace_running_pod_count-$namespace_daemon_pod_count))
		namespace_running_minus_daemon_container_count=$(($namespace_running_container_count-$namespace_daemon_container_count))
		namespace_running_minus_daemon_zeros=$(($namespace_running_zeros-$namespace_daemon_zeros))
		if [ "${namespace_running_minus_daemon_mem_request}" -ne 0 ] ; then
			namespace_running_minus_daemon_mem_percent=`echo "${namespace_running_minus_daemon_mem_current} ${namespace_running_minus_daemon_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_running_minus_daemon_mem_percent=""
		fi	
		if [ "${namespace_running_minus_daemon_cpu_request}" -ne 0 ] ; then
			namespace_running_minus_daemon_cpu_percent=`echo "${namespace_running_minus_daemon_cpu_current} ${namespace_running_minus_daemon_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
		else
			namespace_running_minus_daemon_cpu_percent=""
		fi	
		if [ -n "${whole_cpu}" ] ; then		
			namespace_running_minus_daemon_cpu_current_print=`echo "$namespace_running_minus_daemon_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_running_minus_daemon_cpu_request_print=`echo "$namespace_running_minus_daemon_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
			namespace_running_minus_daemon_cpu_limit_print=`echo "$namespace_running_minus_daemon_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
		else			
			namespace_running_minus_daemon_cpu_current_print=$namespace_running_minus_daemon_cpu_current
			namespace_running_minus_daemon_cpu_request_print=$namespace_running_minus_daemon_cpu_request
			namespace_running_minus_daemon_cpu_limit_print=$namespace_running_minus_daemon_cpu_limit
		fi
		if [ $report -eq '1' ] ; then
			echo "${namespace},Running minus DaemonSet,,${namespace} - Running minus DaemonSet,,$namespace_running_minus_daemon_pod_count,$namespace_running_minus_daemon_container_count,2 Kubernetes Type,,,$namespace_running_minus_daemon_mem_percent,$namespace_running_minus_daemon_mem_current,$namespace_running_minus_daemon_mem_request,$namespace_running_minus_daemon_mem_limit,$namespace_running_minus_daemon_cpu_percent,$namespace_running_minus_daemon_cpu_current_print,$namespace_running_minus_daemon_cpu_request_print,$namespace_running_minus_daemon_cpu_limit_print,,,,,,,$namespace_running_minus_daemon_zeros" >>$report_log
		fi
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Running minus DaemonSet)," "$namespace_running_minus_daemon_pod_count," "$namespace_running_minus_daemon_container_count," "" "$namespace_running_minus_daemon_mem_percent" "$namespace_running_minus_daemon_mem_current" "$namespace_running_minus_daemon_mem_request" "$namespace_running_minus_daemon_mem_limit" "$namespace_running_minus_daemon_cpu_percent" "$namespace_running_minus_daemon_cpu_current_print" "$namespace_running_minus_daemon_cpu_request_print" "$namespace_running_minus_daemon_cpu_limit_print" "$namespace_running_minus_daemon_zeros" | tee -a $output_log
	fi	
	
	PRINT_CATEGORY_TOTALS
	if [ $report -eq '1' ] ; then
		echo "${namespace},Total,,${namespace} - Total,,$namespace_total_pod_count,$namespace_total_container_count,1 Total,,,$namespace_total_mem_percent,$namespace_total_mem_current,$namespace_total_mem_request,$namespace_total_mem_limit,$namespace_total_cpu_percent,$namespace_total_cpu_current_print,$namespace_total_cpu_request_print,$namespace_total_cpu_limit_print,,,,,,,$namespace_total_zeros" >> $report_log
	fi	
	printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace} (Total)," "$namespace_total_pod_count," "$namespace_total_container_count," "" "$namespace_total_mem_percent" "$namespace_total_mem_current" "$namespace_total_mem_request" "$namespace_total_mem_limit" "$namespace_total_cpu_percent" "$namespace_total_cpu_current_print" "$namespace_total_cpu_request_print" "$namespace_total_cpu_limit_print" "$namespace_total_zeros" | tee -a $output_log
	printf "%s\n" "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	if [ ${show_summary_only} == 0 ] ; then
		printf "\n";
	fi
else
	printf "%-50s %10s, %10s,   %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "$namespace," "$namespace_total_pod_count" "$namespace_total_container_count" "" "$namespace_total_mem_percent" "$namespace_total_mem_current" "$namespace_total_mem_request" "$namespace_total_mem_limit" "$namespace_total_cpu_percent" "$namespace_total_cpu_current_print" "$namespace_total_cpu_request_print" "$namespace_total_cpu_limit_print" "$namespace_total_zeros" | tee -a $output_log
fi

}
PRINT_CATEGORY_TOTALS() {
for ((i=0; i < ${#category_name_array[@]}; i++)); do 
	if [ ${report} -eq '1' ] ; then
		#DEBUG 0 "category_pod_count_array[$i] ${category_pod_count_array[$i]}"
		#if [ "${category_name_array[$i]}" == "Other" ] && [ ${category_pod_count_array[$i]} -eq '0' ] ; then
		if [ ${category_pod_count_array[$i]} -eq '0' ] ; then
			DEBUG 1 "Skipping OTHER because it is empty."
		else
			echo "${namespace},${category_name_array[$i]},,${namespace} - ${category_name_array[$i]},,${category_pod_count_array[$i]},${category_container_count_array[$i]},3 Category,,,,${category_mem_current_array[$i]},${category_mem_request_array[$i]},${category_mem_limit_array[$i]},,${category_cpu_current_array[$i]},${category_cpu_request_array[$i]},${category_cpu_limit_array[$i]},,,,,,,${category_zeros_array[$i]}" >>$report_log
		fi
	fi		
	if [ ${category_pod_count_array[$i]} -gt '0' ] ; then
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace}  (${category_name_array[$i]})," "${category_pod_count_array[$i]}," "${category_container_count_array[$i]}," "" "" "${category_mem_current_array[$i]}" "${category_mem_request_array[$i]}" "${category_mem_limit_array[$i]}" "" "${category_cpu_current_array[$i]}" "${category_cpu_request_array[$i]}" "${category_cpu_limit_array[$i]}" "${category_zeros_array[$i]}" | tee -a $output_log
	fi
done
for ((i=0; i < ${#sub_category_name_array[@]}; i++)); do 
	if [ ${report} -eq '1' ] ; then
		#if [ "${sub_category_name_array[$i]}" == "Other" ] && [ ${sub_category_pod_count_array[$i]} -eq '0' ] ; then
		if [ ${sub_category_pod_count_array[$i]} -eq '0' ] ; then
			DEBUG 1 "Skipping OTHER because it is empty."
		else
			echo "${namespace},,${sub_category_name_array[$i]},${namespace} - ${sub_category_name_array[$i]},,${sub_category_pod_count_array[$i]},${sub_category_container_count_array[$i]},4 Sub Category,,,,${sub_category_mem_current_array[$i]},${sub_category_mem_request_array[$i]},${sub_category_mem_limit_array[$i]},,${sub_category_cpu_current_array[$i]},${sub_category_cpu_request_array[$i]},${sub_category_cpu_limit_array[$i]},,,,,,,${sub_category_zeros_array[$i]}" >>$report_log
		fi	
	fi
	if [ ${sub_category_pod_count_array[$i]} -gt '0' ] ; then
		printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "${namespace}   (${sub_category_name_array[$i]})," "${sub_category_pod_count_array[$i]}," "${sub_category_container_count_array[$i]}," "" "" "${sub_category_mem_current_array[$i]}" "${sub_category_mem_request_array[$i]}" "${sub_category_mem_limit_array[$i]}" "" "${sub_category_cpu_current_array[$i]}" "${sub_category_cpu_request_array[$i]}" "${sub_category_cpu_limit_array[$i]}" "${sub_category_zeros_array[$i]}" | tee -a $output_log
	fi
done
}
PRINT_ALL_TOTALS() {
if [ $namespace_count -gt 1 ] && [ $report -eq '0' ] ; then
#if [ ${namespace_count} -gt 1 ] ; then
	namespace="totals"
	if [ ${show_total_only} == 0 ] ; then
		SETUP_CSV
		PRINT_HEADER 1
	fi
	if [ "${all_total_mem_request}" -ne 0 ] ; then
		all_total_mem_percent=`echo "${all_total_mem_current} ${all_total_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		all_total_mem_percent=""
	fi	
	if [ "${all_total_cpu_request}" -ne 0 ] ; then
		all_total_cpu_percent=`echo "${all_total_cpu_current} ${all_total_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
	else
		all_total_cpu_percent=""
	fi	
	if [ -n "${whole_cpu}" ] ; then		
		all_total_cpu_current_print=`echo "$all_total_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
		all_total_cpu_request_print=`echo "$all_total_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
		all_total_cpu_limit_print=`echo "$all_total_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
	else	
		all_total_cpu_current_print=$all_total_cpu_current
		all_total_cpu_request_print=$all_total_cpu_request
		all_total_cpu_limit_print=$all_total_cpu_limit
	fi
	if [ ${show_total_only} == 0 ] ; then
		if [ ${all_replica_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_replica_mem_request}" -ne 0 ] ; then
				all_replica_mem_percent=`echo "${all_replica_mem_current} ${all_replica_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_replica_mem_percent=""
			fi	
			if [ "${all_replica_cpu_request}" -ne 0 ] ; then
				all_replica_cpu_percent=`echo "${all_replica_cpu_current} ${all_replica_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_replica_cpu_percent=""
			fi		
			if [ -n "${whole_cpu}" ] ; then		
				all_replica_cpu_current_print=`echo "$all_replica_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_replica_cpu_request_print=`echo "$all_replica_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_replica_cpu_limit_print=`echo "$all_replica_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_replica_cpu_current_print=$all_replica_cpu_current
				all_replica_cpu_request_print=$all_replica_cpu_request
				all_replica_cpu_limit_print=$all_replica_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (ReplicaSet)," "$all_replica_pod_count," "$all_replica_container_count," "" "$all_replica_mem_percent" "$all_replica_mem_current" "$all_replica_mem_request" "$all_replica_mem_limit" "$all_replica_cpu_percent" "$all_replica_cpu_current_print" "$all_replica_cpu_request_print" "$all_replica_cpu_limit_print" "$all_replica_zeros" | tee -a $output_log
		fi
		if [ ${all_stateful_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then
			if [ "${all_stateful_mem_request}" -ne 0 ] ; then
				all_stateful_mem_percent=`echo "${all_stateful_mem_current} ${all_stateful_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_stateful_mem_percent=""
			fi	
			if [ "${all_stateful_cpu_request}" -ne 0 ] ; then
				all_stateful_cpu_percent=`echo "${all_stateful_cpu_current} ${all_stateful_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_stateful_cpu_percent=""
			fi		
			if [ -n "${whole_cpu}" ] ; then		
				all_stateful_cpu_current_print=`echo "$all_stateful_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_stateful_cpu_request_print=`echo "$all_stateful_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_stateful_cpu_limit_print=`echo "$all_stateful_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_stateful_cpu_current_print=$all_stateful_cpu_current
				all_stateful_cpu_request_print=$all_stateful_cpu_request
				all_stateful_cpu_limit_print=$all_stateful_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (StatefulSet)," "$all_stateful_pod_count," "$all_stateful_container_count," "" "$all_stateful_mem_percent" "$all_stateful_mem_current" "$all_stateful_mem_request" "$all_stateful_mem_limit" "$all_stateful_cpu_percent" "$all_stateful_cpu_current_print" "$all_stateful_cpu_request_print" "$all_stateful_cpu_limit_print" "$all_stateful_zeros" | tee -a $output_log
		fi
		if [ ${all_daemon_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then
			if [ "${all_daemon_mem_request}" -ne 0 ] ; then
				all_daemon_mem_percent=`echo "${all_daemon_mem_current} ${all_daemon_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_daemon_mem_percent=""
			fi	
			if [ "${all_daemon_cpu_request}" -ne 0 ] ; then
				all_daemon_cpu_percent=`echo "${all_daemon_cpu_current} ${all_daemon_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_daemon_cpu_percent=""
			fi		
			if [ -n "${whole_cpu}" ] ; then		
				all_daemon_cpu_current_print=`echo "$all_daemon_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_daemon_cpu_request_print=`echo "$all_daemon_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_daemon_cpu_limit_print=`echo "$all_daemon_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_daemon_cpu_current_print=$all_daemon_cpu_current
				all_daemon_cpu_request_print=$all_daemon_cpu_request
				all_daemon_cpu_limit_print=$all_daemon_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (DaemonSet)," "$all_daemon_pod_count," "$all_daemon_container_count," "" "$all_daemon_mem_percent" "$all_daemon_mem_current" "$all_daemon_mem_request" "$all_daemon_mem_limit" "$all_daemon_cpu_percent" "$all_daemon_cpu_current_print" "$all_daemon_cpu_request_print" "$all_daemon_cpu_limit_print" "$all_daemon_zeros" | tee -a $output_log
		
			if [ $workers_count -ne '0' ] ; then
				all_daemon_per_worker_cpu_current=`echo "$all_daemon_cpu_current $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_cpu_request=`echo "$all_daemon_cpu_request $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_cpu_limit=`echo "$all_daemon_cpu_limit $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_mem_current=`echo "$all_daemon_mem_current $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_mem_request=`echo "$all_daemon_mem_request $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_mem_limit=`echo "$all_daemon_mem_limit $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_pod_count=`echo "$all_daemon_pod_count $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_container_count=`echo "$all_daemon_container_count $workers_count" | awk '{printf "%d", $1 / $2}'`
				all_daemon_per_worker_zeros=`echo "$all_daemon_zeros $workers_count" | awk '{printf "%d", $1 / $2}'`
				if [ "${all_daemon_per_worker_mem_request}" -ne 0 ] ; then
					all_daemon_per_worker_mem_percent=`echo "${all_daemon_per_worker_mem_current} ${all_daemon_per_worker_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
				else
					all_daemon_per_worker_mem_percent=""
				fi	
				if [ "${all_daemon_per_worker_cpu_request}" -ne 0 ] ; then
					all_daemon_per_worker_cpu_percent=`echo "${all_daemon_per_worker_cpu_current} ${all_daemon_per_worker_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
				else
					all_daemon_per_worker_cpu_percent=""
				fi	
				if [ -n "${whole_cpu}" ] ; then		
					all_daemon_per_worker_cpu_current_print=`echo "$all_daemon_per_worker_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
					all_daemon_per_worker_cpu_request_print=`echo "$all_daemon_per_worker_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
					all_daemon_per_worker_cpu_limit_print=`echo "$all_daemon_per_worker_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
				else			
					all_daemon_per_worker_cpu_current_print=$all_daemon_per_worker_cpu_current
					all_daemon_per_worker_cpu_request_print=$all_daemon_per_worker_cpu_request
					all_daemon_per_worker_cpu_limit_print=$all_daemon_per_worker_cpu_limit
				fi
				printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (DaemonSet per Worker)," "$all_daemon_per_worker_pod_count," "$all_daemon_per_worker_container_count," "" "$all_daemon_per_worker_mem_percent" "$all_daemon_per_worker_mem_current" "$all_daemon_per_worker_mem_request" "$all_daemon_per_worker_mem_limit" "$all_daemon_per_worker_cpu_percent" "$all_daemon_per_worker_cpu_current_print" "$all_daemon_per_worker_cpu_request_print" "$all_daemon_per_worker_cpu_limit_print" "$all_daemon_per_worker_zeros" | tee -a $output_log
			fi
		fi
		if [ ${all_job_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_job_mem_request}" -ne 0 ] ; then
				all_job_mem_percent=`echo "${all_job_mem_current} ${all_job_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_job_mem_percent=""
			fi	
			if [ "${all_job_cpu_request}" -ne 0 ] ; then
				all_job_cpu_percent=`echo "${all_job_cpu_current} ${all_job_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_job_cpu_percent=""
			fi		
			if [ -n "${whole_cpu}" ] ; then		
				all_job_cpu_current_print=`echo "$all_job_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_job_cpu_request_print=`echo "$all_job_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_job_cpu_limit_print=`echo "$all_job_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_job_cpu_current_print=$all_job_cpu_current
				all_job_cpu_request_print=$all_job_cpu_request
				all_job_cpu_limit_print=$all_job_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Job)," "$all_job_pod_count," "$all_job_container_count," "" "$all_job_mem_percent" "$all_job_mem_current" "$all_job_mem_request" "$all_job_mem_limit" "$all_job_cpu_percent" "$all_job_cpu_current_print" "$all_job_cpu_request_print" "$all_job_cpu_limit_print" "$all_job_zeros" | tee -a $output_log
		fi
		if [ ${all_configmap_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_configmap_mem_request}" -ne 0 ] ; then
				all_configmap_mem_percent=`echo "${all_configmap_mem_current} ${all_configmap_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_configmap_mem_percent=""
			fi	
			if [ "${all_configmap_cpu_request}" -ne 0 ] ; then
				all_configmap_cpu_percent=`echo "${all_configmap_cpu_current} ${all_configmap_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_configmap_cpu_percent=""
			fi	
			if [ -n "${whole_cpu}" ] ; then		
				all_configmap_cpu_current_print=`echo "$all_configmap_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_configmap_cpu_request_print=`echo "$all_configmap_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_configmap_cpu_limit_print=`echo "$all_configmap_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_configmap_cpu_current_print=$all_configmap_cpu_current
				all_configmap_cpu_request_print=$all_configmap_cpu_request
				all_configmap_cpu_limit_print=$all_configmap_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (ConfigMap)," "$all_configmap_pod_count," "$all_configmap_container_count," "" "$all_configmap_mem_percent" "$all_configmap_mem_current" "$all_configmap_mem_request" "$all_configmap_mem_limit" "$all_configmap_cpu_percent" "$all_configmap_cpu_current_print" "$all_configmap_cpu_request_print" "$all_configmap_cpu_limit_print" "$all_configmap_zeros" | tee -a $output_log
		fi
		if [ ${all_node_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_node_mem_request}" -ne 0 ] ; then
				all_node_mem_percent=`echo "${all_node_mem_current} ${all_node_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_node_mem_percent=""
			fi	
			if [ "${all_node_cpu_request}" -ne 0 ] ; then
				all_node_cpu_percent=`echo "${all_node_cpu_current} ${all_node_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_node_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_node_cpu_current_print=`echo "$all_node_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_node_cpu_request_print=`echo "$all_node_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_node_cpu_limit_print=`echo "$all_node_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_node_cpu_current_print=$all_node_cpu_current
				all_node_cpu_request_print=$all_node_cpu_request
				all_node_cpu_limit_print=$all_node_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Node)," "$all_node_pod_count," "$all_node_container_count," "" "$all_node_mem_percent" "$all_node_mem_current" "$all_node_mem_request" "$all_node_mem_limit" "$all_node_cpu_percent" "$all_node_cpu_current_print" "$all_node_cpu_request_print" "$all_node_cpu_limit_print" "$all_node_zeros" | tee -a $output_log
		fi
		if [ ${all_catalog_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_catalog_mem_request}" -ne 0 ] ; then
				all_catalog_mem_percent=`echo "${all_catalog_mem_current} ${all_catalog_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_catalog_mem_percent=""
			fi	
			if [ "${all_catalog_cpu_request}" -ne 0 ] ; then
				all_catalog_cpu_percent=`echo "${all_catalog_cpu_current} ${all_catalog_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_catalog_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_catalog_cpu_current_print=`echo "$all_catalog_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_catalog_cpu_request_print=`echo "$all_catalog_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_catalog_cpu_limit_print=`echo "$all_catalog_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_catalog_cpu_current_print=$all_catalog_cpu_current
				all_catalog_cpu_request_print=$all_catalog_cpu_request
				all_catalog_cpu_limit_print=$all_catalog_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (CatalogSource)," "$all_catalog_pod_count," "$all_catalog_container_count," "" "$all_catalog_mem_percent" "$all_catalog_mem_current" "$all_catalog_mem_request" "$all_catalog_mem_limit" "$all_catalog_cpu_percent" "$all_catalog_cpu_current_print" "$all_catalog_cpu_request_print" "$all_catalog_cpu_limit_print" "$all_catalog_zeros" | tee -a $output_log
		fi
		if [ ${all_unspecified_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_unspecified_mem_request}" -ne 0 ] ; then
				all_unspecified_mem_percent=`echo "${all_unspecified_mem_current} ${all_unspecified_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_unspecified_mem_percent=""
			fi	
			if [ "${all_unspecified_cpu_request}" -ne 0 ] ; then
				all_unspecified_cpu_percent=`echo "${all_unspecified_cpu_current} ${all_unspecified_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_unspecified_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_unspecified_cpu_current_print=`echo "$all_unspecified_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_unspecified_cpu_request_print=`echo "$all_unspecified_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_unspecified_cpu_limit_print=`echo "$all_unspecified_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_unspecified_cpu_current_print=$all_unspecified_cpu_current
				all_unspecified_cpu_request_print=$all_unspecified_cpu_request
				all_unspecified_cpu_limit_print=$all_unspecified_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Unspecified)," "$all_unspecified_pod_count," "$all_unspecified_container_count," "" "$all_unspecified_mem_percent" "$all_unspecified_mem_current" "$all_unspecified_mem_request" "$all_unspecified_mem_limit" "$all_unspecified_cpu_percent" "$all_unspecified_cpu_current_print" "$all_unspecified_cpu_request_print" "$all_unspecified_cpu_limit_print" "$all_unspecified_zeros" | tee -a $output_log
		fi
		if [ ${all_stopped_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_stopped_mem_request}" -ne 0 ] ; then
				all_stopped_mem_percent=`echo "${all_stopped_mem_current} ${all_stopped_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_stopped_mem_percent=""
			fi	
			if [ "${all_stopped_cpu_request}" -ne 0 ] ; then
				all_stopped_cpu_percent=`echo "${all_stopped_cpu_current} ${all_stopped_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_stopped_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_stopped_cpu_current_print=`echo "$all_stopped_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_stopped_cpu_request_print=`echo "$all_stopped_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_stopped_cpu_limit_print=`echo "$all_stopped_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_stopped_cpu_current_print=$all_stopped_cpu_current
				all_stopped_cpu_request_print=$all_stopped_cpu_request
				all_stopped_cpu_limit_print=$all_stopped_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Not Running)," "$all_stopped_pod_count," "$all_stopped_container_count," "" "$all_stopped_mem_percent" "$all_stopped_mem_current" "$all_stopped_mem_request" "$all_stopped_mem_limit" "$all_stopped_cpu_percent" "$all_stopped_cpu_current_print" "$all_stopped_cpu_request_print" "$all_stopped_cpu_limit_print" "$all_stopped_zeros" | tee -a $output_log
		fi
		if [ ${all_running_pod_count} != 0 ] && [ ${all_stopped_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
			if [ "${all_running_mem_request}" -ne 0 ] ; then
				all_running_mem_percent=`echo "${all_running_mem_current} ${all_running_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_running_mem_percent=""
			fi	
			if [ "${all_running_cpu_request}" -ne 0 ] ; then
				all_running_cpu_percent=`echo "${all_running_cpu_current} ${all_running_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_running_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_running_cpu_current_print=`echo "$all_running_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_running_cpu_request_print=`echo "$all_running_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_running_cpu_limit_print=`echo "$all_running_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else
				all_running_cpu_current_print=$all_running_cpu_current
				all_running_cpu_request_print=$all_running_cpu_request
				all_running_cpu_limit_print=$all_running_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Running)," "$all_running_pod_count," "$all_running_container_count," "" "$all_running_mem_percent" "$all_running_mem_current" "$all_running_mem_request" "$all_running_mem_limit" "$all_running_cpu_percent" "$all_running_cpu_current_print" "$all_running_cpu_request_print" "$all_running_cpu_limit_print" "$all_running_zeros" | tee -a $output_log
		fi
		if [ ${all_running_pod_count} != 0 ] && [ ${all_daemon_pod_count} != 0 ] || [ ${report} -eq '1' ] ; then	
		
			all_running_minus_daemon_cpu_current=$(($all_running_cpu_current-$all_daemon_cpu_current))
			all_running_minus_daemon_cpu_request=$(($all_running_cpu_request-$all_daemon_cpu_request))
			all_running_minus_daemon_cpu_limit=$(($all_running_cpu_limit-$all_daemon_cpu_limit))
			all_running_minus_daemon_mem_current=$(($all_running_mem_current-$all_daemon_mem_current))
			all_running_minus_daemon_mem_request=$(($all_running_mem_request-$all_daemon_mem_request))
			all_running_minus_daemon_mem_limit=$(($all_running_mem_limit-$all_daemon_mem_limit))
			all_running_minus_daemon_pod_count=$(($all_running_pod_count-$all_daemon_pod_count))
			all_running_minus_daemon_container_count=$(($all_running_container_count-$all_daemon_container_count))	
			all_running_minus_daemon_zeros=$(($all_running_container_count-$all_daemon_zeros))	
			if [ "${all_running_minus_daemon_mem_request}" -ne 0 ] ; then
				all_running_minus_daemon_mem_percent=`echo "${all_running_minus_daemon_mem_current} ${all_running_minus_daemon_mem_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_running_minus_daemon_mem_percent=""
			fi	
			if [ "${all_running_minus_daemon_cpu_request}" -ne 0 ] ; then
				all_running_minus_daemon_cpu_percent=`echo "${all_running_minus_daemon_cpu_current} ${all_running_minus_daemon_cpu_request} 100" | awk '{printf "%2d%", $1 / $2 * $3}'`
			else
				all_running_minus_daemon_cpu_percent=""
			fi
			if [ -n "${whole_cpu}" ] ; then		
				all_running_minus_daemon_cpu_current_print=`echo "$all_running_minus_daemon_cpu_current 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_running_minus_daemon_cpu_request_print=`echo "$all_running_minus_daemon_cpu_request 1000" | awk '{printf "%.2f", $1 / $2}'`
				all_running_minus_daemon_cpu_limit_print=`echo "$all_running_minus_daemon_cpu_limit 1000" | awk '{printf "%.2f", $1 / $2}'`
			else			
				all_running_minus_daemon_cpu_current_print=$all_running_minus_daemon_cpu_current
				all_running_minus_daemon_cpu_request_print=$all_running_minus_daemon_cpu_request
				all_running_minus_daemon_cpu_limit_print=$all_running_minus_daemon_cpu_limit
			fi
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces (Running minus DaemonSet)," "$all_running_minus_daemon_pod_count," "$all_running_minus_daemon_container_count," "" "$all_running_minus_daemon_mem_percent" "$all_running_minus_daemon_mem_current" "$all_running_minus_daemon_mem_request" "$all_running_minus_daemon_mem_limit" "$all_running_minus_daemon_cpu_percent" "$all_running_minus_daemon_cpu_current_print" "$all_running_minus_daemon_cpu_request_print" "$all_running_minus_daemon_cpu_limit_print" "$all_running_minus_daemon_zeros" | tee -a $output_log
		fi
		if [ ${all_total_pod_count} != 0 ] ; then
			printf "%-73s %24s %45s %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n\n" "All Selected Namespaces (Total)," "$all_total_pod_count," "$all_total_container_count," "" "$all_total_mem_percent" "$all_total_mem_current" "$all_total_mem_request" "$all_total_mem_limit" "$all_total_cpu_percent" "$all_total_cpu_current_print" "$all_total_cpu_request_print" "$all_total_cpu_limit_print" "$all_total_zeros" | tee -a $output_log
		fi
	else
		printf "%-50s %10s, %10s,   %13s, %6s, %6s, %6s, %6s, %5s, %6s, %6s, %6s, %3s,\n" "All Selected Namespaces," "$all_total_pod_count" "$all_total_container_count" "" "$all_total_mem_percent" "$all_total_mem_current" "$all_total_mem_request" "$all_total_mem_limit" "$all_total_cpu_percent" "$all_total_cpu_current_print" "$all_total_cpu_request_print" "$all_total_cpu_limit_print" "$all_total_zeros" | tee -a $output_log
	fi
	FORMAT_CSV
fi
}
MERGE_REPORT() {
if [ ${report} -eq '1' ] ; then
	if [ ${namespace_count} -gt 0 ] ; then
		#output_log="${CSV_DIR}/${namespace}${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.csv"
		cd $CSV_DIR
		report_name="0-report${file_name_tag}_${environment_name_short}.resources${sum_file_name}.${CSV_DATE}.xlsx"
		if [ -f $SCRIPT_DIR/excel.pl ] ; then
			DEBUG 0 "$SCRIPT_DIR/excel.pl --out ${report_name} --grep ${file_name_tag}.*${CSV_DATE}.csv --debug 1"
			$SCRIPT_DIR/excel.pl --out ${report_name} --grep ${file_name_tag}.*${CSV_DATE}.csv --debug 1
		elif [ -f /perf1/unix/excel/excel.pl ] ; then
			DEBUG 0 "/perf1/unix/excel/excel.pl --out ${report_name} --grep ${file_name_tag}.*${CSV_DATE}.csv --debug 1"
			/perf1/unix/excel/excel.pl --out ${report_name} --grep ${file_name_tag}.*${CSV_DATE}.csv --debug 1		
		else
			DEBUG 0 "Could not find excel.pl in $SCRIPT_DIR" 
		fi
		if [ -f ${report_name} ] ; then
			chmod 755 ${report_name}
		fi
	fi
fi
}

MAIN() {
CHECK_VERSION
if [ "${namespaces}" == "--all-namespaces" ] ; then
	GET_ALL_NAMESPACES
fi
if [ ${show_total_only} == 1 ] ; then
	namespace="totals"
	SETUP_CSV
	PRINT_HEADER 1
fi
namespace_number=0
namespace_count=`echo "${namespaces}" | wc -w`
for namespace in ${namespaces} ; do
	namespace_number=$(($namespace_number+1))
	GET_PODS
	if [ -n "${pods}" ] ; then
		GET_TOP
	fi
	INIT_NAMESPACE_STATS
	if [ ${show_total_only} == 0 ] ; then
		SETUP_CSV
		PRINT_HEADER 1
	fi
	LOOP_PODS "$statefulsets"
	LOOP_PODS "$non_statefulsets"
	SUM_NAMESPACE_STATS_TO_ALL
	PRINT_NAMESPACE_TOTALS
	FORMAT_CSV
done
PRINT_ALL_TOTALS
MERGE_REPORT
}

INITIALIZE
PARSE_ARGS "$@"
MAIN
