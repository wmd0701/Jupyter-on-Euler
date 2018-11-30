#!/bin/bash

# script to start a jupyter notebook from a local computer on Euler

if [ "$#" -ne 1 ]; then
        echo -e "Usage:\tstart_jupyter_nb.sh USERNAME\n"
        echo -e "Arguments:\n"
        echo -e "USERNAME\t\tUsername for which the notebook should be started\n"
        exit
fi

# get username from command line argument
USERNAME=$1
echo -e "Username: $USERNAME"

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

# run the jupyter notebook job on Euler
echo -e "Connecting to Euler to start jupyter notebook in a batch job"
ssh $USERNAME@euler.ethz.ch bsub -n 1 -W 1:00 <<ENDBSUB
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

echo -e "Setting up SSH tunnel for connecting the browser to the jupyter notebook"
ssh $USERNAME@euler.ethz.ch -L $PORTN:$remoteip:$remoteport -N &

sleep 5
nburl=http://localhost:$PORTN/?token=$jnbtoken
echo -e "Starting browser and connecting it to jupyter notebook"
echo -e "url "$nburl

if [[ "$OS_TYPE" == "linux-gnu" ]]; then
	xdg-open $nburl
elif [[ "$OS_TYPE" == "darwin" ]]; then
	open $nburl
else
	echo "Open the url your browser."
fi
