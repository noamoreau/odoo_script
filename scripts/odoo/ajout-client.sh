#!/bin/bash

#Utile ?
echo -e "${jaune_clair}Entrez le nom de l\'entreprise du client avec des _ à la place des espaces${reset}"
read nomclient

echo -e "${jaune_clair}Entrez la version odoo, elle est comprise entre 8 et 17${reset}"
read versionodoo

clientversion="$nomclient:$versionodoo"

ssh odoo1 "echo $clientversion >> $HOME/client-version"

ssh odoo1 "mkdir $nomclient"
ssh odoo1 "cp template-docker-compose-odoo.yml $HOME/$nomclient/docker-compose.yml | sed -i -E 's/image: odoo/image: odoo:$versionodoo/g' $nomclient/docker-compose.yml"
ssh odoo1 "sed -i -E 's/container_name: odoo/container_name: $nomclient/g' $nomclient/docker-compose.yml"
ssh odoo1 "cd $HOME/$nomclient && docker-compose up -d"