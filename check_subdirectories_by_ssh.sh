###############################################################################
# @file         check_subdirectories_by_ssh.sh                                #
# @author       Wollmann, Tobias <t.wollmann@bull.de>                         #
# @date         01/26/2013                                                    #
# @version      0.1                                                           #
# @param H      is used to set the hostname or ip-address of the target.      #
# @param u      is used to set the username that will run the command on the  #
#               remote host. Remember to exchange the public ssh-key before   #
#               you use this script.                                          #
# @param w      is an optional parameter to set the warning threshold. The    #
#               default value is set to 90 percent.                           #
# @param c      is also an optional parameter which is used to set the        #
#               critical threshold. The default value is set to 95 percent.   #
# @param d      specifies the absolute path of the directorie that should be  #
#               monitored.                                                    #
# @param m      maximum count of supported links on the inode.                #
###############################################################################
#!/bin/bash

WARNING="90"
CRITICAL="95"
MAXIMUM="32000"

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
    m)
      MAXIMUM=$OPTARG >&2
      ;;
    d)
      DIRECTORY=$OPTARG >&2
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

LINKCOUNT=`ssh $USER@$HOST "stat -c '%h' $DIRECTORY"`

echo "$LINKCOUNT $MAXIMUM $WARNING $CRITICAL $DIRECTORY" | awk '{
	perf_warn = $2 / 100 * $3;
	perf_crit = $2 / 100 * $4;
	perf_min = 0;
	perf_max = $2;

	perf_curr = $1;

	# Analyse the performance data.
	if(perf_curr < perf_warn && perf_curr < perf_crit)
        {
                printf("DIRECTORY OK - Link count: %i/%i;", perf_curr, perf_max);
                errorcode = 0;
        }
        else if(perf_curr >= perf_warn && perf_curr < perf_crit)
        {
                printf("DIRECTORY WARNING - Link count: %i/%i;", perf_curr, perf_max);
                errorcode = 1;
        }
        else if(perf_curr >= perf_crit)
        {
                printf("DIRECTORY CRITICAL - Link count: %i/%i;", perf_curr, perf_max);
                errorcode = 2;
        }
        else
        {
                printf("DIRECTORY UNKNOWN - Link count: %i/%i;", perf_curr, perf_max);
                errorcode = 3;
        }

	printf("\| %s=%i;%i;%i;%i;%i\n", $5, perf_curr, perf_warn, perf_crit, perf_min, perf_max);

	exit errorcode;
}' 2> /dev/null
