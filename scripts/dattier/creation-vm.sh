#!/bin/bash

#vmiut stop odoo postgres sauvegardes
#vmiut remove odoo postgres sauvegardes
vmiut creer odoo postgres sauvegardes
vmiut start odoo postgres sauvegardes

ip=$(vmiut info odoo | tail -n 1 | cut -d "=" -f 2)

scp changer-ip.sh user@"$ip":.
ssh user@"$ip" 'chmod u+x changer-ip.sh && ./changer-ip.sh 10.42.124.1 odoo'



