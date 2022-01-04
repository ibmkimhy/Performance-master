#!/bin/bash

version="1.1.0"
USAGE() {
	echo "version $version"
	echo "Use this script to display information memory usage of a system."
	echo "Flags: $0 "
	echo "   [ --details ]                   Shows the more detailed explanation of what each value means."
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
		"--DETAILS")  #
			details=1; shift 1; ARGC=$(($ARGC-1)) ;;
		"--HELP")  #
			USAGE ; exit 0;;
		*)
			echo "Argument \"$ARG\" not known, exiting...\n"
			USAGE
			exit 1 ;;
    esac
done
}

GET_DATA() {
LOW_WATERMARK=$(awk '$1 == "low" {LOW_WATERMARK += $2} END {printf "%d", LOW_WATERMARK * 4 / 1024}' /proc/zoneinfo)
MEMFREE=$(free -m)
MEMFREEWIDE=$(free -m --wide)
MEMINFO=$(</proc/meminfo)
SAR_EXISTS=`whereis sar | wc -w`
if [ $SAR_EXISTS -gt '1' ] ; then
	SAR=`sar -r 1 1`
fi
}
PARSE_SAR() {

if [ $SAR_EXISTS -gt '1' ] ; then
	MS_FREE=$(echo "${SAR}" | awk '$1 == "Average:" {printf "%d", $2 / 1024}')
	MS_USED=$(echo "${SAR}" | awk '$1 == "Average:" {printf "%d", $3 / 1024}') #Total - Free
	MS_BUFF=$(echo "${SAR}" | awk '$1 == "Average:" {printf "%d", $5 / 1024}')
	MS_CACHED=$(echo "${SAR}" | awk '$1 == "Average:" {printf "%d", $6 / 1024}')
	MS_COMMIT=$(echo "${SAR}" | awk '$1 == "Average:" {printf "%d", $7 / 1024}')

	MS_ACTIVE=$(($MS_USED-$MS_BUFF-$MS_CACHED))
fi
}
PARSE_FREE() {

MF_TOTAL=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $2}')
MF_USED=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $3}')
MF_FREE=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $4}')
MF_SHARED=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $5}')
MF_BUFFCACHE=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $6}')
MF_AVAIL=$(echo "${MEMFREE}" | awk '$1 == "Mem:" {print $7}')
MFW_BUFF=$(echo "${MEMFREEWIDE}" | awk '$1 == "Mem:" {print $6}')
MFW_CACHE=$(echo "${MEMFREEWIDE}" | awk '$1 == "Mem:" {print $7}')

MF_POP=$(($MF_TOTAL-$MF_FREE))
MF_USED_C=$(($MF_TOTAL-$MF_FREE-$MF_BUFFCACHE))
MF_UNAVL_C=$(($MF_TOTAL-$MF_AVAIL))
}
PARSE_MEMINFO() {
MI_TOTAL=$(echo "${MEMINFO}" | awk '$1 == "MemTotal:" {printf "%d", $2 / 1024} ')
MI_SLAB=$(echo "${MEMINFO}" | awk '$1 == "Slab:" {printf "%d", $2 / 1024}')
MI_MEMFREE=$(echo "${MEMINFO}" | awk '$1 == "MemFree:" {printf "%d", $2 / 1024}')
MI_CACHED=$(echo "${MEMINFO}" | awk '$1 == "Cached:" {printf "%d", $2 / 1024}')
MI_BUFF=$(echo "${MEMINFO}" | awk '$1 == "Buffers:" {printf "%d", $2 / 1024}')
MI_ACTF=$(echo "${MEMINFO}" | awk '$1 == "Active(file):" {printf "%d", $2 / 1024}')
MI_INACTF=$(echo "${MEMINFO}" | awk '$1 == "Inactive(file):" {printf "%d", $2 / 1024}')
MI_SREC=$(echo "${MEMINFO}" | awk '$1 == "SReclaimable:" {printf "%d", $2 / 1024}')
MI_SHMEM=$(echo "${MEMINFO}" | awk '$1 == "Shmem:" {printf "%d", $2 / 1024}')
MI_AVAIL=$(echo "${MEMINFO}" | awk '$1 == "MemAvailable:" {printf "%d", $2 / 1024}')

MI_POP=$(($MI_TOTAL-$MI_MEMFREE))
MI_CACHE_SRECL_C=$(($MI_CACHED+$MI_SREC))
MI_CACH_SREC_BUFF_C=$(($MI_CACHED+$MI_SREC+$MI_BUFF))
MI_PAGECACHE_C=$(($MI_ACTF+$MI_INACTF))
MI_USED_C=$(($MI_TOTAL-$MI_MEMFREE-$MI_BUFF-$MI_CACHED-$MI_SREC))
MI_AVAIL_EST=$(($MI_MEMFREE+$MI_ACTF+$MI_INACTF+$MI_SREC-$LOW_WATERMARK-$LOW_WATERMARK-$LOW_WATERMARK))
MI_UNAVL_C=$(($MI_TOTAL-$MI_AVAIL))
MI_UNAVL_EST=$(($MI_TOTAL-$MI_AVAIL_EST))
MI_ACTIVE=$(($MI_TOTAL-$MI_MEMFREE-$MI_CACHED-$MI_BUFF))

}

