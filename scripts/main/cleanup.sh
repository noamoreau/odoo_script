#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'


ssh dattier 'rm $HOME/creation-vm.sh'

for i in odoo1 postgres1 sauvegardes1
do
    ssh $1 "'rm $HOME/ip_'$1"
    echo -e "${jaune_clair}Entrez un nouveau mot de passe pour user sur $i ${reset}"
    ssh $i 'su --login -c "passwd user"'
    echo -e "${jaune_clair}Entrez un nouveau mot de passe pour root sur $i ${reset}"
    ssh $i 'su --login -c "passwd root"'
done
echo -e "${jaune_clair}Entrez un nouveau mot de passe pour postgres sur postgres1${reset}"
ssh postgres1 'su --login -c "passwd postgres"'