#!/bin/bash

###############################################################################
#                                                                             #
#  Script to start a jupyter notebook on Euler from a local computer          #
#                                                                             #
#  Main author    : Samuel Fux, Dec. 2018                                     #
#  Contributions  : Andrei Plamada, Urban Borsnik, Steven Armstrong,          #
#                   Jarunan Panyasantisuk, Swen Vermeul                       #
#  Date           : December 2018                                             #
#  Location       : ETH Zurich                                                #
#  Version        : 1.0                                                       #
#  Change history :                                                           #
#                                                                             #
#  26.10.2021    The script was rewritten:                                    #
#                * clean up of the code (naming scheme for variables)         #
#                * replaced multiline echo's with heredoc's                   #
#                * added command line parser for options                      #
#                * added option for config file                               #
#                * added option for working directory of the notebook         #
#                * jnbip file no longer required                              #
#                * added choice for software stack (old/new)                  #
#                * added more bsub options                                    #
#                                                                             #
#  23.07.2021    Added partial support for windows 10 with git-bash (thank    #
#                you Henry Lütcke for the input)                              #
#                                                                             #
#  17.08.2020    Added a section with configuration options to specify        #
#                non-standard locations for keys                              #
#                                                                             #
#  02.04.2020    Added reconnect_info file that contains all information to   #
#                reconnect to a notebook                                      #
#                                                                             #
#  01.10.2019    Added bash and R kernels for jupyter notebooks               #
#                                                                             #
#  24.01.2019    Added option to specify cluster on which the notebook is     #
#                executed                                                     #
#                                                                             #
###############################################################################

###############################################################################
# Configuration options, initalising variables and setting default values     #
###############################################################################

# Version
JNB_VERSION="1.0"

# Script directory
JNB_SCRIPTDIR=$(pwd)

# hostname of the cluster to connect to
JNB_HOSTNAME="euler.ethz.ch"

# order for initializing configuration options
# 1. Defaults values set inside this script
# 2. Command line options overwrite defaults
# 3. Config file options  overwrite command line options

# Configuration file default    : $HOME/.jnb_config
JNB_CONFIG_FILE="$HOME/.jnb_config"

# Username default              : no default
JNB_USERNAME=""

# Number of CPU cores default   : 1 CPU core
JNB_NUM_CPU=1

# Runtime limit default         : 1:00 hour
JNB_RUN_TIME="01:00"

# Memory default                : 1024 MB per core
JNB_MEM_PER_CPU_CORE=1024

# Number of GPUs default        : 0 GPUs
JNB_NUM_GPU=0

# Waiting interval default      : 60 seconds
JNB_WAITING_INTERVAL=60

# SSH key location default      : no default
JNB_SSH_KEY_PATH=""

# Software stack default        : new
JNB_SOFTWARE_STACK="new"

# Workdir default               : $HOME
JNB_WORKING_DIR="$HOME"

###############################################################################
# Usage instructions                                                          #
###############################################################################

function display_help {
cat <<-EOF
$0: Script to start a jupyter notebook on Euler from a local computer

Usage: start_jupyter_nb.sh [options]

Options:

        -u | --username       USERNAME         ETH username for SSH connection to Euler
        -n | --numcores       NUM_CPU          Number of CPU cores to be used on the cluster
        -W | --runtime        RUN_TIME         Run time limit for the jupyter notebook in hours and minutes HH:MM
        -m | --memory         MEM_PER_CORE     Memory limit in MB per core

Optional arguments:

        -c | --config         CONFIG_FILE      Configuration file for specifying options
        -g | --numgpu         NUM_GPU          Number of GPUs to be used on the cluster
        -h | --help                            Display help for this script and quit
        -i | --interval       INTERVAL         Time interval for checking if the job on the cluster already started
        -k | --key            SSH_KEY_PATH     Path to SSH key with non-standard name
        -s | --softwarestack  SOFTWARE_STACK   Software stack to be used (old, new)
        -v | --version                         Display version of the script and exit
        -w | --workdir        WORKING_DIR      Working directory for the jupyter notebook

Examlples:

        ./start_jupyter_nb.sh -u sfux -n 4 -W 04:00 -m 2048 -w /cluster/scratch/sfux

        ./start_jupyter_nb.sh --username sfux --numcores 2 --runtime 01:30 --memory 2048 --softwarestack new

        ./start_jupyter_nb.sh -c $HOME/.jnb_config

Format of configuration file:

JNB_USERNAME=""             # ETH username for SSH connection to Euler
JNB_NUM_CPU=1               # Number of CPU cores to be used on the cluster
JNB_NUM_GPU=0               # Number of GPUs to be used on the cluster
JNB_RUN_TIME="01:00"        # Run time limit for the jupyter notebook in hours and minutes HH:MM
JNB_MEM_PER_CPU_CORE=1024   # Memory limit in MB per core
JNB_WAITING_INTERVAL=60     # Time interval to check if the job on the cluster already started
JNB_SSH_KEY_PATH=""         # Path to SSH key with non-standard name
JNB_SOFTWARE_STACK="new"    # Software stack to be used (old, new)
JNB_WORKING_DIR="$HOME"     # Working directory for the jupyter notebook

EOF
exit 1
}

