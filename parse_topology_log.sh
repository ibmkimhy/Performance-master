#!/bin/bash

INITIALIZE(){
temp_log="/tmp/parse_topology_log_formatted_temp.out"
url_temp_log="/tmp/parse_topology_log_url_temp.out"
since="60m"
parse_by_url=0
parse_by_url_detailed=0
rm -rf $temp_log
rm -rf $url_temp_log
reverse=""
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
		"-F")	# 
			log=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--FILE")	# 
			log=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--SINCE")	# 
			since=$2; shift 2; ARGC=$(($ARGC-2)) ;;
		"--URL_DETAILED")	# 
			parse_by_url_detailed=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--URL")	# 
			parse_by_url=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--REVERSE")	# 
			reverse=" -r"; shift 1; ARGC=$(($ARGC-1)) ;;
		"--HELP")	# 
			echo "TODO - help section, sorry."             
            exit 1 ;;			
		*)  
			echo "Argument \"$ARG\" not known, exiting..."
			exit 1 ;;
    esac
done

}

PARSE_ONE() {
grep_regex="$1"
ip="$2"
time="$3"
count=`cat $temp_log | grep "$time" | grep "$grep_regex" | grep "$ip" | wc -l`
if [ $count != 0 ] ; then
	total=`cat $temp_log | grep "$time" | grep "$grep_regex" | grep "$ip" | awk '{ print $5 }' | sed -e 's/[,a-z]//g' | awk '{s+=$1}END{print s}'`
	avg=$(($total/$count))
else
	total=0
	avg=0
fi

printf " %12d, %10.0f, %10.0f," "$count" "$avg" "$total"

}

PARSE_GROUP() {
ip="$1"
message="$@"
printf "$message\n"
printf "%17s, %12s, %10s, %10s, %12s, %10s, %10s, %12s, %10s, %10s, %12s, %10s, %10s, %12s, %10s, %10s, \n" "time" "ALL_count" "avg_resp" "total_resp" "GET_count" "avg_resp" "total_resp" "PUTs_count" "avg_resp" "total_resp" "POST_count" "avg_resp" "total_resp" "DELETE_count" "avg_resp" "total_resp" 
for time in $times "" ; do
	if [ -z "${time}" ] ; then
		printf "%17s," "Total"
	else
		printf "%17s," $time
	fi
	for type in "" "GET" "PUT" "POST" "DELETE" ; do
		PARSE_ONE "$type" "$ip" "$time"
	done
	printf "\n"
done
echo
}

PARSE_IPS(){
count=""
for x in `echo "$ips"` ; do 
	if [ "${count}" == "" ] ; then
		count=$x
	else
		ip=$x
		#printf "$ip `kubectl get pods -o wide | grep " $ip "`\n"
		PARSE_GROUP "$ip" `kubectl get pods -o wide | grep " $ip "`
		echo "----------------------------------------------------------------"
		count=""
	fi
done
}

GET_LOGS() {

if [ -f "${log}" ] ; then
	cat $log | grep ' Finished tx ' | grep -vi healthcheck | awk '{ print $2"_"$3" "$6" "$7" "$16" "$21}' | cut -c 2-17,26-9999 >$temp_log
else
	for topo_pod in `kubectl get pods | grep topology | grep -v 'multicluster-hub' | awk '{ print $1 }'` ; do 
		echo "Reading topolog logs for ${topo_pod}"
		kubectl logs ${topo_pod} --since=$since | grep ' Finished tx ' | grep -vi healthcheck | awk '{ print $2"_"$3" "$6" "$7" "$16" "$21}' | cut -c 2-17,26-9999 >>$temp_log
	done 
	echo 
fi

times=`cat $temp_log | awk '{ print $1 }' | sort | uniq`
ips=`cat $temp_log | awk '{ print $4 }' | sort | uniq -c | sort -k 1 -n ; echo `
}

PARSE_HEAVY_DETAILED() {
queries=`cat $temp_log | awk '{ print $2"+"$3"+"$4}' | sort -k 1 | uniq -c | sort -k 1 -n`
queries_count=$((`echo $queries | wc -w`/2))
count=""
url=""
printf "%12s, %9s, %9s, %6s, %12s, %4s,\n" "total_resp" "avg_resp" "count" "type" "ip" "url" >>$url_temp_log
x=0
for item in $queries ; do
	if [ "${count}" == "" ] ; then
		count=$item
	else
		x=$(($x+1))
		echo -ne "Queries parsed: ($x/$queries_count)\r"
		type=`echo $item| cut -d '+' -f 1`
		url=`echo $item| cut -d '+' -f 2`
		ip=`echo $item| cut -d '+' -f 3`
		grep_url=`echo $url | sed -e 's/\*/\\\*/g' `
		
		avg=`cat $temp_log | grep "$type" | grep "$grep_url" | grep "$ip" | awk '{ print $5 }' | sed -e 's/[,a-z]//g' | awk '{s+=$1}END{print s/NR}' | cut -d '.' -f 1`
		cost=$(($avg*$count))
		printf "%12.0f, %9.0f, %9.0f, %6s, %12s, " $cost $avg $count $type $ip >>$url_temp_log
		echo "$url" >>$url_temp_log
		url=""
		count=""
		ip=""
	fi
done
echo 
echo
cat $url_temp_log | sort -k 1 -n $reverse
}
PARSE_HEAVY() {
cat $temp_log | awk '{ print $3" "$4" "$5 }' | sort -n -k 3 $reverse
}

MAIN() {
GET_LOGS
if [ ${parse_by_url_detailed} == 1 ] ; then
	PARSE_HEAVY_DETAILED
elif [ ${parse_by_url} == 1 ] ; then
	PARSE_HEAVY
else
	PARSE_IPS
	PARSE_GROUP "" "All_requests"
fi
#rm -rf $temp_log
}
 
INITIALIZE
PARSE_ARGS "$@"
MAIN