#!/bin/bash

echo "stop les vm"
vmiut stop odoo1 postgres1 sauvegardes1
echo "rm les vm"
vmiut rm odoo1 postgres1 sauvegardes1
echo "création des vm"
vmiut creer odoo1 postgres1 sauvegardes1
echo "start des vm"
vmiut start odoo1 postgres1 sauvegardes1

sleep 30s

var_ip_odoo=$(vmiut info odoo1 |grep ip-possible |cut -d "=" -f 2)
var_ip_postgres=$(vmiut info postgres1 |grep ip-possible |cut -d "=" -f 2)
var_ip_sauvegardes=$(vmiut info sauvegardes1 |grep ip-possible |cut -d "=" -f 2)

echo "$var_ip_odoo" > ip_odoo1
echo "$var_ip_postgres" > ip_postgres1
echo "$var_ip_sauvegardes" > ip_sauvegardes1

