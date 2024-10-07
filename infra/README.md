# Infra 

How to deploy all the infrastructure validating with ansible and promoted to devops pipelines. 



## Running and Developing Modules

Dependencies: 
- A linux terminal with Python 3.6+ and pip or docker or see run with docker below. 
    - To get up and running with WSL see Reference Material > [Getting started with WSL for Python3 and Pip3](#getting-started-with-wsl-for-python3-and-pip3) 

1. Create and activate virtual env 
    - `python3 -m venv venv` 
    - `source venv/bin/activate` 
1. Install project dependencies with pip
`pip install -r requirements.txt`
1. Install ansible: `pip3 install ansible` 
1. Validate ansible installation
`ansible --version` 
1. Run `sudo ./ubuntu_host_setup.sh` 
1. export SECRETS/Subscription information, app-insights keys, and debugging level/format. 

```
Sample ENV File
export ANSIBLE_STDOUT_CALLBACK=debug
export SUBSCRIPTION_NAME=whgriffi 
export STORAGE_ACCOUNT_NAME=corestorageaccountwus 
export CONTAINER_NAME=state 
export ARM_TENANT_ID=SECRET86f1-41af-91ab-2d7cd011db47
export ARM_CLIENT_SECRET=SECRETKwfFd~FRKkmvb8h7Qu8A_8xbW
export ARM_CLIENT_ID=SECRET56ef-4c21-bae6-a6c32c7cb9c5
export ARM_SUBSCRIPTION_ID=SECRET1982-4b4d-9efa-a9b845a55b13
export ARM_ACCESS_KEY=SECRETxfghAvvsFF9OqWeVNs5zEpWYpvRF15StV1j7Mch93kjRw6F+k12v0RZrL7xlufKl9H5KRagcmk9SA== 
```
Then you can run any playbook in the solution...
See example usage in each module:
- [network module example usage](/src/modules/network/example_usage.md) 
- [ubuntu worker example usage](/src/modules/ubuntu_worker/example_usage.md)

After code is validated locally or in a jumpbox, you can commit and deploy to azure devops using Azure Pipelines, this requires opening the organization and adding a pipeline and pointing to the existing azdo pipeline yaml in the module.  (prefixed 'azdo-' by convention)



## Getting started with WSL for Python3 and Pip3 

Install ubuntu 18.04 distribution on your windows machine using these instructions: 
Connect to that machine
```
> wsl --set-default Ubuntu-18.04
> bash 
```

Run these commands in your new linux shell 

```
$ sudo apt-get update && sudo apt-get upgrade
$ sudo apt install software-properties-common
$ sudo apt-get install gcc libpq-dev build-essential libssl-dev libffi-dev -y
$ sudo apt-get install python3-pip python3-venv -y
```

Create a virtual environment 

```
$ python3 -m venv venv 
$ source venv/bin/activate 
$ pip3 install wheel
$ pip3 list 
```

Now you can install ansible or a `requirements.txt` or ansible directly 

```
$ pip3 install ansible 
$ pip3 install -r requirements.txt
```