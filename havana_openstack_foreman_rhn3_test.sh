#!/bin/sh

#FOREMAN_IP="XX.XX.XX.XX"
#CONTROLLER_IP="XX.XX.XX.XX"
#COMPUTE_IP="XX.XX.XX.XX"
suffix=".scl.lab.tlv.redhat.com"
USER="admin"
PASS="changeme"
ROOTPASS=""


usage()
{
cat << EOF
usage: $0 options

*************************************************************************************************
*The script will performs deployment of OpenStack with  1 contoller and 1 compute using foreman.* 
*************************************************************************************************

You must specify 3 Positinal Arguments:
---------------------------------------
-f     Foreman server IP Address.   
-t     Foreman client IP Address.
-c     Foreman client IP Address (second client).

Example: 
--------
bash sanatiy_openstack_foreman.sh -f <IP ADDR>  -t <IP ADDR> -c <IP ADDR>

Note: 
-----
1) In order to run the script you must provide IP of 3 machines.
2) The names of the machines must be resolvable by FQDN.
3) foremen server machine must have At leaset 2 Availble NICs. 

EOF
}

while getopts ":f:t:c:" OPTION
do
     case $OPTION in
         f)
             FOREMAN_IP=$OPTARG
             ;;
         t)
             CONTROLLER_IP=$OPTARG
             ;;
         c)
             COMPUTE_IP=$OPTARG
             ;;
    esac
done

if [[ -z $FOREMAN_IP ]] || [[ -z $CONTROLLER_IP ]] || [[ -z $COMPUTE_IP ]]
then
     usage
     exit 1
fi

FOREMAN_SERVER_PARM="'PRIVATE_CONTROLLER_IP=$CONTROLLER_IP\nPRIVATE_INTERFACE=eth2\nPRIVATE_NETMASK=10.0.0.0/24\nPUBLIC_CONTROLLER_IP=$CONTROLLER_IP\nPUBLIC_INTERFACE=eth2\nPUBLIC_NETMASK=10.4.3.0/22\nFOREMAN_GATEWAY=false\n'"

FOREMAN_URL="https://$FOREMAN_IP"

echo "choose a hostGroup number for the controller :"
echo " (0) empty host group (don't install the client)"
echo " (1) controller with nova-network"
echo " (2) compute with nova-network"
echo " (3) controller with neutron"
echo " (4) compute with neutron"
echo " (5) openstack neutron networker "
echo " (6) openstack block storage"
echo " (7) openstack load balancer"
echo " (8) HA Mysql node"
read  CONTROLLER_DEPLOYMENT_NUM
if [[ -z $CONTROLLER_DEPLOYMENT_NUM ]]
then
     echo "You must specfiy a hostGroup number for the controller"
     exit 1
fi
if [ $CONTROLLER_DEPLOYMENT_NUM = "0" ]
then
   CONTROLLER_DEPLOYMENT_NUM=" "
fi

echo "choose a hostGroup number for the compute :"
echo " (0) empty host group (don't install the client)"
echo " (1) controller with nova-network"
echo " (2) compute with nova-network"
echo " (3) controller with neutron"
echo " (4) compute with neutron"
echo " (5) openstack neutron networker "
echo " (6) openstack block storage"
echo " (7) openstack load balancer"
echo " (8) HA Mysql node"
read  COMPUTE_DEPLOYMENT_NUM
if [[ -z $COMPUTE_DEPLOYMENT_NUM ]]
then
     echo "You must specfiy a hostGroup number for the compute"
     exit 1
fi
if [ $COMPUTE_DEPLOYMENT_NUM = "0" ]
then
   COMPUTE_DEPLOYMENT_NUM=" "
fi



function myssh
{
#echo $3
sshpass -p $2 /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t root@$1 "$3"
}


function myscp_from_local
{
sshpass -p $2 /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $1 root@$3:$4 2> /dev/null
}


function myscp
{
sshpass -p $2 /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$1:$3 root@$4:$5
}

function myfunc()
{
  NUM_INT=$(sshpass -p $ROOTPASS /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t root@$FOREMAN_IP "facter -p|grep ipaddress_|grep -v _lo|wc -l")
  echo $NUM_INT
}
num_int=$(myfunc)


