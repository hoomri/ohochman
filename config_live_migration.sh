#!/bin/sh
#. read_ini.sh
#read_ini parameters_live_migraion.ini --booleans 0
#ROOTPASS="${INI__environment_params__root_pass}"
#CONTROLLER_IP="${INI__environment_params__controller_ip}"
#COMPUTE1_IP="${INI__environment_params__compute1_ip}"
#COMPUTE2_IP="${INI__environment_params__compute2_ip}"

# The script will configure Shared NFS Storage on the controller machine  
# and will allow live-migration between computes-nodes. 
 
ROOTPASS=" "
CONTROLLER_IP=" "
COMPUTE1_IP=" "
COMPUTE2_IP=" "

function myssh
{
sshpass -p $2 /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t root@$1 "$3"
}


echo "*******************************************************"
echo "**Start configure environment with shared NFS storage**"
echo "*******************************************************" 


yum install http://pkgs.repoforge.org/sshpass/sshpass-1.05-1.el6.rf.x86_64.rpm -y


# Fixing the ssh-copy-id into machines in-order to perform 'pdsh'  :
#############################################################
echo " Fixing the ssh-copy-id into machines in-order to perform 'pdsh'"
echo "" > ~/.ssh/authorized_keys
echo "UserKnownHostsFile=/dev/null" > ~/.ssh/config
echo "StrictHostKeyChecking=no" >> ~/.ssh/config
chmod 600 ~/.ssh/config
sshpass -p ${ROOTPASS} ssh-copy-id root@${CONTROLLER_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${COMPUTE1_IP}
sshpass -p ${ROOTPASS} ssh-copy-id root@${COMPUTE2_IP}
ssh-add


#Configure Shared NFS mount point on the $CONTROLLER_IP
########################################################
echo " "
echo "Configure Shared NFS mount point on the $CONTROLLER_IP"
echo "###################################################### "

echo "(1) Installing rpcbind on  "$CONTROLLER_IP" "
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "yum install nfs* -y && yum install rpcbind -y" || { echo "Failed to install nfs on  "$CONTROLLER_IP", exiting!" ; exit 1 ; }
echo " "


echo " "
echo "(2) Creating the /export/instances folder "$CONTROLLER_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "mkdir -p /export/instances && chmod o+x /export/instances && chown nova:nova /export/instances && chown nova:nova /export"
echo " "

echo " "
echo "(3) echo '/export/instances *(rw,sync,no_root_squash)' > /etc/exports - on: "$CONTROLLER_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "echo '/export/instances *(rw,sync,no_root_squash)' > /etc/exports"
echo " "

echo " "
echo "(4)  vi /etc/nova/nova.conf change to--> instances_path=/export/instances on: "$CONTROLLER_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "sed -i 's/^#instances_path=.*/instances_path=\/export\/instances/g' /etc/nova/nova.conf"
echo " "

echo " "
echo "(5) Fix IpTables on "$CONTROLLER_IP""
echo " "
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I INPUT 1 -p tcp --dport 16509 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I INPUT -p tcp --dport 49152:49261 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp --dport 2049 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p udp -m udp --dport 2049 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p tcp -m state --state RELATED,ESTABLISHED -m tcp --sport 2049 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p udp -m udp --sport 2049 -j ACCEPT"
myssh ${CONTROLLER_IP} ${ROOTPASS} "service iptables save"
myssh ${CONTROLLER_IP} ${ROOTPASS} "service iptables restart"

echo " "
echo "(6) Restart all services of: "$CONTROLLER_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "/etc/init.d/rpcbind restart && /etc/init.d/nfs restart && openstack-service restart"
echo " "

echo " "
echo "(7) Fixing SELinux boolean for NFS on : "$CONTROLLER_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "setsebool -P virt_use_nfs 1"
echo " "


#Configure Shared NFS mount point on the $CONTROLLER_IP
########################################################

echo " "
echo "Mount the Shared NFS from  $CONTROLLER_IP on $COMPUTE1_IP and $COMPUTE2_IP "
echo "########################################################################### "

echo " "
echo "(1) Creating /export/instances folder on  "$COMPUTE1_IP" and "$COMPUTE2_IP""
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "mkdir -p /export/instances && chmod 777 /export/instances && chown nova:nova /export/instances && chown nova:nova /export"
myssh ${COMPUTE2_IP} ${ROOTPASS} "mkdir -p /export/instances && chmod 777 /export/instances && chown nova:nova /export/instances && chown nova:nova /export"
echo " "

echo " "
echo "(2)  vi /etc/nova/nova.conf change to--> instances_path=/export/instances on: "$CONTROLLER_IP""
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#instances_path=.*/instances_path=\/export\/instances/g' /etc/nova/nova.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#instances_path=.*/instances_path=\/export\/instances/g' /etc/nova/nova.conf"
echoo " "

echo " "
echo "(3) Mount the Shared NFS shared  "$COMPUTE1_IP" and "$COMPUTE2_IP""
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "mount $CONTROLLER_IP:/export/instances/ /export/instances/"
myssh ${COMPUTE2_IP} ${ROOTPASS} "mount $CONTROLLER_IP:/export/instances/ /export/instances/"
echo " "
echo " "

echo " "
echo "(4) Fix IpTables on "$COMPUTE1_IP""
echo " "
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I INPUT 1 -p tcp --dport 16509 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I INPUT -p tcp --dport 49152:49261 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp --dport 2049 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p udp -m udp --dport 2049 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p tcp -m state --state RELATED,ESTABLISHED -m tcp --sport 2049 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p udp -m udp --sport 2049 -j ACCEPT"
myssh ${COMPUTE1_IP} ${ROOTPASS} "service iptables save"
myssh ${COMPUTE1_IP} ${ROOTPASS} "service iptables restart"

echo " "
echo "(5) Fix IpTables on "$COMPUTE2_IP""
echo " "
echo " "
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I INPUT 1 -p tcp --dport 16509 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I INPUT -p tcp --dport 49152:49261 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p tcp -m state --state NEW,RELATED,ESTABLISHED -m tcp --dport 2049 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I INPUT 1 -s 0.0.0.0/0 -p udp -m udp --dport 2049 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p tcp -m state --state RELATED,ESTABLISHED -m tcp --sport 2049 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "iptables -I OUTPUT 1 -d 0.0.0.0/0 -p udp -m udp --sport 2049 -j ACCEPT"
myssh ${COMPUTE2_IP} ${ROOTPASS} "service iptables save"
myssh ${COMPUTE2_IP} ${ROOTPASS} "service iptables restart"
echo " "

echo " "
echo "(6) Restart all services of: "$COMPUTE1_IP" "$COMPUTE2_IP""
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "openstack-service restart"
myssh ${COMPUTE2_IP} ${ROOTPASS} "openstack-service restart"
echo " " 

echo " "
echo "(7) Fixing SELinux boolean for NFS on : "$COMPUTE1_IP"  "$COMPUTE2_IP""
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "setsebool -P virt_use_nfs 1"
myssh ${COMPUTE2_IP} ${ROOTPASS} "setsebool -P virt_use_nfs 1"
echo " "


#Allowing nova live-migration : 
###############################
echo " "
echo "(1) Fixing novncproxy_base_url on  : "$CONTROLLER_IP" , "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url \"http://$SERVICE_HOST:6080/vnc_auto.html\""
myssh ${COMPUTE1_IP} ${ROOTPASS} "openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url \"http://$SERVICE_HOST:6080/vnc_auto.html\""
myssh ${COMPUTE2_IP} ${ROOTPASS} "openstack-config --set /etc/nova/nova.conf DEFAULT novncproxy_base_url \"http://$SERVICE_HOST:6080/vnc_auto.html\""
echo " "

echo " "
echo "(2) Fixing nova.conf with - vncserver_listen = 0.0.0.0  : "$CONTROLLER_IP" ,  "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "sed -i 's/^#vncserver_listen=.*/vncserver_listen=0.0.0.0/g' /etc/nova/nova.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^vncserver_listen=.*/vncserver_listen=0.0.0.0/g' /etc/nova/nova.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^vncserver_listen=.*/vncserver_listen=0.0.0.0/g' /etc/nova/nova.conf"
echo " "

echo " "
echo "(3) Fixing nova.conf with  live_migration_flag=VIR_MIGRATE_LIVE -  on  : "$CONTROLLER_IP" , "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "sed -i 's/^#live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER/live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE/g' /etc/nova/nova.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER/live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE/g' /etc/nova/nova.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER/live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE, VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE/g' /etc/nova/nova.conf"
echo " "

echo " "
echo "(4) Fixing libvirt.conf with - listen_tls = 0 , listen_tcp = 1 , auth_tcp = \"none\"  : "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#listen_tls = 0/listen_tls = 0/g' /etc/libvirt/libvirtd.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#listen_tcp = 1/listen_tcp = 1/g' /etc/libvirt/libvirtd.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "echo 'auth_tcp = \"none\"' >> /etc/libvirt/libvirtd.conf"

myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#listen_tls = 0/listen_tls = 0/g' /etc/libvirt/libvirtd.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#listen_tcp = 1/listen_tcp = 1/g' /etc/libvirt/libvirtd.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "echo 'auth_tcp = \"none\"' >> /etc/libvirt/libvirtd.conf"
echo " "

echo " "
echo "(5) Fixing /etc/sysconfig/libvirtd with  #LIBVIRTD_ARGS=\"--listen\" : "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#LIBVIRTD_ARGS=\"--listen\"/LIBVIRTD_ARGS=\"--listen\"/g' /etc/sysconfig/libvirtd"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#LIBVIRTD_ARGS=\"--listen\"/LIBVIRTD_ARGS=\"--listen\"/g' /etc/sysconfig/libvirtd"
echo " "

echo " "
echo "(6) Fixing /etc/libvirt/qemu.conf with user = \"root\" , group = \"root\"  on : "$COMPUTE1_IP" , "$COMPUTE2_IP" "
echo " "
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#user = \"root\"/user = \"root\"/g' /etc/libvirt/qemu.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#group = \"root\"/group = \"root\"/g' /etc/libvirt/qemu.conf"
myssh ${COMPUTE1_IP} ${ROOTPASS} "sed -i 's/^#vnc_listen = \"0.0.0.0\"/vnc_listen = \"0.0.0.0\"/g' /etc/libvirt/qemu.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#user = \"root\"/user = \"root\"/g' /etc/libvirt/qemu.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#group = \"root\"/group = \"root\"/g' /etc/libvirt/qemu.conf"
myssh ${COMPUTE2_IP} ${ROOTPASS} "sed -i 's/^#vnc_listen = \"0.0.0.0\"/vnc_listen = \"0.0.0.0\"/g' /etc/libvirt/qemu.conf"
echo " "

echo " "
echo "(7) Restart all services of: "$CONTROLLER_IP"  "$COMPUTE1_IP" "$COMPUTE2_IP""
echo " "
myssh ${CONTROLLER_IP} ${ROOTPASS} "openstack-service restart"
myssh ${COMPUTE1_IP} ${ROOTPASS} "openstack-service restart"
myssh ${COMPUTE2_IP} ${ROOTPASS} "openstack-service restart"
myssh ${COMPUTE1_IP} ${ROOTPASS} "service libvirtd restart"
myssh ${COMPUTE2_IP} ${ROOTPASS} "service libvirtd restart"
echo " " 




