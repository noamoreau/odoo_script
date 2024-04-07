#!/bin/bash
if [[ -n $(ssh dattier 'vmiut list|grep "sauvegardes"') ]]; then
    while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
    do 
        echo -e "${jaune_clair}Souhaitez-vous récuperer la dernière sauvegarde ? (y/n) : ${reset}"
        read reponse
        clear
        reponse=$(echo "$reponse"|tr '[:upper:]' '[:lower:]')
    done
    if([ "$reponse" == "y" ])
    then
        echo -e "${bleu_clair}Récupération de la derniere sauvegarde${reset}"
        echo -e "${bleu_clair}Envoit la derniere sauvegarde à postgres1 ${reset}"
        ssh sauvegardes1 'echo postgres|rsync backup postgres@10.42.124.2:/var/lib/postgresql/backup_to_add'
        echo -e "${bleu_clair}Création de la nouvelle base avec la sauvegarde${reset}"
        ssh postgres1 'echo postgres |su --login postgres -c "psql -U postgres -f backup_to_add 1>/dev/null 2>&1 "' 1>/dev/null 2>&1
    fi
fi 
echo Récupération des sauvegardes effectuée