echo "*************************************"
echo "*checking script pre-requirements...*" 
echo "*************************************"
#if [ $num_int == "1" ] || [ $num_int == "0" ] ; then
#  echo "This installer needs 2 configured interfaces - only $num_int detected"
#  exit 1
#fi
#echo "found 2 NICs on foreman-machine"

if [ -z "$(rpm -qa|grep pdsh)" ] 
then 
echo "You need to have: 'pdsh' installed in order to run this script"
    exit 1
fi
echo "found pdsh installed"
echo ""
echo ""
echo "************************************************************************************************************"
echo "**Start deploying foreman-server on $FOREMAN_IP ,  controller on $CONTROLLER_IP and compute on $COMPUTE_IP**"
echo "************************************************************************************************************" 

function myssh
{
#echo $3
sshpass -p $2 /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t root@$1 "$3"
}


function myscp_from_local
{
sshpass -p $2 /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $1 root@$3:$4 2> /dev/null
}


function myscp
{
sshpass -p $2 /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$1:$3 root@$4:$5
}


# Fixing the ssh-copy-id into machines in-order to perform 'pdsh'  :
####################################################################
echo "start fixing the ssh-copy-id into machines in-order to perform 'pdsh'"
echo "" > ~/.ssh/authorized_keys
echo "UserKnownHostsFile=/dev/null" > ~/.ssh/config
echo "StrictHostKeyChecking=no" >> ~/.ssh/config
chmod 600 ~/.ssh/config
sshpass -p ${ROOTPASS} ssh-copy-id root@${FOREMAN_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${CONTROLLER_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${COMPUTE_IP}
ssh-add


#Remove old repo files from FOREMAN_IP CONTROLLER_IP COMPUTE_IP
#--------------------------------------------------------------
myssh ${FOREMAN_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$FOREMAN_IP", exiting!" ; exit 1 ; }

myssh ${CONTROLLER_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$CONTROLLER_IP", exiting!" ; exit 1 ; }

myssh ${COMPUTE_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$COMPUTE_IP", exiting!" ; exit 1 ; }

#echo "Remove old repo files from FOREMAN_IP CONTROLLER_IP COMPUTE_IP"


# installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP :
#----------------------------------------------------------- 

echo -e "start \e[92mLight installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP"

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum install -y http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm

echo -e "finished \e[92mLight installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP"



# Fixing the ssh-copy-id into machines in-order to perform 'pdsh'  :
####################################################################
echo "start fixing the ssh-copy-id into machines in-order to perform 'pdsh'"
echo "" > ~/.ssh/authorized_keys
echo "UserKnownHostsFile=/dev/null" > ~/.ssh/config
echo "StrictHostKeyChecking=no" >> ~/.ssh/config
chmod 600 ~/.ssh/config
sshpass -p ${ROOTPASS} ssh-copy-id root@${FOREMAN_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${CONTROLLER_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${COMPUTE_IP}
ssh-add

# Registering hosts to RHN :
#############################

echo  "start registering hosts to RHN "
echo  "#########################################################"
echo  "##     IT MIGHT TAKE A WHILE  - Wait Few Minutes..     ##" 
echo  "#########################################################"

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} /usr/sbin/rhnreg_ks --serverUrl=https://xmlrpc.rhn.redhat.com/XMLRPC --username=qa@redhat.com --password=AeGh8phugee5

#registering hosts to rhn-optional-channel:
############################################

echo "start registering "$FOREMAN_IP" "$CONTROLLER_IP" "$COMPUTE_IP" to rhn-optional-channel"

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} rhn-channel --add --channel rhel-x86_64-server-6-ost-4  -u -p

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} rhn-channel --add --channel rhel-x86_64-server-6 -u -p 

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} rhn-channel --add --channel rhel-x86_64-server-lb-6 -u  -p 

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} rhn-channel --add --channel rhel-x86_64-server-6-mrg-messaging-2 -u  -p 


#Remove old puppet version from machines:
#----------------------------------------
pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum remove puppet -y

