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

## Authors
* Samuel Fux
* Andrei Plamada

## Contributions
* Urban Borstnik
* Steven Armstrong