PRINT_HORIZONTAL() {
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "\`free\`" "Total"   "Total-Free" "Free"      ""         "Used"       "T-F-B-C"  "Unavail"     "Avail"       ""              "BfCache"            "Buff"    "\"Cache\""       ""         ""       ""       "SHMEM"    ""        ""         
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "\`free\`" $MF_TOTAL $MF_POP      $MF_FREE    ""         $MF_USED     $MF_USED_C $MF_UNAVL_C   $MF_AVAIL     ""              $MF_BUFFCACHE        $MFW_BUFF $MFW_CACHE        ""         ""       ""       $MF_SHARED ""        ""         
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "meminfo"  "Total"   "Populated"  "Free"      "T-F-B-C"  "T-F-B-C-SR" ""         "T-Avl"       "Avail"     "PgCache"       "BfCache"            "Buff"    "Cache+SRec"      "Cache"    "Slab"   "SRECL"  "SHMEM"    "ActFile" "InActF"   
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "meminfo"  $MI_TOTAL $MI_POP      $MI_MEMFREE $MI_ACTIVE $MI_USED_C   ""         $MI_UNAVL_C   $MI_AVAIL     $MI_PAGECACHE_C $MI_CACH_SREC_BUFF_C $MI_BUFF  $MI_CACHE_SRECL_C $MI_CACHED $MI_SLAB $MI_SREC $MI_SHMEM  $MI_ACTF  $MI_INACTF 
if [ $SAR_EXISTS -gt '1' ] ; then
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "\`sar\`"  ""        "\"Used\""   "Free"      "Active"   ""           ""         ""            ""            ""              ""                   "Buff"    ""                "Cache"    ""       ""       ""         ""        ""         
printf "%7s %8s %12s %8s %8s %12s %8s %8s %10s %10s %8s %8s %12s %8s %8s %8s %8s %8s %8s %8s\n" "\`sar\`"  ""        $MS_USED     $MS_FREE    $MS_ACTIVE ""           ""         ""            ""            ""              ""                   $MS_BUFF  ""                $MS_CACHED
fi
echo 
}
PRINT_DETAILS() {
if [ -n "${details}" ] ; then
	#echo
	#echo "$SAR" | egrep 'kbmemfree|Average'
	echo 
	echo "$MEMFREE"
	echo
	echo "--------"
	echo 
	printf "%-10s %40s %10s   More information on the stats.  Note, a * represents a read value vs a calculated value.\n" "Command" "Statistic" "Value"
	echo 
	printf "%-10s %40s %10d   \n" "free*" "Total system memory" $MF_TOTAL
	printf "%-10s %40s %10d   \n" "meminfo*" "Total system memory" $MI_TOTAL
	echo 
	printf "%-10s %40s %10d   Memory with nothing in it\n" "free*" "Free (unused) memory" $MF_FREE
	printf "%-10s %40s %10d   Memory with nothing in it\n" "meminfo*" "Free (unused) memory" $MI_MEMFREE
	printf "%-10s %40s %10d   Reported system value estimating memory available to run new applications; based on: MemFree - LowWaterMark + (PageCache - min(PageCache / 2, LowWaterMark))\n" "free*" "MemAvailable" $MF_AVAIL
	printf "%-10s %40s %10d   Reported system value estimating memory available to run new applications; based on: MemFree - LowWaterMark + (PageCache - min(PageCache / 2, LowWaterMark))\n" "meminfo*" "MemAvailable" $MI_AVAIL
	printf "%-10s %40s %10d   Calculated based on values in meminfo: (free + pagecache + sreclaimable + lowwatermark*3)\n" "meminfo" "MemAvailable Estimate" $MI_AVAIL_EST
	echo 
	printf "%-10s %40s %10d   Value read from \`free\`\n" "free*" "Used memory" $MF_USED
	printf "%-10s %40s %10d   Result of calculating (Total - Free - \"Buff/Cache\"), used to validate formula\n" "free" "Used memory (calculation)" $MF_USED_C
	printf "%-10s %40s %10d   (Total - Free - Buffers - \"Cache\" - SReclaimable)\n" "meminfo" "Used memory (calculation)" $MI_USED_C
	printf "%-10s %40s %10d   (Total - Available)\n" "free" "Unavailable Memory" $MF_UNAVL_C
	printf "%-10s %40s %10d   (Total - Available)\n" "meminfo" "Unavailable Memory" $MI_UNAVL_C
	printf "%-10s %40s %10d   Memory with something in it; unused RAM is wasted RAM (total - free)\n" "free" "Populated" $MF_POP
	printf "%-10s %40s %10d   Memory with something in it; unused RAM is wasted RAM (total - free)\n" "meminfo" "Populated" $MI_POP
	echo
	printf "%-10s %40s %10d   File IO buffer, generally writes\n" "free*" "Buffers" $MFW_BUFF
	printf "%-10s %40s %10d   Based on nr_file_pages - Buffers, including SReclaimable\n" "free*" "Cached" $MFW_CACHE
	printf "%-10s %40s %10d   (buffers+cache)\n" "free*" "Buff/Cache" $MF_BUFFCACHE
	echo 
	printf "%-10s %40s %10d   File IO buffer, generally writes\n" "meminfo*" "Buffers" $MI_BUFF
	printf "%-10s %40s %10d   Based on nr_file_pages - Buffers, not including SReclaimable\n" "meminfo*" "Cached" $MI_CACHED
	printf "%-10s %40s %10d   Kernel data structures cache\n" "meminfo*" "Slab" $MI_SLAB
	printf "%-10s %40s %10d   Slab that can be reclaimed\n" "meminfo*" "SReclaimable" $MI_SREC
	printf "%-10s %40s %10d   Should match the \`free\` command's \"cached\", note the inclusion of SReclaimable\n" "meminfo" "Cached + SReclaimable" $MI_CACHE_SRECL_C
	printf "%-10s %40s %10d   Should match the \`free\` command's \"buff/cached\", note the inclusion of SReclaimable\n" "meminfo" "Cached + SReclaimable + Buffers" $MI_CACH_SREC_BUFF_C
	echo
	printf "%-10s %40s %10d   Shmem, shared memory\n" "meminfo*" "Shared Memory" $MF_SHARED
	printf "%-10s %40s %10d   Shmem, shared memory\n" "meminfo*" "Shmem" $MI_SHMEM
	echo
	printf "%-10s %40s %10d   This is page cache memory that has been recently used and is usually not reclaimed for other purposes.\n" "meminfo*" "Active File" $MI_ACTF
	printf "%-10s %40s %10d   This is page cache memory that has not been recently used and can be reclaimed for other purposes.\n" "meminfo*" "Inactive File" $MI_INACTF
	printf "%-10s %40s %10d   (active files + inactive files = page cache --- not the same as cache, which is based on nr_file_pages)\n" "meminfo" "Page Cache" $MI_PAGECACHE_C
	echo
	printf "%-10s %40s %10d   When a system will start to swap\n" "zoneinfo*" "Low Water Mark" $LOW_WATERMARK
	#echo 
	#printf "%20s + %18s + %20s + %20s - %15s \n"  MI_MEMFREE MI_ACTF MI_INACTF MI_SREC LOW_WATERMARK*3
	#printf "%20s + %18s + %20s + %20s - %15s \n"  $MI_MEMFREE $MI_ACTF $MI_INACTF $MI_SREC $LOW_WATERMARK*3
	echo
	echo "-----------------------------------------------------------------------------"
	echo 
fi
}

MAIN() {
GET_DATA
PARSE_SAR
PARSE_FREE
PARSE_MEMINFO
PRINT_HORIZONTAL
PRINT_DETAILS
}

PARSE_ARGS "$@"
MAIN