#start yum update the machines:
#------------------------------
pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum-update -y

#REMOVE ME !!!!!!!!!    Adding lon's workaroung  REMOVE ME !!!!!!!!!!!!!
########################################################################
#pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum install -y http://download.devel.redhat.com/brewroot/packages/sg3_utils/1.28/5.el6/i686/sg3_utils-libs-1.28-5.el6.i686.rpm

#Installing openstack-foreman-installer on FOREMAN_IP
#----------------------------------------------------
echo -e "start \e[92mLight openstack-foreman-installer -  installation"
myssh ${FOREMAN_IP} ${ROOTPASS} "yum install openstack-foreman-installer -y" 
echo -e "finish \e[92mLight openstack-foreman-installer -  installation"


# Edit the foreman_server.sh :
#-----------------------------

echo -e "start \e[92mLight edit foreman_server.sh"

myssh ${FOREMAN_IP} ${ROOTPASS}  "python -c \"f = open('/usr/share/openstack-foreman-installer/bin/foreman_server.sh', 'r+') ; s = f.readlines() ; s[0] += ${FOREMAN_SERVER_PARM} ; f.seek(0) ; f.write(''.join(s)) ; f.close()\"" 

myssh ${FOREMAN_IP} ${ROOTPASS} "sed -i 's/.*\(dhcp_range.*\)/#\ \1/g'  /usr/share/openstack-foreman-installer/bin/foreman_server.sh"

myssh ${FOREMAN_IP} ${ROOTPASS} "sed -i 's/^  FOREMAN_PROVISIONING=.*/  FOREMAN_PROVISIONING=false/g' /usr/share/openstack-foreman-installer/bin/foreman_server.sh"

echo -e "finish \e[92mLight to edit foreman_server.sh"

#fixing iptables of foreman machine:
#------------------------------------

echo -e "start \e[92mLight fixing iptables of foreman machine"

myssh ${FOREMAN_IP} ${ROOTPASS} "iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 8140 -j ACCEPT"
myssh ${FOREMAN_IP} ${ROOTPASS} "iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT"
myssh ${FOREMAN_IP} ${ROOTPASS} "iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT"
myssh ${FOREMAN_IP} ${ROOTPASS} "service iptables save"
myssh ${FOREMAN_IP} ${ROOTPASS} "service iptables restart"

#echo -e "finish \e[92mLight fixing iptables rules on foreman machine"

#removing old puppet CA from the machines:
#-----------------------------------------
echo -e "start: removing old puppet CA from the machines"


myssh ${FOREMAN_IP} ${ROOTPASS} "service puppet stop"
myssh ${CONTROLLER_IP} ${ROOTPASS} "service puppet stop"
myssh ${COMPUTE_IP} ${ROOTPASS} "service puppet stop"

