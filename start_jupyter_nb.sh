#!/bin/bash

# Script to start a jupyter notebook from a local computer on Euler/Leonhard Open
# Samuel Fux, Dec. 2018 @ETH Zurich
# change history:
# 24.01.2019    Added option to specify cluster on which the notebook is executed
# 01.10.2019    Added bash and R kernels for jupyter notebooks
# 02.04.2020    Added reconnect_info file that contains all information to reconnect to a notebook
# 17.08.2020    Added a section with configuration options to specify non-standard SSH keys
# 23.07.2021    Added partial support for windows 10 with git-bash (thank you Henry Lütcke for the input)
# 24.08.2021    Added config file and removed Leonhard Open

#########################
# Configuration options #
#########################

# SSH key location is the path to your SSH key. Please specify the path if you are using a non-standard name for your SSH key
SSH_KEY_LOCATION=""

# Waiting time interval after starting the jupyter notebook. Check every $WAITING_TIME_INTERVAL seconds if the job already started
WAITING_TIME_INTERVAL=60

#############################
# End configuration options #
#############################

# check if SSH_KEY_LOCATION is empty or contains a valid path
if [ -z "$SSH_KEY_LOCATION" ]; then
    SSH_KEY_OPTION=""
else
    SSH_KEY_OPTION="-i $SSH_KEY_LOCATION"
fi

# function to print usage instructions
function print_usage {
        echo -e 'Usage:\t start_jupyter_nb.sh CONFIG_FILE\n'
        echo -e 'Arguments:\n'
        echo -e 'CONFIG_FILE format:\t\t'
        echo -e '    USERNAME=jarunanp'
        echo -e '    NUM_CORES=4'
        echo -e '    NUM_GPUS=2'
        echo -e '    RUN_TIME=4:00'
        echo -e '    MEM_PER_CORE=2048'
        echo -e '    MODULES="gcc/6.3.0 python_gpu/3.8.5 eth_proxy"\n'
        echo -e '    WORKDIR=/cluster/scratch/jarunanp\n'
        echo -e 'Example:'
        echo -e '    ./start_jupyter_nb.sh config.txt \n'
}

