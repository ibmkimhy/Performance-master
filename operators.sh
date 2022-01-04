#!/bin/bash

version="1.0.0 20210827"
USAGE() {
echo "version $version"
echo "Use this script to display operator version for all deployments, statefulsets and jobs that exist in the specified namespace."
echo "The operators are determined based on parsing the manifest yaml in the current or provided env."
echo "Flags: $0 "
echo "   [ --namespace <namespace> ]     Specify the namespace to display resource information about. Default is the current namespace."
echo "   [ --top_dir <directory> ]       Specifies the directory with the catalog manifest information.  Default is the current directory.  Ex, download from https://github.ibm.com/katamari/cicd-operator-catalog"
echo "   [ --namespace <namespace> ]     Specify the namespace to display resource information about. Default is the current namespace."
echo
echo "example:"
echo "$0 "
exit 0
}
INITIALIZE() {
command="kubectl"
global_debug=0
top_dir="."
image_list=""
manifest_dir="catalog/manifests"
used_images=0
}
DEBUG() {
	# 0 is always shown
	# 1 is always shown if any level of tracing is set
	# 2+ other
	#echo "1 $1, 2 $2"
	if [ $1 -eq $global_debug ] || [ $1 -eq '0' ] || [[ $global_debug -gt '0' && $1 -eq '1' ]] ; then
		echo -e "`date` debug $1: $2"
	fi
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
		"--OC")  #
			command="oc"; adm="adm"; shift 1; ARGC=$(($ARGC-1)) ;;
		"--KUBECTL")  #
			command="kubectl"; adm=""; shift 1; ARGC=$(($ARGC-1)) ;;
		"-N")  #
			namespace="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--N")  #
			namespace="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--NAMESPACE")  #
			namespace="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"-M")  #
			metadata_file="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--M")  #
			metadata_file="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--METADATA")  #
			metadata_file="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--TOP_DIR")  #
			top_dir="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--MANIFEST_SUBDIR")  #
			manifest_dir="$2"; shift 2; ARGC=$(($ARGC-2)) ;;
		"--USED_IMAGES")  #
			used_images=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--HELP")  #
			USAGE; exit 0 ;;
		*)
			DEBUG 0 "Argument \"$ARG\" not known, exiting...\n"
			USAGE; exit 1 ;;
    esac
done

if [ -z "${namespace}" ] ; then
	if [ "${command}" == "oc" ] ; then
		namespace=`$command project | cut -d '"' -f 2`		
	else
		namespace=`$command config view --minify --output 'jsonpath={..namespace}'`
	fi
fi
namespace="-n ${namespace}"
DEBUG 1 "Using namespace $namespace"

if [ -z "${metadata_file}" ] ; then
	metadata_file=`ls $top_dir | grep released-images | grep yaml | tail -1`
fi
DEBUG 1 "Using metadata_file $metadata_file"

if [ ! -d ${top_dir}/${manifest_dir} ] ; then
	echo "ERROR! Could not find ${top_dir}/${manifest_dir}, exiting..."
	echo
	USAGE
	exit 1
fi
DEBUG 1 "Using manifest_dir ${top_dir}/${manifest_dir}"
}
CHECK_IMAGE_LIST() {
echo "$image_list" | tee /tmp/images.csv
for image in `cat $metadata_file | grep ' image: '| rev | cut -d '/' -f1 | rev | cut -d '@' -f 1 | cut -d ':' -f 1` ; do
	operator=`cat $metadata_file | grep "image:.*${image}" -B 1 | grep 'operator-name' | head -1 | cut -d ':' -f 2 | sed -e 's/^[ \t]*//g' `
	exists=`echo $image_list | grep " $image "`
	if [ -z "${exists}" ] ; then
		found="NO"
	else
		found="YES"
	fi
	printf "%5s %-55s %-30s\n" "${found}," "${image}," "${operator}," | tee -a /tmp/images.csv
done 

}
CHECK_RESOURCES() {
printf "%-12s %-60s %-50s %-50s\n" "Type," "Resource," "Image," "Operator," | tee /tmp/operators.csv
for type in deployment statefulset job ; do 
	for resource in `$command get ${type} ${namespace} | grep -v NAME | awk '{ print $1 }'` ; do
		DEBUG 1 "resource: $resource" 
		images=`$command describe ${type} ${resource} ${namespace} | grep ' Image:' | rev | cut -d '/' -f1 | rev | cut -d '@' -f 1 | cut -d ':' -f 1 `
		for image in $images ; do 
			if [ -z "`echo $image_list | grep $image`" ] ; then
				DEBUG 2 "Adding $image to image_list"
				image_list=" ${image} ${image_list}"
			fi
			DEBUG 1 "image: $image"
			#operator=`cat $metadata_file | grep "image:.*${image}" -B 1 | grep 'operator-name' | head -1 | cut -d ':' -f 2 | sed -e 's/^[ \t]*//g' `
			operator=""
			if [ -z "${operator}" ] ; then
				DEBUG 1 "Did not find anything for $image.  Checking manifests."
				for operator_dir in `ls ${top_dir}/${manifest_dir}` ; do 
					DEBUG 2 "Checking operator_dir ${top_dir}/${manifest_dir}/${operator_dir}"
					reference=`grep -Ri ${image} ${top_dir}/${manifest_dir}/${operator_dir} | grep -i 'image:'`
					if [ -n "${reference}" ] ; then
						DEBUG 1 "FOUND IT!!!"
						operator="$operator   ${operator_dir}"
						#break
					fi
				done
			fi
			if [ -z "${operator}" ] ; then 
				if [[ "${resource}" == *"redis"* ]] ; then
					operator="?redis"
				elif [[ "${resource}" == *"couchdb"* ]] ; then
					operator="?couchdb"
				elif [[ "${resource}" == *"iaf"* ]] ; then
					operator="?iaf"
				elif [[ "${resource}" == *"zen"* ]] || [[ "${resource}" == *"nginx"* ]] || [[ "${resource}" == *"usermgmt"* ]] || [[ "${resource}" == *"create-secrets"* ]]  ; then
					operator="?zen"
				elif [[ "${image}" == *"redis"* ]] ; then
					operator="?redis"
				elif [[ "${image}" == *"couchdb"* ]] ; then
					operator="?couchdb"
				elif [[ "${image}" == *"iaf"* ]] ; then
					operator="?iaf"
				elif [[ "${image}" == *"zen"* ]] ; then
					operator="?zen"
				else
					operator="UNKNOWN"
				fi
			fi
			operator=`echo $operator | sed -e 's/^[ \t]*//g'`
			DEBUG 1 "operator: $operator"
		done
		printf "%-12s %-60s %-50s %-50s\n" "${type}," "${resource}," "${image}," "${operator}," | tee -a /tmp/operators.csv		
		DEBUG 1 "_________________________________________________________________________"
	done
done
}

MAIN() {
if [ $used_images == 1 ] ; then
	CHECK_IMAGE_LIST
else
	CHECK_RESOURCES
fi
}

INITIALIZE
PARSE_ARGS "$@"
MAIN