###############################################################################
# Parse configuration options                                                 #
###############################################################################

while [[ $# -gt 0 ]]
do
        case $1 in
                -h|--help)
                display_help
                ;;
                -v|--version)
                echo -e "start_jupyter_nb.sh version: $JNB_VERSION\n"
                exit
                ;;
                -u|--username)
                JNB_USERNAME=$2
                shift
                shift
                ;;
                -n|--numcores)
                JNB_NUM_CPU=$2
                shift
                shift
                ;;
                -W|--runtime)
                JNB_RUN_TIME=$2
                shift
                shift
                ;;
                -m|--memory)
                JNB_MEM_PER_CPU_CORE=$2
                shift
                shift
                ;;
                -c|--config)
                JNB_CONFIG_FILE=$2
                shift
                shift
                ;;
                -g|--numgpu)
                JNB_NUM_GPU=$2
                shift
                shift
                ;;
                -i|--interval)
                JNB_WAITING_INTERVAL=$2
                shift
                shift
                ;;
                -k|--key)
                JNB_SSH_KEY_PATH=$2
                shift
                shift
                ;;
                -s|--softstack)
                JNB_SOFTWARE_STACK=$2
                shift
                shift
                ;;
                -w|--workdir)
                JNB_WORKING_DIR=$2
                shift
                shift
                ;;
                *)
                echo -e "Warning: ignoring unknown option $1 \n"
                shift
                ;;
        esac
done

###############################################################################
# Check configuration options                                                 #
###############################################################################

# check if user has a configuration file and source it to initialize options
if [ -f "$JNB_CONFIG_FILE" ]; then
        echo -e "Found configuration file $JNB_CONFIG_FILE"
        echo -e "Initializing configuration from file ${JNB_CONFIG_FILE}:"
        cat "$JNB_CONFIG_FILE"
        source "$JNB_CONFIG_FILE"
fi

# check that username is not an empty string
if [ -z "$JNB_USERNAME" ]
then
        echo -e "Error: No ETH username is specified, terminating script\n"
        display_help
else
        echo -e "ETH username: $JNB_USERNAME"
fi

# check number of CPU cores

