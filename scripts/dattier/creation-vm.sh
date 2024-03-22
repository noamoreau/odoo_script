#!/bin/bash

#vmiut stop odoo postgres sauvegardes
#vmiut remove odoo postgres sauvegardes
vmiut creer odoo1 postgres1 sauvegardes1
vmiut start odoo1 postgres1 sauvegardes1

sleep 30s

ip=$(vmiut info odoo1 |grep ip-possible |cut -d "=" -f 2)

echo $ip > ip_odoo


