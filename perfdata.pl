#!/usr/bin/perl
#-----------------------------------------------------------------------
# (C) Copyright IBM Corporation 2015.
#  
# The source code for this program is not published or otherwise
# divested of its trade secrets, irrespective of what has
# been deposited with the U.S. Copyright Office.
# ----------------------------------------------------------------------
#
$version="6.02.02";
$date_of_last_change="20200928";

#$mem = `ps h -o thcount,sz,rss $$`; print "1 RSS $mem";
use Config;
use Cwd 'chdir';
use Time::localtime;	#Gets current time: localtime->sec()...
use Time::Local; 		#Converts to epoch: timelocal($seconds,$minutes,$hours,$days,$months-1,$year);

#use warnings;
#use threads::shared;
#use File::Basename; 
#use Sys::Hostname; 
#use Term;
#use Memory::Usage;
#use POSIX qw(strftime);
#use DateTime;
#use Time::Piece ();
#use Data::Dumper; 
$command_run = "$0 @ARGV";
#$input_flags = "@ARGV";
$global_debug_setting = 0 ;

# DEBUG VALUES:
#  1: Initialize, always printed when debug is on
#  2: Date/time/sar
#  3: System commands
#  4: dir tar
#  5: initialize
#  6: parse file
#* 7: parse network
#  8: parse ps
#  9: print to console
# 10: convert CPU
# 11: get interval
# 12: Historical data 
# 13: Day time conversion
#*14: parse sar
# 15: store iotop
# 16: parse iotop
#*17: Identify command name
# 18: csv headers
# 19: passing array for csv
# 20: Threads
# 21: Clear process hash
# 22: Repeating header
# 23: Network Averages
# 25: PID Averages
# 26: Midnight errors
# 27: csv iotop 
# 28: WGET response time
# 29: NETSTAT ports
# 30: DB2 snap shots
# 31: df disk
# 32: new disk util
# 33: convery disk name
# 34: disk utilization averages
# 35: disk df averages
# 36: parse lsblk
# 37: print lsblk
# 38: sort commands output screen
# 39: du 

sub println {
	print  ((@_? join($/, @_) : $_), $/);
}
sub debug {
	my $this_debug = shift(@_) ;
	if ( $global_debug_setting == $this_debug || ( $global_debug_setting > 0 && $this_debug == 1 ) || $this_debug == 0 ) {
		my $datestring = sprintf '%04d%02d%02d', localtime->year() + 1900, localtime->mon()+1, localtime->mday();
		my $timestring = sprintf '%02d%02d%02d', localtime->hour(), localtime->min(), localtime->sec();
		#printf "$datestring.$timestring, debug %2d: @_\n", "$this_debug";
		print  ("$datestring.$timestring, debug $this_debug: @_\n");
	}
}
sub printArray {
	my $X = 0 ;
	foreach my $space (@_) {
		println ("$X: $space");
		$X++;
	}
}
# /perf1/downloads/unix/yum.sh install perl-Time-HiRes
#	@timer_array			= (0,0,0,0,0);
#sub startTimer { use Time::HiRes qw( gettimeofday ); my $index=shift(@_) ; $timer_array[$index]=gettimeofday(); }
#sub getTimer { use Time::HiRes qw( gettimeofday ); my $index=shift(@_) ; my $comment=shift(@_) ; my $diff=gettimeofday()-$timer_array[$index]; $sum_array[$index]=$sum_array[$index]+$diff; printf("Timer $index: %20s, %.6f %.6f\n", "$comment", $diff, $sum_array[$index]); }

