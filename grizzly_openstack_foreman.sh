#!/bin/sh
OOTPASS=""
#FOREMAN_IP="XX.XX.XX.XX"
#CONTROLLER_IP="XX.XX.XX.XX"
#COMPUTE_IP="XX.XX.XX.XX"
suffix=".scl.lab.tlv.redhat.com"
USER="admin"
PASS="changeme"


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
-t     Contorller IP Address.
-c     Compute IP Address.

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

FOREMAN_SERVER_PARM="'PRIVATE_CONTROLLER_IP=$CONTROLLER_IP\nPRIVATE_INTERFACE=eth0\nPRIVATE_NETMASK=10.0.0.0/24\nPUBLIC_CONTROLLER_IP=$CONTROLLER_IP\nPUBLIC_INTERFACE=eth2\nPUBLIC_NETMASK=10.4.3.0/22\nFOREMAN_GATEWAY=false\n'"

FOREMAN_URL="https://$FOREMAN_IP"

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



#Building Repo according latest Grizzly Puddle.
#----------------------------------------------
> /tmp/puddle.repo
cat >>/tmp/puddle.repo << EOF
[OpenStack-Grizzly-Puddle]
name=OpenStack-Grizzly-Puddle
baseurl=`python -c "import urllib2 ; puddle_url = 'http://download.lab.bos.redhat.com/rel-eng/OpenStack/Grizzly/' ; req = urllib2.Request(puddle_url) ; f = urllib2.urlopen(req) ; ur = [line.split('\"')[5].rstrip('/').strip() for line in f.readlines() if 'folder.gif' in line and '201' in line][-2] ; print puddle_url+ur+'/\\$basearch/os'"`
gpgcheck=0
enabled=1
EOF

> /tmp/rhel-updates.repo 
cat >> /tmp/rhel-updates.repo << EOF
[rhel64-updates]
name=rhel64-uptades
baseurl=http://download.eng.tlv.redhat.com/sysrepos/rhel6-server-core-x86_64/RPMS.updates/
enabled=1
gpgcheck=0
EOF

echo "Build Repo according latest Grizzly Puddle"


#Remove old repo files from FOREMAN_IP CONTROLLER_IP COMPUTE_IP
#--------------------------------------------------------------
myssh ${FOREMAN_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$FOREMAN_IP", exiting!" ; exit 1 ; }

myssh ${CONTROLLER_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$CONTROLLER_IP", exiting!" ; exit 1 ; }

myssh ${COMPUTE_IP} ${ROOTPASS} "rm -rf /etc/yum.repos.d/*" || { echo "Failed to remove old repo from  "$COMPUTE_IP", exiting!" ; exit 1 ; }

echo "Remove old repo files from FOREMAN_IP CONTROLLER_IP COMPUTE_IP"

#Copy the repos to FOREMAN_IP CONTROLLER_IP COMPUTE_IP 
#----------------------------------------------------------------------------------

echo -e "finish \e[92mLight start copy repo and install sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP"

myscp_from_local "/tmp/puddle.repo" ${ROOTPASS} ${FOREMAN_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$FOREMAN_IP", exiting!" ; exit 1 ; } 
myscp_from_local "/tmp/rhel-updates.repo" ${ROOTPASS} ${FOREMAN_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$FOREMAN_IP", exiting!" ; exit 1 ; }

myscp_from_local "/tmp/puddle.repo" ${ROOTPASS} ${CONTROLLER_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$FOREMAN_IP", exiting!" ; exit 1 ; }
myscp_from_local "/tmp/rhel-updates.repo" ${ROOTPASS} ${CONTROLLER_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$CONTROLLER_IP", exiting!" ; exit 1 ; }

myscp_from_local "/tmp/puddle.repo" ${ROOTPASS} ${COMPUTE_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$COMPUTE_IP", exiting!" ; exit 1 ; } 
myscp_from_local "/tmp/rhel-updates.repo" ${ROOTPASS} ${COMPUTE_IP} "/etc/yum.repos.d/" || { echo "Failed to copy file to "$COMPUTE_IP", exiting!" ; exit 1 ; }

# installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP
#----------------------------------------------------------- 

echo -e "start \e[92mLight installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP"
myssh ${FOREMAN_IP} ${ROOTPASS} "yum install -y http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm" 

pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum install -y http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm

#|| { echo "Failed to install sshpass on  "$FOREMAN_IP", exiting!" ; exit 1 ; }

#myssh ${CONTROLLER_IP} ${ROOTPASS} "yum install -y http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm" 
#|| { echo "Failed to install sshpass on  "$CONTROLLER_IP", exiting!" ; exit 1 ; }

#myssh ${COMPUTE_IP} ${ROOTPASS} "yum install -y http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm" 
#|| { echo "Failed to install sshpass on  "$COMPUTE_IP", exiting!" ; exit 1 ; }

echo -e "finished \e[92mLight to copy repos and installing sshpass on FOREMAN_IP CONTROLLER_IP COMPUTE_IP"


#Remove old puppet and augeas version from machines:
#---------------------------------------------------
#pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum erase augeas* -y
#pdsh -w root@${FOREMAN_IP},root@${CONTROLLER_IP},root@${COMPUTE_IP} yum remove ruby193-puppe -y


#removing old puppet CA from the machines:
#-----------------------------------------
echo -e "start: removing old puppet CA from the machines"

myssh ${FOREMAN_IP} ${ROOTPASS} "service ruby193-puppet stop"
myssh ${CONTROLLER_IP} ${ROOTPASS} "service ruby193-puppet stop"
myssh ${COMPUTE_IP} ${ROOTPASS} "service ruby193-puppet stop"

myssh ${FOREMAN_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"
myssh ${CONTROLLER_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"
myssh ${COMPUTE_IP} ${ROOTPASS} "find /var/lib/puppet/ssl -type f -delete"



#Installing openstack-foreman-installer on FOREMAN_IP
#----------------------------------------------------
echo -e "start \e[92mLight openstack-foreman-installer -  installation"
myssh ${FOREMAN_IP} ${ROOTPASS} "yum install ruby193-openstack-foreman-installer ruby193-foreman-selinux -y" 
echo -e "finish \e[92mLight openstack-foreman-installer -  installation"


# Edit the foreman_server.sh :
#-------------------------------

echo -e "start \e[92mLight edit foreman_server.sh"

#myssh ${FOREMAN_IP} ${ROOTPASS} "sed -i 's/\(^P[A-Z_]*CONTROLLER_IP=\).*/\$CONTROLLER_IP/g' /usr/share/openstack-foreman-installer/bin/foreman_server.sh"


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

echo -e "finish \e[92mLight fixing iptables rules on foreman machine"


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
echo  "Start adding foreman_clients to controller/compute hostGroup"

myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/1 -X PUT  -d "host[hostgroup_id]=1"  -o -"

myssh ${FOREMAN_IP} ${ROOTPASS} "curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/2 -X PUT  -d "host[hostgroup_id]=2"  -o -"

echo  "finished adding foreman_clients to controller/compute hostGroup"

# Change the hostGroup admin_password in order to run tempest:
#--------------------------------------------------------------
echo  "Start Change the hostGroup admin_password in order to run tempest"

curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://${FOREMAN_IP}/api/puppetclasses/quickstack::nova_network::controller/smart_class_parameters/admin_password -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"secret\"} -o -

echo  "Finished change the hostGroup admin_password in order to run tempest"

# Running puppet agent on foreman_clients:
#-----------------------------------------

echo  "Start running puppet agent on foreman_clients"
myssh ${CONTROLLER_IP} ${ROOTPASS} "scl enable ruby193 \"puppet agent -t -v\""
myssh ${COMPUTE_IP} ${ROOTPASS} "scl enable ruby193 \"puppet agent -t -v\""
echo  "finish running puppet agent on foreman_clients"

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
