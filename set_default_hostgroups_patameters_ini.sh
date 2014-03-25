#!/bin/sh
. read_ini.sh
read_ini parameters.ini --booleans 0
ROOTPASS="${INI__environment_params__root_pass}"
FOREMAN_IP="${INI__environment_params__foreman_ip}"
CONTROLLER_IP="${INI__environment_params__controller_ip}"
COMPUTE_IP="${INI__environment_params__compute_ip}"
FOREMAN_URL="https://${INI__environment_params__foreman_ip}"
USER="${INI__environment_params__foreman_user}"
PASS="${INI__environment_params__foreman_pass}"


function myssh
{
sshpass -p $2 /usr/bin/ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -t root@$1 "$3"
}


function myscp_from_local
{
sshpass -p $2 /usr/bin/scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $1 root@$3:$4 2> /dev/null
}


function set_param1
{
echo -e "finish \e[92mLightParameter: $3= $4" 
}

function set_param
{
echo " " 
echo "Parameter: $3= $4" 
echo " " 
echo " "
curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://$1/api/puppetclasses/$2/smart_class_parameters/$3 -X PUT  -H "Content-Type: application/json" -d {\"default_value\":\"$4\"} -o -
echo " " 
echo " "
}


# Change defult host groups parameters :
#--------------------------------
echo  "Start: Change defult host groups parameters"

echo " "
echo "################## Nova Controller #####################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__nova_controller__puppet_class} admin_password ${INI__nova_controller__admin_password}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_controller__puppet_class} controller_priv_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_controller__puppet_class} controller_pub_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_controller__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_controller__puppet_class} qpid_host ${INI__environment_params__controller_ip}
echo " "
echo "###################### Nova Compute #####################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} admin_password ${INI__nova_compute__admin_password}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} controller_priv_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} controller_pub_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} qpid_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} nova_network_private_iface ${INI__nova_compute__nova_network_private_iface}

set_param ${INI__environment_params__foreman_ip} ${INI__nova_compute__puppet_class} nova_network_public_iface ${INI__nova_compute__nova_network_public_iface}


echo " "
echo "################### Neutron Controller #####################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} admin_password ${INI__neutron_controller__admin_password}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} controller_priv_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} controller_pub_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} qpid_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} enable_tunneling ${INI__neutron_controller__enable_tunneling}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} ovs_vlan_ranges ${INI__neutron_controller__ovs_vlan_ranges}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_controller__puppet_class} tenant_network_type ${INI__neutron_controller__tenant_network_type}
echo " "
echo "################### Neutron Compute #####################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} admin_password ${INI__neutron_compute__admin_password}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} controller_priv_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} controller_pub_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} qpid_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} tenant_network_type ${INI__neutron_compute__tenant_network_type}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} enable_tunneling ${INI__neutron_compute__enable_tunneling}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} ovs_vlan_ranges ${INI__neutron_compute__ovs_vlan_ranges}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} ovs_bridge_mappings ${INI__neutron_compute__ovs_bridge_mappings}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_compute__puppet_class} ovs_bridge_uplinks ${INI__neutron_compute__ovs_bridge_uplinks}

echo " "
echo "#################### Neutron-Networker ########################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} controller_priv_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} qpid_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} tenant_network_type ${INI__neutron_networker__tenant_network_type}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} ovs_vlan_ranges ${INI__neutron_networker__ovs_vlan_ranges}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} enable_tunneling ${INI__neutron_networker__enable_tunneling}

set_param  ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} ovs_bridge_mappings ${INI__neutron_networker__ovs_bridge_mappings}

set_param ${INI__environment_params__foreman_ip} ${INI__neutron_networker__puppet_class} ovs_bridge_uplinks ${INI__neutron_networker__ovs_bridge_uplinks}
echo " "
echo "#################### LVM Block Storage ########################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__cinder__puppet_class} controller_priv ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__cinder__puppet_class} mysql_host ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__cinder__puppet_class} qpid_host ${INI__environment_params__controller_ip}
echo " "
echo "#################### Load Balancer #########################"
echo " "
set_param ${INI__environment_params__foreman_ip} ${INI__load_balancer__puppet_class} lb_private_vip ${INI__environment_params__controller_ip}

set_param ${INI__environment_params__foreman_ip} ${INI__load_balancer__puppet_class} lb_public_vip ${INI__environment_params__controller_ip}



echo " "
echo "#################################################################"
echo "# The script finish changing default hostgroups parameters      #"
echo "#################################################################"

#Example How to change a sepcific host parameter
#----------------------------------------
#  curl -s -H "Accept:application/json,version=2" -k -u admin:changeme https://10.35.160.87/api/hosts/cougar14.scl.lab.tlv.redhat.com/smart_class_parameters/327/override_values -X POST -H "Content-Type: application/json" -d "{\"match\":\"fqdn=cougar14.scl.lab.tlv.redhat.com\", \"value\": \"false\"}"  -o -

