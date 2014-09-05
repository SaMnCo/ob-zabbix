# Zabbix Server for Orange Boxes

## A bit of background

There is a very neat system at Canonical called Orange Box that is basically a datacenter-in-a-box.
It is used to make demos on the field and to test deployments of OpenStack, Hadoop or any other workload that has been charmed to be compliant with Juju, a service orchestration solution. 

This monitoring solution based on Zabbix aims at providing a replicate of an industrial-grade NMS at the scale of an Orange Box so that: 

* The Orange Box itself gets monitored properly and reports hardware or software issues
* Workloads deployed via Juju can get real life monitoring to make demos more vivid. 

## Usage

### Installation 

Create a VM on the Orange Box (in fact you can use ANY VM if you just need monitoring of juju deployed workloads. I use an AWS VM for testing and monitoring workloads). There are no specific requirements other than having a disk larger than 8GB. I personally recommend having at least 2 cores and 2GB of RAM if you plan on scaling a bit. 

After you login to the machine, update the below to your username and copy paste to a terminal

    export USERNAME=ubuntu
    cd /home/${USERNAME}
    git clone https://github.com/SaMnCo/ob-zabbix.git
    cd ob-zabbix
    chmod +x *.sh
    # Here you may edit install-zabbix-server.sh to select another default database depending on your workload
    sudo ./install-zabbix-server.sh
    # This will install the server based on MySQL on this machine with the default settings. 
    # By default, no workload is pre-installed and this is a "blank" OB monitoring solution. 
    sudo ./install-zabbix-agent.sh
    # This will install a Zabbix Agent locally as well, pointing on the localhost server so you can actively monitor at least this node. 

### Configuration 

OK now you may start login on http://this-vm/zabbix with default credentials admin:ubuntu

First thing you want to do is activate all auto-discovery in Configuration/Discovery. Then you should be OK for starters

Now you also need to know that there are 2 configuration files hidden for the Zabbix and Juju apis. 

* /usr/lib/zabbix/externalscripts/.jujuapi.yaml: you must modify that one with your Juju environment settings (those are actually the juju-gui access credentials) 
* /usr/lib/zabbix/externalscripts/.zabbixapi.yaml: localhost should be OK as-is but if you want to run a remote instance or if you changed the Zabbix credentials, you'll have to update those. 

### Adding workloads

OK for now there is a single workload configured which is clearwater. Connect on the Zabbix node and

    sudo service zabbix-server stop
    sudo service zabbix-agent stop
    cd /home/${USERNAME}/ob-zabbix
    mysql -uroot -pubuntu zabbix < zabbix_clearwater.sql
    sudo service zabbix-server start
    sudo service zabbix-agent start
    
## Features

Note: the project is very early stage and focused for now on an actual Juju workload. More will come for the OB itself later on. 

### Orange Box

#### Networking

* Auto discovery and removal of hardware cluster nodes via AMT monitoring
* Auto discovery of
** OpenStack Neutron public IPs range
** MAAS managed DHCP
* Fake intrusion detection on ranges where nobody should be

#### Monitoring

* Simple template for all nodes with auto activation when they pop up

### Workloads

#### Clearwater

* SNMP Templates of all Clearwater nodes
* Active Agent Templates of all Clearwater nodes
* Autoscaling of Clearwater with auto-deletion of nodes in Zabbix when they go down

To make this work, you need to use https://github.com/SaMnCo/charm-zabbix-agent as a subordinate charm to your juju bundle. This is still experimental hence the "not in the charmstore yet". 

    export USERNAME=ubuntu
    cd /home/${USERNAME}
    mkdir -p localcharms/precise localcharms/trusty 
    cd localcharms/precise
    git clone https://github.com/SaMnCo/charm-zabbix-agent zabbix-agent
    cd zabbix-agent
    git checkout precise
    cd ../trusty
    git clone https://github.com/SaMnCo/charm-zabbix-agent zabbix-agent
    cd zabbix-agent
    git checkout trusty
    cd ../..
    # We assume you have a Juju environment bootstraped
    juju quickstart clearwater/bundle.yaml # this assumes you have the bundle or you deploy through the GUI
    juju deploy --repository=/home/${USERNAME}/localcharms local:precise/zabbix-agent 
    # Wait until the agent is deployed and configure the server URL to point on your zabbix
    juju add-relation zabbix-agent clearwater-sprout
    juju add-relation zabbix-agent clearwater-bono
    juju add-relation zabbix-agent clearwater-ralf
    juju add-relation zabbix-agent clearwater-homer
    juju add-relation zabbix-agent clearwater-homestead
    juju add-relation zabbix-agent clearwater-ellis
    juju add-relation zabbix-agent dns

Enjoy your nodes automagically enrolled in Zabbix. 

Wanna test autoscaling? 

    juju ssh clearwater-bono/0
    sudo apt-get install -y -qq stress
    stress --cpu 1 --io 2 --vm 2 --vm-bytes 512M --timeout 600
    
## Conclusion

More to come! Let's play!! 

