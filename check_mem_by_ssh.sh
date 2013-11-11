###############################################################################
# @file         check_mem_by_ssh.sh                                           #
# @author       Wollmann, Tobias <t.wollmann@bull.de>                         #
# @date         14/10/2013                                                    #
# @version      0.1                                                           #
# @param H      is used to set the hostname or ip-address of the target.      #
# @param u      is used to set the username that will run the command on the  #
#               remote host. Remember to exchange the public ssh-key before   #
#               you use this script.                                          #
# @param w      is an optional parameter to set the warning threshold. The    #
#               default value is set to 90 percent.                           #
# @param c      is also an optional parameter which is used to set the        #
#               critical threshold. The default value is set to 95 percent.   #
###############################################################################
#!/bin/bash

WARNING="90"
CRITICAL="95"
 
while getopts ":H:u:w:c:" opt; do
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

MEMTOTAL=`ssh $USER@$HOST "cat /proc/meminfo | grep -i '^memtotal'" | awk '{ print $2}'`
MEMFREE=`ssh $USER@$HOST "cat /proc/meminfo | grep -i '^memfree'" | awk '{ print $2}'`
BUFFERS=`ssh $USER@$HOST "cat /proc/meminfo | grep -i '^buffers'" | awk '{ print $2}'`
CACHED=`ssh $USER@$HOST "cat /proc/meminfo | grep -i '^cached'" | awk '{ print $2}'`

echo "$MEMTOTAL $MEMFREE $BUFFERS $CACHED $WARNING $CRITICAL" | awk '{
	perf_curr = ($1-$2-$3-$4)/1024;
	perf_warn = ($1/100*$5)/1024;
	perf_crit = ($1/100*$6)/1024;
	perf_min = 0;
	perf_max = $1/1024;
	
	if(perf_curr < perf_warn && perf_curr < perf_crit)
	{
		printf("MEMORY OK - free memory: %i MB ( %.1f%);", (perf_max-perf_curr), (100-(perf_curr/perf_max*100)));
		errorcode = 0;
	}
	else if(perf_curr >= perf_warn && perf_curr < perf_crit)
	{
		printf("MEMORY WARNING - free memory: %i MB ( %.1f%);", (perf_max-perf_curr), (100-(perf_curr/perf_max*100)));
		errorcode = 1;
	}
	else if(perf_curr >= perf_crit)
	{
		printf("MEMORY CRITICAL - free memory: %i MB ( %.1f%);", (perf_max-perf_curr), (100-(perf_curr/perf_max*100)));
		errorcode = 2;
	}
	else
	{
		printf("MEMORY UNKNOWN - free memory: %i MB ( %.1f%);", (perf_max-perf_curr), (100-(perf_curr/perf_max*100)));
		errorcode = 3;
	}

	printf("\| Memory usage=%iMB;%i;%i;%i;%i\n", perf_curr, perf_warn, perf_crit, perf_min, perf_max);

	exit errorcode;
}' 2> /dev/null