myssh ${FOREMAN_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"
myssh ${CONTROLLER_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"
myssh ${COMPUTE_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"



echo -e "finish: removing old puppet CA from the machines"

# Adding second NIC In case of real HW ( configuration for puma39.scl.lab.tlv.redhat.com )
#----------------------------------------------------------------
#myssh ${FOREMAN_IP} ${ROOTPASS} "ifconfig  eth3 10.35.164.244 netmask 255.255.255.0 up"

#starting Foreman-server.sh script :
#----------------------------------
echo -e "start \e[92mLight Foreman-server.sh script"
myssh ${FOREMAN_IP} ${ROOTPASS} "pushd /usr/share/openstack-foreman-installer/bin/ && yes | bash /usr/share/openstack-foreman-installer/bin/foreman_server.sh && popd" || { echo "Failed in running foreman_server.sh "$FOREMAN_IP", exiting!" ; exit 1 ; }
echo -e "finish \e[92mLight Foreman-server.sh script"

#Copy foreman_client.sh into controller and compute nodes :
#----------------------------------------------------------
echo -e "start \e[92mLight copying foreman_client.sh into controller and compute nodes"

myssh ${FOREMAN_IP} ${ROOTPASS} "sshpass -p '${ROOTPASS}' /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/foreman_client.sh root@${CONTROLLER_IP}:/root/" || { echo "Failed to copy foreman_client.sh to "$CONTROLLER_IP", exiting!" ; exit 1 ; }

myssh ${FOREMAN_IP} ${ROOTPASS} "sshpass -p '${ROOTPASS}' /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/foreman_client.sh root@${COMPUTE_IP}:/root/" || { echo "Failed to copy foreman_client.sh to "$COMPUTE_IP", exiting!" ; exit 1 ; }

echo -e "finsh \e[92mLight copying foreman_client.sh into controller and compute nodes"


#starting foreman_client.sh script on controller and compute nodes:
#-------------------------------------------------------------------
echo -e "start \e[92mLight foreman_client.sh script"
myssh ${CONTROLLER_IP} ${ROOTPASS} "bash /root/foreman_client.sh"  
myssh ${COMPUTE_IP} ${ROOTPASS} "bash /root/foreman_client.sh"
echo -e "finish \e[92mLight foreman_client.sh script"


# Add foreman_clients to controller/compute hostGroup
#-----------------------------------------------------
echo  "Start change the controller and compute hostGroup"

CONTROLLER_FQDN=$(myssh ${CONTROLLER_IP} ${ROOTPASS} "hostname")
myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/$CONTROLLER_FQDN -X PUT  -d "host[hostgroup_id]=$CONTROLLER_DEPLOYMENT_NUM"  -o -"
COMPUTE_FQDN=$(myssh ${COMPUTE_IP} ${ROOTPASS} "hostname")
myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/$COMPUTE_FQDN -X PUT  -d "host[hostgroup_id]=$COMPUTE_DEPLOYMENT_NUM"  -o -"

echo  "Finished change the controller and compute hostGroup"

#echo  "Start change the controller and compute hostGroup"
#myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/1 -X PUT  -d "host[hostgroup_id]=$CONTROLLER_DEPLOYMENT_NUM"  -o -"
#myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/2 -X PUT  -d "host[hostgroup_id]=$COMPUTE_DEPLOYMENT_NUM"  -o -"
#echo  "Finished change the controller and compute hostGroup"


# Change defult host groups parameters :
#--------------------------------

echo  "Start: Change defult host groups parameters"

VLAN_RANGE="int_vlan_range:216:217,int_vlan_range:192"

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::nova_network::controller/smart_class_parameters/admin_password -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"secret\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::controller/smart_class_parameters/admin_password -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"secret\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::networker/smart_class_parameters/controller_priv_floating_ip -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"$CONTROLLER_IP\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::networker/smart_class_parameters/mysql_host -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"$CONTROLLER_IP\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::networker/smart_class_parameters/qpid_host -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"$CONTROLLER_IP\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::networker/smart_class_parameters/ovs_vlan_ranges -X PUT -H "Content-Type: application/json" -d {\"default_value\":\"$VLAN_RANGE\"} -o -

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::neutron::networker/smart_class_parameters/enable_tunneling -X PUT -H "Content-Type: application/json" -d {\"default_value\":\"false\"} -o -

echo  "Finished: Change defult host groups parameters"


# Running puppet agent on foreman_clients:
#-----------------------------------------

echo  "Start running puppet agent on foreman_clients"
myssh ${CONTROLLER_IP} ${ROOTPASS} "puppet agent -t -v"
myssh ${COMPUTE_IP} ${ROOTPASS} "puppet agent -t -v"
echo  "Finish running puppet agent on foreman_clients"

echo "#################################################################"
echo "# The script finish to deploy openstack using openstack-foreman #"
echo "#################################################################"


#cat /usr/share/openstack-foreman-installer/bin/foreman_server.sh >> /usr/share/openstack-foreman-installer/bin/foreman_server.sh << EOF 

#PRIVATE_CONTROLLER_IP=$CONTROLLER_IP
#PRIVATE_INTERFACE=eth2
#PRIVATE_NETMASK=10.0.0.0/24
#PUBLIC_CONTROLLER_IP=$CONTROLLER_IP
#PUBLIC_INTERFACE=eth2
#PUBLIC_NETMASK=10.4.3.0/22
#FOREMAN_GATEWAY=false
#EOF"
