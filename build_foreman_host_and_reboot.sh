#!/bin/sh
FOREMAN_URL="https://theforeman.com"
suffix=".domain"
USER="hostbuilder"
PASS=""

if [ $# -lt 1 ]; then
    echo 'ERROR, missing parameter'
    echo
    echo 'Usage:'
    echo '       '${0}' machine'
    exit 1
fi


host=$1${suffix}

for host in $host ; do
    echo -n "Building host "$host", Return Code (0-successful, 1-fail): "
    curl -s -H "Accept:application/json" -k -u $USER:$PASS $FOREMAN_URL/hosts/$host -X PUT -d "host[build]=1" -o - | grep $host
    echo $? || { echo "Failed to build host "$host", exiting!" ; exit 1 ; }
    echo "Rebooting host "$host
    ssh root@$host "reboot" || { echo "Failed to reboot host "$host", exiting!" ; exit 1 ; }
done
