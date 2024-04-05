#!/bin/bash

echo -e "${jaune_clair}Entrez les noms techniques séparé par un espace${reset}" 
read liste_addon
version=$(../physique/sshpass -p user odoo1 "grep $1 $HOME/client-version | cut -d : -f 2")

for addon in liste_addon
do
  if [[ $? == 0 ]]
  then
    ../physique/sshpass -p user odoo1 'wget https://apps.odoo.com/loempia/download/"$addon"/"$version"/$addon.zip'
    ../physique/sshpass -p user odoo1 $addon.zip
  else
    echo -e "${rouge_fonce}Le addon $addon n'est pas valide, veillez relancer le script en entrant un nom valide${reset}"  
  fi
done

../physique/sshpass -p user odoo1 "cd $HOME/$1 && docker-compose up -d"

echo Rendez-vous sur votre site Odoo en tant qu\'utilisateur \"admin\". Activez le mode développeur. Allez sur la page dédiée aux addons et cliquez sur \"mise à jour de la liste\"