# check if NUMCPU an integer
if ! [[ "$JNB_NUM_CPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $JNB_NUM_CPU -> Incorrect format. Please specify number of CPU cores as an integer and try again\n"
        display_help
fi

# check if NUMCPU is <= 128
if [ "$JNB_NUM_CPU" -gt "128" ]; then
        echo -e "Error: $JNB_NUM_CPU -> Larger than 128. No distributed memory supported, therefore the number of CPU cores needs to be smaller or equal to 128\n"
        display_help
fi

if [ "$JNB_NUM_CPU" -gt "0" ]; then
        echo -e "Requesting $JNB_NUM_CPU CPU cores for running the jupyter notebook"
fi

# check number of GPUs

# check if NUMGPU an integer
if ! [[ "$JNB_NUM_GPU" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $JNB_NUM_GPU -> Incorrect format. Please specify the number of GPU as an integer and try again\n"
        display_help
fi

# check if NUMGPU is <= 8
if [ "$JNB_NUM_GPU" -gt "8" ]; then
        echo -e "Error: No distributed memory supported, therefore number of GPUs needs to be smaller or equal to 8\n"
        display_help
fi

if [ "$JNB_NUM_GPU" -gt "0" ]; then
        echo -e "Requesting $JNB_NUM_GPU GPUs for running the jupyter notebook"
        JNB_SNUM_GPU="-R \"rusage[ngpus_excl_p=$JNB_NUM_GPU]\""
else
        JNB_SNUM_GPU=""
fi

if [ ! "$JNB_NUM_CPU" -gt "0" -a ! "$JNB_NUM_GPU" -gt "0" ]; then
        echo -e "Error: No CPU and no GPU resources requested, terminating script"
        display_help
fi

# check if RUNTIME is provided in HH:MM format
if ! [[ "$JNB_RUN_TIME" =~ ^[0-9][0-9]:[0-9][0-9]$ ]]; then
        echo -e "Error: $JNB_RUN_TIME -> Incorrect format. Please specify runtime limit in the format HH:MM and try again\n"
        display_help
else
    echo -e "Run time limit set to $JNB_RUN_TIME"
fi

# check if MEM is an integer
if ! [[ "$JNB_MEM_PER_CPU_CORE" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $JNB_MEM_PER_CPU_CORE -> Memory limit must be an integer, please try again\n"
        display_help
else
    echo -e "Memory per core set to $JNB_MEM_PER_CPU_CORE MB"
fi

# check if INTERVAL is an integer
if ! [[ "$JNB_WAITING_INTERVAL" =~ ^[0-9]+$ ]]; then
        echo -e "Error: $JNB_WAITING_INTERVAL -> Waiting time interval [seconds] must be an integer, please try again\n"
        display_help
else
    echo -e "Setting waiting time interval for checking the start of the job to $JNB_WAITING_INTERVAL seconds"
fi

# check if KPATH is empty or contains a valid path
if [ -z "$JNB_SSH_KEY_PATH" ]; then
        JNB_SKPATH=""
else
        JNB_SKPATH="-i $JNB_SSH_KEY_PATH"
        echo -e "Using SSH key $JNB_SSH_KEY_PATH"
fi

# check which software stack to use
case $JNB_SOFTWARE_STACK in
        old)
        JNB_MODULE_COMMAND="new gcc/4.8.2 r/3.6.0 python/3.6.1 eth_proxy"
        echo -e "Using old software stack (new gcc/4.8.2 r/3.6.0 python/3.6.1 eth_proxy)"
        ;;
        new)
        JNB_MODULE_COMMAND="gcc/6.3.0 python/3.8.5 eth_proxy"
        echo -e "Using new software stack (gcc/6.3.0 python/3.8.5 eth_proxy)"
        ;;
        *)
        echo -e "Error: $JNB_SOFTWARE_STACK -> Unknown software stack. Software stack either needs to be set to 'new' or 'old'\n"
        display_help
        ;;
esac

# put together string for SSH options
JNB_SSH_OPT="$JNB_SKPATH $JNB_USERNAME@$JNB_HOSTNAME"

###############################################################################
# Check for leftover files                                                    #
###############################################################################

# check if some old files are left from a previous session and delete them

# check for reconnect_info in the current directory on the local computer
echo -e "Checking for left over files from previous sessions"
if [ -f $JNB_SCRIPTDIR/reconnect_info ]; then
        echo -e "Found old reconnect_info file, deleting it ..."
        rm $JNB_SCRIPTDIR/reconnect_info
fi

# check for log files from a previous session in the home directory of the cluster
ssh -T $JNB_SSH_OPT <<ENDSSH
if [ -f /cluster/home/$JNB_USERNAME/jnbinfo ]; then
        echo -e "Found old jnbinfo file, deleting it ..."
        rm /cluster/home/$JNB_USERNAME/jnbinfo
fi
ENDSSH

###############################################################################
# Start jupyter notebook on the cluster                                       #
###############################################################################

# run the jupyter notebook job on Euler and save ip, port and the token in the files jnbip and jninfo in the home directory of the user on Euler
echo -e "Connecting to $JNB_HOSTNAME to start jupyter notebook in a batch job"
# FIXME: save jobid in a variable, that the script can kill the batch job at the end
ssh $JNB_SSH_OPT bsub -n $JNB_NUM_CPU -W $JNB_RUN_TIME -R "rusage[mem=$JNB_MEM_PER_CPU_CORE]" $JNB_SNUM_GPU  <<ENDBSUB
module load $JNB_MOUDLE_COMMAND
export XDG_RUNTIME_DIR=
IP_REMOTE="\$(hostname -i)"
jupyter notebook --no-browser --ip "\$IP_REMOTE" --notebook-dir $JNB_WORKING_DIR &> /cluster/home/$JNB_USERNAME/jnbinfo
ENDBSUB

# wait until jupyternotebook has started, poll every $JNB_WAITING_INTERVAL seconds to check if /cluster/home/$JNB_USERNAME/jupyternbinfo exists
# once the file exists and is not empty, the notebook has been startet and is listening
ssh $JNB_SSH_OPT <<ENDSSH
while ! [ -e /cluster/home/$JNB_USERNAME/jnbinfo -a -s /cluster/home/$JNB_USERNAME/jnbinfo ]; do
        echo 'Waiting for jupyter notebook to start, sleep for $JNB_WAITING_INTERVAL sec'
        sleep $JNB_WAITING_INTERVAL
done
ENDSSH

# get remote ip, port and token from files stored on Euler
echo -e "Receiving ip, port and token from jupyter notebook"
JNB_REMOTE_IP=$(ssh $JNB_SSH_OPT "\$(hostname -i)")
JNB_REMOTE_PORT=$(ssh $JNB_SSH_OPT "cat /cluster/home/$JNB_USERNAME/jnbinfo | grep -m1 token | cut -d '/' -f 3 | cut -d ':' -f 2")
JNB_TOKEN=$(ssh $JNB_SSH_OPT "cat /cluster/home/$JNB_USERNAME/jnbinfo | grep -m1 token | cut -d '=' -f 2")

# check if the IP, the port and the token are defined
if  [[ "$JNB_REMOTE_IP" == "" ]]; then¨
        cat <<-EOF
        Error: remote ip is not defined. Terminating script.
        * Please check login to the cluster and check with bjobs if the batch job on the cluster is running and terminate it with bkill.
        * Please check the /cluster/home/$JNB_USERNAME/jnbinfo for logs regarding the failure to identify the remote ip on the cluster
        EOF
        exit 1
fi

if  [[ "$JNB_REMOTE_PORT" == "" ]]; then
        cat <<-EOF
        Error: remote port is not defined. Terminating script.
        * Please check login to the cluster and check with bjobs if the batch job on the cluster is running and terminate it with bkill.
        * Please check the /cluster/home/$JNB_USERNAME/jnbinfo for logs regarding the failure to identify the remote ip on the cluster
        EOF
        exit 1
fi

if  [[ "$JNB_TOKEN" == "" ]]; then
        cat <<-EOF
        Error: token for the jupyter notebook session is not defined. Terminating script.
        * Please check login to the cluster and check with bjobs if the batch job on the cluster is running and terminate it with bkill.
        * Please check the /cluster/home/$JNB_USERNAME/jnbinfo for logs regarding the failure to identify the remote ip on the cluster
        EOF
        exit 1
fi

# print information about IP, port and token
echo -e "Remote IP address: $JNB_REMOTE_IP"
echo -e "Remote port: $JNB_REMOTE_PORT"
echo -e "Jupyter token: $JNB_TOKEN"

# get a free port on local computer
# FIXME: check if there is a solution that does not require python (as Windows computers don't have Python installed by default)
echo -e "Determining free port on local computer"
JNB_LOCAL_PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()')
echo -e "Using local port: $JNB_LOCAL_PORT"

# write reconnect_info file
cat <<EOF > $JNB_SCRIPTDIR/reconnect_info
Restart file
Remote IP address : $JNB_REMOTE_IP
Remote port       : $JNB_REMOTE_PORT
Local port        : $JNB_LOCAL_PORT
Jupyter token     : $JNB_TOKEN
SSH tunnel        : ssh $JNB_SSH_OPT -L $JNB_LOCAL_PORT:$JNB_REMOTE_IP:$JNB_REMOTE_PORT -N &
URL               : http://localhost:$JNB_LOCAL_PORT/?token=$JNB_TOKEN
EOF

# setup SSH tunnel from local computer to compute node via login node
# FIXME: check if the tunnel can be managed via this script (opening, closing) by using a control socket from SSH
echo -e "Setting up SSH tunnel for connecting the browser to the jupyter notebook"
ssh $JNB_SSH_OPT -L $JNB_LOCAL_PORT:$JNB_REMOTE_IP:$JNB_REMOTE_PORT -N &

# SSH tunnel is started in the background, pause 5 seconds to make sure
# it is established before starting the browser
sleep 5

# save url in variable
JNB_URL=http://localhost:$JNB_LOCAL_PORT/?token=$JNB_TOKEN
echo -e "Starting browser and connecting it to jupyter notebook"
echo -e "Connecting to url $JNB_URL"

# start local browser if possible
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        xdg-open $JNB_URL
elif [[ "$OSTYPE" == "darwin"* ]]; then
        open $JNB_URL
elif [[ "$OSTYPE" == "msys" ]]; then # Git Bash on Windows 10
        start $JNB_URL
else
        echo -e "Your operating system does not allow to start the browser automatically."
        echo -e "Please open $JNB_URL in your browser."
fi
