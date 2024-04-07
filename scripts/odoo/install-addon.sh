#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

echo -e "${jaune_clair}Entrez les noms techniques séparé par un espace${reset}" 
read liste_addon
version=$(ssh odoo1 "grep $1 "'$HOME/client-version | cut -d : -f 2')
for addon in $liste_addon
do
   ssh odoo1 wget "https://apps.odoo.com/loempia/download/$addon/${version}.0/$addon.zip -P "'$HOME/'"$1/addons"  1>/dev/null 2>&1
  if [[ $? == 0 ]]
  then
    ssh odoo1 'unzip $HOME/'"$1/addons/$addon.zip -d "'$HOME'"/$1/addons/"  1>/dev/null 2>&1
  else
    echo -e "${rouge_fonce}Le addon $addon n'est pas valide, veillez relancer le script en entrant un nom valide${reset}"  
  fi
done

ssh odoo1 "cd "'$HOME'"/$1 && docker-compose up -d"  1>/dev/null 2>&1

echo -e ${bleu_clair}Rendez-vous sur votre site Odoo en tant qu\'utilisateur \"admin\". Activez le mode développeur. Allez sur la page dédiée aux addons et cliquez sur \"mise à jour de la liste\"${reset}