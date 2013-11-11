###############################################################################
# @file         check_procs_by_ssh.sh                                         #
# @author       Wollmann, Tobias <t.wollmann@bull.de>                         #
# @date         14/10/2013                                                    #
# @version      0.2                                                           #
# @param H      is used to set the hostname or ip-address of the target.      #
# @param u      is used to set the username that will run the command on the  #
#               remote host. Remember to exchange the public ssh-key before   #
#               you use this script.                                          #
# @param p      is a required parameter that provides the name of the process #
#               which is going to be checked.                                 #
# @param w      is an optional parameter to set the warning threshold. The    #
#               default value is set to 30 percent.                           #
# @param c      is also an optional parameter which is used to set the        #
#               critical threshold. The default value is set to 50 percent.   #
###############################################################################
#!/bin/bash

WARNING=30
CRITICAL=50

while getopts ":H:u:p:w:c:" opt; do
  case $opt in
    H)
      HOST=$OPTARG >&2
      ;;
    u)
      USER=$OPTARG >&2
      ;;
    p)
      PROCESS=$OPTARG >&2
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

PROC_COUNT=`ssh $USER@$HOST "ps -A | grep $PROCESS | wc -l" 2> /dev/null`

echo "$PROC_COUNT $WARNING $CRITICAL" | awk '{
	proc_count = $1;
	proc_warn = $2;
	proc_crit = $3;
	exitcode = 0;

	if(proc_count >= 1 && proc_count < proc_warn)
	{
		printf("PROCESS OK - ");
		exitcode = 0;
	}
	else if(proc_count >= proc_warn && proc_count < proc_crit)
	{
		printf("PROCESS WARNING - ");
		exitcode = 1;
	}
	else if(proc_count >= proc_crit || proc_count == 0)
	{
		printf("PROCESS CRITICAL - ");
		exitcode = 2;
	}
	else
	{
		printf("PROCESS UNKNOWN - ");
		exitcode = 3;
	}

	printf("%i processes are currently running;\| Processes running=%i;%i;%i;%i;%i\n", proc_count, proc_count, proc_warn, proc_crit, 0, proc_crit+5);
	exit exitcode;
}' 2> /dev/null
