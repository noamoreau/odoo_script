#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

while true
do
  echo -e "${jaune_clair}Gestionnaire d'installation Odoo\n1) Installer des addons\n2) Ajouter un client\n3) Récupérer les données sur la sauvegarde quotidienne\n${reset}${rouge_fonce}4) Refaire toute l'installation et perdre toutes les données${reset}"
  read choix
  case $choix in
    1)
      echo -e  "${jaune_clair} Entrez le nom du client ${reset}"
      read client
      ../odoo/install-addon.sh $client
      break
      ;;
    2)
      echo hoho
      ../odoo/ajout-client.sh
      break
      ;;
    3)
      echo sauvegardes
      ../sauvegardes/recup-sauvegardes.sh
      break
      ;;
    4)
      echo -e "${rouge_fonce}Vous allez perdre toutes vos données, backup y compris, êtes-vous certain ?\n1) Non\n2) Oui${reset}"
      read confirmation
      if [[ $confirmation == "2" ]]
      then
        echo olala
        ./init-all.sh
        break
      else
        continue
      fi
      ;;
    *)
      echo 'Veuillez entrer une valeur entre 1 et 4'
      continue
      ;;
  esac
done