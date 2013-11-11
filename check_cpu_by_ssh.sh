#!/bin/bash
#
# @file         check_cpu_by_ssh.sh
# @author       Wollmann, Tobias <t.wollmann@bull.de>
# @date         06/11/2013
# @version      0.1
# @param H      is used to set the hostname or ip-address of the target.
# @param u      is used to set the username that will run the command on the
#               remote host. Remember to exchange the public ssh-key before
#               you use this script.
# @param w      is an optional parameter to set the warning threshold. The
#               default value is set to 90 percent.
# @param c      is also an optional parameter which is used to set the
#               critical threshold. The default value is set to 95 percent.
# @param d      is used to set an individual delay between the redording of
#               the two datasets in seconds. The defualt delay is set to 1.
# @param m      should be used to set the performance indicator that should be
#               monitored. There are four different modes available:
#              	  0. Total CPU usage (default)
#                 1. User CPU usage
#                 2. Nice CPU usage
#                 3. System CPU usage
#               To get an complete overview about the systems workload it is
#               recommended to monitor all of these performance indicators.
#

WARNING="90"
CRITICAL="95"
MODE="0"
DELAY="1"

while getopts ":H:u:w:c:d:m:" opt; do
  case $opt in
    H)
      HOST=$OPTARG >&2
      ;;
    u)
      USER=$OPTARG >&2
      ;;
    w)
      WARNING=$OPTARG >&2
      ;;
    c)
      CRITICAL=$OPTARG >&2
      ;;
    d)
      DELAY=$OPTARG >&2
      ;;
    m)
      MODE=$OPTARG >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 3
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 3
      ;;
  esac
done

#Get the first and second dataset within the configured timeperiod.
CPU_1=`ssh -t $USER@$HOST "grep -i '^cpu ' /proc/stat" 2> /dev/null`
CPU_1=`echo $CPU_1 | awk '{ print $2 " " $3 " " $4 " " $5 }'`
sleep $DELAY
CPU_2=`ssh -t $USER@$HOST "grep -i '^cpu ' /proc/stat" 2> /dev/null`
CPU_2=`echo $CPU_2 | awk '{ print $2 " " $3 " " $4 " " $5 }'`
echo $CPU_1
echo $CPU_2

echo "$MODE $CPU_1 $CPU_2 $WARNING $CRITICAL" | awk '{
	#Sets the mode
	mode = $1;

	#Setting up required performance information for later use.
        perf_warn = $10;
        perf_crit = $11;
        perf_min = 0;
        perf_max = 100;

	#Calculates the difference between the performance indicators of the two datasets.
	diff_user = $6 - $2;
	diff_nice = $7 - $3;
	diff_idle = $9 - $5;
	diff_system = $8 - $4;
	diff_total = diff_user + diff_nice + diff_system;

	#Calculates the current performance data based uppon the chosen monitoring mode.
	if(mode == 0) {
		mode = "Total";
		perf_curr = (diff_total/(diff_total+diff_idle)*100);
	}
	else if(mode == 1) {
		mode = "User";
		perf_curr =  (diff_user/(diff_total+diff_idle)*100);
	}
	else if(mode == 2) {
		mode = "Nice";
		perf_curr = (diff_nice/(diff_total+diff_idle)*100);
	}
	else if(mode == 3) {
		mode = "System";
		perf_curr = (diff_system/(diff_total+diff_idle)*100);
	}
	else {
		printf("CPU WARNING: The monitoring mode does not exist.");
		exit 3;
	}

	#The performance data are going to be interpreted.
        if(perf_curr < perf_warn && perf_curr < perf_crit)
        {
                printf("CPU OK - Utilization: %.1f%;", perf_curr);
                errorcode = 0;
        }
        else if(perf_curr >= perf_warn && perf_curr < perf_crit)
        {
                printf("CPU WARNING - Utilization: %.1f%;", perf_curr);
                errorcode = 1;
        }
        else if(perf_curr >= perf_crit)
        {
                printf("CPU CRITICAL - Utilization: %.1f%;", perf_curr);
                errorcode = 2;
        }
        else
        {
                printf("CPU UNKNOWN - Utilization: %.1f%;", perf_curr);
                errorcode = 3;
        }

        printf("\| %s usage=%.1f%;%.1f;%.1f;%.1f;%.1f\n", mode, perf_curr, perf_warn, perf_crit, perf_min, perf_max);

        exit errorcode;

}' 2> /dev/null
