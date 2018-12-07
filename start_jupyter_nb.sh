#!/bin/bash

# script to start a jupyter notebook from a local computer on Euler
# Samuel Fux, Dec. 2018 @ETH Zurich

# function to print usage instructions
function print_usage {
        echo -e "Usage:\tstart_jupyter_nb.sh NETHZ_USERNAME NUM_CORES RUN_TIME MEM_PER_CORE\n"
        echo -e "Arguments:\n"
        echo -e "NETHZ_USERNAME\t\tNETHZ username for which the notebook should be started"
        echo -e "NUM_CORES\t\tNumber of cores to be used on the cluster (<36)"
        echo -e "RUN_TIME\t\tRun time limit for the jupyter notebook on the cluster (HH:MM)"
        echo -e "MEM_PER_CORE\t\tMemory limit in MB per core\n"
        echo -e "Example:\n"
        echo -e "./start_jupyter_nb.sh sfux 4 01:20 2048\n"
}

# if number of command line arguments is different from 4 or if $1==-h or $1==--help
if [ "$#" !=  4 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        print_usage
        exit
fi

# Parse and check command line arguments (NETHZ username, number of cores, run time limit, memory limit per NUM_CORES)
USERNAME="$1"
echo -e "NETHZ username: $USERNAME\n"
NUM_CORES=$2
# check if NUM_CORES is an integer
if ! [[ "$NUM_CORES" =~ ^[0-9]+$ ]]
    then
        echo -e "Incorrect format. Please specify number of cores as an integer and try again\n"
        print_usage
        exit
fi
# check if NUM_CORES is <= 36
if [ $NUM_CORES > 36 ]; then
    echo -e "No distributed memory supported, therefore number of cores needs to be smaller or equal to 36\n"
    print_usage
    exit
fi
echo -e "Jupyter notebook will run on $NUM_CORES cores\n"
RUN_TIME="$3"
# check if RUN_TIME is provided in HH:MM format
if ! [[ "$RUN_TIME" =~ ^[0-9][0-9]:[0-9][0-9]$ ]]; then
    echo -e "Incorrect format. Please specify runtime limit in the format HH:MM and try again\n"
    print_usage
    exit
else
    echo -e "Run time limit set to $RUN_TIME\n"
fi
MEM_PER_CORE=$4
# check if MEM_PER_CORE is an integer
if ! [[ "$MEM_PER_CORE" =~ ^[0-9]+$ ]]
    then
        echo -e "Memory limit must be an integer, please try again\n"
        print_usage
        exit
fi
echo -e "Memory per core set to $MEM_PER_CORE MB\n"

# check if some old files are left from a previous session and delete them
echo -e "Checking for leftover files from previous sessions"
ssh $USERNAME@euler.ethz.ch <<ENDSSH
if [ -f /cluster/home/$USERNAME/jnbinfo ]; then
        echo -e "Found old jnbinfo file, deleting it ..."
        rm /cluster/home/$USERNAME/jnbinfo
fi
if [ -f /cluster/home/$USERNAME/jnbip ]; then
	echo -e "Found old jnbip file, deleting it ..."
        rm /cluster/home/$USERNAME/jnbip
fi 
ENDSSH

# run the jupyter notebook job on Euler and save ip, port and the token
# in the files jnbip and jninfo in the home directory of the user on Euler
echo -e "Connecting to Euler to start jupyter notebook in a batch job"
ssh $USERNAME@euler.ethz.ch bsub -n $NUM_CORES -W $RUN_TIME -R "rusage[mem=$MEM_PER_CORE]"  <<ENDBSUB
module load new python/3.6.1
export XDG_RUNTIME_DIR=
IP_REMOTE="\$(hostname -i)"
echo "Remote IP:\$IP_REMOTE" >> /cluster/home/$USERNAME/jnbip
jupyter notebook --no-browser --ip "\$IP_REMOTE" &> /cluster/home/$USERNAME/jnbinfo 
ENDBSUB

# wait until jupyternotebook has started, poll every 10 seconds to check if $HOME/jupyternbinfo exists
# once the file exists and is not empty, the notebook has been startet and is listening
ssh $USERNAME@euler.ethz.ch "while ! [ -e /cluster/home/$USERNAME/jnbinfo -a -s /cluster/home/$USERNAME/jnbinfo ]; do echo 'Waiting for jupyter notebook to start, sleep for 10 sec'; sleep 10; done"

# get remote ip, port and token from files stored on Euler
echo -e "Receiving ip, port and token from jupyter notebook"
remoteip=$(ssh $USERNAME@euler.ethz.ch cat "/cluster/home/$USERNAME/jnbip | grep -m1 'Remote IP' | cut -d ':' -f 2")
remoteport=$(ssh $USERNAME@euler.ethz.ch "cat /cluster/home/$USERNAME/jnbinfo | grep -m1 token | cut -d '/' -f 3 | cut -d ':' -f 2")
jnbtoken=$(ssh $USERNAME@euler.ethz.ch "cat /cluster/home/$USERNAME/jnbinfo | grep -m1 token | cut -d '=' -f 2")

echo -e "Remote IP address: $remoteip"
echo -e "Remote port: $remoteport"
echo -e "Jupyter token: $jnbtoken"

# get a free port on local computer
echo -e "Determining free port on local computer"
PORTN=$(python -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')
echo -e "Local port: $PORTN"

# setup SSH tunnel from local computer to compute node via login node
echo -e "Setting up SSH tunnel for connecting the browser to the jupyter notebook"
ssh $USERNAME@euler.ethz.ch -L $PORTN:$remoteip:$remoteport -N &

# SSH tunnel is started in the background, pause 5 seconds to make sure
# it is established before starting the browser
sleep 5

# save url in variable
nburl=http://localhost:$PORTN/?token=$jnbtoken
echo -e "Starting browser and connecting it to jupyter notebook"
echo -e "Connecting to url "$nburl

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	xdg-open $nburl
elif [[ "$OSTYPE" == "darwin"* ]]; then
	open $nburl
else
	echo -e "Your operating system does not allow to start the browser automatically."
        echo -e "Please open $nburl in your browser."
fi
