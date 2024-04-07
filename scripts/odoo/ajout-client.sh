#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

#Utile ?
echo -e "${jaune_clair}Entrez le nom de l'entreprise du client avec des _ à la place des espaces${reset}"
read nomclient

echo -e "${jaune_clair}Entrez la version odoo, elle est comprise entre 8 et 17${reset}"
read versionodoo

clientversion="$nomclient:$versionodoo"



ssh odoo1 "echo $clientversion >> "'$HOME/client-version'

ssh postgres1 "echo user|sudo -S sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    postgres             '$nomclient'             odoo            scram-sha-256\nhost    '$nomclient'             '$nomclient'             odoo            scram-sha-256/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "echo postgres|su --login postgres -c 'createuser --createdb --no-superuser --no-createrole $nomclient'"
sed "s/@/$nomclient/g"  ../odoo/template_changer_mdp.sql > ../odoo/changer_mdp.sql
scp ../odoo/changer_mdp.sql postgres1:.
ssh postgres1 "echo user |sudo -S cp changer_mdp.sql /var/lib/postgresql/changer_mdp.sql"
ssh postgres1 "echo postgres|su - postgres -c 'psql -f changer_mdp.sql'"
ssh postgres1 "echo user|sudo -S systemctl restart postgresql"

sed "s/@/$nomclient/g" ../odoo/template_odoo.conf > ../odoo/odoo.conf 
ssh odoo1 "mkdir -p $nomclient/addons"

scp ../odoo/odoo.conf odoo1:~/$nomclient/odoo.conf

ssh odoo1 "cp template-docker-compose-odoo.yml" '$HOME'"/$nomclient/docker-compose.yml && sed -i -E 's/image: odoo/image: odoo:$versionodoo/g' $nomclient/docker-compose.yml"
ssh odoo1 "sed -i -E 's/@/$nomclient/g' $nomclient/docker-compose.yml"
ssh odoo1 "cd "'$HOME'"/$nomclient && docker-compose up -d"