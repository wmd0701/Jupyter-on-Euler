# Jupyter on Euler

When you run this shell script on your local computer, then it starts a Jupyter notebook in a batch job on Euler and connects your local browser with it.

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

Download the repository with the commnad

```
git clone https://gitlab.ethz.ch/sfux/jupyter-on-euler
```

After downloading the script from gitlab.ethz.ch, you need to change its permissions to make it executable

```
chmod 755 start_jupyter_nb.sh
```

Running the script:

```
./start_jupyter_nb.sh NETHZ_USERNAME NUM_CORES RUN_TIME MEM_PER_CORE
```


| Argument       | Description |
|----------------|---------------------------------------------------------|
| NETHZ_USERNAME | NETHZ username for which the notebook should be started | 
| NUM_CORES      | Number of cores to be used on the cluster (maximum: 36) | 
| RUN_TIME       | Run time limit for the jupyter notebook on the cluster (HH:MM) |  
| MEM_PER_CORE   | Memory limit in MB per core |

Example:

```
./start_jupyter_nb.sh sfux 4 01:20 2048
```

Please note that when you finish working with the jupyter notebook, you need to click on the "Quit" button in your Browser. This will stop the batch job running on Euler. Afterwards you also need to clean up the SSH tunnel that is running in the background. Example:

```
samfux@bullvalene:~/jupyter-on-euler$ ps -u | grep -m1 -- "-L" | grep -- "-N"
samfux    8729  0.0  0.0  59404  6636 pts/5    S    13:46   0:00 ssh sfux@euler.ethz.ch -L 51339:10.205.4.122:8888 -N
samfux@bullvalene:~/jupyter-on-euler$ kill 8729
```

## Authors
* Samuel Fux
* Andrei Plamada

## Contributions
* Urban Borstnik
* Steven Armstrong
* Swen Vermeul