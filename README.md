# Jupyter on Euler or Leonhard Open
This project aims to help beginner users to run simple jupyter notebooks on our HPC clusters Euler and Leonhard. It is not addressing advanced users that need a wide range of additional features going beyond simple jupyter notebooks. There will soon be an new section added, providing hints for advanced users on how to run jupyer notebooks without this script.

When you run this shell script on your local computer, then it starts a Jupyter notebook in a batch job on Euler/Leonhard Open (depending on which cluster you choose) and connects your local browser with it.

## Requirements

The script assumes that you have setup SSH keys for passwordless access to the cluster. Please find some instructions on how to create SSH keys on the scicomp wiki:

https://scicomp.ethz.ch/wiki/Accessing_the_clusters#SSH_keys

Please note that the example on the wiki refers to the Euler cluster and for Leonhard Open, then hostname needs to be changed from

```
euler.ethz.ch
```

to

```
login.leonhard.ethz.ch
```

Currently the script runs on Linux and Mac OS X. Windows is not supported as the script is written in bash and uses a Python command. When using a Linux computer, please make sure that xdg-open is installed. This package is used to automatically start your default browser. You can install it with the command

CentOS:

```
yum install xdg-utils
```

Ubuntu:

```
apt-get install xdg-utils
```

Further more, the script requires that there is a Python installation available, which is usually included in the Linux distribution or Mac OS.

## Usage

### Install

Download the repository with the commnad

```
git clone https://gitlab.ethz.ch/sfux/Jupyter-on-Euler-or-Leonhard-Open
```

After downloading the script from gitlab.ethz.ch, you need to change its permissions to make it executable

```
chmod 755 start_jupyter_nb.sh
```

### Run Jupyter in a batch job

The start_jupyer_nb.sh script needs to be executed on your local computer:

```
./start_jupyter_nb.sh CLUSTER NETHZ_USERNAME NUM_CORES RUN_TIME MEM_PER_CORE
```


| Argument       | Description |
|----------------|---------------------------------------------------------|
| CLUSTER        | Name of the cluster (Euler or LeoOpen) |
| NETHZ_USERNAME | NETHZ username for which the notebook should be started | 
| NUM_CORES      | Number of cores to be used on the cluster (maximum: 36) | 
| RUN_TIME       | Run time limit for the jupyter notebook on the cluster (HH:MM) |  
| MEM_PER_CORE   | Memory limit in MB per core |

Example:

```
./start_jupyter_nb.sh Euler sfux 4 01:20 2048
```

### Running multiple notebooks in a single Jupyter instance
If you run Jupyter on the Leonhard cluster, using GPUs, then you need to make sure a notebook is correctly terminated before you can start another one.

If you don't properly close the first notebook and run a second one, then the previous notebook will still occupy some GPU memory and have processes running, which will throw some errors, when executing the second notebook.

Therefore please make sure that you stop running kernels in the "running" tab in the browser, before starting a new notebook.

### Terminate the Jupyter session

Please note that when you finish working with the jupyter notebook, you need to click on the "Quit" or "Logout" button in your Browser. This will stop the batch job running on Euler. Afterwards you also need to clean up the SSH tunnel that is running in the background. Example:

```
samfux@bullvalene:~/Jupyter-on-Euler-or-Leonhard-Open$ ps -u | grep -m1 -- "-L" | grep -- "-N"
samfux    8729  0.0  0.0  59404  6636 pts/5    S    13:46   0:00 ssh sfux@euler.ethz.ch -L 51339:10.205.4.122:8888 -N
samfux@bullvalene:~/jupyter-on-Euler-or-Leonhard-Open$ kill 8729
```

## Authors
* Samuel Fux
* Andrei Plamada

## Contributions
* Urban Borstnik
* Steven Armstrong
* Swen Vermeul