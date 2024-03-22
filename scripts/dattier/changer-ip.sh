#!/bin/bash
su -

hostnamectl set-hostname $2
sed -i 's/iface enp0s3 inet dhcp/iface enp0s3 inet static\n\taddress $1\/16\n\tgateway 10.42.0.1/g' /etc/network/interfaces