# if number of command line arguments is different from 5 or if $1==-h or $1==--help
if [ "$#" !=  1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    print_usage
    exit
fi


# find out in which directory the script is located
SCRIPTDIR=$(pwd)

#========================================================================
# Parse variables from config file
#========================================================================
# Source config file
source $1

#-----------------
# CLUSTERNAME
#-----------------
CLUSTERNAME="Euler"
CHOSTNAME="euler.ethz.ch"
echo -e "\nCluster: $CLUSTERNAME"

#-----------------
# USERNAME
#-----------------
# no need to do checks on the username. If it is wrong, the SSH commands will not work
echo -e "\nUsername: $USERNAME"
# define the jupyter folder
JNB_DIR=/cluster/home/$USERNAME/jnb

#-----------------
# NUM_CORES
#-----------------
# check if NUM_CORES is an integer
if ! [[ "$NUM_CORES" =~ ^[0-9]+$ ]]; then
    echo -e "Incorrect format. Please specify number of cores as an integer and try again.\n"
    print_usage
    exit
fi
# check if NUM_CORES is <= 36
if [ "$NUM_CORES" -gt "36" ]; then
    echo -e "No distributed memory supported, therefore number of cores needs to be smaller or equal to 36.\n"
    print_usage
    exit
fi
echo -e "Jupyter notebook will run on $NUM_CORES cores"


#-----------------
# NUM_GPUS
#-----------------
# check if NUM_GPUS is an integer
if ! [[ "$NUM_GPUS" =~ ^[0-9]+$ ]]; then
    echo -e "Incorrect format. Please specify number of cores as an integer and try again.\n"
    print_usage
    exit
fi
# check if NUM_GPUS is <= 8
if [ "$NUM_GPUS" -gt "8" ]; then
    echo -e "No distributed memory supported, therefore number of gpus needs to be smaller or equal to 8.\n"
    print_usage
    exit
fi
echo -e "Jupyter notebook will run on $NUM_GPUS gpus"

#-----------------
# Run time limit
#-----------------
# check if RUN_TIME is provided in HH:MM format
if ! [[ "$RUN_TIME" =~ ^[0-9][0-9]:[0-9][0-9]$ ]]; then
    echo -e "Incorrect format. Please specify runtime limit in the format HH:MM and try again\n"
    print_usage
    exit
else
    echo -e "Run time limit set to $RUN_TIME"
fi

#-----------------
# Memory per core
#-----------------
# check if MEM_PER_CORE is an integer
if ! [[ "$MEM_PER_CORE" =~ ^[0-9]+$ ]]
    then
        echo -e "Memory limit must be an integer, please try again\n"
        print_usage
        exit
fi
echo -e "Memory per core set to $MEM_PER_CORE MB\n"


#-----------------
# modules
#-----------------
PCOMMAND=$MODULES
echo -e "Load these modules: $MODULES\n"

#-----------------
# check if some old files are left from a previous session and delete them
#-----------------
echo -e "Checking for left over files from previous sessions"
if [ -f $SCRIPTDIR/reconnect_info ]; then
        echo -e "Found old reconnect_info file, deleting it ..."
        rm $SCRIPTDIR/reconnect_info
fi
ssh $SSH_KEY_OPTION -T $USERNAME@$CHOSTNAME <<ENDSSH
if [ -f $JNB_DIR/jnbinfo ]; then
        echo -e "Found old jnbinfo file, deleting it ..."
        rm $JNB_DIR/jnbinfo
fi
if [ -f $JNB_DIR/jnbip ]; then
	      echo -e "Found old jnbip file, deleting it ..."
        rm $JNB_DIR/jnbip
fi 
ENDSSH

#========================================================================
# Run the jupyter notebook job on Euler
# and save ip, port and the token in the files jnbip and jninfo
# in the home directory of the user on Euler
#========================================================================
echo -e "Connecting to $CLUSTERNAME to start jupyter notebook in a batch job"
ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME bsub -n $NUM_CORES -W $RUN_TIME -R "rusage[mem=$MEM_PER_CORE]" -R "rusage[ngpus_excl_p=$NUM_GPUS]" <<ENDBSUB
env2lmod
module load $PCOMMAND
export XDG_RUNTIME_DIR=
IP_REMOTE="\$(hostname -i)"
mkdir -p $JNB_DIR
cd $WORKDIR
echo "Remote IP:\$IP_REMOTE" >> $JNB_DIR/jnbip
jupyter notebook --no-browser --ip "\$IP_REMOTE" &> $JNB_DIR/jnbinfo 
ENDBSUB

#-----------------
# wait until jupyternotebook has started, poll every $WAITING_TIME_INTERVAL seconds
# to check if $HOME/jupyternbinfo exists
# once the file exists and is not empty, the notebook has been started and is listening
#-----------------
ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME "while ! [ -e $JNB_DIR/jnbinfo -a -s $JNB_DIR/jnbinfo ]; do echo 'Waiting for jupyter notebook to start, sleep for $WAITING_TIME_INTERVAL sec'; sleep $WAITING_TIME_INTERVAL; done"

#-----------------
# get remote ip, port and token from files stored on Euler
#-----------------
echo -e "Receiving ip, port and token from jupyter notebook"
remoteip=$(ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME "cat $JNB_DIR/jnbip | grep -m1 'Remote IP' | cut -d ':' -f 2")
remoteport=$(ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME "cat $JNB_DIR/jnbinfo | grep -m1 token | cut -d '/' -f 3 | cut -d ':' -f 2")
jnbtoken=$(ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME "cat $JNB_DIR/jnbinfo | grep -m1 token | cut -d '=' -f 2")

if  [[ "$remoteip" == "" ]]; then
    echo -e "Error: remote ip is not defined. Terminating script."
    echo -e "Please login to the cluster and check with bjobs if the batch job is still running."
    exit 1
fi

if  [[ "$remoteport" == "" ]]; then
    echo -e "Error: remote port is not defined. Terminating script."
    echo -e "Please login to the cluster and check with bjobs if the batch job is still running."
    exit 1
fi

if  [[ "$jnbtoken" == "" ]]; then
    echo -e "Error: token for the jupyter notebook is not defined. Terminating script."
    echo -e "Please login to the cluster and check with bjobs if the batch job is still running."
    exit 1
fi

echo -e "Remote IP address: $remoteip"
echo -e "Remote port: $remoteport"
echo -e "Jupyter token: $jnbtoken"

#-----------------
# get a free port on local computer
#-----------------
echo -e "Determining free port on local computer"
PORTN=$(python -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')
echo -e "Local port: $PORTN"

#-----------------
# write reconnect_info file
#-----------------
echo -e "Restart file \n" >> $SCRIPTDIR/reconnect_info
echo -e "Remote IP address: $remoteip\n" >> $SCRIPTDIR/reconnect_info
echo -e "Remote port: $remoteport\n" >> $SCRIPTDIR/reconnect_info
echo -e "Local port: $PORTN\n" >> $SCRIPTDIR/reconnect_info
echo -e "Jupyter token: $jnbtoken\n" >> $SCRIPTDIR/reconnect_info
echo -e "SSH tunnel: ssh $USERNAME@$CHOSTNAME -L $PORTN:$remoteip:$remoteport -N &\n" >> $SCRIPTDIR/reconnect_info
echo -e "URL: http://localhost:$PORTN/?token=$jnbtoken\n" >> $SCRIPTDIR/reconnect_info

#-----------------
# setup SSH tunnel from local computer to compute node via login node
#-----------------
echo -e "Setting up SSH tunnel for connecting the browser to the jupyter notebook"
ssh $SSH_KEY_OPTION $USERNAME@$CHOSTNAME -L $PORTN:$remoteip:$remoteport -N &

# SSH tunnel is started in the background, pause 5 seconds to make sure
# it is established before starting the browser
sleep 5

#-----------------
# save url in variable
#-----------------
nburl=http://localhost:$PORTN/?token=$jnbtoken
echo -e "Starting browser and connecting it to jupyter notebook"
echo -e "Connecting to url "$nburl

if [[ "$OSTYPE" == "linux-gnu" ]]; then
        xdg-open $nburl
elif [[ "$OSTYPE" == "darwin"* ]]; then
        open $nburl
elif [[ "$OSTYPE" == "msys" ]]; then # Git Bash on Windows 10
        start $nburl
else
        echo -e "Your operating system does not allow to start the browser automatically."
        echo -e "Please open $nburl in your browser."
fi