sub STARTUP_INITIALIZE {
	$disable_collection		= 0;
	$other_workload			= 0;
	$csv_output				= 0;
	$perf1					= 0;
	$small_screen			= 0;
	$collect_all_processes	= 0;
	$separate_processes		= 0;
	$collect_all_processes_flag	= "";
	$allowed_ofset_seconds	= 2;
	$process_is_running		= "";
	#$PerlVersion 			= "$]";
	$perfdata_dir 			= "/usr/perfdata";
	$db2_snapshots_dir_name	= "db2_snapshots";
	$dir_flag 				= "";
	$temp_input_file		= "";
	$iotop_flag				= "";
	#$db2_command			= "/opt/ibm/db2/V10.5/bin/db2";
	$start_collection_loop 	= 0;
	$iotop_activity_type	= "Total";
	$nohup_collect 			= 0;
	$kill_collection 		= 0;
	#$hostname 				= `hostname | cut -d "." -f 1 | tr -d '\r\n'`;
	$hostname 				= `hostname | tr -d '\r\n'`;
#	if ( -f '/host/usr/bin/hostname' ) { 
#		$hostname 				= `/host/usr/bin/hostname | tr -d '\r\n'`;
#	} else {
#		$hostname 				= `hostname | tr -d '\r\n'`;
#	}
	$osname					= $Config{osname};
	$archname				= $Config{archname};
	$read_interval			= 60;
	$write_interval			= 60;
	$current_interval		= 60;
	$db2_interval			= 3600;
	#$default_egrevp			= "grep|tail|$$";
	$endofloop				= "End of loop.";
	$read_update_speed		= 5;
	$print_header			= 1;
	$header_loop_count		= 0;
	$use_full_command		= 0;
	$use_front_command 		= 0 ;
	$input_regex			= "";
	$identify_disk_name		= 1;
	$command_PID			= 0;
	$sum_processes			= 0;
	$show_dir_size			= 0;
	$output_count			= 0;
	$iotop_installed		= 0;
	$lsblk_installed		= 0;
	#$lsblk_mod				= 0; #RDZ
	$old_lsblk_output		= "";
	%lsblk_devname_to_mount_hash	= ();
	$averages_interval		= 5;
	#$end_of_parsing_range	= 0;
	$cleanup_dirs			= 0;
	$disk_used				= 0;
	$disk_free				= 0;
	$disk_tps				= 0;
	$disk_rps				= 0;
	$disk_wps				= 0;
	$disk_await				= 0;
	$disk_svctm				= 0;
	$previous_iteration_count = 0;
	
	#@active_disk_names		= ();
	#$disks_displayed_count 	= 0;
	@requested_disk_df_names_array = ();
	$disk_df_displayed_count = 0;
	
	@requested_disk_metric_names_array = ();
	
	@requested_network_names_array	= ();
	$networks_displayed_count = 0;
	$KILO					= 1024;
	$MEGA					= 1048576;
	$BITS					= 8; #1=bytes 8=bits
	$network_divide			= $MEGA; #default Mbits
	$network_scale			= "Mb";
	$sum_network			= 0;
	
	$max_processes_used		= 0;	
	@used_codes 			= ();
	$regex					= "";
		
	STARTUP_PRODUCT_CODES();
	
	%old_CPU_seconds		= ();
	%new_CPU_seconds		= ();
	
	STARTUP_INDEXES();	
	
	debug ( 0 , "$version, $date_of_last_change, command: $command_run" );
	
	$linux=0;
	$aix=0;
	$solaris=0;
	$hp=0;
	$windows=0;
	if ( $osname =~ m/linux/ ) {
		$linux=1;
		$OSCODE="Linux";
		$cpu_cores  = `cat /proc/cpuinfo | grep "processor" | wc -l`;
		
		$iotop_installed = `whereis iotop | grep bin | wc -l`;
		if ( $iotop_installed != 0 ) {
			$iotop_command_path = `whereis iotop | grep bin | cut -d ' ' -f 2`;
			chomp($iotop_command_path);
			$iotop_version = `${iotop_command_path} --version`;
			chomp($iotop_version);
			debug ( 0 , "iotop is installed in \"$iotop_command_path\", version \"$iotop_version\"" );
		} 
		else {
			debug ( 0 , "iotop not installed" );
		}
		$lsblk_installed = `whereis lsblk | grep bin | wc -l`;
		if ( $lsblk_installed ) {
			$lsblk_command_path = `whereis lsblk | grep bin | cut -d ' ' -f 2`;
			chomp($lsblk_command_path);
			debug ( 1 , "lsblk is installed in \"$lsblk_command_path\"" );
		} 
		else {
			debug ( 0 , "lsblk not installed" );
		}
		$ps_version=`ps -V | awk -F " " '{print $NF}' | cut -d '.' -f 1-2`;
		$use_ps_thcount=1;	
		if ( $ps_version >= 3.3 ) {
			my $ps_sub_version=`ps -V | awk -F " " '{print $NF}' | cut -d '.' -f 3`;
			if ( $ps_sub_version < 10 ) {
				debug ( 0 , "ps_sub_version $ps_sub_version is less than 10, turning off threads in ps" );
				$use_ps_thcount=0;	
			}
		}
		$ubuntu=`uname -a | grep -i ubuntu| wc -l`;
		debug ( 0 , "use_ps_thcount $use_ps_thcount" );
	} 
	elsif ( $osname =~ m/aix/ ) {
		$aix=1;
		$OSCODE="AIX";
		$cpu_cores = `lsdev -Cc processor | wc -l | sed -e 's/^[ \t]*//'`;
	} 
	elsif ( $osname =~ m/solaris/ ) {
		$solaris=1;
		$OSCODE="SunOS";
		$cpu_cores = `prtdiag | grep on-line | wc -l | sed -e 's/^[ \t]*//'`;
	} 
	elsif ( $osname =~ m/hp/ ) {
		$hp=1;
		$OSCODE="HP";
		$cpu_cores  = `cat /proc/cpuinfo | grep "processor" | wc -l`;
	} 
	elsif ( $osname =~ m/windows/ ) {
		$windows=1;
		$OSCODE="Windows_NT";
		debug ( 0 , "The osname \"$osname\" is not setup yet, exiting..."); exit 1;
	} 
	else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }

	$ifconfig_command_path = `whereis ifconfig | grep bin | cut -d ' ' -f 2`;
	chomp($ifconfig_command_path);
	
	
	chomp($cpu_cores);
	$max_CPU_seconds = $cpu_cores * 60;
	$max_CPU_percent = $cpu_cores * 100;
	
	$max_klzagent_iotop = 10;
	
	#OTHER WORKLOADS
	#$run_db2_snapshot			= 0;
	$monitor_response_times		= 0;
	$monitored_response_address = "";
	$monitor_netstat_ports		= 0;
	$monitored_netstat_regex 	= "";
}
sub STARTUP_PRODUCT_CODES { #CUSTOMIZE_AREAS

	#CUSTOMIZE_1: Add general terms to grep for processes to store raw ps data. "ibm" should cover most products we want
	$egrepstring_ps			= "ibm|IBM|opt|perf1|itp-bam|Rserve| db2sysc|mongod|BESClient|kt5agent|kfc|kasmain|Cassandra|kairosdb|docker|kube|etcd|redis|redmonz|grafana|influx|firefox|Xvfb|flanneld|salt|httpmonitor|haproxy|charon|scylla|carbon|node|postgres|python|prometheus|cloudant|calico|gluster|nginx|npm|java|coredns|icam-ui|amui|go|collector|minio|thanos";
	$egrepvstring_ps 		= "grep|kworker|perfdata.pl regex";
	#$egrepvstring_ps 		= "grep|\\[|\\]";
	#$egrepstring_iotop		= "Total DISK READ|jbd2|flush|cp |tar |mv |$egrepstring_ps";
	$egrepvstring_iotop		= "klzagent";
	#$df_drives_regex		= " /\$| /dev/shm\$| /boot\$";
	$df_drives_regex		= "\% /";
	
	#CUSTOMIZE_2: Add specific processes to view data for
	#[Short name],[display rank for csv file],[regex]
	
	%prod_code_hash	= 	( 	
	"em" => 	["TEMS: kdsmain",					1,		0,	"bin/kdsmain|./kdsmain", 						""],
	"cq" => 	["TEPS: KfwServices",				2,		0,	"bin/kfwservices|./kfwservices",				""],
	"ew" => 	["TEPS: eWAS",						3,		0,	"/iw/profiles",									""],
	"hd" => 	["Warehouse: khdxprtj",				4,		0,	"bin/khdxprtj|./khdxprtj",						""], 
	
	"mn" => 	["MIN",								10,		0,	"ws-server.jar min --clean",					" start| stop"],		# APM
	"s1" => 	["Server1",							11,		0,	"ws-server.jar server1 --clean",				" start| stop"],		# APM
	"ui" => 	["APMUI",							12,		0,	"ws-server.jar apmui --clean",					" start| stop"],		# APM
	"oed" => 	["OED",								13,		0,	"ws-server.jar oed --clean",					" start| stop"],		# APM
	"uv" => 	["Uviews",							13,		0,	"ws-server.jar uviews --clean",					" start| stop"],		# APM
	"id" => 	["Open ID Connect",					14,		0,	"ws-server.jar oidc --clean",					" start| stop"],		# APM
	"ar" => 	["ASFREST",							15,		0,	"ws-server.jar asfrest --clean",				" start| stop"],		# APM
	"hg" => 	["Hybrid Gateway",					16,		0,	"ws-server.jar hybridgateway --clean",			" start| stop"],		# APM
	"db" => 	["DB2: db2sysc",					17,		1,	"db2sysc",										""],				# APM
	"scr" => 	["SCR Toolkit",						18,		0,	"SCR/XMLtoolkit/sdk",							""],				# APM
	"as" => 	["KAS: kasmain",					19,		0,	"bin/kasmain|./kasmain",						""],				# APM
	"sy" => 	["SPA: ksy610",						20,		0,	"bin/ksy610|./ksy610",							""],				# APM
	"itp" => 	["ITP: BAM",						21,		0,	"itp-bam",										""],				# APM
	
	"kk" => 	["Kafka",							30,		0,	"Kafka.kafka",									""],				# 	BOTH
	"kr" => 	["Kafkarest",						31,		0,	"common-kafkarest-all.jar",						""],				# 	BOTH
	"zk" => 	["Zookeeper",						32,		0,	"config/zookeeper.properties|/zoo.cfg",			""],				# 	BOTH		
	"zm" => 	["ZooKeeperMain",					32,		0,	"org.apache.zookeeper.ZooKeeperMain",			""],				# 		CLOUD
	"md" => 	["Mongod",							33,		0,	"bin/mongod",					   "user|cron|log|csv"],				# 	BOTH
	"ca" => 	["Cassandra",						34,		0,	"org.apache.cassandra.service.CassandraDaemon",	""],				# 	BOTH
	"scy" => 	["ScyllaDB",						35,		0,	"scylla --",									""],				# 	BOTH
	"scj" => 	["scylla-jmx",						36,		0,	"scylla-jmx",									""],				# 	BOTH
	"es" =>		["elasticsearch",					37,		0,	"bootstrap.Elasticsearch",						""],

	"in" => 	["Ingress Service",					40,		0,	"ws-server.jar ingress",						""],				#		CLOUD
	"acm" => 	["Agent Communication",				41,		0,	"ws-server.jar agentcomm",			" start| stop"],				# 		CLOUD
	"tc" => 	["TEMA Config Liberty",				42,		0,	"ws-server.jar temaconfig",			" start| stop"],				# 		CLOUD
	"tcg" => 	["TEMA Config Go",					43,		0,	"/temaconfig",						            ""],				# 		CLOUD
	"tcm" => 	["TEMA Communication",				44,		0,	"ws-server.jar temacomm",			" start| stop"],				# 		CLOUD
	"ts" => 	["Tema SDA",						45,		0,	"ws-server.jar temasda",						""],				#		CLOUD	
	"cs" => 	["Config Server",					46,		0,	"ws-server.jar config_server",					""],				#		CLOUD
	"ab" => 	["Agent bootstrap",					47,		0,	"agentbootstrap.js",							""],				#		CLOUD
	
	"mp" => 	["Metric Provider",					50,		0,	"ws-server.jar metricprovider|metricprovider.jar",	""],				#		CLOUD
	"lk" => 	["Linking Service",					51,		0,	"relationship.jar",								""],				#		CLOUD
	"mps" => 	["MP standalone",					52,		0,	"standalone.MetricProducer",					""],				#		CLOUD
	"mpc" => 	["MP conversion",					53,		0,	"metricconversion.MetricProcessing",			""],				#		CLOUD
	"mpp" => 	["MP publish",						54,		0,	"metricpublish.MetricPublishProcessing",		""],				#		CLOUD
	"kd" => 	["KairosDB",						55,		0,	"conf/kairosdb.properties",						""],				#		CLOUD
	
	"kd128" => 	["KairosDB 128M",					55,		0,	"Xmx128M.*conf/kairosdb.properties",			""],				#		CLOUD
	"kd256" => 	["KairosDB 256M",					55,		0,	"Xmx256M.*conf/kairosdb.properties",			""],				#		CLOUD
	"kd512" => 	["KairosDB 512M",					55,		0,	"Xmx512M.*conf/kairosdb.properties",			""],				#		CLOUD
	"kd1024" => ["KairosDB 2G",						55,		0,	"Xmx1024M.*conf/kairosdb.properties",			""],				#		CLOUD
	"kd1" => 	["KairosDB 2G",						55,		0,	"Xmx1G.*conf/kairosdb.properties",				""],				#		CLOUD
	"kd2" => 	["KairosDB 2G",						55,		0,	"Xmx2G.*conf/kairosdb.properties",				""],				#		CLOUD
	
	"kdsq" => 	["KairosDB Summary Query",			55,		0,	"Xms60M.*conf/kairosdb.properties",				""],				#		CLOUD
	"kdq" => 	["KairosDB Query",					55,		0,	"Xms61M.*conf/kairosdb.properties",				""],				#		CLOUD
	"kdss" => 	["KairosDB Summary Storage",		55,		0,	"Xms62M.*conf/kairosdb.properties",				""],				#		CLOUD
	"kds" => 	["KairosDB Storage",				55,		0,	"Xms63M.*conf/kairosdb.properties",				""],				#		CLOUD
	
	"mcs" => 	["Metric Consumer Summary",			56,		0,	"-Xms64M.*metric.consumer.jar",					""],				#		CLOUD
	"mcr" => 	["Metric Consumer Raw",				57,		0,	"-Xms63M.*metric.consumer.jar",					""],				#		CLOUD
	"ms" => 	["Metric Service API",				58,		0,	"metric_service_api.js",						""],				#		CLOUD
	"msc" => 	["Metric Summary Creation",			59,		0,	"service.metricsummarycreation.jar",			""],				#		CLOUD
	"msp" => 	["Metric Summary Policy",			60,		0,	"./go_metric_summary_policy",					""],				#		CLOUD
	"sts" => 	["Streaming Service",		        61,		0,	"ws-server.jar streamingservice",	" start| stop"],				#		CLOUD
	"mer" => 	["Metric Enrichment",		        62,		0,	"metricenrichment.jar",				" start| stop"],				#		CLOUD
	"geo" => 	["Geolocation",		       			63,		0,	"ws-server.jar geolocation",				" start| stop"],				#		CLOUD
	
	"amr" => 	["AM ReST",							70,		0,	"ws-server.jar applicationmgmt",				""],				#		CLOUD
	"amc" => 	["AM Consumer",						71,		0,	"service.applicationmgmt.kafkaConsumer.jar",	""],				#		CLOUD
	"amrg" => 	["AM ReST GO",						72,		0,	"/opt/ibm/app/webserver-prod",	""],				#		CLOUD
	"amcg" => 	["AM Consumer GO",					73,		0,	"/opt/ibm/app/consumer-prod",	""],				#		CLOUD
	"agm" => 	["Agent Management",				74,		0,	"agentmgmt.js",								 "sh "],				#		CLOUD
	"th" => 	["Threshold Service",				75,		0,	"ws-server.jar thresholdservice",	" start| stop"],				#		CLOUD
	"to" => 	["Topology Service",				76,		0,	"topology-service",								""],				# 	BOTH
	"ssr" => 	["Search Service",					77,		0,	"search-service/search-service.jar",								""],				# 	BOTH
	
	"al" => 	["Alarm REST Service",				80,		0,	"ws-server.jar alarmrest",						""],				#		CLOUD	NEED!!!
	"af" => 	["Alarm Forwarder Service",			81,		0,	"ws-server.jar alarmfwd",						""],				#		CLOUD	NEED!!!
	"ae" => 	["Alarm Event Source",				82,		0,	"ws-server.jar alarmeventsrc|alarmeventsrc.jar",		""],				#		CLOUD	NEED!!!
	"at" => 	["Alarm Transform",					83,		0,	"rti.alarm.transform.AlarmTransformer",			""],				#		CLOUD	NEED!!!
	"rtm" => 	["RTE Metric",						84,		0,	"rte.core-with-dependencies.jar metric.json",						""],				#		CLOUD	NEED!!!
	"rts" => 	["RTE Synthetic",					85,		0,	"RteEngine aar.synthetic.json",					""],				#		CLOUD	NEED!!!
	"eo" => 	["Event-observer",					86,		0,	"event-observer.jar",							""],				#		CLOUD	NEED!!!
	
	"cui" => 	["icam-ui",							100,	0,	"icam-ui",									"log|perfdata"],				#		CLOUD	
	"amr" => 	["amuirest",						101,	0,	"amuirest",									"log|perfdata"],				#		CLOUD	
	
	"k8" => 	["k8s-monitor",						110,	0,	"collector.py|resource_event_driver.pyc|metric_driver.pyc",	""],	#		CLOUD
	"k8r" => 	["k8s-monitor resources",			111,	0,	"resource_event_driver.pyc",					""],	#		CLOUD
	"k8m" => 	["k8s-monitor metrics",				112,	0,	"metric_driver.pyc",							""],	#		CLOUD
	"mex" => 	["metric-extender",					112,	0,	"/opt/ibm/metric-extender-bin",						""],	#		CLOUD
	
	"sdc" => 	["Sidecar",							111,	0,	"sidecar-",							" start| stop|bin/sh"],			# 		CLOUD
	"me" => 	["Metering",						112,	0,	"ws-server.jar metering",						""],				#		CLOUD
	"ra" => 	["Docker.R",						113,	0,	"/etc/Rserve_analytics.conf",					""],				#		CLOUD
	"smt" => 	["Synthetic MT",					114,	0,	"SyntheticMetricTransformer.json",				""],				#		CLOUD
	"mmt" => 	["Middleware MT",					115,	0,	"MiddlewareMetricTransformer.json",				""],				#		CLOUD
	
	"st" => 	["Synthetic Service",				120,	0,	"ws-server.jar synthetic",			" start| stop"],				#		CLOUD
	"sg" => 	["Synthetic Agent",					121,	0,	"synthetic.agent.SyntheticAgent",				""],				#		CLOUD
	"rt" => 	["rtioutputtransformer",			124,	0,	"rtioutputtransformer",				" start| stop"],				#		CLOUD
	"sls" => 	["Selenium Start",					125,	0,	"ws-server.jar selenium --pid",					""],				#		CLOUD
	"sl" => 	["Selenium",						126,	0,	"ws-server.jar selenium",						""],				#		CLOUD
	"sq" => 	["Selenium QueueMoniter",			127,	0,	"synthetic.playback.selenium.QueueMoniter",		""],				#		CLOUD
	"ss" => 	["Selenium Server Standalone",		128,	0,	"selenium-server-standalone",					""],				# 		CLOUD
	"ff" => 	["FireFox",							129,	0,	"/firefox ",									""],				# 		CLOUD	
	"cdr" => 	["Chromedriver",					130,	0,	"/opt/chrome/chromedriver-",					""],				# 		CLOUD	
	"goo" => 	["Google-chrome",					131,	0,	"/opt/google/chrome/google-chrome",				""],				# 		CLOUD	
	"nh" => 	["Chrome nacl_helper",				132,	0,	"/opt/google/chrome/nacl_helper",				""],				# 		CLOUD	
	"zy" => 	["Chrome zygote",					133,	0,	"/opt/google/chrome/chrome --type=zygote",		""],				# 		CLOUD	
	"re" => 	["Chrome renderer",					134,	0,	"/opt/google/chrome/chrome --type=renderer",	""],				# 		CLOUD	
	"gp" => 	["Chrome gpu",						135,	0,	"/opt/google/chrome/chrome --type=gpu-process",	""],				# 		CLOUD	
	
	"xv" => 	["Xvfb",							140,	0,	"Xvfb ",										""],				# 		CLOUD	
	"rd" =>		["Redis",							141,	0,	"redis-server",									""],
	"pb" => 	["HTTP Playback",					142,	0,	"httpmonitor",									"log"],				# 		CLOUD	
	"jpi" => 	["Javascript Playback Index",		143,	0,	"node index.js",								"log"],				# 		CLOUD
	"jpb" => 	["Javascript Playback bin",			144,	0,	"/opt/ibm/microservice/javascript-playback/bin/index.js",	"log"],	# 		CLOUD
	"tr" => 	["Transaction Service",				145,	0,	"ws-server.jar transaction",					" start| stop"],	#		CLOUD
	"ea" => 	["Synthetic Event Agent",			146,	0,	"syntheticevents.client.SyntheticEventsAgent",	" start| stop"],	#		CLOUD
	
	"gu" => 	["geolocation-update.sh",			150,	0,	"geolocation-update.sh",						""],				# APM		
	"te" => 	["tx kteagent",						151,	0,	"bin/kteagent",									""],				# APM		
	"ac" => 	["tx AgentControl",					152,	0,	"com.ibm.tivoli.monitoring.jat.AgentControl",	""],				# APM		
	"so" => 	["ksoagent",						153,	0,	"bin/ksoagent",									""],				# APM	
	"bi" => 	["kbiagent",						154,	0,	"bin/kbiagent",									""],				# APM		

	"nmp" => 	["nmp",								160,	0,	"npm",											""],				# CLOUD	
	"naj" => 	["node app.js",						161,	0,	"node app.js",									"sh"],				# CLOUD	
	"nww" => 	["node bin/www",					162,	0,	"node bin/www",									""],				# CLOUD	
	"ceaw" => 	["node ./bin/www",					160,	0,	"node ./bin/www",								""],				# CEM	
	"cnm" => 	["cem normalizer",					161,	0,	"node --max-old-space-size=1000 bin/www",		""],				# CEM	
	#"cic" => 	["cem integration-controller",		162,	0,	"node bin/www",									""],				# CEM		
	"cep" => 	["cem eventpreprocessor",			163,	0,	"node eventpreprocessor.js",					""],				# CEM			
	"cdl" => 	["cem datalayer (dataapi)",			164,	0,	"node dataapi",										"js|sh"],			# CEM		
	"cbr" => 	["cem brokers",						165,	0,	"node --optimize_for_size --max_old_space_size=230 app/index",	""],				# CEM	
	"cip" => 	["cem incidentprocessor",			166,	0,	"node incidentprocessor.js",									""],				# CEM		
	#"cus" => 	["cem users",						167,	0,	"node bin/www",									""],				# CEM		
	"cdb" => 	["cem couchdb",						168,	0,	"progname couchdb",								""],				# CEM		
	"ccs" => 	["cem channelservices",				169,	0,	"node channelservices.js",						""],				# CEM		
	"ceai" => 	["cem event-analytics-ui index",	170,	0,	"bin/node /app/src/rt_server/index.js",			""],				# CEM		
	"csu" => 	["cem scheduling-ui",				171,	0,	"node --max-old-space-size=1000 app.js",		"sh"],				# CEM		

	"otc" => 	["opentt-collector",				180,	0,	"/opt/jaeger-collector",							" start| stop"],	#		CLOUD	
	"otq" => 	["opentt-query",					181,	0,	"/opt/service.opentt.query",						" start| stop"],	#		CLOUD	
	"otjq" => 	["opentt-query jaeger",				182,	0,	"/opt/jaeger-query",								" start| stop"],	#		CLOUD	
	"ota" => 	["opentt-analyzer",					183,	0,	"java -jar /opt/service.opentt.analyzer.jar|/opt/ibm/opentt_analyzer",		" start| stop"],	#		CLOUD	
	"otd" => 	["opentt-dependency",				184,	0,	"/opt/jaeger-spark-dependencies.jar",				" start| stop"],	#		CLOUD	
	"oti" => 	["opentt-ingester",					185,	0,	"/opt/jaeger-ingester",				" start| stop"],	#		CLOUD	
		
	#"sp" => 	["Spark Server",					201,	0,	"ws-server.jar spark",							""],				# 		CLOUD	
	#"sz" => 	["Spark Zookeeper",					202,	0,	"org.apache.hadoop.hdfs.tools.IBMSPARKDFSZKController",		""],				# 	BOTH		
	#"nn" => 	["Hadoop NameNode",					203,	0,	"org.apache.hadoop.hdfs.server.namenode.NameNode",	""],			# 		CLOUD
	#"dn" => 	["Hadoop DataNode",					205,	0,	"org.apache.hadoop.hdfs.server.datanode.DataNode",	""],			# 		CLOUD
	#"ta" => 	["Threshold Analysis Driver",		207,	0,	"analytics.spark.streaming.IoTAnalyticsEngineContext",	""],		#		CLOUD
	#"sc" => 	["Score Calculator Driver",			208,	0,	"com.ibm.perfmgmt.calculatescore.Driver",		""],		#		CLOUD
	#"ioaa" => 	["IOA Analytics Driver",			210,	0,	"com.ibm.itoa.analytics.",						""],				# 	BOTH
	#"ioam" => 	["IOA Mediation Driver",			211,	0,	"com.ibm.itoa.mediation.",						""],				# 	BOTH
	#"scga" => 	["Spark CrGnSc Analytics",			212,	1,	"/opt/shared/analytics/config/",				""],				# 	BOTH
	#"scgm" => 	["Spark CrGnSc Mediation",			213,	1,	"/opt/shared/mediation/config/",				""],				# 	BOTH
	#"sb" => 	["Spark SparkSubmit",				216,	1,	"org.apache.spark.deploy.SparkSubmit",			""],				# 	BOTH
	#"spd" => 	["Spark Driver",					217,	1,	"Dspark.driver.extraJavaOptions=",			""],				# 	BOTH
	
	"sm" => 	["Spark Master",					200,	0,	"org.apache.spark.deploy.master.Master",		"tail"],				# 	BOTH
	"sw" => 	["Spark Worker",					201,	0,	"org.apache.spark.deploy.worker.Worker",		"tail"],				# 	BOTH
	"sea" => 	["Spark EA-Analytics",				202,	0,	"ea-analytics-runtime-spark.jar",				""],		#		CLOUD
	"saa" => 	["Spark AARAggregator",				203,	0,	"aaraggregator",								""],				# 	BOTH
	"sii" => 	["Spark InterestingInst",			204,	0,	"InterestingInstances_cfg.json",				""],				# 	BOTH
	"cg" => 	["Spark CrGnExBc",					205,	1,	"CoarseGrainedExecutorBackend",					""],				# 	BOTH
	
	"blc" => 	["Baseline Config",					220,	0,	"ws-server.jar baselineconfiguration",	" start| stop"],				#		CLOUD	
	"pip" => 	["PI Policy Registry",				221,	0,	".bin/hdm-api-server",	""],											#		CLOUD
	"pii" => 	["PI Inference",					222,	0,	"jar lib/inference-service",	""],									#		CLOUD
	"pit" => 	["PI Trainer",						223,	0,	"lib/ea-training-service",	""],										#		CLOUD

	"dd" =>		["Docker Daemon",					230,	0,	"docker daemon|dockerd|docker -d",								""],
	"dp" =>		["Docker Proxy",					231,	0,	"docker-proxy",									""],
	"dr" =>		["Docker Registry",					232,	0,	"docker_registry.wsgi:application",				""],
	"de" =>		["Docker exec",						233,	0,	"docker exec",									""],
	"et" =>		["etcd",							234,	0,	"bin/etcd|etcd --",										""],
	"dc" =>		["docker -d",						235,	0,	"docker-containerd",							""],
	
	"kl" =>		["kubelet",							240,	0,	"hyperkube kubelet|kubelet --config",							"/bin/sh|/bin/bash"],
	"kc" =>		["kube-controller-manager",			241,	0,	"hyperkube controller-manager|kube-controller-manager",	"/bin/sh|/bin/bash"],
	"ka" =>		["kube-apiserver",					242,	0,	"hyperkube apiserver|kube-apiserver ",					"/bin/sh|/bin/bash|cluster-kube-apiserver-operator"],
	"scl" =>	["service-catalog",					242,	0,	"service-catalog apiserver",							"/bin/sh|/bin/bash"],
	"ks" =>		["kube-scheduler",					243,	0,	"hyperkube scheduler|kube-scheduler",					"/bin/sh|/bin/bash"],
	"kp" =>		["kube-proxy",						244,	0,	"hyperkube proxy|kube-proxy",							"/bin/sh|/bin/bash"],
	"ku" =>		["kube-ui",							245,	0,	"kube-ui",												"/bin/sh|/bin/bash"],
	"k2" =>		["kube2sky",						246,	0,	"kube2sky",												"/bin/sh|/bin/bash"],
	"ko" =>		["kube-addons.sh",					247,	0,	"kube-addons.sh",										""],
	"kw" =>		["kworker",							248,	0,	"kworker",												""],
	"fl" =>		["flanneld",						249,	0,	"flanneld",												""],
	"cdns" =>	["coredns",							249,	0,	"coredns",												""],
	"salt" =>	["salt",							250,	0,	"salt",													""],
	"ips" =>	["IPSEC charon",					251,	0,	"strongswan/charon",									""],
	"ls" =>		["logstash",						252,	0,	"/logstash",										""],
	"kb" =>		["kibana",							254,	0,	"/kibana/bin",											""],
	"cc" =>		["calico-felix",					255,	0,	"calico-felix",											""],
	"gd" =>		["glusterd",						256,	0,	"/usr/sbin/glusterd",									""],
	"gfs" =>	["glusterfs",						257,	0,	"/usr/sbin/glusterfs",									"/usr/sbin/glusterfsd"],
	"gfsd" =>	["glusterfsd",						258,	0,	"/usr/sbin/glusterfsd",									""],
	
	"hp" =>		["Heapster",						260,	0,	"heapster",												""],
	"rm" =>		["Redmon",							261,	0,	"redmon",												""],
	"gr" =>		["Grafana Server",					262,	0,	"grafana-server",										""],
	"gk" =>		["Grafana kuisp",					263,	0,	"kuisp",												""],
	"idb" =>	["Influxdb",						264,	0,	"influxdb --config",									""],
	"if" =>		["Influxd",							265,	0,	"influxd --config",										""],
	"pr" =>		["Prometheus",						266,	0,	"/bin/prometheus|\\./prometheus",						""],
	"minio" =>	["Minio",							267,	0,	"bin/minio server",										""],
	"tsc" =>	["Thanos Sidecar",					270,	0,	"/bin/thanos sidecar|./thanos sidecar",					""],
	"trc" =>	["Thanos Receive",					271,	0,	"/bin/thanos receive|./thanos receive",					""],
	"tcp" =>	["Thanos Compact",					272,	0,	"/bin/thanos compact|./thanos compact",					""],
	"tst" =>	["Thanos Store",					273,	0,	"/bin/thanos store|./thanos store",						""],
	"tqu" =>	["Thanos Query",					274,	0,	"/bin/thanos query|./thanos query",						""],
	"trl" =>	["Thanos Rule",						275,	0,	"/bin/thanos rule|./thanos rule",						""],
	
	"http" => 	["HTTPServer",						280,	0,	"/opt/IBM/HTTPServer",									""],
	"hap" =>	["haproxy",							281,	0,	"/sbin/haproxy",										""],
	"ng" =>	    ["nginx",							282,	0,	"nginx",												""],

	"gc" => 	["go-carbon",						283,	0,	"go-carbon",											""],
	"cr" =>		["carbon-relay",					284,	0,	"carbon-relay",											""],
	"ioa" => 	["IOA  Mediation",					285,	0,	"ioa-analytics/mediation/config/config.properties",		""],				#		CLOUD	NEED!!!
	"drs" => 	["IOA Data Retrieval",				286,	0,	"ws-server.jar drs",									""],				#		CLOUD	NEED!!!

	"psql" => 	["postgres",						290,	0,	"postgres ",											""],				#		CLOUD	NEED!!!
	"pcp" => 	["postgres: checkpointer",			291,	0,	"postgres: checkpointer process",						""],				#		CLOUD	NEED!!!
	"pwr" => 	["postgres: writer",				292,	0,	"postgres: writer process",								""],				#		CLOUD	NEED!!!
	"pww" => 	["postgres: wal writer",			293,	0,	"postgres: wal writer process",							""],				#		CLOUD	NEED!!!
	"pav" => 	["postgres: autovacuum launcher",	294,	0,	"postgres: autovacuum launcher",						""],				#		CLOUD	NEED!!!
	"psc" => 	["postgres: stats collector",		295,	0,	"postgres: stats collector",							""],				#		CLOUD	NEED!!!
	"pml" => 	["postgres: metricdb [local]",		296,	0,	"postgres: postgres metricdb \\[local\\]",				""],				#		CLOUD	NEED!!!
	"pmr" => 	["postgres: metricdb [remote]",		297,	0,	"postgres: postgres metricdb ",							"local"],				#		CLOUD	NEED!!!
		
	"lz" => 	["Agent: klzagent",					300,	0,	"bin/klzagent|./klzagent",								""],
	"ux" => 	["Agent: kuxagent",					301,	0,	"bin/kuxagent|./kuxagent",								""],
	"lo" => 	["Logfile: kloagent",				302,	0,	"bin/kloagent|./kloagent",								""],
	"se" => 	["Agent: kseagent (MySQL)",			303,	0,	"bin/kseagent|./kseagent",								""],
	"kj" => 	["Agent: kkjagent (Mongo)",			304,	0,	"bin/kkjagent|./kkjagent",								""],
	"km" => 	["Agent: kkmagent (Ruby)",			305,	0,	"bin/kkmagent|./kkmagent",								""],
	"t5" => 	["Agent: kt5agent (WRT)",			306,	0,	"bin/kt5agent|kt5agent",								""],
	"fc" => 	["Agent: kfcm120 (WRT Spawn)",		307,	0,	"bin/kfcm120|kfcm120",									""],
	"yn" => 	["Agent: kynagent (WAS)",			308,	0,	"bin/kynagent|./kynagent",								""],
	"pn" => 	["Agent: kpnagent (Post)",			309,	0,	"bin/kpnagent|./kpnagent",								""],
	"pj" => 	["Agent: kpjagent (PHP)",			310,	0,	"bin/kpjagent|./kpjagent",								""],
	"pg" => 	["Agent: kpgagent (Python)",		311,	0,	"bin/kpgagent|./kpgagent",								""],
	"ud" => 	["Agent: kuddb2 (DB2 agent)",		312,	0,	"bin/kuddb2|./kuddb2",									""],
	"rz" => 	["Agent: krzagent (Oracle)",		313,	0,	"bin/krzagent|./krzagent",								""],
	"oq" => 	["Agent: koqagent (MS SQL)",		314,	0,	"bin/koqagent|./koqagent",								""],
	"3z" => 	["Agent: k3zagent (Active Dir)",	315,	0,	"bin/k3zagent|./k3zagent",								""],
	"mq" => 	["Agent: kmqagent (WebSphere)",		316,	0,	"bin/kmqagent|./kmqagent",								""],
	"qi" => 	["Agent: kqiagent (Message Broker)",317,	0,	"bin/kqiagent|./kqiagent",								""],
	"v1" => 	["Agent: kv1agent (KVM)",			318,	0,	"bin/kv1agent|./kv1agent",								""],
	"nj" => 	["Agent: knjagent (Node.js)",		319,	0,	"bin/knjagent|./knjagent",								""],
	"qe" => 	["Agent: kqeagent (.NET)",			320,	0,	"bin/kqeagent|./kqeagent",								""],
	"ot" => 	["Agent: kotagent (Tomcat)",		321,	0,	"bin/kotagent|./kotagent",								""],
	"i0" => 	["Agent: ki0eifcl (eif)",			322,	0,	"bin/ki0eifcl|./ki0eifcl",								""],
	"cl" => 	["Agent: kclagent (Bluemix)",		323,	0,	"bin/kclagent|./kclagent",								""],
	"44" => 	["Agent: k44agent (Walgreens)",		324,	0,	"bin/k44agent|./k44agent",								""],
	"d4" => 	["Agent: kd4agent (ITCAM SOA)",		325,	0,	"bin/kd4agent|./kd4agent",								""],
	"44j" => 	["Agent: k44 Java (Walgreens)",		326,	0,	"k44.topology",											""],
	"hu" => 	["Agent: khuagent (IHS)",			326,	0,	"bin/khuagent|./khuagent",								""],
	"bes" => 	["Agent: BESClient (BES)",			400,	0,	"bin/BESClient|./BESClient",							""],
	"goe" => 	["Go Exporter",						401,	0,	"./collector",											""],
	"pid" => 	["PID",								999,	0,	"pid",													""],
	"rx" => 	["Regex",							999,	0,	"regex",												""]);
}
sub STARTUP_INDEXES {

	#prod_code_hash
	$prod_code_name_index 	= 0;
	$prod_code_order_index	= 1;
	$prod_code_special_process_index	= 2;
	$prod_code_regex_index	= 3;
	$prod_code_vregex_index	= 4;

	#Processes indexes
	%process_hash			= ();
	%processes_averages_hash	= ();
	$ppid_index				= 0;	
	$uid_index				= 15;			
	$thcnt_index			= 1;			
	$vsz_index				= 2;				
	$rss_index				= 3;				
	$etime_index			= 4;			
	$cpu_time_index			= 5;			
	$short_command_index	= 6;	
	$full_command_index		= 7;	
	$new_cpu_seconds_index	= 8;	
	$old_cpu_seconds_index	= 9;
	$cpu_seconds_index		= 10;
	$cpu_percent_index		= 11;
	$averages_count_index	= 12;
	$read_KB_index			= 13;
	$write_KB_index			= 14;
	$used_code_index		= 15;
	$du_count_index			= 16;
	
	#CSV file output indexes
	%header_placement_hash = ();
	$csv_file_line_count	= 0;
	@main_csv_file_array	= ();
	$epoch_index			= 0;
	$date_index				= 1;
	$time_index				= 2;
	#$disk_io_index			= 3;	
	$network_in_hash_index	= 4;
	$network_out_hash_index	= 5;
	$process_hash_index		= 6;
	$pid_array_index		= 7;
	$active_mem_index		= 8;
	$swap_mem_index			= 9;
	$user_cpu_index			= 10;
	$system_cpu_index		= 12;
	$iowait_cpu_index		= 13;
	$idle_cpu_index			= 14;
	$total_cpu_index		= 15;
	$total_disk_read_index	= 16;
	$total_disk_write_index	= 17;
	$disk_df_percent_index			= 18;
	$disk_df_used_index		= 19;
	$disk_df_free_index		= 20;
	$disk_util_index		= 21;
	$disk_tps_index			= 22;
	$disk_rps_index			= 23;
	$disk_wps_index			= 24;
	$disk_await_index		= 25;
	$disk_svctm_index		= 26;
	$disk_du_index			= 27;
	
	#Averages indexes
	$first_index			= 1;
	$last_index				= 2;
	$min_index				= 3;
	$max_index				= 4;
	$sum_index				= 5;
	$avg_short_cmd_index	= 6;
	$avg_full_cmd_index		= 7;
	$avg_used_code_index	= 8;
	
	$network_in_index		= 0;
	$network_out_index		= 1;
	
	
}
sub PRINT_USAGE {
	println("Developed by Riley D. Zimmerman - rdzimmer\@us.ibm.com");
	println("version $version, date of last change $date_of_last_change");
	println("Welcome to the UNIX on-system performance data tool!");
	println("This script is designed to continuously run in the background collecting raw performance metrics.");
	println("The metrics collected include `ps` `sar` `ifconfig` as well as `iotop` and `lsblk` where available.");
	println("The script only collects sellect processes and stats, compressing the raw data daily.");
	println("This selection and compression reduces the disk footprint to roughly half a MB of disk per day.");
	println("Please see the CUSTOMIZE_AREAS of the code to add additional processes to the script's known list.");
	println("");
	println("Once the raw metrics are collected, the script may be used to reduce and analyize the data.");
	println("Ranges of dates and time may be specified for analysis of one or more processes.");
	println("The output is formatted to be displayed to the putty session or command prompt.");
	println("");
	println("$0");
	println(" -c|collect                           Turn on data collection in the background");
	println(" -k|kill                              Kill data collection");
	println(" -r|restart                           Restart data collection");
	println(" -iw|write <interval in seconds>      Data collection interval, how frequently to log metrics (default 60)");
	println(" -ir|read <interval in seconds>       Data output interval, used for data analysis (default 60)");
	println(" start <date.time|#h|#m>              Start day and time of output, or number of hours/minutes ago (default 30m)");
	println(" end <date.time|#h|#m>                End day and time of output, or number of hours/minutes ago (default is live data)");
	println(" dev#-#                               Name of disk device(s) to monitor. Use `sar -d 10 1` and `lsblk -l` or `dmsetup ls` or `blkid` to identify drive(s) on linux");
	println(" full|short                           Display as much of a command name as fits on screen or a process summary (default short)");
	println(" pid                                  The PID of the command to select (a command type must also be specified)");
	println(" sum                                  When multiple processes are displayed, sum the attributes");
	println(" csv                                  Output is stored in a csv file, default location is /usr/perfdata/reduced/");
	println("");
	println(" EM           = kdsmain (TEMS)");
	println(" CQ           = kfwservices (TEPS)");
	println(" EW           = eWAS (/iw/profiles)");
	println(" HD           = khdxprtj (WPA)");
	println(" SY           = ksy610 (SPA)");
	println(" AS           = kasmain (KAS)");
	println(" DB2          = DB2  ( db2sysc)");
	println(" MN           = MIN");
	println(" S1           = Server1");
	println(" SCR          = SCR XMLtoolkit");
	println(" UI           = APMUI");
	println(" AR           = Asfrest (depreciated)");
	println(" HG           = Hybrid Gateway");
	println(" MD|Mongo     = MongoDB");
	println(" KK|Kafka     = Kafka");
	println(" ZK|Zoo       = ZooKeeper");
	println(" Spark        = Spark (Master Worker AARAggregator CoarseGrained)");
	println(" TE|txevagent = txevagent and AgentControl (KTE)");
	println(" APM          = mn s1 ui scr db as sy ar kk zk md sm sw sa sc te ac");
	println(" http|httpd   = httpd proxy server");
	println(" LZ|linux     = klzagent (KLZ)");
	println(" UX|unix      = kuxagent (KUX)");
	println(" LO|logfile   = kloagent (LFA)");
	println(" SE|mysql     = kseagent (KSE)");
	println(" KJ|mongo     = kkjagent (KKJ)");
	println(" KM|ruby      = kkmagent (KKM)");
	println(" T5|wrt       = kt5agent (KT5)");
	println(" YN|was       = kynagent (KYN)");
	println(" PN|postgres  = kpnagent (KPN)");
	println(" PJ|php       = kpjagent (KPJ)");
	println(" PG|python    = kpgagent (KPG)");
	println(" QE|net       = kqeagent (KQU)");
	println(" NJ|node.js   = knjagent (KNJ)");
	println(" V1|KVM       = kv1agent (KV1)");
	println(" UD|DB2       = kudagent (KUD)");
	println(" OT|tomcat    = kotagent (KOT)");
	println(" RZ|oracle    = krzagent (KRZ)");
	println(" OQ|MS SQL    = koqagent (KOQ)");
	println(" MQ|websphere = kmqagent (KMQ)");
	println(" I0|EIF       = ki0agent (KI0)");
	println(" CL|Bluemix   = kclagent (KCL)");
	println(" sys|system   = System wide only statistics");
	println(" -rx <regex>  = Specify your own regular expression to search commands for");
	println("");
	#println(" b            = Display network usage in bits");
	#println(" Kb           = Display network usage in Kilobits");
	#println(" Mb           = Display network usage in Megabits (default)");
	#println(" B            = Display network usage in Bytes");
	#println(" KB           = Display network usage in KiloBytes");
	#println(" MB           = Display network usage in MegaBytes");
	println("");
	println("example: turn on collection");
	println("$0 collect");
	println("");
	println("example: display TEMS data from the last 30 minutes, continues to monitor with real time updates");
	println("$0 EM");
	println("");
	println("example: display MIN and Server1 data from a range of dates");
	println("$0 MN S1 start 20131027.1325 end 20131027.1630");
	println("");
	println("example: display information for the \"foobar\" process");
	println("$0 regex \"foobar\"");
	println("");
	println("example: display real time APM data for device 253-1 and 8-0 (use `sar -d 10 1` and `lsblk -l` or `dmsetup ls` or `blkid` to identify on linux)");
	println("$0 APM dev253-1 dev8-0");
	println("");
	println("RealTime Data column descriptions (individual processes, not using the \"sum\" flag)");
	println("date, time, -> The day and time of the data being displayed on the row");
	println("PID         -> Process ID");
	#println("PPID        -> Partent Process ID (the process that launched this process)");
	println("THC         -> Thread Count");
	println("VSZ         -> Virtual Memory used by the process (memory accessable to the process, address space)");
	println("RSS         -> Resident Set Size used by the process (memory allocated to the process, physical resident memory)");
	println("e-time      -> Total elapse time the process has been running");
	println("CPU TIME    -> Total CPU used by the process since it was started (reported in CPU hours:minutes:seconds)");
	println("Sec         -> CPU seconds used by the process in this interval (difference in CPU TIME between this row and the previous)");
	println("CPU %       -> The amount of CPU used by the process in this interval, converted to the % of a CPU core (Sec/0.6)");
	println("P-Read      -> KB of disk reads performed by the process in this interval");
	println("P-Write     -> KB of disk writes performed by the process in this interval");
	println("(eth0) RX   -> Average Mbps of network data received in this interval for the system (could be different interface than eth0)");
	println("(eth0) TX   -> Average Mbps of network data transmitted in this interval for the system (could be different interface than eth0)");
	println("(dev253-1)% -> Disk % utilization (old format with device MAJOR MINOR numbers)");
	println("(/mount) U% -> Disk % utilization (new format that resolves the device to its mount point)");
	println("Act-M       -> Active memory used by the total system, equivalent to the \"-/+ buffers/cache\" line of the `free` command. ");
	println("SWAP        -> Swap memory (disk) used by the entire system");
	println("T-CPU%      -> The total CPU used by the entire system.  This includes System and User CPU (in old perfdata.pl it included IOWait)");
	println("Command     -> The process being reported on this row of data");
	println("");
	println("RealTime Data column descriptions (multiple processes using the \"sum\" flag)");
	println("Each row is the SUM of all of the processes.");
	println("For example, with APM there are ~16 processes, so the RSS is the sum of all of the 16 processes RSS.");
	println("date, time, -> The day and time of the data being displayed on the row");
	println("THC         -> Thread Count");
	println("RSS         -> Resident Set Size used by the sum of processes (memory allocated to the process, physical resident memory)");
	println("Sec         -> CPU seconds used by the sum of processes in this interval (difference in CPU TIME between this row and the previous)");
	println("CPU %       -> The amount of CPU used by the sum of processes in this interval, converted to the % of a CPU core (Sec/0.6)");
	println("P-Read      -> KB of disk reads performed by the sum of processes in this interval");
	println("P-Write     -> KB of disk writes performed by the sum of processes in this interval");
	println("(eth0) RX   -> Average Mbps of network data received by the system in this interval (could be different interface than eth0)");
	println("(eth0) TX   -> Average Mbps of network data transmitted by the system in this interval (could be different interface than eth0)");
	println("(dev253-1)% -> Disk % utilization for the device (old format with device MAJOR MINOR numbers)");
	println("(/mount) U% -> Disk % utilization for the device (new format that resolves the device to its mount point)");
	println("T-Read      -> KB of disk reads performed by the entire system in this interval");
	println("T-Write     -> KB of disk writes performed by the entire system in this interval");
	println("Act-M       -> Active memory used by the entire system, equivalent to the \"-/+ buffers/cache\" line of the `free` command. ");
	println("SWAP        -> Swap memory (disk) used by the total system");
	println("T-CPU%      -> The total CPU used by the entire system.  This includes System and User CPU (in old perfdata.pl it included IOWait)");
	println("Command     -> How many processes are in the summation for this interval (\"sum of ## process\")");
	println("");
	println("");
}
sub PARSE_ARGS { #CUSTOMIZE_AREAS
	$ARGC = $#ARGV + 1;
	if ( $ARGC == 0 ) { PRINT_USAGE; exit 0; }
	
	#!!! START FLAGS !!!
	while ( $ARGC != 0 ) { 
		$ARG = shift(@ARGV);
		#/usr/sbin/rsct/bin/rmcd -a IBM.LPCommands -r 1082
		if ( $ARG =~ m/^-h$|^help$/i )			{ PRINT_USAGE; exit 0; 													$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^nohup_collect$/i )	{ $start_collection_loop=1; 											$ARGC=$ARGC-1; } #Actually runs the collection
		elsif ( $ARG =~ m/^disable_collection$/i )	{ $disable_collection=1; 											$ARGC=$ARGC-1; } 
		elsif ( $ARG =~ m/^debug$/i	)			{ $ARG=shift(@ARGV); 	$global_debug_setting=$ARG; 					$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^dir$/i	)			{ $ARG=shift(@ARGV); 	$perfdata_dir=$ARG; $dir_flag="dir $perfdata_dir";	$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^small_screen$/i	)	{ $small_screen=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^csv$/i	)			{ $csv_output=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^dir_size$/i	)		{ $show_dir_size=1; push (@used_codes,"rx"); $input_regex="Overall System";	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^avg/i	)			{ $ARG=shift(@ARGV);	$averages_interval=$ARG; 						$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^perf1$/i	)			{ $csv_output=1; $perf1=1; 												$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^csv_dir$/i	)		{ $ARG=shift(@ARGV); 	$csv_output_dir=$ARG; 							$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^csv_summary_file$/i )	{ $ARG=shift(@ARGV); 	$csv_summary_output_file_name=$ARG; 							$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^csv_detail_file$/i )		{ $ARG=shift(@ARGV); 	$csv_output_file_name=$ARG; 							$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^cleanup$/i	)		{ $cleanup_dirs=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^df_used$/i	)		{ $disk_used=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^df_free$/i	)		{ $disk_free=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tps$/i	)			{ $disk_tps=1; 															$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rps$/i	)			{ $disk_rps=1; 															$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^wps$/i	)			{ $disk_wps=1; 															$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^await$/i	)			{ $disk_await=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^svctm$/i	)			{ $disk_svctm=1; 														$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^actual$/i	)		{ $iotop_activity_type="Actual"; 										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^noiotop$/i	)		{ $iotop_installed=0; $iotop_flag="noiotop";							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^all_proc$/i	)		{ $collect_all_processes=1; $collect_all_processes_flag="all_proc";		$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^-f$/i	)			{ $ARG=shift(@ARGV);	$temp_input_file=$ARG;							$ARGC=$ARGC-2; }

		elsif ( $ARG =~ m/^-c$|^collect$/i )	{ $nohup_collect=1; 													$ARGC=$ARGC-1; } #Calls a new instance of the script with a nohup
		elsif ( $ARG =~ m/^-k$|^kill$/i )		{ $kill_collection=1;	 												$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^-r$|^restart$/i )	{ $kill_collection=1; 	$nohup_collect=1; 								$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^-iw$|^write$/i )		{ $ARG=shift(@ARGV); 	$write_interval=$ARG; 							$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^-ir$|^read$/i )		{ $ARG=shift(@ARGV); 	$read_interval=$ARG; 							$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^-st$|^start$/i )		{ $ARG=shift(@ARGV); 	$console_start_datetime=$ARG; 					$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^-e$|^end$/i )		{ $ARG=shift(@ARGV); 	$console_end_datetime=$ARG; 					$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^full$/i )			{ $use_full_command=1; 													$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^short$/i )			{ $use_full_command=0; 													$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sum$|^combine$/i )	{ $sum_processes=1; 													$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pid$/i )				{ push (@used_codes,("pid")); $ARG=shift(@ARGV); 	$command_PID=$ARG; 	$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^separate/i )			{ $separate_processes=1;												 	$ARGC=$ARGC-1; }
				
		elsif ( $ARG =~ m/^em$|tems/i ) 			{ push (@used_codes,"em"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cq$|teps/i ) 			{ push (@used_codes,"cq"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ew$|ewas/i ) 			{ push (@used_codes,"ew"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^hd$|warehous/i ) 		{ push (@used_codes,"hd"); 							$ARGC=$ARGC-1; }		
		
		elsif ( $ARG =~ m/^apm/i )					{ push (@used_codes,("lz","mn","s1","ui","oed","uv","to","td","id","ar","hg","scr","as","sy","db","ca","md","kk","kr","zm","zk","sm","sw","sa","ii","gu","te","ac","so","ff","xv","sl","ss","cg","sb","mc","ms","kd","mp","mps","mpc","mpp","ea","itp","bi"));	$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^mn$|^min$/i ) 			{ push (@used_codes,"mn"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^s1$|^server1$/i ) 		{ push (@used_codes,"s1"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ui$|^apmui$/i ) 			{ push (@used_codes,"ui"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^oed$|^oed/i ) 			{ push (@used_codes,"oed"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^uv$|^uviews/i ) 			{ push (@used_codes,"uv"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^id$|^openid$/i ) 		{ push (@used_codes,"id"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ar$|^asfrest$/i ) 		{ push (@used_codes,"ar"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^hg$|^hybrid/i ) 			{ push (@used_codes,"hg"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^db$|^DB2$/i )			{ push (@used_codes,"db"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^scr$|^tk$/i ) 			{ push (@used_codes,"scr"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^as$|^oslc$/i ) 			{ push (@used_codes,"as"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sy$|^spa$/i ) 			{ push (@used_codes,"sy"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^itp$|^bam$/i ) 			{ push (@used_codes,"itp"); 						$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^kk$|^kafka$/i ) 			{ push (@used_codes,"kk"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kr$|^kafkarest/i ) 		{ push (@used_codes,"kr"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^zm$|^zookeepermain/i ) 	{ push (@used_codes,"zm"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^zk$|^zoo/i ) 			{ push (@used_codes,"zk"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^md$|^mongod$/i ) 		{ push (@used_codes,"md"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ca$|^cassandra$/i ) 		{ push (@used_codes,"ca"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^scy$|^scylla/i ) 		{ push (@used_codes,"scy"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^scj$|^scylla-jmx/i ) 	{ push (@used_codes,"scj"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cdb$|^couch/i ) 			{ push (@used_codes,"cdb"); 						$ARGC=$ARGC-1; }
					
		#elsif ( $ARG =~ m/cloud|icam|pmgm/i )		{ push (@used_codes,(sm,sw,cg,sea,rd,kk,kr,zk,ca,cdb,tc,tcg,tcm,ts,ab,mp,lk,kdsq,kdq,kdss,kds,mcs,mcr,ms,msc,msp,mer,amr,amc,amrg,amcg,agm,th,to,ssr,ae,rtm,eo,cui,amr,st,otc,otjq,otq,ota,otd,oti,blc,es));	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/cloud|icam|pmgm/i )		{ push (@used_codes,(rd,kk,kr,zk,ca,cdb,tc,tcg,tcm,ts,ab,mp,lk,kdsq,kdq,kdss,kds,mcs,mcr,ms,msc,msp,mer,amr,amc,amrg,amcg,agm,th,to,ssr,ae,rtm,eo,cui,amr,st,otc,otjq,otq,ota,otd,oti,blc,es,sm,sw,cg,sea));	$ARGC=$ARGC-1; }
	
		elsif ( $ARG =~ m/^in$|^ingress/i ) 		{ push (@used_codes,"in"); 							$ARGC=$ARGC-1; }	
		elsif ( $ARG =~ m/^acm$|^agentcomm/i ) 		{ push (@used_codes,"acm"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tc$|^temaconfig$/i ) 	{ push (@used_codes,"tc"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tcg$|^temaconfiggo/i )	{ push (@used_codes,"tcg"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tcm$|^temacomm/i ) 		{ push (@used_codes,"tcm"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ts$|^temasda/i )			{ push (@used_codes,"ts"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cs$|^config_server/i ) 	{ push (@used_codes,"cs"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ab$|^agentboot/i ) 		{ push (@used_codes,"ab"); 							$ARGC=$ARGC-1; }		
		
		elsif ( $ARG =~ m/^mp$|^metricpro/i ) 		{ push (@used_codes,"mp"); 	   						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^lk$|^linking/i ) 		{ push (@used_codes,"lk"); 	   						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mps/i ) 					{ push (@used_codes,"mps"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mpc/i ) 					{ push (@used_codes,"mpc"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mpp/i ) 					{ push (@used_codes,"mpp"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd$|^kairos/i ) 			{ push (@used_codes,(kdsq,kdq,kdss,kds)); 			$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd128$/i ) 				{ push (@used_codes,"kd128"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd256$/i ) 				{ push (@used_codes,"kd256"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd512$/i ) 				{ push (@used_codes,"kd512"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd1024$/i ) 				{ push (@used_codes,"kd1024"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd1$/i ) 				{ push (@used_codes,"kd1"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kd2$/i ) 				{ push (@used_codes,"kd2"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kdsq$/i ) 				{ push (@used_codes,"kdsq"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kdq$/i ) 				{ push (@used_codes,"kdq"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kdss$/i ) 				{ push (@used_codes,"kdss"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kds$/i ) 				{ push (@used_codes,"kds"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mcs$|^metriconsumersum/i ) 	{ push (@used_codes,"mcs"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mcr$|^metriconsumerraw/i ) 	{ push (@used_codes,"mcr"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ms$|^ma$|^metricapi/i ) 	{ push (@used_codes,"ms"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^msc$|^metricsummarycreation/i ) { push (@used_codes,"msc"); 					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^msp$|^metricsummarypolicy/i ) { push (@used_codes,"msp"); 					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mer$|^metricenrichment/i ) { push (@used_codes,"mer"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sts$|^streaming/i ) 		{ push (@used_codes,"sts"); 	   					$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^appmgmt$/i ) 			{ push (@used_codes,(amr,amc,amrg,amcg));			$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^amr$/i ) 				{ push (@used_codes,"amr"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^amc$/i ) 				{ push (@used_codes,"amc"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^amrg$/i ) 				{ push (@used_codes,"amrg"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^amcg$/i ) 				{ push (@used_codes,"amcg"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^agm|agentmgmt/i ) 		{ push (@used_codes,"agm"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^th$|^thresh/i ) 			{ push (@used_codes,"th"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^to$|^topo/i ) 			{ push (@used_codes,"to"); 							$ARGC=$ARGC-1; }	
		elsif ( $ARG =~ m/^ssr$|^search/i ) 		{ push (@used_codes,"ssr"); 						$ARGC=$ARGC-1; }	
			
		elsif ( $ARG =~ m/^al$|^alarmrest/i )		{ push (@used_codes,"al"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^af$|^alarmforward/i )	{ push (@used_codes,"af"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ae$|^alarmevent/i )		{ push (@used_codes,"ae"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^at$|^alarmtransform/i )	{ push (@used_codes,"at"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rtm$|^rtemetric/i )		{ push (@used_codes,"rtm"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rts$|^rtesynthetic/i )	{ push (@used_codes,"rts"); 						$ARGC=$ARGC-1; }	
		elsif ( $ARG =~ m/^eo$|^event-observer/i ) 	{ push (@used_codes,"eo"); 							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^cui$|^icam-ui/i ) 		{ push (@used_codes,"cui"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^amr$|^amuirest/i ) 		{ push (@used_codes,"amr"); 						$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^k8$|^k8monitor/i ) 			{ push (@used_codes,(k8m,k8r)); 				$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^k8m$|^k8monitor_metric/i ) 	{ push (@used_codes,"k8m"); 					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^k8r$|^k8monitor_resources/i ) { push (@used_codes,"k8r"); 					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mex$|^metric-extender/i ) { push (@used_codes,"mex"); 					$ARGC=$ARGC-1; }
			
		elsif ( $ARG =~ m/^tt$/i ) 					{ push (@used_codes,("st","sg","th","sq","sls","sl","ss","rd","pb","ff","xv","tr","gu","te","ac","so","sa","ii","sc","sb","jp")); 	$ARGC=$ARGC-1; }		
		elsif ( $ARG =~ m/^st$|^syntheticserv/i ) 	{ push (@used_codes,"st"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sg$|^syntheticagent/i )	{ push (@used_codes,"sg"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rt$|^rti/i ) 			{ push (@used_codes,"rt"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sl$|^selenium$/i ) 		{ push (@used_codes,"sl"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sls$|^seleniumstart$/i ) { push (@used_codes,"sls"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sq$|^seleniumqueue/i ) 	{ push (@used_codes,"sq"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ss$|^seleniumserver$/i ) { push (@used_codes,"ss"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ff$|^firefox$/i ) 		{ push (@used_codes,"ff"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cdr$|^chromedriver$/i ) 	{ push (@used_codes,"cdr"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^goo$|^google-chrome$/i ) { push (@used_codes,"goo"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^nh$|^nacl_helper$/i ) 	{ push (@used_codes,"nh"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^zy$|^zygote$/i ) 		{ push (@used_codes,"zy"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^re$|^renderer$/i ) 		{ push (@used_codes,"re"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^gp$|^gpu$/i ) 			{ push (@used_codes,"gp"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ch$|^chrome$/i ) 		{ push (@used_codes,"cdr","goo","nh","zy","re","gp"); 				$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^xv$|^xvfb$/i ) 			{ push (@used_codes,"xv"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rd$|^redis/i )			{ push (@used_codes,"rd");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pb$|^httpmonitor/i )		{ push (@used_codes,"pb");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^jp$|^javascript/i )		{ push (@used_codes,("jpi","jpb"));					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tr$|^transaction/i ) 	{ push (@used_codes,"tr"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ea$|^eventagent/i ) 		{ push (@used_codes,"ea"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^itp$|^itp-bam/i ) 		{ push (@used_codes,"itp"); 						$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^ott$/i ) 					{ push (@used_codes,("otc","otjq","otq","ota","otd")); 	$ARGC=$ARGC-1; }		
		elsif ( $ARG =~ m/^otc$|^opentt-collector/i ) 	{ push (@used_codes,"otc"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^otq$|^opentt-query^/i ) 		{ push (@used_codes,"otq"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^otjq$|^opentt-jaeger-query/i ) { push (@used_codes,"otjq"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ota$|^opentt-analyzer/i ) 	{ push (@used_codes,"ota"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^otd$|^opentt-dependency/i ) 	{ push (@used_codes,"otd"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^oti$|^opentt-ingester/i ) 	{ push (@used_codes,"oti"); 						$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^cem$/i ) 				{ push (@used_codes,("nmp","naj","nww","cnm","cdl","cbr","cdb","ceaw","ceai","csu","ccs","cep","cip"));		$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^nmp$/i ) 				{ push (@used_codes,"nmp"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^naj$/i ) 				{ push (@used_codes,"naj"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^nww$/i ) 				{ push (@used_codes,"nww"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cnm$/i ) 				{ push (@used_codes,"cnm"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cic$/i ) 				{ push (@used_codes,"cic"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cep$/i ) 				{ push (@used_codes,"cep"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cdl$/i ) 				{ push (@used_codes,"cdl"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cbr$/i ) 				{ push (@used_codes,"cbr"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cip$/i ) 				{ push (@used_codes,"cip"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cus$/i ) 				{ push (@used_codes,"cus"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ccs$/i ) 				{ push (@used_codes,"ccs"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ceaw$/i ) 				{ push (@used_codes,"ceaw"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ceai$/i ) 				{ push (@used_codes,"ceai"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^csu$/i ) 				{ push (@used_codes,"csu"); 						$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^gu$|^geoupdate$/i ) 		{ push (@used_codes,"gu"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^te$|^txevagent$/i ) 		{ push (@used_codes,("te","ac")); 					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^so$|^ksoagent$/i ) 		{ push (@used_codes,"so"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^bi$|^kbiagent$/i ) 		{ push (@used_codes,"bi"); 							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^spark$/i ) 				{ push (@used_codes,(sm,sw,cg,sea,saa,sii)); 	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sm$|^master$/i ) 		{ push (@used_codes,"sm"); 								$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sw$|^worker$/i ) 		{ push (@used_codes,"sw"); 								$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cg$/i ) 					{ push (@used_codes,"cg"); 								$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sea$/i ) 				{ push (@used_codes,"sea"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^saa$/i ) 				{ push (@used_codes,"saa"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sii$/i ) 				{ push (@used_codes,"sii"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^sp$|^sparkserver$/i ) 	{ push (@used_codes,"sp"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^sz$|^sparkzoo/i ) 		{ push (@used_codes,"sz"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^nn$|^namenode$/i ) 		{ push (@used_codes,"nn"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^dn$|^datanode$/i ) 		{ push (@used_codes,"dn"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^ta$|thresholda/i ) 		{ push (@used_codes,"ta"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^sc$|scorecal/i ) 		{ push (@used_codes,"sc"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^ioaa/i ) 				{ push (@used_codes,"ioaa"); 						$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^ioam/i ) 				{ push (@used_codes,"ioam"); 						$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^sb$/i ) 					{ push (@used_codes,"sb"); 							$ARGC=$ARGC-1; }
		#elsif ( $ARG =~ m/^spd$/i ) 				{ push (@used_codes,"spd"); 							$ARGC=$ARGC-1; }
		
		
		elsif ( $ARG =~ m/^blc$|^baseline/i ) 		{ push (@used_codes,"blc"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pip$|^pipolicy/i ) 		{ push (@used_codes,"pip"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pii$|^inference/i ) 		{ push (@used_codes,"pii"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pit$|^trainer/i ) 		{ push (@used_codes,"pit"); 							$ARGC=$ARGC-1; }
				
		elsif ( $ARG =~ m/^sdc$|^sidecar/i ) 		{ push (@used_codes,"sdc"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^me$|^meter/i ) 			{ push (@used_codes,"me"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ra$|^docker.r/i ) 		{ push (@used_codes,"ra"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^smt$|^transform/i ) 		{ push (@used_codes,"smt"); 						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mmt$|^transform/i ) 		{ push (@used_codes,"mmt"); 						$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^gc$|^gocarbon/i ) 		{ push (@used_codes,"gc"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cr$|^carbonrelay/i ) 	{ push (@used_codes,"cr"); 							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^docker$/i )				{ push (@used_codes,("dd","dp","de","dr","et","dc"));					$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^dd$|^dockerdaemon/i )	{ push (@used_codes,"dd");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^dp$|^dockerproxy/i )		{ push (@used_codes,"dp");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^de$|^dockerexe/i )		{ push (@used_codes,"de");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^dr$|^dockerreg/i )		{ push (@used_codes,"dr");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^et$|^etcd/i )			{ push (@used_codes,"et");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^dc$|^docker-container/i ){ push (@used_codes,"dc");							$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^kube$/i )				{ push (@used_codes,("kl","kc","ka","scl","ks","kp","ku","k2","ko","kw","cdns","fl","salt","hp","rd","rm","gr","gk","idb","if","ls","es","kb","ips","cc"));	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kl$|^kubelet$/i )		{ push (@used_codes,"kl");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kc$|^kubecon/i )			{ push (@used_codes,"kc");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ka$|^kubeapi$/i )		{ push (@used_codes,"ka");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^scl$|^servicecatalog$/i ) { push (@used_codes,"scl");						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kp$|^kubeproxy/i )		{ push (@used_codes,"kp");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ks$|^kubesch/i )			{ push (@used_codes,"ks");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ku$|^kubeui/i )			{ push (@used_codes,"ku");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^k2$|^kube2sky/i )		{ push (@used_codes,"k2");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ko$|^kubeadd/i )			{ push (@used_codes,"ko");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kw$|^kworker/i )			{ push (@used_codes,"kw");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cdns$|^coredns/i )		{ push (@used_codes,"cdns");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^fl$|^flannel/i )			{ push (@used_codes,"fl");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cc$|^calico/i )			{ push (@used_codes,"cc");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^gd$|^gluster daemon/i )	{ push (@used_codes,"gd");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^gl$|^gluster/i )			{ push (@used_codes,("gd","gfs","gfsd"));			$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^salt$/i )				{ push (@used_codes,"salt");						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ips$|^charon|ipsec/i )	{ push (@used_codes,"ips");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^hp$|^heapster/i )		{ push (@used_codes,"hp");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rm$|^redmon/i )			{ push (@used_codes,"rm");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^gr$|^grafana/i )			{ push (@used_codes,"gr");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^gk$|^kuisp/i )			{ push (@used_codes,"gk");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^idb$|^influxdb$/i )		{ push (@used_codes,"idb");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^if$|^influxd$/i )		{ push (@used_codes,"if");							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^pr$|^prometheus/i )		{ push (@used_codes,"pr");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^minio$/i )				{ push (@used_codes,"minio");						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^goe$/i ) 				{ push (@used_codes,"goe");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^thanos$/i )				{ push (@used_codes,(tsc,trc,tcp,tst,tqu,trl));			$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tsc|^thanos-sidecar$/i ) { push (@used_codes,"tsc");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^trc|^thanos-receive$/i ) { push (@used_codes,"trc");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tcp|^thanos-compact$/i ) { push (@used_codes,"tcp");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tst|^thanos-store$/i ) 	{ push (@used_codes,"tst");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^tqu|^thanos-query$/i ) 	{ push (@used_codes,"tqu");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^trl|^thanos-rule$/i ) 	{ push (@used_codes,"trl");							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^ls$|^logstash$/i )		{ push (@used_codes,"ls");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^es$|^elasticsearch$/i )	{ push (@used_codes,"es");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kb$|^kibana$/i )			{ push (@used_codes,"kb");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^elk$/i )					{ push (@used_codes,("ls","es","kb"));				$ARGC=$ARGC-1; }
			
		elsif ( $ARG =~ m/^http$|^httpd$/i )	{ push (@used_codes,"http");						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^hap/i )				{ push (@used_codes,"hap");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ng/i )				{ push (@used_codes,"ng");							$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^ioa/i )				{ push (@used_codes,"ioa");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^drs/i )				{ push (@used_codes,"drs");							$ARGC=$ARGC-1; }

		elsif ( $ARG =~ m/^postgres/i )	{ push (@used_codes,("pcp","pwr","pww","pav","psc","pml","pmr"));	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^psql/i )	{ push (@used_codes,"psql");									$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pcp/i )	{ push (@used_codes,"pcp");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pwr/i )	{ push (@used_codes,"pwr");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pww/i )	{ push (@used_codes,"pww");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pav/i )	{ push (@used_codes,"pav");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^psc/i )	{ push (@used_codes,"psc");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pml/i )	{ push (@used_codes,"pml");										$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pmr/i )	{ push (@used_codes,"pmr");										$ARGC=$ARGC-1; }
	
		elsif ( $ARG =~ m/^lz$|^linux$/i ) 		{ push (@used_codes,"lz"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ux$|^unix$/i ) 		{ push (@used_codes,"ux"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^lo$|^logfile$/i ) 	{ push (@used_codes,"lo"); 							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^se$|^mysql$/i ) 		{ push (@used_codes,"se");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^kj$|^mongo$/i ) 		{ push (@used_codes,"kj");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^km$|^ruby$/i ) 		{ push (@used_codes,"km");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^t5$|^wrt$/i ) 		{ push (@used_codes,"t5");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^fc$|^kfc/i ) 		{ push (@used_codes,"fc");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^yn$|^was$/i ) 		{ push (@used_codes,"yn");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pn$|^postgres$/i ) 	{ push (@used_codes,"pn");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pj$|^php$/i ) 		{ push (@used_codes,"pj");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^pg$|^python$/i ) 	{ push (@used_codes,"pg");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ud$|^db2_agent$/i ) 	{ push (@used_codes,"ud");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^rz$|^oracle$/i ) 	{ push (@used_codes,"rz");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^oq$|^ms_sql$/i ) 	{ push (@used_codes,"oq");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^mq$|^websphere$/i ) 	{ push (@used_codes,"mq");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^qi$|^mb$/i )			{ push (@used_codes,"qi");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^v1$|^kvm$/i )		{ push (@used_codes,"v1");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^nj$|^node/i )		{ push (@used_codes,"nj");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^qe$|^net$/i ) 		{ push (@used_codes,"qe");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^ot$|^tomcat/i )		{ push (@used_codes,"ot");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^3z$|^active/i )		{ push (@used_codes,"3z");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^i0$|^eif/i )			{ push (@used_codes,"i0");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^44$|^walgreens/i )	{ push (@used_codes,("44"));						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^d4$|^soa/i )			{ push (@used_codes,("d4"));						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^44j$/i )				{ push (@used_codes,("44j"));						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^hu$|^ihs$/i )		{ push (@used_codes,("hu"));						$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^bes$/i ) 			{ push (@used_codes,"bes");							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^cl$/i ) 				{ push (@used_codes,"cl");							$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^-rx$|^regex$/i ) 	{ push (@used_codes,"rx");							$ARGC=$ARGC-2; $ARG=shift(@ARGV); $input_regex=$ARG; }
		elsif ( $ARG =~ m/^system$|^sys$/i ) 	{ push (@used_codes,"rx");	$sum_processes=1;		$ARGC=$ARGC-1; $input_regex="Overall System"; }
		#CUSTOMIZE_2: Add specific processes to view data for above
		
		elsif ( $ARG =~ m/^dev/ )			{ 						push(@requested_disk_metric_names_array,$ARG); $identify_disk_name=0;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^disk$/i )		{ $ARG=shift(@ARGV); 	push(@requested_disk_metric_names_array,$ARG); $identify_disk_name=0;	$ARGC=$ARGC-2; }
		elsif ( $ARG =~ m/^\// )			{ 						push(@requested_disk_df_names_array,$ARG);							$ARGC=$ARGC-1; }		
		elsif ( $ARG =~ m/^bond|^br|^eth|^ent|^ipip|^docker|^ens/ )		{ 	push(@requested_network_names_array,$ARG);							$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^B$/ ) 			{ $network_divide=1; 			$network_scale="B";				$BITS=1;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^KB$/ ) 			{ $network_divide=$KILO; 		$network_scale="KB";			$BITS=1;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^MB$/ ) 			{ $network_divide=$MEGA; 		$network_scale="MB";			$BITS=1;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^b$/ ) 			{ $network_divide=1; 			$network_scale="b";				$BITS=8;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^Kb$/ ) 			{ $network_divide=$KILO; 		$network_scale="Kb";			$BITS=8;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^Mb$/ ) 			{ $network_divide=$MEGA; 		$network_scale="Mb";			$BITS=8;	$ARGC=$ARGC-1; }
		elsif ( $ARG =~ m/^sum_network$|^network_sum$/ ) 	{ $sum_network=1; 											$ARGC=$ARGC-1; }
		
		elsif ( $ARG =~ m/^resp/ ) 					{ $other_workload=1; 	$monitor_response_times=1;	$ARG=shift(@ARGV); 	$monitored_response_address=$ARG; 	$ARG=shift(@ARGV); 	$write_interval=$ARG; 	$ARGC=$ARGC-3; }
		elsif ( $ARG =~ m/^netstat/ ) 				{ $other_workload=1; 	$monitor_netstat_ports=1;	$ARG=shift(@ARGV); 	$monitored_netstat_regex=$ARG; 		$ARG=shift(@ARGV); 	$write_interval=$ARG; 	$ARGC=$ARGC-3; }
		
		else  { print "Could not find argument \"$ARG\", exiting...\n" ; 				exit 1; }
	}
	#!!! END FLAGS !!!

}
sub POST_PARSE_ARGS {
	
	chdir "$perfdata_dir";
	$write_interval_file	= "$perfdata_dir/perfdata.pl.interval";
	$disk_name_file			= "$perfdata_dir/perfdata.pl.diskname";
	$db_list_file			= "$perfdata_dir/perfdata.pl.dblist";
	$du_list_file			= "$perfdata_dir/perfdata.pl.dulist";
	$debug_file				= "$perfdata_dir/perfdata.pl.debug";
	$log_file				= "$perfdata_dir/perfdata.pl.log";
	$crontab_file			= "$perfdata_dir/perfdata.pl.crontab";
	mkdir($perfdata_dir) unless(-d $perfdata_dir);
			
	WRITE_DISKNAME_TO_FILE();
	LOAD_DISKNAME_FROM_FILE();
	WRITE_INTERVAL_TO_FILE();
	
	if ( $collect_all_processes == 1 ) { 
		$egrepstring_ps = "";
	}
	
	if ( $sum_network ) { 
		$network_scale="${network_scale} sum in interval";	
	} else {
		$network_scale="${network_scale}ps";
	}
	$header				= "Running on hostname \"$hostname\" platform \"$osname\"  architecture \"$archname\".  Network scale is \"$network_scale\". There are $cpu_cores CPU cores. perfdata_dir $perfdata_dir";
	debug ( 0 , "$header");
	
	if ( $csv_output ) {
		use Storable qw(dclone); #Used in STORE_DATA_FOR_CSV_FILE
		my $used_codes_count = @used_codes;
		debug( 18, "Used Code Count: $used_codes_count");
		if ( $used_codes_count == 0 ) {
			while (($key) = each(%prod_code_hash)){ #RDZ $key, $value
				push (@used_codes,$key);
			}
		}
		
		if ( $csv_output_dir eq "" ) {
			if ( $perf1 ) {
				$csv_output_dir			= "/perf1/perfdata/reduced/$hostname";
			} else {
				$csv_output_dir			= "$perfdata_dir/reduced";
			}
		}
		if ( ! -d $csv_output_dir) {
			mkdir($csv_output_dir);
			qx/chmod 775 $csv_output_dir/;
		}
		
	}
	
	my $pipe = "";
	$used_code_count = 0;
	for my $code (@used_codes) {
		debug ( 1, "code $code: $prod_code_hash{$code}[$prod_code_regex_index]");
		if ($code eq "rx") {
			$regex = "$input_regex$pipe$regex";
		} 
		elsif ($code eq "pid") {
			$regex = "$command_PID$pipe$regex";
		} 
		else {
			$regex = "$prod_code_hash{$code}[$prod_code_regex_index]$pipe$regex";
		}
		$pipe = "|";
		$used_code_count++;
	}
	
	$networks_displayed_count=$#requested_network_names_array+1;
	if ( $networks_displayed_count == 0 ) {
		if ( $csv_output ) {
			if ( $linux ) {
				my $temp=`$ifconfig_command_path | egrep "Link encap|flags" | egrep -v ":1 |docker|lo|cali|virb|tun" | cut -d " " -f 1 | cut -d ":" -f 1 | head -1`; 
				@requested_network_names_array = split( /\n/, $temp );
			}
			elsif ( $aix ) {
				my $temp=`$ifconfig_command_path -a | grep -v lo | grep flags | cut -d ":" -f 1`; 
				@requested_network_names_array = split( /\n/, $temp );
			}
			elsif ( $solaris ) {
				my $temp=`$ifconfig_command_path | grep "Link encap" | egrep -v ":1 |lo " | cut -d " " -f 1`; #todo
				@requested_network_names_array = split( /\n/, $temp );
			}
			elsif ( $hp ) {
				my $temp=`$ifconfig_command_path | grep "Link encap" | egrep -v ":1 |lo " | cut -d " " -f 1`;  #todo
				@requested_network_names_array = split( /\n/, $temp );
			}
			else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
		} 
		else {
			if ( $linux ) {
				my $temp=`$ifconfig_command_path | egrep "Link encap|flags" | egrep -v ":1 |docker|lo|cali|virb|tun" | cut -d " " -f 1 | cut -d ":" -f 1 | head -1`; 
				@requested_network_names_array = split( /\n/, $temp );
			}
			elsif ( $aix ) {
				my $temp=`$ifconfig_command_path -a | grep -v lo | grep flags | cut -d ":" -f 1 | head -1`; 
				@requested_network_names_array = split( /\n/, $temp );
			} 
			elsif ( $solaris ) {
				my $temp=`$ifconfig_command_path | head -1 | cut -d " " -f 1`;  #todo
				@requested_network_names_array = split( /\n/, $temp );
			} 
			elsif ( $hp ) {
				my $temp=`$ifconfig_command_path | head -1 | cut -d " " -f 1`;  #todo
				@requested_network_names_array = split( /\n/, $temp );
			} 
			else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
		}
	}
	$networks_displayed_count=$#requested_network_names_array+1;
	debug ( 7 , "requested_network_names_array size is $networks_displayed_count  ->  \"@requested_network_names_array\"") ;
	$requested_network_names_string = join("",@requested_network_names_array);
	
	$disk_df_displayed_count=$#requested_disk_df_names_array+1;
	debug ( 31 , "requested_disk_df_names_array size is $disk_df_displayed_count  ->  \"@requested_disk_df_names_array\"") ;
	
	debug ( 32 , "requested_disk_metric_names_array size is $#requested_disk_metric_names_array+1  ->  \"@requested_disk_metric_names_array\"") ;
	
	$set_header_sizes=1;
	
	debug ( 0, "regex: \"$regex\"");
}
sub DETERMINE_CONSOLE_OUTPUT_SIZES {
	debug ( 1 , "DETERMINE_CONSOLE_OUTPUT_SIZES");
	
	$csv_command_size = 100;
	
	$NET_decimal 	= 1;
	$DEV_decimal 	= 2;
	if (( $disk_rps == 1 ) || ( $disk_wps == 1 ) || ( $disk_tps == 1 )) {
		$DEV_decimal = 0;		
	}
	$PER_decimal 	= 2;
	$TCPU_decimal 	= 2;
	
	$DATE_size 		= 8;
	$DTIME_size 	= 6;
	if ( $aix ) {
		$PID_size 		= 8;
	} else {
		$PID_size 		= 7;
	}
	$THC_size 		= 5;
	$VSZ_size 		= 9;
	$RSS_size 		= 9;
	$ETIME_size 	= 12;
	$TIME_size 		= 12;
	$SEC_size 		= 4;
	$PER_size 		= 7;
	$READ_size 		= 8;
	$WRITE_size 	= 8;
	$NET_size 		= 8;
	$DF_size 		= 10;
	$DEV_size		= 8;
	$ACTM_size 		= 6;
	$SWAP_size 		= 5;
	$TCPU_size 		= 7;
	$DU_size 		= 15;
	
	
	$DISK_DU_HEADER_CODE = " b";
	$DISK_DF_HEADER_CODE = " S%";
	if (( $disk_used == 1 ) || ( $disk_free == 1 )) {
		$DISK_DF_HEADER_CODE = " MB";	
	}
	$DISK_UTIL_HEADER_CODE = " U%";
	if ( $disk_tps != 0 ) {
		$DISK_UTIL_HEADER_CODE = " tps";	
	} elsif ( $disk_rps != 0 ) {
		$DISK_UTIL_HEADER_CODE = " rps";	
	} elsif ( $disk_wps != 0 ) {
		$DISK_UTIL_HEADER_CODE = " wps";	
	} elsif ( $disk_await != 0 ) {
		$DISK_UTIL_HEADER_CODE = " awt";	
	} elsif ( $disk_svctm != 0 ) {
		$DISK_UTIL_HEADER_CODE = " svc";	
	} 
		
	my $temp_NET_size = $NET_size - 3;
	@NET_SIZE=("%0s%0s","%0s%0s","%0s%0s","%0s%0s","%0s%0s");
	@NETRX_NAME=();
	@NETTX_NAME=();
	for ( my $x=0 ; $x < $networks_displayed_count ; $x ++) {
		$NETRX_NAME[$x]= sprintf( "%.${temp_NET_size}s RX", substr($requested_network_names_array[$x], -$temp_NET_size));
		$NETTX_NAME[$x]= sprintf( "%.${temp_NET_size}s TX", substr($requested_network_names_array[$x], -$temp_NET_size));
		$NET_SIZE[$x]= " %${NET_size}s, %${NET_size}s,";
	}
	
	my $temp_DF_size = $DF_size - length($DISK_DF_HEADER_CODE);
	@DF_SIZE=("%0s","%0s","%0s","%0s","%0s");
	@DF_NAME=();
	for ( my $x=0 ; $x < $disk_df_displayed_count ; $x ++) {
		$DF_NAME[$x]= sprintf( "%.${temp_DF_size}s$DISK_DF_HEADER_CODE", substr($requested_disk_df_names_array[$x], -$temp_DF_size));
		$DF_SIZE[$x]= " %${DF_size}s,";
	}
	
	my $temp_DU_size = $DU_size - length($DISK_DU_HEADER_CODE);
	@DU_SIZE=("%0s","%0s","%0s","%0s","%0s");
	@DU_NAME=();
	my $x=0;
	foreach my $du_dir_name (sort keys %disk_du_size_hash) { 
		$DU_NAME[$x]= sprintf( "%.${temp_DU_size}s$DISK_DU_HEADER_CODE", substr($du_dir_name, -$temp_DU_size));
		$DU_SIZE[$x]= " %${DU_size}s,";
		debug( 39 , "$x header: $DU_NAME[$x], $temp_DU_size, ${DU_size}, $DU_SIZE[$x]");
		$x++;
	}
	
	debug ( 33 , "length $#requested_disk_metric_names_array+1  requested_disk_metric_names_array @requested_disk_metric_names_array");
	@DEV_SIZE=("%0s","%0s","%0s","%0s","%0s","%0s","%0s","%0s");
	@MOUNT_NAME=();
	$total_dev_columns=0;
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		$temp_DEV_size = $DEV_size - length($DISK_UTIL_HEADER_CODE);	
		my $length = length($requested_mount_names_array[$x]);
		if ( $length < $temp_DEV_size ) {
			$temp_DEV_size = $length;
		}
		if ( $temp_DEV_size+length($DISK_UTIL_HEADER_CODE) < 6 ) {
			$temp_DEV_size = 3;
		}
		my $print_size = $temp_DEV_size+length($DISK_UTIL_HEADER_CODE);
		$MOUNT_NAME[$x]= sprintf( "%${temp_DEV_size}s$DISK_UTIL_HEADER_CODE", substr($requested_mount_names_array[$x], -$temp_DEV_size));
		$DEV_SIZE[$x]= " %${print_size}s,";
		$total_dev_columns=$total_dev_columns+$print_size+2;
		debug ( 33 , "total_dev_columns $total_dev_columns, length $length, temp_DEV_size $temp_DEV_size, print_size $print_size, Setting DEV_SIZE[$x] to \"$DEV_SIZE[$x]\", MOUNT_NAME $MOUNT_NAME[$x],");	
	}
	if ( $total_dev_columns == 0 ) {
		$total_dev_columns=10;
	}
	
	IDENTIFY_SCREEN_SIZE();
	
	$VARIABLE_SIZE="$NET_SIZE[0]$NET_SIZE[1]$NET_SIZE[2]$NET_SIZE[3]$NET_SIZE[4]$DF_SIZE[0]$DF_SIZE[1]$DF_SIZE[2]$DF_SIZE[3]$DF_SIZE[4]$DEV_SIZE[0]$DEV_SIZE[1]$DEV_SIZE[2]$DEV_SIZE[3]$DEV_SIZE[4]$DEV_SIZE[5]$DEV_SIZE[6]$DEV_SIZE[7]";
	$VARIABLE_DIR_SIZE="$DU_SIZE[0]$DU_SIZE[1]$DU_SIZE[2]$DU_SIZE[3]$DU_SIZE[4]";
	
	#CUSTOMIZE_3
	$console_individual_processes_output_string	= "%${DATE_size}s, %${DTIME_size}s, %${PID_size}s, %${THC_size}s, %${RSS_size}s, %${ETIME_size}s, %${TIME_size}s, %${SEC_size}s, %${PER_size}s, %${READ_size}s, %${WRITE_size}s,${VARIABLE_SIZE} %${ACTM_size}s, %${SWAP_size}s, %${TCPU_size}s, %${COMMAND_MAX_LENGTH}s,\n";
	$console_summed_output_string				= "%${DATE_size}s, %${DTIME_size}s, %${THC_size}s, %${RSS_size}s, %${SEC_size}s, %${PER_size}s, %${READ_size}s, %${WRITE_size}s,${VARIABLE_SIZE} %${READ_size}s, %${WRITE_size}s, %${ACTM_size}s, %${SWAP_size}s, %${TCPU_size}s, %${COMMAND_MAX_LENGTH}s,\n";
	$console_dir_size_output_string				= "%${DATE_size}s, %${DTIME_size}s,${VARIABLE_DIR_SIZE} %${ACTM_size}s, %${SWAP_size}s, %${TCPU_size}s, %${COMMAND_MAX_LENGTH}s,\n";

}

sub WGET_RESPONSE_ADDRESS {
	debug ( 28 , "\{ time wget $monitored_response_address -q -O /dev/null ; \} |& grep real");
	while ( 1 ) {
		SET_GLOBAL_DATE_TIME();
		my $temp = qx/{ time wget $monitored_response_address -q -O \/dev\/null ; } |& grep real/;
		chomp($temp);
		$temp =~ s/real//g;
		$temp =~ s/\s//g;
		my $minute = (split ( /m/, $temp ))[0];
		my $seconds = (split ( /m/, $temp ))[1];
		$seconds =~ s/s//g;
		my $total = $minute * 60 + $seconds;
			
		my $sleep_seconds = $write_interval - (RETURN_EPOCH() % $write_interval) ;
		if ( $sleep_seconds < 1 ) {
			$sleep_seconds = 10;
		}
		printf("$datestring.$timestring,RESPONSE,$monitored_response_address,$temp,%7.3f,\n", $total);
		sleep $sleep_seconds;
	}
}
sub MONITOR_NETSTAT {
	debug ( 29 , "netstat -plan | egrep \"$monitored_netstat_regex\" | wc -l");
	while ( 1 ) {
		SET_GLOBAL_DATE_TIME();
		my $temp = qx/netstat -plan | egrep "$monitored_netstat_regex" | wc -l/;
		chomp($temp);
		my $sleep_seconds = $write_interval - (RETURN_EPOCH() % $write_interval) ;
		if ( $sleep_seconds < 1 ) {
			$sleep_seconds = 10;
		}
		printf("$datestring.$timestring,NETSTAT,$monitored_netstat_regex,$temp,\n");
		sleep $sleep_seconds;
	}	
}

sub SET_GLOBAL_DATE_TIME {
	#1398954468 or nothing for current time, returns NOTHING but does set globals $datestring and $timestring
	if ( $_[0] ne "" ) {
		my $epoch = $_[0];
		$datestring = sprintf '%04d%02d%02d', localtime($epoch)->year() + 1900, localtime($epoch)->mon()+1, localtime($epoch)->mday();
		$timestring = sprintf '%02d%02d%02d', localtime($epoch)->hour(), localtime($epoch)->min(), localtime($epoch)->sec();
	} else {
		$datestring = sprintf '%04d%02d%02d', localtime->year() + 1900, localtime->mon()+1, localtime->mday();
		$timestring = sprintf '%02d%02d%02d', localtime->hour(), localtime->min(), localtime->sec();
	}
	debug ( 1 , "SET_GLOBAL_DATE_TIME $datestring.$timestring");
}
sub RETURN_DATE_TIME {
	#input of 1398954468 or nothing for current time, returns $date.$time
	my $date = "";
	my $time = "";
	if ( $_[0] ne "" ) {
		my $epoch = $_[0];
		debug ( 2 , "Input epoch $epoch");
		$date = sprintf '%04d%02d%02d', localtime($epoch)->year() + 1900, localtime($epoch)->mon()+1, localtime($epoch)->mday();
		$time = sprintf '%02d%02d%02d', localtime($epoch)->hour(), localtime($epoch)->min(), localtime($epoch)->sec();
	} else {
		$date = sprintf '%04d%02d%02d', localtime->year() + 1900, localtime->mon()+1, localtime->mday();
		$time = sprintf '%02d%02d%02d', localtime->hour(), localtime->min(), localtime->sec();
	}
	debug ( 1 , "RETURN_DATE_TIME \"$date\" \"$time\"");
	return "$date.$time";
}
sub RETURN_EPOCH {
	#Input of 20140130.145914 or nothing for current time, returns $epoch
	my $epoch = "";
	if (( $_[0] ne "" ) && ( $_[1] ne "")) {
		debug ( 2 , "Input date time \"$_[0]\" \"$_[1]\"");
		$epoch = timelocal(	substr($_[1], 4, 2),
							substr($_[1], 2, 2),
							substr($_[1], 0, 2),
							substr($_[0], 6, 2),
							(substr($_[0], 4, 2))-1,
							substr($_[0], 0, 4));
	} else {
		$epoch = time;
	}
	debug ( 2 , "Return epoch $epoch");
	return $epoch;
}
sub CONVERT_ELAPSE_TIME {
	my $minutes = "";
	if ( $_[0] ne "" ) {
		debug ( 27 , "Input elapse time \"$_[0]\"");
		my $split_day = split ( /-/, $_[0] );
		my $days = 0;
		my $time = $split_day[0];
		if ( scalar $split_day == 2 ) {
			$days = $split_day[0];	
			$time = $split_day[1];	
		}
		my $split_day = split ( /-/, $_[0] );
		
		$minutes=$_[0];#temp
	} else {
		$minutes = time;
	}
	debug ( 27 , "Return minutes $minutes");
	return $minutes;
}
sub INC_LOOP_DATE {
	my $temp_epoch=RETURN_EPOCH($console_loop_date,"020000");
	$temp_epoch=$temp_epoch+86400;
	my $temp_datetime = RETURN_DATE_TIME($temp_epoch);
	SET_GLOBAL_DATE_TIME;
	if ( $console_loop_date lt $datestring ) {
		my $old_console_loop_date = $console_loop_date;
		$console_loop_date = (split ( /\./, $temp_datetime ))[0];
		debug ( 1 , "$old_console_loop_date lt $datestring -> Incrementing console_loop_date to $console_loop_date, temp_epoch $temp_epoch");
	} else {
		debug ( 0 , "$console_loop_date !lt $datestring -> NOT incrementing console_loop_date");	
	}
}
sub SYNC_TIME { 
#Used to fake adjust only the written clock output by up to 1 second
#Sar will sync real clock by running shorter in the next loop.
	my $seconds = substr($timestring, 4, 2);
	my $mod = ($seconds % $write_interval);
	if ( $mod != 0 ) {
		if ( $mod <= 4 ) {
			$timestring = sprintf '%06d', $timestring - $mod;
			debug ( 0 , "Sync timestamp by $mod $datestring.$timestring");
		}
		elsif ( $mod > 4 ) {
			$timestring = sprintf '%06d', $timestring - $mod;
			debug ( 0 , "WARNING! Sync timestamp by $mod $datestring.$timestring");	
		}
	}
}
sub SETUP_INTERVAL_WAIT {
	my $extra_seconds = shift ;
	my $current_mod_seconds = sprintf '%2d', localtime->sec();
	my $modified_mod_seconds = $current_mod_seconds + $extra_seconds;
	$interval_wait_seconds = $write_interval - ( $modified_mod_seconds % $write_interval ) ; 
	debug ( 20 , "current_mod_seconds $current_mod_seconds modified_mod_seconds $modified_mod_seconds" );
}
sub SETUP_PS_COMMANDS {
	$ps_command_start = "ps ";
	if ( $linux ) {
		if ( $use_ps_thcount == 0 ) {
			$ps_command 		= "ps w -e -o pid,ppid,uid,vsz,rss,etime,time,args | egrep -i \"$egrepstring_ps\" | egrep -vi \"$egrepvstring_ps\"";
		} else {
			$ps_command 		= "ps w -e -o pid,ppid,uid,thcount,vsz,rss,etime,time,args | egrep -i \"$egrepstring_ps\" | egrep -vi \"$egrepvstring_ps\"";
		}
	} elsif ( $aix ) {
		$ps_command 		= "ps -efo pid,ppid,uid,thcount,vsz,rssize,etime,time,args | egrep -i \"$egrepstring_ps\" | egrep -vi \"$egrepvstring_ps\"";
	} elsif ( $solaris ) {
		$ps_command 		= "ps -efo pid,ppid,uid,nlwp,vsz,rss,etime,time,args | egrep -i \"$egrepstring_ps\" | egrep -vi \"$egrepvstring_ps\"";
	} elsif ( $hp ) {
		$ps_command = "UNIX95= ps -e -o 'pid ppid vsz sz etime time args' | egrep -i \"$egrepstring_ps\" | egrep -vi \"$egrepvstring_ps\"";
	} else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
}
sub SETUP_NETWORK_COMMANDS {
	if ( $linux ) {
		#$network_command_0 = "$ifconfig_command_path eth0 | grep \"bytes:\" | grep -v \"(0.0 b)\" | head -1";
		$network_command = "$ifconfig_command_path -a | egrep \"Link|bytes\" | egrep -vi inet6";
		$network_command_start = "$ifconfig_command_path";
	} 
	elsif ( $aix ) {
		$network_command = "netstat -v | egrep \"Bytes|STATISTICS\" | sed 's/ent/en/g'";
		$network_command_start = "netstat";
	} 
	elsif ( $solaris ) {
		$network_command = "netstat -s | egrep \"tcpOutDataBytes|tcpInInorderBytes\""; #todo
		$network_command_start = "netstat";
	} 
	elsif ( $hp ) {
		$network_command = "$ifconfig_command_path -a | egrep \"Link|bytes:\" | egrep -vi inet6"; #todo
		$network_command_start = "$ifconfig_command_path";
	} 
	else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
}
sub SETUP_DF_COMMANDS {
	if ( $linux ) {
		$df_command = "df -Plk | egrep -v 'kubernetes.io~secret|/overlay2/|/containers/'";
		$df_command_start = "df";
	} 
	elsif ( $aix ) {
		$df_command = "/usr/sysv/bin/df -l";
		$df_command_start = "df";
	} 
	elsif ( $solaris ) {
		$df_command = "df -Plk"; 
		$df_command_start = "df";
	} 
	elsif ( $hp ) {
		$df_command = "df -Pk"; #todo
		$df_command_start = "df";
	} 
	else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
}
sub SETUP_LSBLK_COMMANDS {
	if ( $linux ) {
		$lsblk_command = "$lsblk_command_path -l";
		$lsblk_command_start = "lsblk";
	} 
	elsif ( $aix ) {
		$lsblk_command = "";
		$lsblk_command_start = "";
	} 
	elsif ( $solaris ) {
		$lsblk_command = "";
		$lsblk_command_start = "";
	} 
	elsif ( $hp ) {
		$lsblk_command = "";
		$lsblk_command_start = "";
	} 
	else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
}
sub SETUP_SAR_COMMANDS {
	$sar_commandstart 	= "sar -" ;
	if ( $linux ) {
		$sar_version = `sar -V 2>&1`;
		debug ( 2 , "sar_version \"$sar_version\"");
		if ( $sar_version !~ m/sysstat version/ ) {
			debug ( 0 , "\"sar\" command is not installed. Please install the \"sysstat\" package before using, exiting...");
			exit 1;
		}
		if ( $sar_version !~ m/sysstat version 7.*/ ) {
			$sar_command 	= "sar -druS -n DEV $interval_wait_seconds 1 | grep Average | grep -v '^\$'";			
		}
		else {
			$sar_command 	= "sar -dru -n DEV $interval_wait_seconds 1 | grep Average | grep -v '^\$'";
		}
	} elsif ( $aix ) {
		#$sar_command 		= "sar -du $interval_wait_seconds 1 | egrep -vi '^\$|AIX|sys|device|cd'";
		$sar_command 		= "sar -du $interval_wait_seconds 1 | egrep -vi '^\$|AIX|cd' ; svmon -G -O unit=MB | egrep 'memory|space'";
	} elsif ( $solaris ) {
		#$sar_command 		= "sar -du $interval_wait_seconds 1 | egrep -v '^\$|device|sys|SunOS|ohc|ehci|,|nfs'";
		$sar_command 		= "sar -du $interval_wait_seconds 1 | egrep -v '^\$|SunOS|ohc|ehci|,|nfs'";
	} elsif ( $hp ) {
		$sar_command 		= "sar -dru -n DEV $interval_wait_seconds 1 | grep Average | grep -v '^\$'";
	} else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
	debug ( 2 , "sar_command $sar_command");
}
sub SETUP_IOTOP_COMMANDS {
	$iotop_command_start		= "iotop -";
	if ( $iotop_installed !=0 ) {
		my $iotop_interval_wait_seconds = $interval_wait_seconds;
	#	if ( $ps_klzagent_list_output <= $max_klzagent_iotop ) {
	#		$iotop_command 		= "$iotop_command_path -obtqqaPk -d $iotop_interval_wait_seconds -n 2 | head -100";		
	#	} else {
			#$iotop_command 	= "$iotop_command_path -obtqqaPk -d $iotop_interval_wait_seconds -n 2 | egrep \"$egrepstring_iotop\" | egrep -v \"$egrepvstring_iotop\" ";
			$iotop_command 		= "$iotop_command_path -obtqqaPk -d $iotop_interval_wait_seconds -n 2 | egrep -v \"$egrepvstring_iotop\" | head -100";
	#	}
	}
}
sub IDENTIFY_SCREEN_SIZE {
	if ( $small_screen ) {
		$cols = 1000;
		$COMMAND_MAX_LENGTH = $csv_command_size;
	} else {
		$used_cols=0;
		if ( $sum_processes == 1 ) {
			$used_cols=3+$DATE_size+2+$DTIME_size+2+$THC_size+2+$RSS_size+2+$SEC_size+2+$PER_size+2+$READ_size+2+$WRITE_size+2+$READ_size+2+$WRITE_size+2+$ACTM_size+2+$SWAP_size+2+$TCPU_size;
		}
		else {
			$used_cols=3+$DATE_size+2+$DTIME_size+2+$PID_size+2+$THC_size+2+$RSS_size+2+$ETIME_size+2+$TIME_size+2+$SEC_size+2+$PER_size+2+$READ_size+2+$WRITE_size+2+$ACTM_size+2+$SWAP_size+2+$TCPU_size;
		}
		$used_cols=$used_cols+(($NET_size+2+$NET_size+2)*$networks_displayed_count);
		$used_cols=$used_cols+(($DF_size+2)*$disk_df_displayed_count);
		$used_cols=$used_cols+$total_dev_columns;
		debug ( 1 , "used_cols=$used_cols");
		if ( $linux ) {
			$cols = `/bin/stty size | cut -d " " -f 2`;
		} elsif ( $aix ) {
			$cols = `/bin/stty size | cut -d " " -f 2`;
		} elsif ( $solaris ) {
			$cols = `/bin/stty | grep columns | cut -d "=" -f 3 | cut -d ";" -f 1`;
		} elsif ( $hp ) {
			$cols = `/bin/stty size | cut -d " " -f 2`;
		} else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
		chomp($cols);
		#$COMMAND_MAX_LENGTH 	= ($cols-$used_cols-1);
		$COMMAND_MAX_LENGTH 	= ($cols-$used_cols);
	}
	debug ( 1 , "COMMAND_MAX_LENGTH=$COMMAND_MAX_LENGTH");
}

# File Functions
sub INITIALIZE_OUTPUT_FILE {
	debug ( 1 , "Initialize output file $output_file");
	open (OUTPUTFILE, ">>", "$output_file") or die $!;
	print OUTPUTFILE "$command_run\n";
	print OUTPUTFILE "$header\n";
	close (OUTPUTFILE) or die $!;
}
sub WRITE_INTERVAL_TO_FILE {
	debug ( 0 , "Initialize interval file $write_interval_file to $write_interval");
	if ( $write_interval < 5 ) {
		$write_interval = 5 ;
	}
	open (INTERVAL_FILE, ">", "$write_interval_file" ) or die $!;
	print INTERVAL_FILE "$write_interval";
	close (INTERVAL_FILE);
}
sub LOAD_INTERVAL_FROM_FILE {
	if ( -f $write_interval_file ) { 
		open INTERVAL_FILE, "<", $write_interval_file or die $! ;
		while (<INTERVAL_FILE>) { chomp; $write_interval=$_; }
		close (INTERVAL_FILE);
		debug ( 1 , "New write_interval $write_interval");
	}
	else {
		debug ( 1 , "No write_interval_file \"$write_interval_file\"");
	}
}
sub WRITE_DISKNAME_TO_FILE {
	if (@requested_disk_metric_names_array) {
		debug ( 0 , "Initialize disk name(s) file $disk_name_file to contain \"@requested_disk_metric_names_array\"");
		open (DISKNAME_FILE, ">", "$disk_name_file" ) or die $!;
		for my $temp_device_name (@requested_disk_metric_names_array){
			print DISKNAME_FILE "$temp_device_name\n";
		}
		close (DISKNAME_FILE);
		qx/chmod 775 $disk_name_file/;
	}
}
sub LOAD_DISKNAME_FROM_FILE {
	if ( -f $disk_name_file ) {
		if ( $identify_disk_name ) { 
			open DISKNAME_FILE, "<", $disk_name_file or die $! ;
			while (<DISKNAME_FILE>) { 
				chomp; 
				push(@requested_disk_metric_names_array,$_);
			}
			close (DISKNAME_FILE);
			debug ( 0 , "Loaded disk name(s) from file $disk_name_file - \"@requested_disk_metric_names_array\"");
			$identify_disk_name=0;
		}
	} 
}
sub LOAD_DB_LIST_FROM_FILE_AND_SNAPSHOT {
	if ( -f $db_list_file ) { 
		my $thread_self = shift;
		#debug ( 30 , "$thread_self 1 System call cat /etc/passwd before");
		#my $db2_exists = `timeout 1 cat /etc/passwd | grep db2 | wc -l`;
		#debug ( 30 , "$thread_self 1 System call cat /etc/passwd db2_exists $db2_exists");
		my $db2_exists = 1;
		if ( $db2_exists != 0 ) {
			my $db2_snapshot_dir = shift;
			if ( ! -d $db2_snapshot_dir ) {
				debug ( 1 , "mkdir($db2_snapshot_dir)" );
				mkdir($db2_snapshot_dir);
				qx/chmod 775 $db2_snapshot_dir/;
				debug ( 30 , "$thread_self 2 System call cat /etc/group before");
				my $is_dasadm1 = `timeout 1 cat /etc/group | grep dasadm1 | wc -l`; #once per day
				debug ( 30 , "$thread_self 2 System call cat /etc/group is_dasadm1 $is_dasadm1");
				#my $db2_user = `cat /etc/group | grep dasadm1 | rev | cut -d ':' -f 1 | rev`;
				#chomp ($db2_user);
				#debug ( 1 , "db2_user $db2_user" );
				if ( $is_dasadm1 != 0 ) { 
					#debug ( 1 , "qx/chown $db2_user:dasadm1 $db2_snapshot_dir/" );
					#qx/chown $db2_user:dasadm1 $db2_snapshot_dir/;
					debug ( 1 , "qx/chgrp dasadm1 $db2_snapshot_dir/" );
					qx/chgrp dasadm1 $db2_snapshot_dir/;
				}
			}	
			debug ( 30 , "Reading DB snapshot info from $db_list_file");	
			open DB_LIST_FILE_HANDLE, "<", $db_list_file or die $! ;
			while( my $line = <DB_LIST_FILE_HANDLE> ) { 
				my @split = split( / /, $line );
				my $database = $split[0];
				my $db2_user = $split[1];
				my $db2_interval = $split[2];
				chomp $db2_interval;		
				debug ( 30 , "Read database $database, $db2_user, $db2_interval");
				#debug ( 30 , "$thread_self 3 System call cat /etc/passwd before");
				#my $db2_user_exists = `timeout 1 cat /etc/passwd | grep "$db2_user" | wc -l`;
				#debug ( 30 , "$thread_self 3 System call cat /etc/passwd db2_user_exists $db2_user_exists");
				my $db2_user_exists = 1; 
				if ( $db2_user_exists != 0 ) {	
					my $epoch = RETURN_EPOCH;
					my $mod = ( $epoch % $db2_interval );
					debug ( 30 , "epoch $epoch, mod $mod");
					if ( $mod < 5 ) {
						my $nohup_output_location = "/dev/null";
						my $db2_snapshot_time = RETURN_DATE_TIME($epoch + $db2_interval);
						my $snapshot_file_name = "$hostname.$db2_snapshot_time.$db2_interval.$database.db2ss.log";
						#my $db2_snapshot_command_string="db2 connect to $database; db2 UPDATE MONITOR SWITCHES USING BUFFERPOOL ON; db2 UPDATE MONITOR SWITCHES USING LOCK ON; db2 UPDATE MONITOR SWITCHES USING SORT ON; db2 UPDATE MONITOR SWITCHES USING STATEMENT ON; db2 UPDATE MONITOR SWITCHES USING TABLE ON; UPDATE MONITOR SWITCHES USING UOW ON; UPDATE MONITOR SWITCHES USING TIMESTAMP ON; db2 reset monitor for db $database; sleep $db2_interval; db2 get snapshot for all on $database > $db2_snapshot_dir/$snapshot_file_name";
						my $db2_snapshot_command_string="db2 connect to $database; db2 UPDATE MONITOR SWITCHES USING BUFFERPOOL ON LOCK ON SORT ON STATEMENT ON TABLE ON UOW ON TIMESTAMP ON; db2 reset monitor for db $database; sleep $db2_interval; db2 get snapshot for all on $database > $db2_snapshot_dir/$snapshot_file_name ; gzip $db2_snapshot_dir/$snapshot_file_name";
						debug ( 1 , "nohup su - $db2_user -c \"$db2_snapshot_command_string \" >$nohup_output_location &");
						system("nohup su - $db2_user -c \"$db2_snapshot_command_string\" >$nohup_output_location &");
					}
				}			
			}
			close (DB_LIST_FILE_HANDLE);
		}
	} 
	else {
		debug ( 30 , "No db_list_file \"$db_list_file\"");
	}	
}
sub LOAD_DU_LIST_FROM_FILE_AND_SNAPSHOT {
	my $du_output = "";
	if ( -f $du_list_file ) { 
		debug ( 39 , "Reading du snapshot info from $du_list_file");	
		open DU_LIST_FILE_HANDLE, "<", $du_list_file or die $! ;
		while( my $line = <DU_LIST_FILE_HANDLE> ) { 
			my @split = split( / /, $line );
			my $du_dir = $split[0];
			chomp $du_dir;
			my $du_interval = $split[1];
			chomp $du_interval;		
			debug ( 39 , "Read du_dir $du_dir du_interval $du_interval");
			if ( -d $du_dir ) {	
				my $epoch = RETURN_EPOCH;
				my $mod = ( $epoch % $du_interval );
				debug ( 39 , "$epoch % $du_interval, mod $mod");
				if ( $mod < 5 ) {
					my $du_output_temp = qx/du -s $du_dir/;
					$du_output_temp =~ s/ +/ /;
					#chomp $du_output_temp;
					$du_output = "${du_output}${du_output_temp}";
					debug ( 39 , "du_output \"$du_output\"");
				}
			}
		}
		close (DB_LIST_FILE_HANDLE);
	} 
	else {
		debug ( 39 , "No du_list_file \"$du_list_file\"");
	}
	debug ( 39 , "Returning du_output \"$du_output\"");
	return $du_output;
}
sub LOAD_DEBUG_FROM_FILE {
	if ( -f $debug_file ) { 
		open DEBUG_FILE_HANDLE, "<", $debug_file or die $! ;
		while(<DEBUG_FILE_HANDLE>) { 
			$global_debug_setting = $_;
			chomp($global_debug_setting);
		}
		close (DEBUG_FILE_HANDLE);
		debug ( 1 , "debug_file $debug_file, global_debug_setting $global_debug_setting");
	} 
}

# Print to Console
sub PRINT_HEADER_TO_CONSOLE {
	if ( $set_header_sizes ) {
		for ( my $x=0 ; $x < ($#requested_disk_metric_names_array+1) ; $x ++) {
			CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		}
		DETERMINE_CONSOLE_OUTPUT_SIZES();
		$set_header_sizes=0;
		if ( $COMMAND_MAX_LENGTH < 10 ) {
			debug ( 0 , "Window is too small. This is only $cols wide, needs to be at least $used_cols + 10");
			exit 1;
		}
	}
	debug ( 22 , "header_loop_count $header_loop_count");
	if ( $header_loop_count >= 30 ) {
		$print_header=1;
	}
	
	if ( $print_header ) { 
		if ( $linux || $aix || $solaris ) {
			print "-" x $cols;
			printf  ("\n"); 
			if ( $show_dir_size == 1 ) {			
				printf  ("$console_dir_size_output_string",
				"date", 
				"time", 
				"$DU_NAME[0]",
				"$DU_NAME[1]",
				"$DU_NAME[2]",
				"$DU_NAME[3]",
				"$DU_NAME[4]",
				"Act-M",
				"SWAP",
				"T-CPU%",
				"command");
			}
			elsif ( $sum_processes == 1 ) {
				printf  ("$console_summed_output_string",
				"date", 
				"time", 
				"THC", 
				"RSS",  
				"Sec",
				"CPU %",
				"P-Read",
				"P-Write",
				"$NETRX_NAME[0]",
				"$NETTX_NAME[0]",
				"$NETRX_NAME[1]",
				"$NETTX_NAME[1]",
				"$NETRX_NAME[2]",
				"$NETTX_NAME[2]",
				"$NETRX_NAME[3]",
				"$NETTX_NAME[3]",
				"$NETRX_NAME[4]",
				"$NETTX_NAME[4]",
				"$DF_NAME[0]",
				"$DF_NAME[1]",
				"$DF_NAME[2]",
				"$DF_NAME[3]",
				"$DF_NAME[4]",
				"$MOUNT_NAME[0]",
				"$MOUNT_NAME[1]",
				"$MOUNT_NAME[2]",
				"$MOUNT_NAME[3]",
				"$MOUNT_NAME[4]",
				"$MOUNT_NAME[5]",
				"$MOUNT_NAME[6]",
				"$MOUNT_NAME[7]",
				"T-Read",
				"T-Write",
				"Act-M",
				"SWAP",
				"T-CPU%",
				"command");			
			} 
			else {
				printf  ("$console_individual_processes_output_string",
				"date", 
				"time", 
				"PID", 
				#"PPID", 
				"THC", 
				#"VSZ", 
				"RSS", 
				"e-time", 
				"CPU TIME", 
				"Sec",
				"CPU %",
				"P-Read",
				"P-Write",
				"$NETRX_NAME[0]",
				"$NETTX_NAME[0]",
				"$NETRX_NAME[1]",
				"$NETTX_NAME[1]",
				"$NETRX_NAME[2]",
				"$NETTX_NAME[2]",
				"$NETRX_NAME[3]",
				"$NETTX_NAME[3]",
				"$NETRX_NAME[4]",
				"$NETTX_NAME[4]",
				"$DF_NAME[0]",
				"$DF_NAME[1]",
				"$DF_NAME[2]",
				"$DF_NAME[3]",
				"$DF_NAME[4]",
				"$MOUNT_NAME[0]",
				"$MOUNT_NAME[1]",
				"$MOUNT_NAME[2]",
				"$MOUNT_NAME[3]",
				"$MOUNT_NAME[4]",
				"$MOUNT_NAME[5]",
				"$MOUNT_NAME[6]",
				"$MOUNT_NAME[7]",
				"Act-M",
				"SWAP",
				"T-CPU%",
				"command");
			}
		} 
		elsif ( $hp ) {
		} else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
	}
	
	if ( $header_loop_count >= 30 ) {
		$print_header=0;
		$header_loop_count=0;
	}
	if ( $#pid_array > $max_processes_used ) {
		$max_processes_used=$#pid_array;
	}
	if ( (( $used_code_count <= 1 ) && ( $max_processes_used <= 1 )) || $sum_processes ) {
		$print_header=0;
	} else {
		$print_header=1;
	}
	debug ( 22 , "max_processes_used:$max_processes_used   print_header:$print_header");

	$header_loop_count++;
	$identify_disk_name=0;
}
sub PRINT_NEW_OUTPUT_TO_CONSOLE {
	
	my $continue = 1;
	if ( $show_dir_size == 1 ) { 
		$continue = keys %disk_du_size_hash;
	}	
	if ( $continue > 0 ) {
		PRINT_HEADER_TO_CONSOLE; 
		if ( $linux || $aix || $solaris ) {
			while ( $next_printed_epoch lt $new_parsed_epoch ) {
				SET_GLOBAL_DATE_TIME($next_printed_epoch);
					printf  ("%${DATE_size}s, %${DTIME_size}s, %10s\n",
					"$datestring", 
					"$timestring",
					"No collected data");	
				$next_printed_epoch=$next_printed_epoch+$read_interval;
				PRINT_HEADER_TO_CONSOLE;
			}
			
			CONVERT_NETWORK();
			CONVERT_DISK_DF();
			CONVERT_DISK_METRICS();
			CONVERT_DU_METRICS();
			if ( ! @pid_array ) {		#Initialize an empty pid list
				push (@pid_array,"");
			}
			
			if ( $show_dir_size == 1 ) {			
				printf  ("$console_dir_size_output_string",
				"$parsed_date",
				"$parsed_time",
				"$du_reported_metric_array[0]",
				"$du_reported_metric_array[1]",
				"$du_reported_metric_array[2]",
				"$du_reported_metric_array[3]",
				"$du_reported_metric_array[4]",
				"$active_mem",
				"$swap_mem",
				"$total_cpu",
				"disk size measurements");
			}
			elsif ( $sum_processes == 1 ) { #Sum all processes into a single line of output 
				my $thc=0;
				my $rss=0;
				my $time=0;
				my $read=0;
				my $write=0;
				my $count=0; 
				for my $pid (@pid_array) {
					my $diff = "";
					if ( @{$process_hash{$pid}}[$old_cpu_seconds_index] ne '' ) {
						$diff = sprintf "%5d", @{$process_hash{$pid}}[$new_cpu_seconds_index] - @{$process_hash{$pid}}[$old_cpu_seconds_index];
					}
					$thc = $thc + @{$process_hash{$pid}}[$thcnt_index];
					$rss = $rss + @{$process_hash{$pid}}[$rss_index];
					$read = $read + @{$process_hash{$pid}}[$read_KB_index];
					$write = $write + @{$process_hash{$pid}}[$write_KB_index];
					$time = $time + $diff;
					if ( $pid ne '' ) {
						$count++;
					}
				}
				$percent = sprintf "%5.2f", $time * (100/$current_interval);
				printf  ("$console_summed_output_string",
				"$parsed_date",
				"$parsed_time",
				"$thc",
				"$rss",
				"$time",
				"$percent",
				"$read",
				"$write",
				"$network_in_converted_array[0]",
				"$network_out_converted_array[0]",
				"$network_in_converted_array[1]",
				"$network_out_converted_array[1]",
				"$network_in_converted_array[2]",
				"$network_out_converted_array[2]",
				"$network_in_converted_array[3]",
				"$network_out_converted_array[3]",
				"$network_in_converted_array[4]",
				"$network_out_converted_array[4]",
				"$disk_df_current_metric_array[0]",
				"$disk_df_current_metric_array[1]",
				"$disk_df_current_metric_array[2]",
				"$disk_df_current_metric_array[3]",
				"$disk_df_current_metric_array[4]",
				"$disk_reported_metric_array[0]",
				"$disk_reported_metric_array[1]",
				"$disk_reported_metric_array[2]",
				"$disk_reported_metric_array[3]",
				"$disk_reported_metric_array[4]",
				"$disk_reported_metric_array[5]",
				"$disk_reported_metric_array[6]",
				"$disk_reported_metric_array[7]",
				"$disk_read_KBs",
				"$disk_write_KBs",
				"$active_mem",
				"$swap_mem",
				"$total_cpu",
				"sum of $count processes");
				
			}
			
			else { #Default, print output for individual processes
				my $count = 0 ;
				my %command_placement_hash = ();
				for my $pid (@pid_array) {
					my $temp_code = @{$process_hash{$pid}}[$used_code_index];
					my $temp_place = $prod_code_hash{$temp_code}[$prod_code_order_index];
					debug ( 38 , "$pid, $temp_code, $temp_place");
					$command_placement_hash{$pid} = $temp_place
				}
				
	#			foreach my $pid (sort { $command_placement_hash {$a} <=> $command_placement_hash {$b}} keys %command_placement_hash ){
	#				debug ( 38 , "$pid, $command_placement_hash{$pid}");
	#			}
				
				#for my $pid (@pid_array) {
				foreach my $pid (sort { $command_placement_hash {$a} <=> $command_placement_hash {$b}} keys %command_placement_hash ){
					my $read_KB = @{$process_hash{$pid}}[$read_KB_index];
					my $write_KB = @{$process_hash{$pid}}[$write_KB_index];
					if ( !$read_KB ) { $read_KB=0; }
					if ( !$write_KB ) { $write_KB=0; }
					printf  ("$console_individual_processes_output_string",
					"$parsed_date",
					"$parsed_time",
					"$pid",
					#"@{$process_hash{$pid}}[$ppid_index]",
					"@{$process_hash{$pid}}[$thcnt_index]",
					#"@{$process_hash{$pid}}[$vsz_index]",
					"@{$process_hash{$pid}}[$rss_index]",
					"@{$process_hash{$pid}}[$etime_index]",
					"@{$process_hash{$pid}}[$cpu_time_index]",
					"@{$process_hash{$pid}}[$cpu_seconds_index]",
					"@{$process_hash{$pid}}[$cpu_percent_index]",
					"$read_KB",
					"$write_KB",
					"$network_in_converted_array[0]",
					"$network_out_converted_array[0]",
					"$network_in_converted_array[1]",
					"$network_out_converted_array[1]",
					"$network_in_converted_array[2]",
					"$network_out_converted_array[2]",
					"$network_in_converted_array[3]",
					"$network_out_converted_array[3]",
					"$network_in_converted_array[4]",
					"$network_out_converted_array[4]",
					"$disk_df_current_metric_array[0]",
					"$disk_df_current_metric_array[1]",
					"$disk_df_current_metric_array[2]",
					"$disk_df_current_metric_array[3]",
					"$disk_df_current_metric_array[4]",
					"$disk_reported_metric_array[0]",
					"$disk_reported_metric_array[1]",
					"$disk_reported_metric_array[2]",
					"$disk_reported_metric_array[3]",
					"$disk_reported_metric_array[4]",
					"$disk_reported_metric_array[5]",
					"$disk_reported_metric_array[6]",
					"$disk_reported_metric_array[7]",
					"$active_mem",
					"$swap_mem",
					"$total_cpu",
					"@{$process_hash{$pid}}[$short_command_index]");
					$count++;
				}
			}
			STORE_AVERAGES();
		}
		elsif ( $hp ) {
			debug ( 0 , "No HP support yet");
		} 
		else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
	} else {
		debug ( 1 , "skiping because no disk dir sizes");
	}
}
sub STORE_AVERAGES {
	
	my $mod = $average_count % $averages_interval;
	
	#Store per process information
	for my $pid (@pid_array) { 
		my $command = @{$process_hash{$pid}}[$short_command_index]; #$pid
		@{$processes_averages_hash{$command}}[$averages_count_index]	+= 1 ;
		@{$processes_averages_hash{$command}}[$avg_short_cmd_index] 	= @{$process_hash{$pid}}[$short_command_index];
		@{$processes_averages_hash{$command}}[$avg_used_code_index] 	= @{$process_hash{$pid}}[$used_code_index];
		
		my @index_array = ($thcnt_index, $vsz_index, $rss_index, $cpu_seconds_index, $read_KB_index, $write_KB_index);
		for my $index (@index_array) {
			if ( $average_count == 0 ) {
				@{${processes_averages_hash{$command}}[$index]}[$first_index]	= @{$process_hash{$pid}}[$index];
			}
			@{${processes_averages_hash{$command}}[$index]}[$last_index]		= @{$process_hash{$pid}}[$index];
			
			@{${processes_averages_hash{$command}}[$index]}[$sum_index]			+= @{$process_hash{$pid}}[$index];
			if ( @{${processes_averages_hash{$command}}[$index]}[$min_index] > @{$process_hash{$pid}}[$index] || @{${processes_averages_hash{$command}}[$index]}[$min_index] == "") {
				@{${processes_averages_hash{$command}}[$index]}[$min_index]		= @{$process_hash{$pid}}[$index];
			}
			if ( @{${processes_averages_hash{$command}}[$index]}[$max_index] < @{$process_hash{$pid}}[$index] ) {
				@{${processes_averages_hash{$command}}[$index]}[$max_index]		= @{$process_hash{$pid}}[$index];
			}
		}
		
		if ( $averages_interval > 0 ) { #Store CPU/Disk averages by interval (such as prefetch every 5 minutes)
			@{${process_interval_averages_hash{$command}}[$cpu_seconds_index]}[$mod] 	+= @{$process_hash{$pid}}[$cpu_seconds_index];
			@{${process_interval_averages_hash{$command}}[$read_KB_index]}[$mod] 		+= @{$process_hash{$pid}}[$read_KB_index];
			@{${process_interval_averages_hash{$command}}[$write_KB_index]}[$mod] 		+= @{$process_hash{$pid}}[$write_KB_index];
			
			@{${process_interval_averages_hash{$command}}[$averages_count_index]}[$mod] += 1 ;
			debug ( 25 , "$mod @{${process_interval_averages_hash{$command}}[$averages_count_index]}[$mod] $command");
		}
	}
	
	#Store network information
	for my $nic_name (@requested_network_names_array){
		my $network_in = $network_in_converted_hash{$nic_name};
		my $network_out = $network_out_converted_hash{$nic_name};
		debug ( 23 , "Storing averages values for $nic_name: in $network_in out $network_out");
		
		my @values_array = ($network_in, $network_out);
		my @index_array = ($network_in_index, $network_out_index);
		
		@{${network_interval_averages_hash{$nic_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		for my $i (0 .. $#index_array) {
			my $index = $index_array[$i];
			my $value = $values_array[$i];
			if ( $average_count == 0 ) {
				@{${network_averages_hash{$nic_name}}[$index]}[$first_index]	= $value;
			}
			#@{${network_averages_hash{$nic_name}}[$index]}[$last_index]			= $value;
			
			@{${network_averages_hash{$nic_name}}[$index]}[$sum_index]			+= $value;
			if ( @{${network_averages_hash{$nic_name}}[$index]}[$min_index] > $value || @{${network_averages_hash{$nic_name}}[$index]}[$min_index] == "") {
				@{${network_averages_hash{$nic_name}}[$index]}[$min_index]		= $value;
			}
			if ( @{${network_averages_hash{$nic_name}}[$index]}[$max_index] < $value ) {
				@{${network_averages_hash{$nic_name}}[$index]}[$max_index]		= $value;
			}
			if ( $averages_interval > 0 ) { #Store network averages by interval (such as prefetch every 5 minutes)
				@{${network_interval_averages_hash{$nic_name}}[$index]}[$mod] 	+= $value;
				debug ( 23 , "mod[$mod][@{${network_interval_averages_hash{$nic_name}}[$averages_count_index]}[$mod]] value $value");
			}
		}
	}
	
	#Stores disk utilization averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_util_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_util_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_util_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_util_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_util_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_util_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_util_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_util_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_util_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_util_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_util_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}
	
	#Stores disk tps averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_tps_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_tps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_tps_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_tps_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_tps_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_tps_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_tps_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_tps_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_tps_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_tps_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_tps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}

	#Stores disk rps averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_rps_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_rps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_rps_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_rps_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_rps_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_rps_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_rps_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_rps_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_rps_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_rps_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_rps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}

	#Stores disk wps averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_wps_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_wps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_wps_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_wps_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_wps_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_wps_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_wps_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_wps_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_wps_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_wps_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_wps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}

	#Stores disk await averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_await_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_await_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_await_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_await_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_await_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_await_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_await_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_await_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_await_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_await_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_await_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}

	#Stores disk svctm averages
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $value = $disk_svctm_percent_hash{$disk_metric_name};
		my $index = 0;
		debug ( 34 , "Storing averages values for $disk_metric_name: $value%" );
		
		@{${disk_svctm_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		#$disk_svctm_averages_hash{$disk_metric_name}[$last_index]		= $value;
		
		$disk_svctm_averages_hash{$disk_metric_name}[$sum_index]			+= $value;
		if ( $disk_svctm_averages_hash{$disk_metric_name}[$min_index] > $value || $disk_svctm_averages_hash{$disk_metric_name}[$min_index] == "") {
			$disk_svctm_averages_hash{$disk_metric_name}[$min_index]		= $value;
		}
		if ( $disk_svctm_averages_hash{$disk_metric_name}[$max_index] < $value ) {
			$disk_svctm_averages_hash{$disk_metric_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_svctm_interval_averages_hash{$disk_metric_name}}[$index]}[$mod] 	+= $value ;
			debug ( 34 , "mod[$mod][@{${disk_svctm_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}
	
	#Stores disk space % usage averages
	for my $disk_df_name (@requested_disk_df_names_array){
		my $value = $disk_df_percent_hash{$disk_df_name};
		my $index = 0;
		debug ( 35 , "Storing averages values for $disk_df_name: $value%" );
		
		@{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		if ( $average_count == 0 ) {
			$disk_df_percent_averages_hash{$disk_df_name}[$first_index]			 = $value
		}
		$disk_df_percent_averages_hash{$disk_df_name}[$last_index]			 = $value;
		
		$disk_df_percent_averages_hash{$disk_df_name}[$sum_index]			+= $value;
		if ( $disk_df_percent_averages_hash{$disk_df_name}[$min_index] > $value || $disk_df_percent_averages_hash{$disk_df_name}[$min_index] == "") {
			$disk_df_percent_averages_hash{$disk_df_name}[$min_index]		= $value;
		}
		if ( $disk_df_percent_averages_hash{$disk_df_name}[$max_index] < $value ) {
			$disk_df_percent_averages_hash{$disk_df_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$index]}[$mod] 	+= $value ;
			debug ( 35 , "mod[$mod][@{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}	
	
	#Stores disk space used averages
	for my $disk_df_name (@requested_disk_df_names_array){
		my $value = $disk_df_used_hash{$disk_df_name};
		my $index = 0;
		debug ( 35 , "Storing averages values for $disk_df_name: $value" );
		
		@{${disk_df_used_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		if ( $average_count == 0 ) {
			$disk_df_used_averages_hash{$disk_df_name}[$first_index]			 = $value
		}
		$disk_df_used_averages_hash{$disk_df_name}[$last_index]			 = $value;
		
		$disk_df_used_averages_hash{$disk_df_name}[$sum_index]			+= $value;
		if ( $disk_df_used_averages_hash{$disk_df_name}[$min_index] > $value || $disk_df_used_averages_hash{$disk_df_name}[$min_index] == "") {
			$disk_df_used_averages_hash{$disk_df_name}[$min_index]		= $value;
		}
		if ( $disk_df_used_averages_hash{$disk_df_name}[$max_index] < $value ) {
			$disk_df_used_averages_hash{$disk_df_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_df_used_interval_averages_hash{$disk_df_name}}[$index]}[$mod] 	+= $value ;
			debug ( 35 , "mod[$mod][@{${disk_df_used_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}	
	
	#Stores disk space free averages
	for my $disk_df_name (@requested_disk_df_names_array){
		my $value = $disk_df_free_hash{$disk_df_name};
		my $index = 0;
		debug ( 35 , "Storing averages values for $disk_df_name: $value" );
		
		@{${disk_df_free_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		if ( $average_count == 0 ) {
			$disk_df_free_averages_hash{$disk_df_name}[$first_index]			 = $value
		}
		$disk_df_free_averages_hash{$disk_df_name}[$last_index]			 = $value;
		
		$disk_df_free_averages_hash{$disk_df_name}[$sum_index]			+= $value;
		if ( $disk_df_free_averages_hash{$disk_df_name}[$min_index] > $value || $disk_df_free_averages_hash{$disk_df_name}[$min_index] == "") {
			$disk_df_free_averages_hash{$disk_df_name}[$min_index]		= $value;
		}
		if ( $disk_df_free_averages_hash{$disk_df_name}[$max_index] < $value ) {
			$disk_df_free_averages_hash{$disk_df_name}[$max_index]		= $value;
		}
		if ( $averages_interval > 0 ) { #Store disk averages by interval (such as prefetch every 5 minutes)
			@{${disk_df_free_interval_averages_hash{$disk_df_name}}[$index]}[$mod] 	+= $value ;
			debug ( 35 , "mod[$mod][@{${disk_df_free_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$mod]] value $value");
		}
	}	
			
	#Stores dir size averages
	foreach my $du_dir_name (keys %disk_du_size_hash) { 
		my $value = $disk_du_size_hash{$du_dir_name};
		debug ( 39 , "Storing averages values for $du_dir_name: $value" );
				
		$disk_du_interval_averages_hash{$du_dir_name}[$du_count_index] 	+= 1 ;
		@{${disk_du_interval_averages_hash{$du_dir_name}}[$averages_count_index]}[$mod] 	+= 1 ;
		
		if ( $average_count == 0 ) {
			$disk_du_averages_hash{$du_dir_name}[$first_index]			 = $value;
		}
		$disk_du_averages_hash{$du_dir_name}[$last_index]			 = $value;
		
		$disk_du_averages_hash{$du_dir_name}[$sum_index]			+= $value;
		if ( $disk_du_averages_hash{$du_dir_name}[$min_index] > $value || $disk_du_averages_hash{$du_dir_name}[$min_index] == "") {
			$disk_du_averages_hash{$du_dir_name}[$min_index]		= $value;
		}
		if ( $disk_du_averages_hash{$du_dir_name}[$max_index] < $value ) {
			$disk_du_averages_hash{$du_dir_name}[$max_index]		= $value;
		}
	}		
	
	#Store Overall System information
	if ( $average_count == 0 ) {
		$first_average_timestamp="$parsed_date.$parsed_time";
	}
	$last_average_timestamp="$parsed_date.$parsed_time";
	my @values_array = ($active_mem, $swap_mem, $total_cpu);
	my @index_array = ($active_mem_index, $swap_mem_index, $total_cpu_index);
	for my $i (0 .. $#index_array) {
		my $index = $index_array[$i];
		my $value = $values_array[$i];
		if ( $average_count == 0 ) {
			$system_averages[$index][$first_index]		= $value;
		}
		$system_averages[$index][$last_index]			= $value;
		
		$system_averages[$index][$sum_index]			+= $value;
		if ( $system_averages[$index][$min_index] > $value || $system_averages[$index][$min_index] == "") {
			$system_averages[$index][$min_index]		= $value;
		}
		if ( $system_averages[$index][$max_index] < $value) {
			$system_averages[$index][$max_index]		= $value;
		}
		
	}
	
	if ( $averages_interval > 0 ) { #Store CPU averages by interval (such as prefetch every 5 minutes)
		my $mod = $average_count % $averages_interval;
		$system_interval_averages[$total_cpu_index][$mod] 	+= $total_cpu;
		$system_interval_averages[$averages_count_index][$mod] 	+= 1;
	}
	$average_count++;
}
sub PRINT_SUMMARY_TO_CONSOLE {
	my $desc_size = ${COMMAND_MAX_LENGTH}+20;
	if ( $desc_size < 60 ) {
		$desc_size = 60;
	}
	
	my $hostname_length = length($hostname)+3;
	my $number_size = 12.2;
	my $number_size_intervals = 10.2;
	my $string_size = 12;
	my $string_size_intervals = 10;
	my $summary_string_size_short							= "%${desc_size}s,%${hostname_length}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,\n";
	my $summary_string_size									= "%${desc_size}s,%${hostname_length}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size}s,%${string_size_intervals}s,%${string_size_intervals}s,%${string_size_intervals}s,%${string_size_intervals}s,%${string_size_intervals}s,\n";
	my $summary_formatted_with_first_last_change			= "%${desc_size}s,%${hostname_length}s,%${number_size}d,%${number_size}d,%${number_size}d,%${number_size}d,%${number_size}d,%${number_size}d,";
	my $summary_formatted_without_first_last_change			= "%${desc_size}s,%${hostname_length}s,%${number_size}d,%${number_size}d,%${number_size}d,%${string_size}s,%${string_size}s,%${string_size}s,";
	my $summary_formatted_without_first_last_change_float	= "%${desc_size}s,%${hostname_length}s,%${number_size}f,%${number_size}f,%${number_size}f,%${string_size}s,%${string_size}s,%${string_size}s,";
	
	print "-" x $cols;
	println ("");
	println ("${header} Interval (Int.) is $read_interval seconds.");
	println ("Summary of $average_count intervals from $first_average_timestamp to $last_average_timestamp.\n");
	if ( $average_count < $averages_interval ) {
		$averages_interval=0;
	}
	if ( $averages_interval > 0 ) {
		$summary_header_string = sprintf "$summary_string_size", "Process", "Host", "Average", "Min", "Max", "First", "Last", "Change", "Min 1 Avg", "Min 2 Avg", "Min 3 Avg", "Min 4 Avg", "Min 5 Avg";
	} else {
		$summary_header_string = sprintf "$summary_string_size_short", "Process", "Host", "Average", "Min", "Max", "First", "Last", "Change";	
	}
	my $system_string = "";
	my $threads_string = "";
	my $vsz_string = "";
	my $rss_string = "";
	my $diskReads_string = "";
	my $diskWrites_string = "";
	my $CPUsec_string = "";
	my $CPUpercent_string = "";
	
	
	println ("");
	if ( $average_count == 0 ) { 
		$average_count = 1;
	}
	$system_string = sprintf "$system_string$summary_formatted_with_first_last_change\n",
		"Active Memory (MB)",
		$hostname,
		$system_averages[$active_mem_index][$sum_index]	/ $average_count,
		$system_averages[$active_mem_index][$min_index],
		$system_averages[$active_mem_index][$max_index],
		$system_averages[$active_mem_index][$first_index],
		$system_averages[$active_mem_index][$last_index],
		$system_averages[$active_mem_index][$last_index]-$system_averages[$active_mem_index][$first_index];
	$system_string = sprintf "$system_string$summary_formatted_with_first_last_change\n",
		"SWAP Memory (MB)",
		$hostname,
		$system_averages[$swap_mem_index][$sum_index]	/ $average_count,
		$system_averages[$swap_mem_index][$min_index],
		$system_averages[$swap_mem_index][$max_index],
		$system_averages[$swap_mem_index][$first_index],
		$system_averages[$swap_mem_index][$last_index],
		$system_averages[$swap_mem_index][$last_index]-$system_averages[$swap_mem_index][$first_index];
		
	$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
		"Total System Wide CPU Sec/Int. (Out of $max_CPU_seconds sec)",
		$hostname,
		($system_averages[$total_cpu_index][$sum_index]	/ $average_count ) * 0.6,
		($system_averages[$total_cpu_index][$min_index] ) * 0.6,
		($system_averages[$total_cpu_index][$max_index] ) * 0.6,
		"-","-","-",;
	#$system_string = sprintf "$system_string";
	for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
		$system_string = sprintf "$system_string%${number_size_intervals}d,", ($system_interval_averages[$total_cpu_index][$x]/$system_interval_averages[$averages_count_index][$x] ) * 0.6; 
	}  	
	$system_string = sprintf "$system_string\n";
	
	$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
		"Total System Wide CPU Core %/Int. (Out of $max_CPU_percent%)",
		$hostname,
		($system_averages[$total_cpu_index][$sum_index]	/ $average_count),
		($system_averages[$total_cpu_index][$min_index]),
		($system_averages[$total_cpu_index][$max_index]),
		"-","-","-",;
	for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
		$system_string = sprintf "$system_string%${number_size_intervals}d,", ($system_interval_averages[$total_cpu_index][$x]/$system_interval_averages[$averages_count_index][$x]); 
	}  
	$system_string = sprintf "$system_string\n";
	
	$nework_multiplier=1;
	for my $nic_name (@requested_network_names_array){		
		my @values_array = ("$network_scale Rx", "$network_scale TX");
		my @index_array = ($network_in_index, $network_out_index);
		for my $x (0 .. $#index_array) {
			my $index = $index_array[$x];
			$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
				"$nic_name $values_array[$x]",
				$hostname,
				(@{${network_averages_hash{$nic_name}}[$index]}[$sum_index]	/ $average_count),
				(@{${network_averages_hash{$nic_name}}[$index]}[$min_index]),
				(@{${network_averages_hash{$nic_name}}[$index]}[$max_index]),
				"-","-","-",;
			for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
				$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${network_interval_averages_hash{$nic_name}}[$index]}[$x]/@{${network_interval_averages_hash{$nic_name}}[$averages_count_index]}[$x]); 
			}  
			$system_string = sprintf "$system_string\n";
		}
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name percent util",
			$hostname,
			${disk_util_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_util_averages_hash{$disk_metric_name}}[$min_index],
			${disk_util_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_util_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_util_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name tps",
			$hostname,
			${disk_tps_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_tps_averages_hash{$disk_metric_name}}[$min_index],
			${disk_tps_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_tps_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_tps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name rps",
			$hostname,
			${disk_rps_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_rps_averages_hash{$disk_metric_name}}[$min_index],
			${disk_rps_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_rps_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_rps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name wps",
			$hostname,
			${disk_wps_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_wps_averages_hash{$disk_metric_name}}[$min_index],
			${disk_wps_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_wps_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_wps_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name await",
			$hostname,
			${disk_await_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_await_averages_hash{$disk_metric_name}}[$min_index],
			${disk_await_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_await_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_await_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_metric_name (@requested_disk_metric_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change",
			"$disk_metric_name svctm",
			$hostname,
			${disk_svctm_averages_hash{$disk_metric_name}}[$sum_index]	/ $average_count,
			${disk_svctm_averages_hash{$disk_metric_name}}[$min_index],
			${disk_svctm_averages_hash{$disk_metric_name}}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_svctm_interval_averages_hash{$disk_metric_name}}[$index]}[$x]/@{${disk_svctm_interval_averages_hash{$disk_metric_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_df_name (@requested_disk_df_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_with_first_last_change",
			"$disk_df_name percent space",
			$hostname,
			${disk_df_percent_averages_hash{$disk_df_name}}[$sum_index]	/ $average_count,
			${disk_df_percent_averages_hash{$disk_df_name}}[$min_index],
			${disk_df_percent_averages_hash{$disk_df_name}}[$max_index],
			${disk_df_percent_averages_hash{$disk_df_name}}[$first_index],
			${disk_df_percent_averages_hash{$disk_df_name}}[$last_index],
			${disk_df_percent_averages_hash{$disk_df_name}}[$last_index]-${disk_df_percent_averages_hash{$disk_df_name}}[$first_index];
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			debug ( 35 , "sum: @{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$index]}[$x] / intervals @{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]" );
			$system_string = sprintf "$system_string%${number_size_intervals}d,", (@{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$index]}[$x]/@{${disk_df_percent_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}	
	
	for my $disk_df_name (@requested_disk_df_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_with_first_last_change",
			"$disk_df_name used space (MB)",
			$hostname,
			${disk_df_used_averages_hash{$disk_df_name}}[$sum_index]	/ $average_count,
			${disk_df_used_averages_hash{$disk_df_name}}[$min_index],
			${disk_df_used_averages_hash{$disk_df_name}}[$max_index],
			${disk_df_used_averages_hash{$disk_df_name}}[$first_index],
			${disk_df_used_averages_hash{$disk_df_name}}[$last_index],
			${disk_df_used_averages_hash{$disk_df_name}}[$last_index]-${disk_df_used_averages_hash{$disk_df_name}}[$first_index];
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			debug ( 35 , "sum: @{${disk_df_used_interval_averages_hash{$disk_df_name}}[$index]}[$x] / intervals @{${disk_df_used_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]" );
			$system_string = sprintf "$system_string%${string_size_intervals}d,", (@{${disk_df_used_interval_averages_hash{$disk_df_name}}[$index]}[$x]/@{${disk_df_used_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
	
	for my $disk_df_name (@requested_disk_df_names_array){
		my $index = 0;
		$system_string = sprintf "$system_string$summary_formatted_with_first_last_change",
			"$disk_df_name free space (MB)",
			$hostname,
			${disk_df_free_averages_hash{$disk_df_name}}[$sum_index]	/ $average_count,
			${disk_df_free_averages_hash{$disk_df_name}}[$min_index],
			${disk_df_free_averages_hash{$disk_df_name}}[$max_index],
			${disk_df_free_averages_hash{$disk_df_name}}[$first_index],
			${disk_df_free_averages_hash{$disk_df_name}}[$last_index],
			${disk_df_free_averages_hash{$disk_df_name}}[$last_index]-${disk_df_free_averages_hash{$disk_df_name}}[$first_index];
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			debug ( 35 , "sum: @{${disk_df_free_interval_averages_hash{$disk_df_name}}[$index]}[$x] / intervals @{${disk_df_free_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]" );
			$system_string = sprintf "$system_string%${string_size_intervals}d,", (@{${disk_df_free_interval_averages_hash{$disk_df_name}}[$index]}[$x]/@{${disk_df_free_interval_averages_hash{$disk_df_name}}[$averages_count_index]}[$x]); 
		}  
		$system_string = sprintf "$system_string\n";
	}
			
	foreach my $du_dir_name (keys %disk_du_averages_hash) { 
		my $index = 0;
		debug ( 39 , "$du_dir_name " );
		$system_string = sprintf "$system_string$summary_formatted_without_first_last_change\n",
			"$du_dir_name  dir size",
			$hostname,
			${disk_du_averages_hash{$du_dir_name}}[$sum_index]	/ $disk_du_interval_averages_hash{$du_dir_name}[$du_count_index],
			${disk_du_averages_hash{$du_dir_name}}[$min_index],
			${disk_du_averages_hash{$du_dir_name}}[$max_index],
			${disk_du_averages_hash{$du_dir_name}}[$first_index],
			${disk_du_averages_hash{$du_dir_name}}[$last_index],
			${disk_du_averages_hash{$du_dir_name}}[$last_index]-${disk_du_averages_hash{$du_dir_name}}[$first_index];
		$system_string = sprintf "$system_string";
		
	}
	
	debug ( 23 , "average_count $average_count");
	
	
	my %command_placement_hash = ();
	while ( my( $command, $value ) = each %processes_averages_hash ) {
		my $temp_code = @{$processes_averages_hash{$command}}[$avg_used_code_index];
		my $temp_place = $prod_code_hash{$temp_code}[$prod_code_order_index];
		debug ( 38 , "$command, $temp_code, $temp_place,");
		$command_placement_hash{$command} = $temp_place
	}
#	while( my( $key, $value ) = each %command_placement_hash ){
#		print "$key: $value\n";
#	}	
#	foreach my $pid (keys(%processes_averages_hash)) {
	foreach my $command (sort { $command_placement_hash {$a} <=> $command_placement_hash {$b}} keys %command_placement_hash ){
		#print "Printing command: $command\n";
		#next if $command == "";
		my $CPU_interval = 60 / $read_interval;
		
		my $threads = sprintf "$summary_formatted_with_first_last_change",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] Threads",
			$hostname,
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$min_index],
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$max_index],
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$first_index],
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$last_index],
			@{${processes_averages_hash{$command}}[$thcnt_index]}[$last_index]-@{$processes_averages_hash{$command}[$thcnt_index]}[$first_index];
		#printf "$threads";
		$threads_string = "$threads_string$threads\n";
		my $vsz = sprintf "$summary_formatted_with_first_last_change",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] VSZ (KB)",
			$hostname,
			@{${processes_averages_hash{$command}}[$vsz_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			@{${processes_averages_hash{$command}}[$vsz_index]}[$min_index],
			@{${processes_averages_hash{$command}}[$vsz_index]}[$max_index],
			@{${processes_averages_hash{$command}}[$vsz_index]}[$first_index],
			@{${processes_averages_hash{$command}}[$vsz_index]}[$last_index],
			@{${processes_averages_hash{$command}}[$vsz_index]}[$last_index]-@{${processes_averages_hash{$command}}[$vsz_index]}[$first_index];
		#printf "$vsz";
		$vsz_string = "$vsz_string$vsz\n";
		my $rss = sprintf "$summary_formatted_with_first_last_change",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] RSS (KB)",
			$hostname,
			@{${processes_averages_hash{$command}}[$rss_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			@{${processes_averages_hash{$command}}[$rss_index]}[$min_index],
			@{${processes_averages_hash{$command}}[$rss_index]}[$max_index],
			@{${processes_averages_hash{$command}}[$rss_index]}[$first_index],
			@{${processes_averages_hash{$command}}[$rss_index]}[$last_index],
			@{${processes_averages_hash{$command}}[$rss_index]}[$last_index]-@{${processes_averages_hash{$command}}[$rss_index]}[$first_index];
		#printf "$rss";
		$rss_string = "$rss_string$rss\n";
	
		#CPUSec
		my $CPUsec = sprintf "$summary_formatted_without_first_last_change_float",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] CPU Sec/Int. (Out of $max_CPU_seconds sec)",
			$hostname,
			$CPU_interval * @{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			$CPU_interval * @{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$min_index],
			$CPU_interval * @{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){
			my $divide = @{${process_interval_averages_hash{$command}}[$averages_count_index]}[$x];
			debug ( 25 , "@{$processes_averages_hash{$command}}[$avg_short_cmd_index] $divide" );
			if ( $divide != 0 ) {
				$CPUsec = sprintf "$CPUsec%${number_size_intervals}d,", $CPU_interval * @{${process_interval_averages_hash{$command}}[$cpu_seconds_index]}[$x]/$divide; 
			} else {
				$CPUsec = sprintf "$CPUsec%${string_size_intervals}s,", "0 err";
			}
		}
		$CPUsec = sprintf "$CPUsec\n";
		#printf "$CPUsec";
		$CPUsec_string = "$CPUsec_string$CPUsec";
		
		#CPUpercent
		my $CPUpercent = sprintf "$summary_formatted_without_first_last_change_float",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] CPU Core %/Int. (Out of $max_CPU_percent%)",
			$hostname,
			$CPU_interval * (@{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index])/0.6,
			$CPU_interval * (@{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$min_index])/0.6,
			$CPU_interval * (@{${processes_averages_hash{$command}}[$cpu_seconds_index]}[$max_index])/0.6,
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){ 
			my $divide = @{${process_interval_averages_hash{$command}}[$averages_count_index]}[$x];
			debug ( 25 , "@{$processes_averages_hash{$command}}[$avg_short_cmd_index] $divide" );
			if ( $divide != 0 ) {
				$CPUpercent = sprintf "$CPUpercent%${number_size_intervals}d,", $CPU_interval * @{${process_interval_averages_hash{$command}}[$cpu_seconds_index]}[$x]/$divide/0.6; 
			} else {
				$CPUpercent = sprintf "$CPUpercent%${string_size_intervals}s,", "0 err";
			}
		}
		$CPUpercent = sprintf "$CPUpercent\n";
		#printf "$CPUpercent";
		$CPUpercent_string = "$CPUpercent_string$CPUpercent";
		
		#diskReads
		my $diskReads = sprintf "$summary_formatted_without_first_last_change",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] Disk Reads (KB)",
			$hostname,
			@{${processes_averages_hash{$command}}[$read_KB_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			@{${processes_averages_hash{$command}}[$read_KB_index]}[$min_index],
			@{${processes_averages_hash{$command}}[$read_KB_index]}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){
			my $divide = @{${process_interval_averages_hash{$command}}[$averages_count_index]}[$x];
			debug ( 25 , "@{$processes_averages_hash{$command}}[$avg_short_cmd_index] $divide" );
			if ( $divide != 0 ) {
				$diskReads = sprintf("$diskReads%${number_size_intervals}d,", $CPU_interval * @{${process_interval_averages_hash{$command}}[$read_KB_index]}[$x]/$divide); 
			} else {
				$diskReads = sprintf("$diskReads%${string_size_intervals}s,", "0 err");
			}
		}
		$diskReads = sprintf("$diskReads\n");
		#printf "$diskReads";
		$diskReads_string = "$diskReads_string$diskReads";
		
		#diskWrites
		my $diskWrites = sprintf "$summary_formatted_without_first_last_change",
			"@{$processes_averages_hash{$command}}[$avg_short_cmd_index] Disk Writes (KB)",
			$hostname,
			@{${processes_averages_hash{$command}}[$write_KB_index]}[$sum_index]	/ @{$processes_averages_hash{$command}}[$averages_count_index],
			@{${processes_averages_hash{$command}}[$write_KB_index]}[$min_index],
			@{${processes_averages_hash{$command}}[$write_KB_index]}[$max_index],
			"-","-","-",;
		for ( my $x = 0 ; $x < $averages_interval ; $x++ ){
			my $divide = @{${process_interval_averages_hash{$command}}[$averages_count_index]}[$x];
			debug ( 25 , "@{$processes_averages_hash{$command}}[$avg_short_cmd_index] $divide" );
			if ( $divide != 0 ) {
				$diskWrites = sprintf  ("$diskWrites%${number_size_intervals}d,", $CPU_interval * @{${process_interval_averages_hash{$command}}[$write_KB_index]}[$x]/$divide); 
			} else {
				$diskWrites = sprintf  ("$diskWrites%${string_size_intervals}s,", "0 err");
			}
		}
		$diskWrites = sprintf  ("$diskWrites\n");
		#printf "$diskWrites";
		$diskWrites_string = "$diskWrites_string$diskWrites";
		
		#println ("");
	}
	
	printf ("$summary_header_string\n$system_string\n$threads_string\n$rss_string\n$CPUsec_string\n$CPUpercent_string\n$diskReads_string\n$diskWrites_string\n");
	
	if ( $csv_output ) {
	
		if ( $csv_summary_output_file_name eq "" ) {
			$csv_summary_output_file_name	= "$hostname.$OSCODE.$actual_console_start_datetime.$csv_file_line_count.summary.perfdata.csv";
		}
		$csv_summary_output_file		= "$csv_output_dir/$csv_summary_output_file_name";

		debug ( 0 , "Sending CSV Summary output to $csv_summary_output_file" );
		open (CSV_SUMMARY_FILE, ">", "$csv_summary_output_file" ) or die $!;
		
		$summary_header_string=~s/^[ \t]*//g;
		$system_string=~s/^[ \t]*//g;
		$threads_string=~s/^[ \t]*//g;
		$rss_string=~s/^[ \t]*//g;
		$CPUsec_string=~s/^[ \t]*//g;
		$CPUpercent_string=~s/^[ \t]*//g;
		$diskReads_string=~s/^[ \t]*//g;
		$diskWrites_string=~s/^[ \t]*//g;
		
		$summary_header_string=~s/\n[ \t]*/\n/g;
		$system_string=~s/\n[ \t]*/\n/g;
		$threads_string=~s/\n[ \t]*/\n/g;
		$rss_string=~s/\n[ \t]*/\n/g;
		$CPUsec_string=~s/\n[ \t]*/\n/g;
		$CPUpercent_string=~s/\n[ \t]*/\n/g;
		$diskReads_string=~s/\n[ \t]*/\n/g;
		$diskWrites_string=~s/\n[ \t]*/\n/g;
		
		$summary_header_string=~s/,[ \t]*/,/g;
		$system_string=~s/,[ \t]*/,/g;
		$threads_string=~s/,[ \t]*/,/g;
		$rss_string=~s/,[ \t]*/,/g;
		$CPUsec_string=~s/,[ \t]*/,/g;
		$CPUpercent_string=~s/,[ \t]*/,/g;
		$diskReads_string=~s/,[ \t]*/,/g;
		$diskWrites_string=~s/,[ \t]*/,/g;
		
		print CSV_SUMMARY_FILE "$summary_header_string\n$system_string\n$threads_string\n$rss_string\n$CPUsec_string\n$CPUpercent_string\n$diskReads_string\n$diskWrites_string\n";
	}	
}

# Print to CSV file
sub SORT_CSV_HEADERS {
	$header_count = keys %prod_code_hash;
	for ( my $i = 1 ; $i< $csv_file_line_count ; $i++ ) {
		my $temp_process_hash = $main_csv_file_array[$i][$process_hash_index];
		my @temp_pid_array = @{$main_csv_file_array[$i][$pid_array_index]};
		for my $pid (@temp_pid_array) {
			my $short_command = $temp_process_hash->{$pid}[$short_command_index];
			if ( $separate_processes eq 1 ) {
				$short_command = "$temp_process_hash->{$pid}[$short_command_index] - $pid";
			}
			if ( ! exists $header_placement_hash{$short_command}) {
				my $full_command = $temp_process_hash->{$pid}[$full_command_index];
				my $temp_code = IDENTIFY_USED_CODE($full_command);				
				if ( $temp_code ) {
					debug( 18, "$pid, $temp_code, \"$short_command\"");
					$header_placement_hash{$short_command} = $prod_code_hash{$temp_code}[$prod_code_order_index];
				} else {
					debug( 18, "Did not find \"$short_command\"");
					$header_placement_hash{$short_command} = $header_count;
					$header_count++;				
				}
			}
		}
	}
	$header_count = 0;
	foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
		$header_placement_hash{$short_command}=$header_count;
		$header_count++;
		debug( 18, "$header_placement_hash{$short_command} $short_command");
	}
}
sub PRINT_CSV_HEADERS {
	my $possible_cpu_perent = $cpu_cores * 100;
	print CSV_FILE "DateStamp ,Time ,Total Disk Reads (KB),Total Disk Writes (KB),Active Memory Used (MB),SWAP Memory Used (MB),User CPU % (out of 100%),System CPU % (out of 100%),IOwait CPU % (out of 100%),Idle CPU % (out of 100%),Total CPU Used % (out of ${possible_cpu_perent}%),";
	for my $NIC_NAME (@requested_network_names_array){
		print CSV_FILE "$NIC_NAME $network_scale RX,$NIC_NAME $network_scale TX,";
	}
	for my $DF_NAME (@requested_disk_df_names_array){
		print CSV_FILE "$DF_NAME Disk Space Used %,";
	}
	for my $DF_NAME (@requested_disk_df_names_array){
		print CSV_FILE "$DF_NAME Disk Space Used (MB),";
	}
	for my $DF_NAME (@requested_disk_df_names_array){
		print CSV_FILE "$DF_NAME Disk Space Free (MB),";
	}
	
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk Utilization %,";		
	}
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk tps,";		
	}
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk rps,";		
	}
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk wps,";		
	}
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk await,";		
	}
	for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
		CONVERT_DEV_MOUNT_LSBLK($requested_disk_metric_names_array[$x], $x);
		$requested_mount_names_array[$x] =~ s/ U%//g;
		print CSV_FILE "$requested_mount_names_array[$x] $requested_disk_metric_names_array[$x] Disk svctm,";		
	}
	foreach my $du_dir_name (sort keys %disk_du_size_hash ) {
		print CSV_FILE "$du_dir_name Dir Size KB,";		
	}
	
	if ( $group_by_process ) {
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command TIME,";
			print CSV_FILE "$short_command RSS,";
			print CSV_FILE "$short_command VSZ,";
			print CSV_FILE "$short_command THCNT,";
			print CSV_FILE "$short_command Disk_KB_Reads,";
			print CSV_FILE "$short_command Disk_KB_Writes,";
		}
	} else {
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command TIME,";
		}
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command RSS,";
		}
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command VSZ,";
		}
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command THCNT,";
		}
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command Disk_KB_Reads,";
		}
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command Disk_KB_Writes,";
		}	
		foreach my $short_command (sort { $header_placement_hash {$a} <=> $header_placement_hash {$b}} keys %header_placement_hash ){
			print CSV_FILE "$short_command Elapse_Time,";
		}	
	}
	print CSV_FILE "\n";
}
sub PRINT_CSV_OUTPUT {

	if ( $csv_output_file_name eq "" ) {
		$csv_output_file_name	= "$hostname.$OSCODE.$actual_console_start_datetime.$csv_file_line_count.perfdata.csv";
	}
	$csv_output_file		= "$csv_output_dir/$csv_output_file_name";
	debug ( 0 , "Sending CSV output to $csv_output_file" );
	open (CSV_FILE, ">", "$csv_output_file" ) or die $!;
	
	$group_by_process=0;
	
	SORT_CSV_HEADERS();
	PRINT_CSV_HEADERS();
	for ( my $index = 0 ; $index < $csv_file_line_count ; $index++ ) {
		my $epoch 				= $main_csv_file_array[$index][$epoch_index];
		my $date				= $main_csv_file_array[$index][$date_index];
		my $time				= $main_csv_file_array[$index][$time_index];
		my @time_chars			= split("", $time);
		my $formatted_time		= "$time_chars[0]$time_chars[1]:$time_chars[2]$time_chars[3]:$time_chars[4]$time_chars[5]";
		my $DateStamp 			= CORE::localtime($epoch);
		#my $disk_util			= $main_csv_file_array[$index][$disk_io_index];
		my $disk_reads			= $main_csv_file_array[$index][$total_disk_read_index];
		my $disk_writes			= $main_csv_file_array[$index][$total_disk_write_index];
		my $active_mem			= $main_csv_file_array[$index][$active_mem_index];
		my $swap_mem			= $main_csv_file_array[$index][$swap_mem_index];
		my $user_cpu			= $main_csv_file_array[$index][$user_cpu_index];
		my $system_cpu			= $main_csv_file_array[$index][$system_cpu_index];
		my $iowait_cpu			= $main_csv_file_array[$index][$iowait_cpu_index];
		my $idle_cpu			= $main_csv_file_array[$index][$idle_cpu_index];
		my $total_cpu			= $main_csv_file_array[$index][$total_cpu_index];
		my $temp_process_hash 	= $main_csv_file_array[$index][$process_hash_index];
		my $network_in_hash 	= $main_csv_file_array[$index][$network_in_hash_index];
		my $network_out_hash 	= $main_csv_file_array[$index][$network_out_hash_index];
		my $disk_df_percent_hash = $main_csv_file_array[$index][$disk_df_percent_index];
		my $disk_df_used_hash 	= $main_csv_file_array[$index][$disk_df_used_index];
		my $disk_df_free_hash 	= $main_csv_file_array[$index][$disk_df_free_index];
		my $disk_util_hash 		= $main_csv_file_array[$index][$disk_util_index];
		my $disk_tps_hash 		= $main_csv_file_array[$index][$disk_tps_index];
		my $disk_rps_hash 		= $main_csv_file_array[$index][$disk_rps_index];
		my $disk_wps_hash 		= $main_csv_file_array[$index][$disk_wps_index];
		my $disk_await_hash 	= $main_csv_file_array[$index][$disk_await_index];
		my $disk_svctm_hash 	= $main_csv_file_array[$index][$disk_svctm_index];
		my $du_hash 			= $main_csv_file_array[$index][$disk_du_index];
		my @temp_pid_array 		= @{$main_csv_file_array[$index][$pid_array_index]};
		
		my $network_in			= $main_csv_file_array[$index][$network_in_hash_index];
		my $network_out			= $main_csv_file_array[$index][$network_out_hash_index];
		
		#$disk_util =~ s/\s*//;
		$disk_reads =~ s/\s*//;
		$disk_writes =~ s/\s*//;
		$active_mem =~ s/\s*//;
		$swap_mem =~ s/\s*//;
		$user_cpu =~ s/\s*//;
		$system_cpu =~ s/\s*//;
		$iowait_cpu =~ s/\s*//;
		$idle_cpu =~ s/\s*//;
		$total_cpu =~ s/\s*//;
		
		my @temp_process_array = ();
		print CSV_FILE "$DateStamp,$formatted_time,$disk_reads,$disk_writes,$active_mem,$swap_mem,$user_cpu,$system_cpu,$iowait_cpu,$idle_cpu,$total_cpu,";
		for my $nic_name (@requested_network_names_array){
			print CSV_FILE "$network_in_hash->{$nic_name},$network_out_hash->{$nic_name},";
		}
		for my $disk_df_name (@requested_disk_df_names_array){
			my $temp_disk_df = $disk_df_percent_hash->{$disk_df_name};
			$temp_disk_df =~ s/^\s+//;
			print CSV_FILE "$temp_disk_df,";
		}
		for my $disk_df_name (@requested_disk_df_names_array){
			my $temp_disk_df = $disk_df_used_hash->{$disk_df_name};
			$temp_disk_df =~ s/^\s+//;
			print CSV_FILE "$temp_disk_df,";
		}
		for my $disk_df_name (@requested_disk_df_names_array){
			my $temp_disk_df = $disk_df_free_hash->{$disk_df_name};
			$temp_disk_df =~ s/^\s+//;
			print CSV_FILE "$temp_disk_df,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_util = $disk_util_hash->{$disk_metric_name};
			$temp_disk_util =~ s/^\s+//;
			print CSV_FILE "$temp_disk_util,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_tps = $disk_tps_hash->{$disk_metric_name};
			$temp_disk_tps =~ s/^\s+//;
			print CSV_FILE "$temp_disk_tps,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_rps = $disk_rps_hash->{$disk_metric_name};
			$temp_disk_rps =~ s/^\s+//;
			print CSV_FILE "$temp_disk_rps,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_wps = $disk_wps_hash->{$disk_metric_name};
			$temp_disk_wps =~ s/^\s+//;
			print CSV_FILE "$temp_disk_wps,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_await = $disk_await_hash->{$disk_metric_name};
			$temp_disk_await =~ s/^\s+//;
			print CSV_FILE "$temp_disk_await,";
		}
		for ( my $x=0 ; $x < $#requested_disk_metric_names_array+1 ; $x ++) {
			my $disk_metric_name = $requested_disk_metric_names_array[$x];
			my $temp_disk_svctm = $disk_svctm_hash->{$disk_metric_name};
			$temp_disk_svctm =~ s/^\s+//;
			print CSV_FILE "$temp_disk_svctm,";
		}
		foreach my $du_dir_name (sort keys %disk_du_size_hash ) {
			$du_dir_value = $du_hash->{$du_dir_name};
			$du_dir_value =~ s/^\s+//;
			printf CSV_FILE "%.3f,", $du_dir_value;
		}
	
		
		my $number_of_process_attributes = 7;
		for my $pid (@temp_pid_array) {
			my $short_command = $temp_process_hash->{$pid}[$short_command_index];
			if ( $separate_processes eq 1 ) {
				$short_command = "$temp_process_hash->{$pid}[$short_command_index] - $pid";
			}
			my $place = $header_placement_hash{$short_command};
			
			my $time 		= $temp_process_hash->{$pid}[$cpu_seconds_index];
			my $rss 		= $temp_process_hash->{$pid}[$rss_index];
			my $vsz 		= $temp_process_hash->{$pid}[$vsz_index];
			my $thcnt 		= $temp_process_hash->{$pid}[$thcnt_index];
			my $read_KB		= $temp_process_hash->{$pid}[$read_KB_index];
			my $write_KB	= $temp_process_hash->{$pid}[$write_KB_index];
			#my $etime		= CONVERT_ELAPSE_TIME($temp_process_hash->{$pid}[$etime_index]);
			my $etime		= $temp_process_hash->{$pid}[$etime_index];
			
			if ( !$read_KB ) { $read_KB=0; }
			if ( !$write_KB ) { $write_KB=0; }
			$read_KB =~ s/^\s+//;
			$write_KB =~ s/^\s+//;
			$time =~ s/\s*//;
			debug ( 27 , "cpu_seconds $cpu_seconds_index->$time rss $rss_index->$rss vsz $vsz_index->$vsz thcnt $thcnt_index->$thcnt read_KB $read_KB_index->$read_KB write_KB $write_KB_index->$write_KB $etime_index->$etime" );
			if ( $group_by_process ) {
				$temp_process_array[$place*$number_of_process_attributes+0]=$time;
				$temp_process_array[$place*$number_of_process_attributes+1]=$rss;
				$temp_process_array[$place*$number_of_process_attributes+2]=$vsz;
				$temp_process_array[$place*$number_of_process_attributes+3]=$thcnt;
				$temp_process_array[$place*$number_of_process_attributes+4]=$read_KB;
				$temp_process_array[$place*$number_of_process_attributes+5]=$write_KB;
				$temp_process_array[$place*$number_of_process_attributes+6]=$etime;
			} else {
				$temp_process_array[$place+$header_count*0]=$time;
				$temp_process_array[$place+$header_count*1]=$rss;
				$temp_process_array[$place+$header_count*2]=$vsz;
				$temp_process_array[$place+$header_count*3]=$thcnt;
				$temp_process_array[$place+$header_count*4]=$read_KB;
				$temp_process_array[$place+$header_count*5]=$write_KB;
				$temp_process_array[$place+$header_count*6]=$etime;
			}
		}
		
		for ( my $index = 0 ; $index < $header_count*$number_of_process_attributes ; $index++ ) {
			print CSV_FILE "$temp_process_array[$index],";
		}
	print CSV_FILE "\n";
	}
	close (CSV_FILE);
	qx/chmod 775 $csv_output_file/;
}
sub STORE_DATA_FOR_CSV_FILE {
	while ( $next_printed_epoch lt $new_parsed_epoch ) {
		SET_GLOBAL_DATE_TIME($next_printed_epoch);
		$next_printed_epoch=$next_printed_epoch+$read_interval;
		$main_csv_file_array[$csv_file_line_count][$epoch_index] 	= $next_printed_epoch;
		my $datetime = RETURN_DATE_TIME($next_printed_epoch);
		my @datetime_split = split( /,/, $datetime );
		my $date = (split( /\./, $datetime_split[0]))[0];
		my $time = (split( /\./, $datetime_split[0]))[1];
		$time = sprintf '%06d', $time;
		$main_csv_file_array[$csv_file_line_count][$date_index] 	= $date;
		$main_csv_file_array[$csv_file_line_count][$time_index] 	= $time;
		$csv_file_line_count++;
	}
	CONVERT_NETWORK();
	CONVERT_DISK_METRICS();
	CONVERT_DISK_DF();
	$main_csv_file_array[$csv_file_line_count][$epoch_index] 				= $next_printed_epoch;
	$main_csv_file_array[$csv_file_line_count][$date_index] 				= $parsed_date;
	$main_csv_file_array[$csv_file_line_count][$time_index] 				= $parsed_time;
	$main_csv_file_array[$csv_file_line_count][$total_disk_read_index] 		= $disk_read_KBs;
	$main_csv_file_array[$csv_file_line_count][$total_disk_write_index] 	= $disk_write_KBs;
	$main_csv_file_array[$csv_file_line_count][$active_mem_index] 			= $active_mem;
	$main_csv_file_array[$csv_file_line_count][$swap_mem_index] 			= $swap_mem;
	$main_csv_file_array[$csv_file_line_count][$user_cpu_index] 			= $user_cpu;
	$main_csv_file_array[$csv_file_line_count][$system_cpu_index] 			= $system_cpu;
	$main_csv_file_array[$csv_file_line_count][$iowait_cpu_index] 			= $iowait_cpu;
	$main_csv_file_array[$csv_file_line_count][$idle_cpu_index] 			= $idle_cpu;
	$main_csv_file_array[$csv_file_line_count][$total_cpu_index] 			= $total_cpu;
	$main_csv_file_array[$csv_file_line_count][$network_in_hash_index] 		= dclone(\%network_in_converted_hash);
	$main_csv_file_array[$csv_file_line_count][$network_out_hash_index] 	= dclone(\%network_out_converted_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_df_percent_index] 		= dclone(\%disk_df_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_df_used_index] 		= dclone(\%disk_df_used_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_df_free_index] 		= dclone(\%disk_df_free_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_du_index] 				= dclone(\%disk_du_size_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_util_index] 			= dclone(\%disk_util_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_tps_index] 			= dclone(\%disk_tps_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_rps_index] 			= dclone(\%disk_rps_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_wps_index] 			= dclone(\%disk_wps_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_await_index] 			= dclone(\%disk_await_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$disk_svctm_index] 			= dclone(\%disk_svctm_percent_hash);
	$main_csv_file_array[$csv_file_line_count][$process_hash_index] 		= dclone(\%process_hash);
	$main_csv_file_array[$csv_file_line_count][$pid_array_index] 			= [ @pid_array ];
	
	$csv_file_line_count++;
}

# Parse data
sub INITIALIZE_NEW_LOOP {
	@pid_array = ();
	
	$old_parsed_epoch = $new_parsed_epoch;
	
	if ( $valid_iteration == 1 ) {
		%old_bytes_in = ();
		%old_bytes_out = ();
		foreach my $key (keys(%new_bytes_in)) {
			if ( $new_bytes_in{$key} ne '' ) {
				$old_bytes_in{$key} = $new_bytes_in{$key};	
			}
		}
		foreach my $key (keys(%new_bytes_out)) {
			if ( $new_bytes_out{$key} ne '' ) {
				$old_bytes_out{$key} = $new_bytes_out{$key};	
			}
		}
		
		%old_CPU_seconds		= %new_CPU_seconds;
	}
	
	%new_CPU_seconds		= ();
	%process_hash			= ();
	
	%new_bytes_in = ();
	%new_bytes_out = ();
	
	%disk_df_used_hash = ();
	%disk_df_free_hash = ();
	%disk_df_percent_hash = ();
	
	%disk_util_percent_hash = ();
	%disk_tps_percent_hash = ();
	%disk_rps_percent_hash = ();
	%disk_wps_percent_hash = ();
	%disk_await_percent_hash = ();
	%disk_svctm_percent_hash = ();
		
	$active_mem="";
	$swap_mem="";
	$total_cpu="";
	
	$parsing_sar_mem_all=0;
	$parsing_sar_ACT=0;
	$parsing_sar_SWP=0;
	$parsing_sar_IFACE=0;
	
	$iotop_second_summary_count=0;
	
	$network_modifier = 1 ;
	$valid_iteration = 1 ;
}
sub IDENTIFY_USED_CODE {
	my $input_command = $_[0];
	debug ( 17 , "input_command $input_command");
	for my $temp_code (@used_codes) {
		if ( $temp_code eq "rx" ) {
			if ( $input_command =~ m/$input_regex/i ) {
				return $temp_code;					
			}
		} elsif ( $temp_code eq "pid" ) {
		#	if ( $input_command =~ m/$command_PID/i ) {
				return $temp_code;					
		#	}
		} elsif ( $input_command =~ m/$prod_code_hash{$temp_code}[$prod_code_regex_index]/i ) {
			if ( $prod_code_hash{$temp_code}[$prod_code_vregex_index] ) {
				if ( $input_command =~ m/$prod_code_hash{$temp_code}[$prod_code_vregex_index]/i ) {
					debug ( 17 , "code $temp_code was canceled out by the vregex" );
					return "";
				}
			}
			debug ( 17 , "code is $temp_code" );
			return $temp_code;		
		} 
	}
	return "";
}
sub IDENTIFY_SHORT_COMMAND { 
	my $input_command = $_[0];
	debug ( 17 , "");

	#Get perfdata.pl process code letters
	my $temp_code = IDENTIFY_USED_CODE($input_command);
	if ( $temp_code eq "" ) {
		debug ( 17 , "temp_code empty" );
		return ",";	
	}
	
	#Get User ID, specifically for DB2
	my $extra = "";
	if ( $prod_code_hash{$temp_code}[$prod_code_special_process_index] == 1 ) {
		if ( "${temp_code}" eq "db" ) {
			debug ( 17 , "$temp_code, adding extra $_[1]" );
			$extra = "-$_[1]";
		} elsif ( "${temp_code}" eq "sc" ) {
			debug ( 17 , "$temp_code, evaluating Spark CoarseGrain" );
			my $executor = "";
			while ($input_command =~ m/\b(executor-id \d{1})\b/g) {
				$executor = $1;
			}
			my $app_id = "";
			while ($input_command =~ m/\b(app-id app-\d{14}-\d{4})\b/g) {
				$app_id = $1;
			}
			debug ( 17 , "executor \"$executor\"" );
			debug ( 17 , "app_id \"$app_id\"" );
			my $ex = chop($executor);
			my $ap = chop($app_id);
			$extra = " ex$ex ap$ap" ;
			debug ( 17 , "extra \"$extra\"" );
		}
	}	
	
	if (( $use_full_command == 0 ) && ( $temp_code ne "rx" ) && ( $temp_code ne "pid" ))  {
		my $return_string = "$prod_code_hash{$temp_code}[$prod_code_name_index]${extra}";
		my $length = length($return_string);
		#my $length1 = length($prod_code_hash{$temp_code}[$prod_code_name_index]);
		#my $length2 = length($extra);
		my $diff = $COMMAND_MAX_LENGTH - $length;
		if ( $diff< 0 ) {
			debug ( 17 , "Trimming $diff characters from $return_string");
			$return_string = substr($return_string, 0, $diff);
		}
		debug ( 17 , "Return A: $temp_code, length $length of $COMMAND_MAX_LENGTH, \"$return_string\"");
		return "$temp_code,$return_string";	
	} else { 
		my $length = length($input_command);
		if ( $length < $COMMAND_MAX_LENGTH ) {
			debug ( 17 , "Return B: $temp_code, \"${input_command}${extra}\"");
			return "$temp_code,${input_command}${extra}"; 	
		} else { #Full command was requested but it is too long, shorten it
			if ( $use_front_command ) { #Starts at the beginning of the command, not often used
				my $sub_string = substr($input_command, 0, $COMMAND_MAX_LENGTH);
				debug ( 17 , "Return C: $temp_code, \"$sub_string\"");
				return "$temp_code,$sub_string";
			} 
			else { #Starts at the end of the command
				my $length = length($input_command);
				my $start = $length - $COMMAND_MAX_LENGTH;
				my $sub_string = substr($input_command, $start, $length);
				debug ( 17 , "Return D: $start, $length, $COMMAND_MAX_LENGTH, $temp_code, \"$sub_string\"");
				return "$temp_code,$sub_string";		
			}		
		}
	}
	
	return "no command found";
}
sub CONVERT_CPU {
	my $time = shift ;
	$time =~ s/-/:/;
	my @time_split = split( /:/, $time );
	my $length = @time_split;
	my $seconds = 0;
	my $minutes = 0;
	my $hours = 0;
	my $days = 0;
	if ( $length == 2 ) {
		$seconds = $time_split[1];
		$minutes = $time_split[0];
	} elsif ( $length == 3 ) {
		$seconds = $time_split[2];
		$minutes = $time_split[1];
		$hours = $time_split[0];	
	} elsif ( $length == 4 ) {
		$seconds = $time_split[3];
		$minutes = $time_split[2];
		$hours = $time_split[1];	
		$days = $time_split[0];	
	}
	my $total_seconds = $seconds + ( $minutes * 60 ) + ( $hours * 3600 ) + ( $days * 3600 * 24 ) ;
	debug ( 10 , "CPU $length $days:$hours:$minutes:$seconds -- $total_seconds");
	
	return $total_seconds;
}
sub CONVERT_NETWORK {
	my $stored_NICs = 0;
	@network_in_converted_array=();
	@network_out_converted_array=();
	%network_in_converted_hash={};
	%network_out_converted_hash={};
	debug ( 7 , "requested_network_names_array \"@requested_network_names_array\"");
	if ( $sum_network ) { 
		$nework_multiplier=(($BITS)/$network_divide)/1;
	} else {
		$nework_multiplier=(($BITS)/$network_divide)/$read_interval;	
	}
	
	foreach my $nic_name (@requested_network_names_array) {
		my $network_in_diff=0;
		my $network_out_diff=0;
		if ( $linux ) {
			$network_in_diff=$new_bytes_in{$nic_name};
			$network_out_diff=$new_bytes_out{$nic_name};
		} else {
			$network_in_diff=($new_bytes_in{$nic_name}-$old_bytes_in{$nic_name});
			$network_out_diff=($new_bytes_out{$nic_name}-$old_bytes_out{$nic_name});
		}
		if ( $linux || ( $old_bytes_in{$nic_name} ne '' && $old_bytes_out{$nic_name} ne '' )) {
			$network_in_converted_hash{$nic_name} = sprintf "%${$NET_size}.${NET_decimal}f", ($network_in_diff*$nework_multiplier);
			$network_out_converted_hash{$nic_name} = sprintf "%${$NET_size}.${NET_decimal}f", ($network_out_diff*$nework_multiplier);
			
			$network_in_converted_array[$stored_NICs]=$network_in_converted_hash{$nic_name};
			$network_out_converted_array[$stored_NICs]=$network_out_converted_hash{$nic_name};				
		}
		debug ( 7 , "$nic_name DIFF Bytes IN  $network_in_diff  -> $network_in_converted_hash{$nic_name} $network_scale");
		debug ( 7 , "$nic_name DIFF Bytes OUT $network_out_diff -> $network_out_converted_hash{$nic_name} $network_scale");
		
		$stored_NICs++;
	}
}
sub CONVERT_DISK_METRICS {
	my $stored_disk_metric_count = 0;
	@disk_reported_metric_array=();
	
	foreach my $disk_metric_name (@requested_disk_metric_names_array) {
		if ( $disk_tps == 1 ) {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_tps_percent_hash{$disk_metric_name};	
		} elsif ( $disk_rps == 1 ) {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_rps_percent_hash{$disk_metric_name};
		} elsif ( $disk_wps == 1 ) {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_wps_percent_hash{$disk_metric_name};
		} elsif ( $disk_await == 1 ) {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_await_percent_hash{$disk_metric_name};
		} elsif ( $disk_svctm == 1 ) {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_svctm_percent_hash{$disk_metric_name};
		} else {
			$disk_reported_metric_array[$stored_disk_metric_count]=$disk_util_percent_hash{$disk_metric_name};
		}
		$disk_reported_metric_array[$stored_disk_metric_count] =~ s/^\s+|\s+$//g;
		debug ( 32 , "disk metric: $disk_metric_name => $disk_reported_metric_array[$stored_disk_metric_count]");
		$stored_disk_metric_count++;
	}
}
sub CONVERT_DU_METRICS {
	my $stored_du_metric_count = 0;
	@du_reported_metric_array=();	
	foreach my $du_dir_name (sort keys %disk_du_size_hash) {
		$du_reported_metric_array[$stored_du_metric_count]=$disk_du_size_hash{$du_dir_name};
		debug ( 39 , "du size: $du_dir_name => $du_reported_metric_array[$stored_du_metric_count]");
		$stored_du_metric_count++;
	}
}
sub CONVERT_DISK_DF {
	my $stored_disk_df_count = 0;
	@disk_df_current_metric_array=();
	
	foreach my $disk_df_name (@requested_disk_df_names_array) {
		if ( $disk_used == 1 ) {
			$disk_df_current_metric_array[$stored_disk_df_count]=$disk_df_used_hash{$disk_df_name};
		} elsif ( $disk_free == 1 ) {
			$disk_df_current_metric_array[$stored_disk_df_count]=$disk_df_free_hash{$disk_df_name};
		} else {
			$disk_df_current_metric_array[$stored_disk_df_count]=$disk_df_percent_hash{$disk_df_name};		
		}
		debug ( 31 , "disk df: $disk_df_name => $disk_df_current_metric_array[$stored_disk_df_count]");
		$stored_disk_df_count++;
	}
}
sub CONVERT_DEV_MOUNT_LSBLK {
	if ( $linux ) {
		if ( !keys %lsblk_devname_to_mount_hash) {
			#debug ( 0, "GET_LSBLK_ONE_TIME" );
			GET_LSBLK_ONE_TIME()
		}
	}
	my ($dev_name, $number) = @_;
	$requested_mount_names_array[$number] = "$lsblk_devname_to_mount_hash{$dev_name}";	
	if ( $requested_mount_names_array[$number] eq '' ) { $requested_mount_names_array[$number] = $dev_name }
	$requested_mount_names_array[$number] = "$requested_mount_names_array[$number]";
	debug ( 33, "dev_name $dev_name, requested_mount_names_array[$number] $requested_mount_names_array[$number]," );
}
sub GET_LSBLK_ONE_TIME {
	$lsblk_output = qx/$lsblk_command/;
	my @lines = split /\n/, $lsblk_output;
	my $count = 2;
	foreach my $line (@lines) {
		PARSE_LSBLK($line,$count);
		$count++;
	}
}
sub PARSE_PS {
	my $line = shift ;
	my $count = shift ;
	if ( $count == 1 ) {
		if ( $line !~ m/$ps_command_start/ ) {
			debug ( 1 , "Failed header line: \"$line\" \"$ps_command_start\"" );
		} else {		
			if ( $line =~ m/thcount/ ) {
				$use_ps_thcount = 1;
			} else { 
				$use_ps_thcount = 0;
			}
		}
	} 
	else {
		if ( $line =~ m/$regex/i ) { #to-do find a less expensive way to do this check for if the process is something we want to display or use
			$line =~ s/^\s+//;
			my @line_split = split( /\s+/, $line );
			
			#printArray(@line_split);
			if ( $linux || $aix || $solaris ) { # ps w -eo pid,ppid,uid,thcount,vsz,rss,etime,time,args
				my $pid = shift (@line_split); 
				debug ( 26 , "command_PID $command_PID -> $pid: @line_split");
				if ( $command_PID == 0 || $command_PID == $pid ) { #Default command_PID is 0, so this is checking if you asked for a specific PID.  
					if ( ! $process_hash{$pid} ) { 
						$process_hash{$pid} = ['','','','','','','','','',''];
					}
					@{$process_hash{$pid}}[$ppid_index] 			= shift (@line_split); 
					@{$process_hash{$pid}}[$uid_index]				= shift (@line_split); #uid
					if ( $use_ps_thcount == 1 ) {
						@{$process_hash{$pid}}[$thcnt_index] 			= shift (@line_split); 
					}
					@{$process_hash{$pid}}[$vsz_index] 				= shift (@line_split); 
					@{$process_hash{$pid}}[$rss_index] 				= shift (@line_split); 
					@{$process_hash{$pid}}[$etime_index] 			= shift (@line_split); 
					@{$process_hash{$pid}}[$cpu_time_index] 		= shift (@line_split); 
					my $temp_return									= IDENTIFY_SHORT_COMMAND("@line_split","@{$process_hash{$pid}}[$uid_index]"); 
					my @return_split = split( /,/, $temp_return );
					my $used_code = $return_split[0];
					my $return_command = $return_split[1];
					if ( $return_command ) {
						push (@pid_array,$pid);
						debug ( 17 , "return_command exists \"$return_command\", pid $pid ");
						@{$process_hash{$pid}}[$short_command_index]	= $return_command;
						@{$process_hash{$pid}}[$used_code_index] 		= $used_code;
						@{$process_hash{$pid}}[$full_command_index] 	= "@line_split"; 
						@{$process_hash{$pid}}[$old_cpu_seconds_index] 	= $old_CPU_seconds{$pid}; 
						my $temp_CPU_seconds 							= CONVERT_CPU(@{$process_hash{$pid}}[$cpu_time_index]); 
						@{$process_hash{$pid}}[$new_cpu_seconds_index] 	= $temp_CPU_seconds;
						$new_CPU_seconds{$pid}							= $temp_CPU_seconds;	
						debug ( 17 , "$pid $new_CPU_seconds{$pid} ");				
						my $sec_diff = "";
						my $percent = "";
						if ( @{$process_hash{$pid}}[$old_cpu_seconds_index] eq '' ) {
							@{$process_hash{$pid}}[$old_cpu_seconds_index] = 0;
						}
						$sec_diff = sprintf "%${SEC_size}d", @{$process_hash{$pid}}[$new_cpu_seconds_index] - @{$process_hash{$pid}}[$old_cpu_seconds_index];
						$percent = sprintf "%${PER_size}.${PER_decimal}f", $sec_diff * (100/$current_interval);
						
						@{$process_hash{$pid}}[$cpu_seconds_index] = $sec_diff;
						@{$process_hash{$pid}}[$cpu_percent_index] = $percent;
					} else {
						debug ( 17 , "return_command empty \"$return_command\", pid $pid ");
					}
				}
			} 
			elsif ( $hp ) { # UNIX95= ps -e -o 'pid ppid vsz sz etime time args'
				println ("todo - Riley Zimmerman");
				exit 1;
				shift (@line_split); #blank
				my $pid = shift (@line_split); #pid
				if ( ! $process_hash{$pid} ) { $process_hash{$pid} = [0,0,0,0,0,0,0,0];	}
				
				@{$process_hash{$pid}}[$ppid_index] 		= shift (@line_split); #ppid
				@{$process_hash{$pid}}[$vsz_index] 			= shift (@line_split); #vsz
				shift (@line_split); #sz
				@{$process_hash{$pid}}[$rss_index] 			= ""; #rss
				@{$process_hash{$pid}}[$etime_index] 		= shift (@line_split); #etime
				@{$process_hash{$pid}}[$cpu_time_index] 	= shift (@line_split); #time
				@{$process_hash{$pid}}[$full_command_index] = "@line_split"; #command
				@{$process_hash{$pid}}[$short_command_index] = IDENTIFY_SHORT_COMMAND("@line_split","uid"); #short command
			} 
			else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }
			debug ( 8 , "ps line: $line") ; 
		}
	}
}
sub PARSE_SAR {
	my $line = shift ;
	my $count = shift ;
	if ( $count == 1 ) {
		if ( $line !~ m/$sar_commandstart/ ) {
			debug ( 1 , "Failed header line: \"$line\" \"$sar_commandstart\"" );
		} else {
			debug ( 14 , "Sar Start line: \"$line\"");
		}
	} 
	else {
		$line =~ s/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]//g;
		$line =~ s/Average://;
		$line =~ s/^\s+//;
		
		my @line_split = split( /\s+/, $line );
		
		if (( $line =~ m/kbmem/ ) && ( $line =~ m/kbswp/ )) {
			$parsing_sar_mem_all=1; $parsing_sar_ACT=0; $parsing_sar_SWP=0; $parsing_sar_IFACE=0; $parsing_sar_ACT_new=0;
			debug ( 14 , "parsing_sar_mem_all\t\"$line\"");
		}
		elsif (( $line =~ m/kbmem/ ) && ( $line =~ m/kbavail/ )) {
			$parsing_sar_mem_all=0; $parsing_sar_ACT=0; $parsing_sar_SWP=0; $parsing_sar_IFACE=0; $parsing_sar_ACT_new=1;
			debug ( 14 , "parsing_sar_ACT_new\t\"$line\"");
		}
		elsif ( $line_split[0] =~ m/kbmem/ ) { 
			$parsing_sar_mem_all=0; $parsing_sar_ACT=1; $parsing_sar_SWP=0; $parsing_sar_IFACE=0; $parsing_sar_ACT_new=0;
			debug ( 14 , "parsing_sar_ACT\t\"$line\"");
		}
		elsif ( $line_split[0] =~ m/kbswp/ )  { 
			$parsing_sar_mem_all=0; $parsing_sar_ACT=0; $parsing_sar_SWP=1; $parsing_sar_IFACE=0; $parsing_sar_ACT_new=0;
			debug ( 14 , "parsing_sar_SWP\t\"$line\"");
		}			
		elsif ( $line_split[0] =~ m/IFACE/ )  { 
			$parsing_sar_mem_all=0; $parsing_sar_ACT=0; $parsing_sar_SWP=0; $parsing_sar_IFACE=1; $parsing_sar_ACT_new=0;
			debug ( 7 , "parsing_sar_IFACE\t\"$line\"");
			if (( $line_split[3] =~ m/rxkB\/s/ ) || ( $line_split[4] =~ m/txkB\/s/ )) { 
				$network_modifier=1024;			
			}
			debug ( 7 , "network_modifier $network_modifier");
		}	
		elsif ( $line_split[0] =~ m/dev|hdisk|sd/ ) { #disk collection
			
			if ( $identify_disk_name ) {
				my $current_disk_name = '';
				for ( my $index = 1 ; $index <= $#line_split ; $index++ ) {
					if ( $line_split[$index] > 0 ) { #look for a non-zero value to say disk is being used
						$current_disk_name=$line_split[0];
						debug ( 32 , "current_disk_name $current_disk_name");
					}
				}
				if ( $current_disk_name ne '' ) {
					$requested_disk_metric_names_array[0] = $current_disk_name;
					debug ( 32 , "Setting requested_disk_metric_names_array[0] to $current_disk_name");
				}
			}
			
			my $current_disk_name=$line_split[0];
			my $current_disk_tps;
			my $current_disk_rps;
			my $current_disk_wps;
			my $current_disk_await;
			my $current_disk_svctm;
			my $current_disk_util_percent;
			if ( $aix ) {
				$current_disk_util_percent = $line_split[1];
			} else {
				$current_disk_tps = $line_split[1];
				$current_disk_rps = $line_split[2];
				$current_disk_wps = $line_split[3];
				$current_disk_await = $line_split[6];
				$current_disk_svctm = $line_split[7];
				$current_disk_util_percent = $line_split[8];
			}
			$current_disk_tps = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_tps;
			$current_disk_rps = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_rps;
			$current_disk_wps = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_wps;
			$current_disk_await = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_await;
			$current_disk_svctm = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_svctm;
			$current_disk_util_percent = sprintf "%${DEV_size}.${DEV_decimal}f", $current_disk_util_percent;
			debug ( 14 , "$line");
			debug ( 14 , "current_disk_tps $current_disk_tps");
			debug ( 14 , "current_disk_rps $current_disk_rps");
			debug ( 14 , "current_disk_wps $current_disk_wps");
			debug ( 14 , "current_disk_await $current_disk_await");
			debug ( 14 , "current_disk_svctm $current_disk_svctm");
			debug ( 14 , "current_disk_util_percent $current_disk_util_percent");
			if ( $aix ) { $aix_after_disk_lines=1; }
			$disk_tps_percent_hash{$current_disk_name} = $current_disk_tps;
			$disk_rps_percent_hash{$current_disk_name} = $current_disk_rps;
			$disk_wps_percent_hash{$current_disk_name} = $current_disk_wps;
			$disk_await_percent_hash{$current_disk_name} = $current_disk_await;
			$disk_svctm_percent_hash{$current_disk_name} = $current_disk_svctm;
			$disk_util_percent_hash{$current_disk_name} = $current_disk_util_percent;
			
		}
		elsif ( $line_split[0] =~ m/all/ ) {
			$user_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[1];
			$nice_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[2];
			$system_cpu = sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[3];
			$iowait_cpu = sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[4];
			$steal_cpu  = sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[5];
			$idle_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[6];
			#$total_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", (100-$idle_cpu)*$cpu_cores;
			$total_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", ($user_cpu+$nice_cpu+$system_cpu+$steal_cpu)*$cpu_cores;
			debug ( 14 , "idle_cpu A $idle_cpu\t\"$line\"");
		}
		elsif ( $parsing_sar_IFACE ){
			my $current_NIC_name=$line_split[0];
			if ( $requested_network_names_string =~ /$current_NIC_name/ ) {
				debug ( 7 , "parsing_sar_IFACE\t\"$line\"");
				debug ( 7 , "network_modifier $network_modifier");
				$new_bytes_in{$current_NIC_name} = ($line_split[3]*$network_modifier)*$current_interval;
				$new_bytes_out{$current_NIC_name} = ($line_split[4]*$network_modifier)*$current_interval;
				debug ( 7 , "new_bytes_in{$current_NIC_name} $line_split[3]->$new_bytes_in{$current_NIC_name} new_bytes_out{$current_NIC_name} $line_split[4]->$new_bytes_out{$current_NIC_name}");
			}
		}
		elsif ( $parsing_sar_mem_all ) {
			$active_mem = sprintf "%${ACTM_size}d", ($line_split[1] - $line_split[3] - $line_split[4])/1024;
			$swap_mem = sprintf "%${SWAP_size}d", ($line_split[6])/1024;
			$parsing_sar_mem_all=0;
			debug ( 14 , "active_mem $active_mem\t\"$line\" ");
			debug ( 14 , "swap_mem   $swap_mem\t\"$line\"");
		}
		elsif ( $parsing_sar_ACT_new ) {
			$active_mem = sprintf "%${ACTM_size}d", ($line_split[2] - $line_split[4] - $line_split[5])/1024;
			$swap_mem = sprintf "%${SWAP_size}d", ($line_split[6])/1024;
			$parsing_sar_mem_all=0;
			debug ( 14 , "active_mem $active_mem\t\"$line\" ");
			debug ( 14 , "swap_mem   $swap_mem\t\"$line\"");
		}
		elsif ( $parsing_sar_ACT || $line_split[0] =~ m/memory/ ) {
			if ( $linux ) {
				$active_mem = sprintf "%${ACTM_size}d", ($line_split[1] - $line_split[3] - $line_split[4])/1024;
			} 
			elsif ( $aix ){
				$active_mem = sprintf "%${ACTM_size}d", $line_split[4];			
			}
			$parsing_sar_ACT=0;
			debug ( 14 , "active_mem $active_mem\t\"$line\"");
		}
		elsif ( $parsing_sar_SWP || $line_split[0] =~ m/pg/ ) {
			if ( $linux ) {
				$swap_mem = sprintf "%${SWAP_size}d", ($line_split[1])/1024;
			} 
			elsif ( $aix ){
				$swap_mem = sprintf "%${SWAP_size}d", $line_split[3];
			}
			$parsing_sar_SWP=0;
			debug ( 14 , "swap_mem   $swap_mem\t\"$line\"");
		}
		elsif ( $aix_after_disk_lines ) { #must be after hard drive area.  elsif so that AIX works
			$user_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[0];
			$system_cpu = sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[1];
			$iowait_cpu = sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[2];
			$idle_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", $line_split[3];
			$total_cpu 	= sprintf "%${TCPU_size}.${TCPU_decimal}f", (100-$idle_cpu)*$cpu_cores;
			debug ( 14 , "idle_cpu B $idle_cpu\t\"$line\"");
		} 
		else {
			debug ( 14 , "un-matched      \t\"$line\"") ; 
		}
	}
}
sub PARSE_NETWORK {
	my $line = shift ;
	my $count = shift ;
	
	debug ( 7 , "network line:              \"$line\"") ;
	if ( $count == 1 ) {
		if ( $line !~ m/$network_command_start/ ) {
			debug ( 1 , "Failed header line: \"$line\" \"$network_command_start\"" );
		}
		#$current_NIC_name="eth0";
	}
	else {
		my @line_split = split( /\s+/, $line );
		if ( $linux ) {
			if ( $line =~ m/Link encap:/ ) {
				$current_NIC_name = $line_split[0];
			}
			elsif ( $line =~ m/.*bytes:.*/ ) {
				if ( $requested_network_names_string =~ /$current_NIC_name/ ) {
					if ( $current_NIC_name eq '' ) {
						$current_NIC_name=$requested_network_names_array[0];
					}
					$new_bytes_in{$current_NIC_name} = (split( /:/, $line_split[2]))[1];
					$new_bytes_out{$current_NIC_name} = (split( /:/, $line_split[6]))[1];
					debug ( 7 , "$current_NIC_name Bytes IN  $old_bytes_in{$current_NIC_name}->$new_bytes_in{$current_NIC_name}") ; 
					debug ( 7 , "$current_NIC_name Bytes OUT $old_bytes_out{$current_NIC_name}->$new_bytes_out{$current_NIC_name}") ; 
				} 
				else {
					debug ( 7 , "$current_NIC_name not in requested_network_names_array \"@requested_network_names_array\" so it must not be operational.") ; 
				}
			}
		}
		elsif ( $aix ) {
			if ( $line =~ m/ETHERNET STATISTICS / ) {
				$current_NIC_name = $line_split[2];
				$current_NIC_name =~ s/\(//g;
				$current_NIC_name =~ s/\)//g;
			}
			elsif ( $line =~ m/.*bytes:.*/i ) {
				my $requested_network_names_array = join("",@requested_network_names_array);
				if ( $requested_network_names_array =~ /$current_NIC_name/ ) {
					if ( $current_NIC_name eq '' ) {
						$current_NIC_name=$requested_network_names_array[0];
					}
					$new_bytes_in{$current_NIC_name} = $line_split[1];
					$new_bytes_out{$current_NIC_name} = $line_split[3];
					debug ( 7 , "$current_NIC_name Bytes IN  $old_bytes_in{$current_NIC_name}->$new_bytes_in{$current_NIC_name}") ; 
					debug ( 7 , "$current_NIC_name Bytes OUT $old_bytes_out{$current_NIC_name}->$new_bytes_out{$current_NIC_name}") ; 
				} 
				else {
					debug ( 7 , "$current_NIC_name not in requested_network_names_array \"@requested_network_names_array\" so it must not be operational.") ; 
				}
			}
		} 
		elsif ( $solaris ) { #todo
			if ( $line =~ m/OutData/ ) {
				$new_bytes_out{$current_NIC_name} = $line_split[4];
				$new_bytes_out{$current_NIC_name} =~ s/[=]//g;
			}
			if ( $line =~ m/InInorder/ ) {
				$new_bytes_in{$current_NIC_name} = $line_split[4];
				$new_bytes_in{$current_NIC_name} =~ s/[=]//g;
			}
		} 
		elsif ( $hp ) { #todo
		} 
		else { debug ( 0 , "The osname \"$osname\" is unknown, exiting..."); exit 1 }

	}
}
sub PARSE_IOTOP {
	my $line = shift ;
	my $count = shift ;
	debug ( 16 , "iotop line:              \"$line\"") ;
	
	if ( $count == 1 ) {
		if ( $line !~ m/$iotop_command_start/ ) {
			debug ( 1 , "Failed header line: \"$line\" \"$iotop_command_start\"" );
		}
	}
	else {
		if ( $linux ) {
			if ( $iotop_second_summary_count < 2 ) { 
				if ( $line =~ m/ $iotop_activity_type DISK READ:/ ) { #IOTOP version 0.3-
					$iotop_second_summary_count++;
					if ( $iotop_second_summary_count == 2 ) {
						my @line_split = split( /\s+/, $line );
						$disk_read_KBs = $line_split[4]*$current_interval;
						$disk_write_KBs = $line_split[10]*$current_interval;
						$disk_read_KBs = sprintf "%${READ_size}d", $disk_read_KBs;
						$disk_write_KBs = sprintf "%${WRITE_size}d", $disk_write_KBs;
						debug ( 16 , "Parsing IOTOP 0.3 summary, read $disk_read_KBs, write $disk_write_KBs" );
					}
				}
				elsif ( $line =~ m/$iotop_activity_type DISK READ:/ ) { #IOTOP version 0.6-
					$iotop_second_summary_count++;
					if ( $iotop_second_summary_count == 2 ) {
						my @line_split = split( /\s+/, $line );
						$disk_read_KBs = $line_split[3]*$current_interval;
						$disk_write_KBs = $line_split[9]*$current_interval;
						$disk_read_KBs = sprintf "%${READ_size}d", $disk_read_KBs;
						$disk_write_KBs = sprintf "%${WRITE_size}d", $disk_write_KBs;
						debug ( 16 , "Parsing IOTOP 0.3 summary, read $disk_read_KBs, write $disk_write_KBs" );
					}
				}
				elsif ( $line =~ m/ $iotop_activity_type DISK READ :/ ) { #IOTOP version 0.6-
					$iotop_second_summary_count++;
					if ( $iotop_second_summary_count == 2 ) {
						my @line_split = split( /\s+/, $line );
						$disk_read_KBs = $line_split[5]*$current_interval;
						$disk_write_KBs = $line_split[12]*$current_interval;
						$disk_read_KBs = sprintf "%${READ_size}d", $disk_read_KBs;
						$disk_write_KBs = sprintf "%${WRITE_size}d", $disk_write_KBs;
						debug ( 16 , "Parsing IOTOP 0.6 summary, read $disk_read_KBs, write $disk_write_KBs" );
					}
				}
			}
			else {
				my @line_split = split( /\s+/, $line );
				my $pid = $line_split[1];
				if ( ! $process_hash{$pid} ) { 
					debug ( 16 , "PID $pid not used");
				} else {
					my $process_read_KB = $line_split[4];
					$process_read_KB = sprintf "%${READ_size}d", $process_read_KB;
					@{$process_hash{$pid}}[$read_KB_index] = $process_read_KB;
					
					my $process_write_KB = $line_split[6];
					$process_write_KB = sprintf "%${WRITE_size}d", $process_write_KB;
					@{$process_hash{$pid}}[$write_KB_index] = $process_write_KB;
					
					debug ( 16 , "PID $pid read \"${process_read_KB}\" KB wrote \"${process_write_KB}\" KB%" );	
				}
			}
		}
		else { debug ( 0 , "iotop is not setup for OS \"$osname\", exiting..."); exit 1 } 	
	}
}
sub PARSE_LSBLK {
	my $line = shift ;
	my $count = shift ;
	debug ( 36 , "lsblk line:              \"$line\"") ;
	
	if ( $count == 1 ) {
		if ( $line !~ m/$lsblk_command_start/ ) {
			debug ( 1 , "Failed header line: \"$line\" \"$lsblk_command_start\"" );
			
		}
	}
	else {
		if ( $linux ) {
			if ( $line !~ m/MAJ:MIN/ ) { 
				my @line_split = split( /\s+/, $line );
				my $lenght = scalar @line_split;
				if ( $lenght > 6 ) {
					my $major_minor = $line_split[1];
					if ( $lenght == 8 ) { 
						$major_minor = $line_split[2];
					}
					my $mountpoint = $line_split[$lenght-1]; 
					$major_minor =~ s/\:/\-/g;
					my $device = "dev${major_minor}";
					debug ( 36 , "length $lenght,  major_minor $major_minor,  device $device,  mountpoint $mountpoint") ;
					$lsblk_devname_to_mount_hash{$device} = $mountpoint;
				}
			}			
		}
		else { debug ( 0 , "lsblk is not setup for OS \"$osname\", exiting..."); exit 1 } 	
	}
}
sub PARSE_DF {
	my $line = shift ;
	my $count = shift ;
	debug ( 31 , "df line:              \"$line\"") ;
	
	#if ( $requested_disk_df_names_array =~ /$line/ ) {
	if ( $line  =~ m/$df_drives_regex/ ) {
		my @line_split = split( /\s+/, $line );
		my $current_disk_df_used = $line_split[2];
		my $current_disk_df_free = $line_split[3];
		my $current_disk_df_percent = $line_split[4];
		$current_disk_df_percent =~ s/[\%]//g;
		my $current_disk_df_name = $line_split[5];
		debug ( 31 , "$current_disk_df_name : $current_disk_df_used used, $current_disk_df_free free, $current_disk_df_percent");
		$disk_df_used_hash{$current_disk_df_name} = sprintf "%${DF_size}d", $current_disk_df_used/1024;
		$disk_df_free_hash{$current_disk_df_name} = sprintf "%${DF_size}d", $current_disk_df_free/1024;
		$disk_df_percent_hash{$current_disk_df_name} = $current_disk_df_percent;
	}
}
sub PARSE_DU {
	my $line = shift ;
	my $count = shift ;
	debug ( 39 , "du line:              \"$line\"") ;
	
	if ( $line  =~ m/\// ) {
		my @line_split = split( /\s+/, $line );
		my $current_du_size = $line_split[0];
		my $current_du_dir = $line_split[1];
		debug ( 39 , "current_du_dir, $current_du_dir, current_du_size, $current_du_size");
		$disk_du_size_hash{$current_du_dir} = $current_du_size;
	}
	
}
sub PARSE_PS_HEADER {
	my $line = shift ;
	my @header_split = split( /,/, $line );
	$parsed_date = (split( /\./, $header_split[0]))[0];
	$parsed_time = (split( /\./, $header_split[0]))[1];
	$parsed_time = sprintf '%06d', $parsed_time;
	my $iteration = $header_split[1];
		
	if ( $iteration < ($previous_iteration_count+1) && $iteration != 1 ) {
		debug ( 11 , "WARNING!!! iteration $iteration, $previous_iteration_count");
		$valid_iteration = 0;
	} else {
		$previous_iteration_count = $iteration;
		
		$new_parsed_epoch=RETURN_EPOCH($parsed_date,$parsed_time);
		my $new_current_interval = ($new_parsed_epoch - $old_parsed_epoch);
		if ( $new_current_interval gt 0 ) {
			$current_interval = $new_current_interval;
		}
		debug ( 11 , "current_interval: $new_parsed_epoch - $old_parsed_epoch = $current_interval") ; 
		
		debug ( 12 , "RESET parsed_date.parsed_time: $parsed_date.$parsed_time") ; 
		$valid_time = 1;
		
		
		my $mod = $new_parsed_epoch % $read_interval;
		if ( ( $valid_time eq 1 ) && ( $mod > $allowed_ofset_seconds ) ) {
			debug ( 12 , "$parsed_date.$parsed_time: $new_parsed_epoch % $read_interval is $mod") ; 
			$valid_time = 0;
		}
		
		if ( ( $valid_time eq 1 ) && ( $parsed_date eq $console_start_date ) ) {
			if ( ( $parsed_time < $console_start_time ) && ( $parsed_time != 0 ) ){
			debug ( 12 , "$parsed_date.$parsed_time: Too early") ; 
				$valid_time = 0;
			}
		}
		if ( ( $valid_time eq 1 ) && ( $parsed_date eq $console_end_date ) ) {
			if ( $parsed_time > $console_end_time ) {
				debug ( 12 , "$parsed_date.$parsed_time: Too late") ; 
				$valid_time = 0;
			}
		} 
		if ( ( $valid_time eq 1 ) && ( $parsed_date gt $console_end_date ) ) {
			debug ( 12 , "$parsed_date.$parsed_time: A day too late") ; 
			$valid_time = 0;
		} 
	}
	
}
sub PARSE_NEW_LINES {
	my $parsing_ps 			= 0;
	my $parsing_sar 		= 0;
	my $parsing_network 	= 0;
	my $parsing_iotop	 	= 0;
	my $parsing_df	 		= 0;
	my $parsing_lsblk	 	= 0;
	my $parsing_du	 		= 0;
	my $count 				= 0;
	foreach my $line (@new_input_lines) {
		chomp $line;
		if ( $line  =~ m/$endofloop/ ) {
			if ( $valid_time && $valid_iteration ) {
				if ( $output_count > 0 ) {
					if ( $csv_output ) { 
						STORE_DATA_FOR_CSV_FILE;
					} 
					PRINT_NEW_OUTPUT_TO_CONSOLE;
					
				}
				$next_printed_epoch=$next_printed_epoch+$read_interval;
				debug ( 12 , "next_printed_epoch $next_printed_epoch" );
				$output_count++;
			}
			debug ( 6 , "Read end of loop output_count: $output_count parsed_time: $parsed_time valid_time: $valid_time" );
			INITIALIZE_NEW_LOOP;
		}
		elsif ( $valid_iteration == 0 ) {
			debug ( 11 , "WARNING!!! valid_iteration $valid_iteration");		
		} else {
			if ( $line =~ m/ps_output/ ) {
				$parsing_ps = 1 ; $parsing_sar = 0 ; $parsing_network = 0 ; $parsing_iotop = 0 ; $parsing_df = 0 ; $parsing_lsblk = 0 ; $parsing_du = 0; $count = 0 ;
				PARSE_PS_HEADER($line);
			} 
			elsif ( $line =~ m/sar_output/ ) {
				debug ( 14 , "sar line:              \"$line\"") ;
				$parsing_ps = 0 ; $parsing_sar = 1 ; $parsing_network = 0 ; $parsing_iotop = 0 ; $parsing_df = 0 ; $parsing_lsblk = 0 ; $parsing_du = 0; $count = 0 ;
			}
			elsif ( $line =~ m/network_output/ ) {
				debug ( 7 , "network line:              \"$line\"") ;
				$parsing_ps = 0 ; $parsing_sar = 0 ; $parsing_network = 1 ; $parsing_iotop = 0 ; $parsing_df = 0 ; $parsing_lsblk = 0 ; $parsing_du = 0; $count = 0 ;
			} 
			elsif ( $line =~ m/iotop_output/ ) {
				$parsing_ps = 0 ; $parsing_sar = 0 ; $parsing_network = 0 ; $parsing_iotop = 1 ; $parsing_df = 0 ; $parsing_lsblk = 0 ; $parsing_du = 0; $count = 0 ;
			}
			elsif ( $line =~ m/df_output/ ) {
				$parsing_ps = 0 ; $parsing_sar = 0 ; $parsing_network = 0 ; $parsing_iotop = 0 ; $parsing_df = 1 ; $parsing_lsblk = 0 ; $parsing_du = 0; $count = 0 ;
			}
			elsif ( $line =~ m/lsblk_output/ ) {
				$parsing_ps = 0 ; $parsing_sar = 0 ; $parsing_network = 0 ; $parsing_iotop = 0 ; $parsing_df = 0 ; $parsing_lsblk = 1 ; $parsing_du = 0; $count = 0 ;
			}
			elsif ( $line =~ m/du_output/ ) {
				$parsing_ps = 0 ; $parsing_sar = 0 ; $parsing_network = 0 ; $parsing_iotop = 0 ; $parsing_df = 0 ; $parsing_lsblk = 0 ; $parsing_du = 1; $count = 0 ;
			}
			elsif ( $line =~ m/Running on hostname.*/ ) {
				my @line_split = split( /\s+/, $line );
				$cpu_cores = $line_split[14];
				if ( $temp_input_file ne '' ) {
					debug ( 0 , "Header in file: \"$line\"") ;
					debug ( 0 , "Read cpu_cores from file: \"$cpu_cores\"") ;
				} else {
					debug ( 1 , "Header in file: \"$line\"") ;
					debug ( 1 , "Read cpu_cores from file: \"$cpu_cores\"") ;
				}
			}
			if ( $valid_time && $valid_iteration ) {
				if ( $count > 0 ) {
					if ( $parsing_ps ) { PARSE_PS($line,$count); }
					if ( $parsing_sar ) { PARSE_SAR($line,$count); }
					if (( $parsing_network ) && ( ! $linux ) ) { PARSE_NETWORK($line,$count); }
					if ( $parsing_iotop ) { PARSE_IOTOP($line,$count); }
					if ( $parsing_df ) { PARSE_DF($line,$count); }
					if ( $parsing_lsblk ) { PARSE_LSBLK($line,$count); } 	
					if ( $parsing_du ) { PARSE_DU($line,$count); } 					
				}
			} elsif ( $parsing_lsblk ) { PARSE_LSBLK($line,$count); } #NOT SURE WHY THIS WAS HERE???
		}
		$count++;
	}
	@new_input_lines = ();
}

sub CLEAN_AND_GZIP_OLD_OUTPUT_FILES {
	SET_GLOBAL_DATE_TIME;
	debug ( 0 , "Skipping today \"$datestring\"" );
	opendir (my $perfdata_dir_handle, $perfdata_dir) or die $!;
	my @temp_date_dirs = sort { $a <=> $b } readdir($perfdata_dir_handle);
	while ( my $temp_date_dir = shift @temp_date_dirs ) {
		next if ( -f "$perfdata_dir/$temp_date_dir" );
		next if ( $temp_date_dir =~ m/^\./ );
		next if ( $temp_date_dir !~ m/^20/ );
		next if ( $temp_date_dir =~ m/$datestring/ );
		#debug ( 0 , "Checking in $perfdata_dir/$temp_date_dir");
		my $raw_file = "$perfdata_dir/$temp_date_dir/$hostname.$temp_date_dir.out";
		my $gzip_file = "$perfdata_dir/$temp_date_dir/$hostname.$temp_date_dir.out.gz";
		my $temp_file = "$perfdata_dir/$temp_date_dir/$hostname.$temp_date_dir.out.gz.temp";
		my $temp_file2 = "$perfdata_dir/$temp_date_dir/$hostname.$temp_date_dir.out.gz.temp2";
	
		if ( -f "$raw_file" ) {
			if ( -f "$gzip_file" ) {
				my $gzip_size = -s $gzip_file;
				my $raw_size = -s $raw_file;
				debug ( 0 , "  Two files exist in $perfdata_dir/$temp_date_dir!!!" );
				debug ( 0 , "  Already compressed $gzip_file - $gzip_size" );
				debug ( 0 , "  Raw file $raw_file - $raw_size" );
				
				debug ( 0 , "  mv ${gzip_file} ${temp_file}");
				system("mv ${gzip_file} ${temp_file}");
				debug ( 0 , "  gzip -f \"$raw_file\"");
				system("gzip -f $raw_file");
				
				$gzip_size = -s $gzip_file;
				my $temp_size = -s $temp_file;				
				if ( $temp_size > $gzip_size) {
					debug ( 0 , "  mv ${gzip_file} ${temp_file2}");
					system("mv ${gzip_file} ${temp_file2}");
					debug ( 0 , "  mv ${temp_file} ${gzip_file}");
					system("mv ${temp_file} ${gzip_file}");
					debug ( 0 , "  mv ${temp_file2} ${temp_file}");
					system("mv ${temp_file2} ${temp_file}");					
				}
				$temp_size = -s $temp_file;	
			} else {
				debug ( 0 , "  gzip -f \"$raw_file\"");
				system("gzip -f $raw_file");
				#qx/gzip -f $raw_file/;
			}
		} 
		
		
		if ( -f "$raw_file" ) {
			my $raw_size = -s $raw_file;
			debug ( 0 , "WARNING!!! Raw file still exists: $raw_file - $raw_size" );			
		}
		if ( -f "$gzip_file" ) { 
			my $gzip_size = -s $gzip_file;
			if ( $gzip_size < 2500 ) {
				debug ( 0 , "  rm ${gzip_file} - $gzip_size");
				system("rm  ${gzip_file}");					
			} else {
				debug ( 0 , "Compressed file: $gzip_file - $gzip_size" );
			}
			
			if ( -f "$temp_file" ) { 
				my $temp_size = -s $temp_file;
				if ( $temp_size < 2500 ) {
					debug ( 0 , "  rm ${temp_file} - $temp_size");
					system("rm  ${temp_file}");					
				} else {
					debug ( 0 , "WARNING!!! Extra compressed file: $temp_file - $temp_size" );
				}
			}
		} else {
			debug ( 0 , "$perfdata_dir/$temp_date_dir was empty" );		
		}
	}
	debug ( 0 , "Done with CLEAN_AND_GZIP_OLD_OUTPUT_FILES");
}
sub CHECK_IF_RUNNING {
	debug ( 1, "ps -ef | egrep -v \"grep|$$\" | grep perfdata | grep \"nohup_collect\" | wc -l" );
	$process_is_running = qx/ps -ef | egrep -v "grep|$$" | grep perfdata | grep "nohup_collect" | wc -l/;
	chomp($process_is_running);
	if ( $process_is_running == 1) {
		debug ( 0 , "$process_is_running collection process is already running." );
	} elsif ( $process_is_running > 1 ) {
		debug ( 0 , "WARNING!!! $process_is_running processes are running!" );
	} else {
		debug ( 0 , "Collection process is not running." );
	}
}
sub NOHUP_LAUNCH_COLLECTION {
	if ( $process_is_running == 0 ) {
		debug ( 0 , "Starting new process in the background to run collection" );
		debug ( 0 , "nohup $0 nohup_collect $collect_all_processes_flag $dir_flag $iotop_flag >>$log_file 2>&1&" ) ;
		system("nohup $0 nohup_collect $collect_all_processes_flag $dir_flag $iotop_flag >>$log_file 2>&1&" ); 
		if ( -e '/usr/lib/systemd/system/perfdata.service' ) {
			system("ps -ef | awk '!/awk/ && /perfdata.* nohup_collect/ { print \$2 }' > $perfdata_dir/perfdata.pl.pid");
		}
		elsif ( $linux ) {
			debug ( 0 , "Adding \@reboot crontab" ) ;
			system("crontab -l | grep -v 'perfdata.*.pl' > $crontab_file" ); 
			system("echo '\@reboot $0 collect >>$log_file' >>$crontab_file" ); 
			system("crontab $crontab_file" ); 
		}
		
		debug ( 0 , "Follow with:\ttail -f $log_file" ) ;
		debug ( 0 , "Please wait for one iteration for data output..." ) ;
	} else {
		debug ( 0 , "Not starting a new collection process because one was already found." );
	}
}
sub KILL_COLLECTION {
	debug ( 1, "ps -ef | egrep -v \"grep|$$\" | grep perfdata | grep pl | grep collect | awk '{print\$2}'" );
	my $processes = qx/ps -ef | egrep -v "grep|$$" | grep perfdata | grep pl | grep collect | awk '{print\$2}'/;
	chomp($processes);
	if ( $processes ) {
		debug ( 0 , "Killing processes \"$processes\"");
		system("kill -9 $processes");
	} else {
		debug ( 0 , "Could not find any processes already running to kill.");
	}
	if ( $linux ) {
		debug ( 0 , "Removing \@reboot crontab" ) ;
		system("crontab -l | grep -v 'perfdata.*.pl' > $crontab_file" ); 
		system("crontab $crontab_file" ); 
	}
	
	sleep 1;
}

sub SAR_WORKER_THREAD {
	my $thread_self = "threads"->self();
	debug ( 20 , "$thread_self Start SAR thread. Running $sar_command");
	
	debug ( 3, "sar_command $sar_command");
	$sar_output = qx/$sar_command/;
	debug ( 3, "sar_output \n$sar_output");
	return($sar_output);
}
sub IOTOP_WORKER_THREAD {
	my $thread_self = "threads"->self();
	debug ( 20 , "$thread_self Start IOTOP thread. Running $iotop_command");
	
	debug ( 3, "iotop_command $iotop_command");
	$iotop_output = qx/$iotop_command/;
	debug ( 3, "iotop_output \n$iotop_output");
	return($iotop_output);
}
sub SINGLE_INTERVAL_WORKER_THREAD {
	my $thread_self = "threads"->self();
	debug ( 20 , "$thread_self Worker thread started");
	my $iotop_thread = "";
	SETUP_INTERVAL_WAIT(1);
	#if (( $iotop_installed ) && ( $ps_klzagent_list_output <= $max_klzagent_iotop )) {
	if ( $iotop_installed != 0 ) {
		SETUP_IOTOP_COMMANDS;
		$iotop_thread = "threads"->create(\&IOTOP_WORKER_THREAD);
		debug ( 20 , "$thread_self Worker thread launched IOTOP $iotop_thread");
	}
	sleep 1; #Needed for iotop sync
	
	#SETUP_INTERVAL_WAIT(0); #TEST RDZ to see if this is causing the missed minutes
	SETUP_SAR_COMMANDS;
	my $sar_thread = "threads"->create(\&SAR_WORKER_THREAD);
	debug ( 20 , "$thread_self Worker thread launched SAR $sar_thread");
	
	
	SET_GLOBAL_DATE_TIME;
	my $date_dir = "$perfdata_dir/$datestring";
	my $db2_snapshot_dir = "$date_dir/$db2_snapshots_dir_name";
	my $dir_datestring = $datestring;
	$output_file = "$date_dir/$hostname.$datestring.out";
	debug ( 20 , "$thread_self Worker thread assigned dirs");
	if ( ! -d $date_dir ) {
		mkdir($date_dir);
		qx/chmod 775 $date_dir/;
		#DB2 Centralized Servers
		debug ( 1 , "0 $thread_self System call cat /etc/group is_db2inst1_dasadm1 before");
		my $is_db2inst1_dasadm1 = `timeout 1 cat /etc/group | grep dasadm1 | grep db2inst | wc -l`; #Once per day
		debug ( 1 , "0 $thread_self System call cat /etc/group is_db2inst1_dasadm1 $is_db2inst1_dasadm1");
		if ( $is_db2inst1_dasadm1 != 0 ) { 
			qx/chgrp dasadm1 $date_dir/;
		}
	}
	debug ( 20 , "$thread_self Worker thread after date_dir");	
	if ( ! -f $output_file ) {
		INITIALIZE_OUTPUT_FILE;
	}
	debug ( 20 , "$thread_self Worker thread after output_file");	
	
	LOAD_DB_LIST_FROM_FILE_AND_SNAPSHOT($thread_self, $db2_snapshot_dir);	#Can hang
	debug ( 20 , "$thread_self Worker thread after db2 snapshots");	
	
	my $du_output = LOAD_DU_LIST_FROM_FILE_AND_SNAPSHOT();	
	debug ( 20 , "$thread_self Worker thread after du snapshots");	
	
	#Final sleep to syn to next interval
	SETUP_INTERVAL_WAIT(0);
	debug ( 20 , "$thread_self Worker thread sleeping $interval_wait_seconds");
	sleep $interval_wait_seconds;
	
	SET_GLOBAL_DATE_TIME;
	SYNC_TIME;
	my $record_date = sprintf '%08d', $datestring;
	my $record_time = sprintf '%06d', $timestring;
	debug ( 3, "ps_command $ps_command");
	my $ps_output = qx/$ps_command/;
	debug ( 3, "ps_output\n$ps_output");
	
	my $network_output = "";
	if ( ! $linux ) {
		debug ( 3, "network_command $network_command");
		$network_output = qx/$network_command/;
		debug ( 3, "network_output \n$network_output");
	}
	
	debug ( 3, "df_command $df_command");
	$df_output = qx/$df_command/;
	debug ( 3, "df_output \n$df_output");
	
	debug ( 20 , "$thread_self Collected ps, network and df data.");
	
	
	my $sar_output = $sar_thread->join();
	my $iotop_output = "";
	#if (( $iotop_installed ) && ( $ps_klzagent_list_output <= $max_klzagent_iotop )) {
	if ( $iotop_installed != 0 ) {
		$iotop_output = $iotop_thread->join();
	}
	debug ( 20 , "$thread_self Called threads finished.\n");
	
	open (OUTPUTFILE, ">>", "$output_file") or die $!;
	SET_GLOBAL_DATE_TIME;
	print OUTPUTFILE "$datestring.$timestring,$loop_count,start_loop_output\n";
	print OUTPUTFILE "$record_date.$record_time,$loop_count,sar_output,\n$sar_command\n$sar_output";
	print OUTPUTFILE "$record_date.$record_time,$loop_count,ps_output,\n$ps_command\n$ps_output";
	if ( ! $linux ) {
		print OUTPUTFILE "$record_date.$record_time,$loop_count,network_output,\n$network_command\n$network_output";
	}
	#if (( $iotop_installed ) && ( $ps_klzagent_list_output <= $max_klzagent_iotop )) {
	if ( $iotop_installed !=0 ) {
		print OUTPUTFILE "$record_date.$record_time,$loop_count,iotop_output,\n$iotop_command\n$iotop_output";
	}
	if ( $print_lsblk_output ne '' ) {
		print OUTPUTFILE "$record_date.$record_time,$loop_count,lsblk_output,\n$lsblk_command\n$lsblk_output";
	}
	if ( $du_output ne '' ) {
		print OUTPUTFILE "$record_date.$record_time,$loop_count,du_output,\n$du_output";
	}
	print OUTPUTFILE "$record_date.$record_time,$loop_count,df_output,\n$df_command\n$df_output";
	
	print OUTPUTFILE "$endofloop\n\n";
	close (OUTPUTFILE) or die $!;
	
	if ( $datestring > $dir_datestring ) {
		sleep 5;
		#RDZ MIDNIGHT DEBUG
		if ( -f "$output_file" ) {
			debug ( 0 , "End of the day $dir_datestring, running gzip -f \"$output_file\"");
			qx/gzip -f $output_file/;
			debug ( 0 , "Completed gzip");		
		} else {
			debug ( 0 , "End of the day $dir_datestring, file is already gzipped \"$output_file\"");
		}
		if ( -d $db2_snapshot_dir ) { 
			debug ( 0 , "End of the day $dir_datestring, running gzip -f \"$db2_snapshot_dir\/*db2ss*\"");
			qx/gzip -f "$db2_snapshot_dir\/*db2ss*"/;	
			debug ( 0 , "Completed gzip");		
		}
	}

}
sub PERFDATA_RUN_LOOP {    #data collection loop, runs in background continuously
	SETUP_PS_COMMANDS;
	SETUP_NETWORK_COMMANDS;
	SETUP_DF_COMMANDS;
	SETUP_LSBLK_COMMANDS;
	debug ( 0 , "Starting perfdata.pl collection");
	$sar_output = "";
	$loop_count = 1 ; 
	SET_GLOBAL_DATE_TIME;
	my $old_datestring = $datestring;
	# 17280 allows for a max of 5 second interval for the entire day.
	while ( $loop_count <= 20000 ) {
		#startTimer(1);
		LOAD_DEBUG_FROM_FILE;
		SET_GLOBAL_DATE_TIME;
		if ( $datestring != $old_datestring ) {
			$loop_count = 1 ;
		}
		$old_datestring = $datestring;
		
		LOAD_INTERVAL_FROM_FILE();
		if ( $linux ) { 
			#$ps_klzagent_list_output = qx/$ps_klzagent_list_command/;
			if ( $lsblk_installed ) {
				debug ( 3, "lsblk_command $lsblk_command");
				$lsblk_output = qx/$lsblk_command/;
				debug ( 3, "lsblk_output \n$lsblk_output");
				if (( $old_lsblk_output ne $lsblk_output ) || ( $loop_count == 1 )) {
					debug ( 3, "lsblk not equal or loop_count == $loop_count ");
					$print_lsblk_output = $lsblk_output;
				} else {
					debug ( 3, "lsblk is equal");
					$print_lsblk_output = '';					
				}
				$old_lsblk_output=$lsblk_output;
			}
		}
		debug ( 20 , "$loop_count, Main program launch worker" );
		my $single_interval_worker_thread = "threads"->create(\&SINGLE_INTERVAL_WORKER_THREAD);
		$single_interval_worker_thread->detach;
		sleep 1; #Needed for iotop sync		

		SETUP_INTERVAL_WAIT(0);
		debug ( 20 , "$loop_count, Main program sleeping $interval_wait_seconds-1" );
		sleep $interval_wait_seconds-1; #sleep 1 second less to allow an extra second for iotop		
		$loop_count++;
	}
	debug ( 0 , "Reached end of loop count, this should not happen! Exiting..." );
	exit 1;
}
sub SETUP_START_END_TIME { #format start and end date and times based on arguments

	#Setup start datetime
	if ( $console_start_datetime eq "" ) { $console_start_datetime="30m"; }
	if ( $console_start_datetime =~ m/h$/i ) { 
		$console_start_datetime =~ s/h$//gi; 
		my $epoch = RETURN_EPOCH() - ($console_start_datetime*60*60);
		$epoch = $epoch - ($epoch % $write_interval);
		$console_start_datetime = RETURN_DATE_TIME($epoch);
	}
	elsif ( $console_start_datetime =~ m/m$/i ) { 
		$console_start_datetime =~ s/m$//gi; 
		my $epoch = RETURN_EPOCH() - ($console_start_datetime*60);
		$epoch = $epoch - ($epoch % $write_interval);
		$console_start_datetime = RETURN_DATE_TIME($epoch);
	}
	elsif ( $console_start_datetime =~ m/^today$/i ) 	{ #Replace the entire string
		$console_start_datetime="$datestring.000000"; 	
		$console_start_date = (split ( /\./, $console_start_datetime ))[0];
		$console_start_time = (split ( /\./, $console_start_datetime ))[1];
		my $epoch = RETURN_EPOCH($console_start_date,$console_start_time) - $read_interval;
		$console_start_datetime = RETURN_DATE_TIME($epoch);
	}
	else { #Replace only the beginning
		$console_start_datetime=~s/^today/$datestring/gi;  
		$console_start_date = (split ( /\./, $console_start_datetime ))[0];
		$console_start_time = (split ( /\./, $console_start_datetime ))[1];
		if ( length($console_start_time) == 5 ) 	{ $console_start_time="0${console_start_time}"; }
		while ( length($console_start_time) < 6 ) 	{ $console_start_time="${console_start_time}0"; }
		my $epoch = RETURN_EPOCH($console_start_date,$console_start_time) - $read_interval;
		$console_start_datetime = RETURN_DATE_TIME($epoch);
	}
	$console_start_date = (split ( /\./, $console_start_datetime ))[0];
	$console_start_time = (split ( /\./, $console_start_datetime ))[1];
	my $epoch = RETURN_EPOCH($console_start_date,$console_start_time) + $read_interval;
	$actual_console_start_datetime = RETURN_DATE_TIME($epoch);
	
	#Setup end datetime
	#if ( $console_end_datetime eq "" ) 					{ $console_end_datetime="20991230.235959"; }
	if ( $console_end_datetime eq "" ) 					{ $console_end_datetime="20991230.240000"; }
	if ( $console_end_datetime =~ m/h$/i ) 				{ 
		$console_end_datetime =~ s/h$//gi; 
		my $epoch = RETURN_EPOCH() - ($console_end_datetime*60*60);
		$epoch = $epoch - ($epoch % $write_interval);
		$console_end_datetime = RETURN_DATE_TIME($epoch);
	}
	elsif ( $console_end_datetime =~ m/m$/i ) 				{ 
		$console_end_datetime =~ s/m$//gi; 
		my $epoch = RETURN_EPOCH() - ($console_end_datetime*60);
		$epoch = $epoch - ($epoch % $write_interval);
		$console_end_datetime = RETURN_DATE_TIME($epoch);
	}
	elsif ( $console_end_datetime =~ m/^today$/i ) 		{ $console_end_datetime="$datestring.000000"; }		#Replace the entire string
	else											 	{ $console_end_datetime=~s/^today/$datestring/gi; } #Replace only the beginning
		
	#Split dates and times
	$console_start_date = (split ( /\./, $console_start_datetime ))[0];
	$console_start_time = (split ( /\./, $console_start_datetime ))[1];
	$console_end_date 	= (split ( /\./, $console_end_datetime ))[0];
	$console_end_time 	= (split ( /\./, $console_end_datetime ))[1];
	
	$next_printed_epoch=RETURN_EPOCH($console_start_date,$console_start_time);
	
	
	#Make sure zeros and year are set
	if ( length($console_start_date) == 4 )		{ $console_start_date=($console_start_date + (localtime->year() + 1900)*10000);}
	if ( length($console_end_date) == 4 ) 		{ $console_end_date=($console_end_date + (localtime->year() + 1900)*10000);}	
	if ( length($console_start_time) == 5 ) 	{ $console_start_time="0${console_start_time}"; }
	while ( length($console_start_time) < 6 ) 	{ $console_start_time="${console_start_time}0"; }
	if ( length($console_end_time) == 5 ) 		{ $console_end_time="0${console_end_time}"; }
	while ( length($console_end_time) < 6 ) 	{ $console_end_time="${console_end_time}0"; }
	
	
	debug ( 13 , "start: $console_start_date $console_start_time");
	debug ( 13 , "end:   $console_end_date $console_end_time");
}
sub GENERATE_OUTPUT_LOOP {
	SETUP_PS_COMMANDS;
	SETUP_NETWORK_COMMANDS;
	SETUP_SAR_COMMANDS; 
	SETUP_IOTOP_COMMANDS;
	SETUP_DF_COMMANDS;
	SETUP_LSBLK_COMMANDS;
	INITIALIZE_NEW_LOOP;
	SET_GLOBAL_DATE_TIME;
	@new_input_lines = ();
	
	SETUP_START_END_TIME;
	$console_loop_date = $console_start_date;
	
	$s = IO::Select->new();
	$s->add(\*STDIN);
	while ( $console_loop_date le $console_end_date ) {
		$date_dir = "$perfdata_dir/$console_loop_date";
		debug ( 12 , "date_dir is $date_dir");
		if ( -d "$date_dir" ) {
			debug ( 12 , "Opening dir $date_dir, temp_input_file $temp_input_file");
			if (( -f $temp_input_file ) || ( -f "$temp_input_file.gz" )) {
				$input_file = $temp_input_file;
			}
			else {
				$input_file = "$date_dir/$hostname.$console_loop_date.out";
			}
			debug ( 12 , "input_file \"$input_file\"");
			if ( -f "$input_file" || -f "$input_file.gz" ) {
				if ( -f "$input_file.gz" ) { 
					debug ( 12 , "gunzip \"$input_file.gz\"");
					qx/gunzip "$input_file.gz"/; 
				}
				if ( $input_file =~ m/\.gz/ ) { 
					debug ( 12 , "gunzip \"$input_file\"");
					qx/gunzip "$input_file"/; 
					$input_file = substr($input_file, 0, -3);
					debug ( 12 , "new input_file \"$input_file\"");
				}
				if ( tell($INPUTFILE) == -1 ) {
					open ( $INPUTFILE, "<", "$input_file") or die $!;
				}
				#Previous Day
				if ( $console_loop_date lt $datestring ) { 
					debug ( 12 , "Analyzing historical data from $console_loop_date");
					while (<$INPUTFILE>) {
						chomp $_;
						push (@new_input_lines, $_);
						if ( $_  =~ m/$endofloop/ ) {
							PARSE_NEW_LINES; 
						}
					}
					close ($INPUTFILE);
					#RDZ MIDNIGHT DEBUG
					if ( $timestring > "000100" ) {
						if (( ! -f "$input_file.gz" ) && ( -f "$input_file" )) {
							debug ( 0 , "A: console_loop_date $console_loop_date, datestring $datestring, timestring $timestring gzip -f \"$input_file\"");
							qx/gzip -f "$input_file"/;
						} else {
							debug ( 0 , "B: console_loop_date $console_loop_date, datestring $datestring, timestring $timestring did not gzip -f \"$input_file\" because of file existence");						
						}
					} else {
						debug ( 0 , "C: console_loop_date $console_loop_date, datestring $datestring, timestring $timestring did not gzip -f \"$input_file\" because of timestring"); #This is what is hit
					}
					debug ( 12 , "Before INC_LOOP_DATE(): console_loop_date $console_loop_date, datestring $datestring, timestring $timestring");
					INC_LOOP_DATE;
					debug ( 12 , "After INC_LOOP_DATE(): console_loop_date $console_loop_date, datestring $datestring, timestring $timestring");
				}
				#Today, continues to read file
				elsif ( $console_loop_date eq $datestring ) { 
					debug ( 12 , "Analyzing today's data $console_loop_date");
					while (<$INPUTFILE>) {
						chomp $_;
						push (@new_input_lines, $_);
						if ( $_  =~ m/$endofloop/ ) {
							debug ( 12 , "PARSE_NEW_LINES");
							PARSE_NEW_LINES; 
						}
					}
					if ( $csv_output ) { #Escapes loop to print csv file.  
						$console_loop_date = 99999999;
					} 
					else {
						if ( "$console_end_time" > "$timestring" ) {
							debug ( 12 , "console_end_time $console_end_time > timestring $timestring -> Seeking today" );
							#sleep $read_update_speed;
							if ($s->can_read($read_update_speed)) {
								chomp($stdin = <STDIN>);
								debug ( 12 , "Read $stdin from STDIN." );
								PRINT_SUMMARY_TO_CONSOLE;
								debug ( 1 , "Finished summary after user input, exiting script" );
								exit 0;	
							} else {
								debug ( 12 , "Did not read any user input to STDIN" );
							}
							seek INPUTFILE, 0 , 1;
						} else {
							debug ( 12 , "console_end_time $console_end_time lt timestring $timestring -> Done with today" );
							$console_end_date=0;
						}
					}
				}
			}
			else { 
				debug ( 12 , "!(-f \"$input_file\" || -f \"$input_file.gz\") -> Trying to increment console_loop_date in INC_LOOP_DATE()");
				INC_LOOP_DATE;
				sleep $read_update_speed;
			}
		}
		else { #Today's folder does not exist yet, must be mindnight.
			if ( $console_loop_date eq $datestring ) { 
				debug ( 0 , "Today's folder does not exist yet, must be mindnight. $console_loop_date eq $datestring -> Waiting for today's dir to be made, sleep $read_update_speed");
				sleep $read_update_speed;
			} 
			else {
				debug ( 0 , "Today's folder does not exist yet, must be mindnight. $console_loop_date !eq $datestring -> Trying to increment console_loop_date in INC_LOOP_DATE()");
				INC_LOOP_DATE;
				sleep $read_update_speed;
			}
		}
		if ( $temp_input_file ne '' ) {
			debug ( 12 , "Escape temp file");  
			$console_loop_date = 99999999;
			qx/gzip "$input_file"/; 
		}
		SET_GLOBAL_DATE_TIME;
	}
	PRINT_SUMMARY_TO_CONSOLE;
	if ( $csv_output ) {
		PRINT_CSV_OUTPUT;
	} 
	
	debug ( 1 , "Reached end of GENERATE_OUTPUT_LOOP, exiting script" );
	exit 0;	
}

sub MAIN {
	STARTUP_INITIALIZE;
	PARSE_ARGS;
	POST_PARSE_ARGS;
	
	if ( $cleanup_dirs ) {
		CLEAN_AND_GZIP_OLD_OUTPUT_FILES();
	}
	if ( $other_workload ) {
		debug ( 1 , "Other workload");
		if ( $monitor_response_times ) {
			WGET_RESPONSE_ADDRESS()
		}
		if ( $monitor_netstat_ports ) {
			MONITOR_NETSTAT()
		}
		exit 0;
	}
	if ( $kill_collection ) {
		KILL_COLLECTION;
	}
	CHECK_IF_RUNNING;
	if ( $start_collection_loop  ) {	#Run data collection
		use threads;
		PERFDATA_RUN_LOOP;
	}
	if ( $nohup_collect ) {				#Launch backgroud process to collect data
		NOHUP_LAUNCH_COLLECTION;
	}
	DETERMINE_CONSOLE_OUTPUT_SIZES;

	if ( length $regex ) {				#View data
		if (( $process_is_running == 0 ) && ( $disable_collection == 0 )) {
			NOHUP_LAUNCH_COLLECTION;
		}
		use IO::Select;
		GENERATE_OUTPUT_LOOP;
	}
}

MAIN();
exit 0;
