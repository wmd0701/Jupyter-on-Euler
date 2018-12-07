# Jupyter on Euler

This shell script starts a Jupyter notebook in a batch job on Euler and connects your local browser with it.

## Requirements

The script assumes that you have setup SSH keys for passwordless access to the Euler cluster. Please find some instructions on how to create SSH keys on the scicomp wiki:

https://scicomp.ethz.ch/wiki/Accessing_the_clusters#SSH_keys

Currently the script runs on Linux and Mac OS X. When using a Linux computer, please make sure that xdg-open is installed. You can install it with the command

CentOS:

```
yum install xdg-utils
```

Ubuntu:

```
apt-get install xdg-utils
```

## Usage

./start_jupyter_nb.sh NETHZ_USERNAME NUM_CORES RUN_TIME MEM_PER_CORE

Arguments:

| NETHZ_USERNAME | NETHZ username for which the notebook should be started  
| NUM_CORES      | Number of cores to be used on the cluster (maximum: 36)  
| RUN_TIME       | Run time limit for the jupyter notebook on the cluster (HH:MM)  
| MEM_PER_CORE   | Memory limit in MB per core  

Example:

./start_jupyter_nb.sh sfux 4 01:20 2048

## Authors
* Samuel Fux
* Andrei Plamada

## Contributions
* Urban Borstnik
* Steven Armstrong
* Swen Vermeul