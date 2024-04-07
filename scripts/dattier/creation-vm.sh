#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'


echo -e "${bleu_clair}Arrêt des VMs${reset}"
vmiut stop odoo1 postgres1 sauvegardes1  1>/dev/null 2>&1
echo -e "${bleu_clair}Suppression des VMs${reset}"
vmiut rm odoo1 postgres1 sauvegardes1  1>/dev/null 2>&1
echo -e "${bleu_clair}Création des VMs${reset}"
vmiut creer odoo1 postgres1 sauvegardes1  1>/dev/null 2>&1
echo -e "${bleu_clair}Démarrage des VMs${reset}"
vmiut start odoo1 postgres1 sauvegardes1  1>/dev/null 2>&1

sleep 30s

var_ip_odoo=$(vmiut info odoo1 |grep ip-possible |cut -d "=" -f 2)
var_ip_postgres=$(vmiut info postgres1 |grep ip-possible |cut -d "=" -f 2)
var_ip_sauvegardes=$(vmiut info sauvegardes1 |grep ip-possible |cut -d "=" -f 2)

echo "$var_ip_odoo" > ip_odoo1
echo "$var_ip_postgres" > ip_postgres1
echo "$var_ip_sauvegardes" > ip_sauvegardes1

