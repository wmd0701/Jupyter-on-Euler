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

### Starting in a different location than your home directory
By default, the Jupyter notebook will start in your home directory. It is also possible to start in a different location. For this you would need to change line 122 in the script from

```
jupyter notebook --no-browser --ip "\$IP_REMOTE" &> /cluster/home/$USERNAME/jnbinf
```

to

```
jupyter notebook --no-browser --ip "\$IP_REMOTE" --notebook-dir PATH &> /cluster/home/$USERNAME/jnbinf
```

where PATH needs to be replaced with the path in which the Jupyter notebook should start.

### Reconnect to a Jupyter notebook
When running the script, it creates a local file called reconnect_info in the installation directory, which contains all information regarding the used ports, the remote ip address, the command for the SSH tunnel and the URL for the browser. This information should be sufficient to reconnect to a Jupyter notebook if connection was lost.

### Running multiple notebooks in a single Jupyter instance
If you run Jupyter on the Leonhard cluster, using GPUs, then you need to make sure a notebook is correctly terminated before you can start another one.

If you don't properly close the first notebook and run a second one, then the previous notebook will still occupy some GPU memory and have processes running, which will throw some errors, when executing the second notebook.

Therefore please make sure that you stop running kernels in the "running" tab in the browser, before starting a new notebook.

### Terminate the Jupyter session

Please note that when you finish working with the jupyter notebook, you need to click on the "Quit" or "Logout" button in your Browser. "Quit" will stop the batch job running on Euler, "Logout" will just log you out from the session but not stop the batch job (in this case you need to login to the cluster, identify the job with bjobs and then kill it with the bkill command, using the jobid as parameter). Afterwards you also need to clean up the SSH tunnel that is running in the background. Example:

```
samfux@bullvalene:~/Jupyter-on-Euler-or-Leonhard-Open$ ps -u | grep -m1 -- "-L" | grep -- "-N"
samfux    8729  0.0  0.0  59404  6636 pts/5    S    13:46   0:00 ssh sfux@euler.ethz.ch -L 51339:10.205.4.122:8888 -N
samfux@bullvalene:~/jupyter-on-Euler-or-Leonhard-Open$ kill 8729
```

### Additional kernels

When using this script, you can either use the Python 3.6 Kernel, or in addition a bash kernel or an R kernel (3.6.0 on Euler, 3.5.1 on Leonhard Open)

### Installing additional Python and R packages locally

When starting a Jupyter notebook with this script, then it will use a central Python and R installation:

```
Euler: python/3.6.1, r/3.6.0
Leonhard Open: python_cpu/3.6.4, r/3.5.1
```

Therefore you can only use packages that are centrally installed out-of-the-box. But you have the option to install additional packages locally in your home directory, which can afterwards be used.

For installing a Python package from inside a Jupyter notebook, you would need to run the following command:

```
!pip install --user package_name
```

This will install <tt>package_name</tt> into <tt>$HOME/.local</tt>, as described on our wiki page about Python:

```
https://scicomp.ethz.ch/wiki/Python#Installing_a_Python_package.2C_using_PIP
```

The command to locally install an R package:

```
install.packages("package_name")
```

Then follow the instructions provided on our wiki:

```
https://scicomp.ethz.ch/wiki/R#Extensions
```

## Authors
* Samuel Fux
* Andrei Plamada

## Contributions
* Urban Borstnik
* Steven Armstrong
* Swen Vermeul
