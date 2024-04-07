#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

echo -e "${bleu_clair}Nettoyage en cours${reset}"

ssh dattier 'rm $HOME/creation-vm.sh'  1>/dev/null 2>&1
ssh odoo1 "rm daemon.json mkcert-v*-amd64"  1>/dev/null 2>&1
ssh postgres1 'rm changer_mdp.sql'  1>/dev/null 2>&1
ssh sauvegardes1 'rm sshpass'  1>/dev/null 2>&1

for i in odoo1 sauvegardes1 postgres1
do
    ssh $1 "'rm $HOME/ip_'$1"  1>/dev/null 2>&1
    echo -e "${jaune_clair}Entrez un nouveau mot de passe pour user sur $i ${reset}"
    read  password
    ssh $i "echo root |su --login -c 'echo user:'$password'|chpasswd'" 1>/dev/null 2>&1
    echo -e "${jaune_clair}Entrez un nouveau mot de passe pour root sur $i ${reset}"
    read  password
    ssh $i "echo root |su --login -c 'echo root:'$password'|chpasswd'" 1>/dev/null 2>&1
done
echo -e "${jaune_clair}Entrez un nouveau mot de passe pour postgres sur postgres1${reset}"
read password
ssh postgres1 "echo root |su --login -c 'echo postgres:'$password'|chpasswd'" 1>/dev/null 2>&1