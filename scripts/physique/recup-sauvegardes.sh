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
        echo "${bleu_clair}Récupération de la derniere sauvegarde${reset}"
        dernier_backup=$(ssh sauvegardes1 'ls -1 -r|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1')
        if [[ -n $dernier_backup ]]; then
            echo -e "${bleu_clair}Envoit la derniere sauvegarde à postgres1 ${reset}"
            ssh sauvegardes1 'echo postgres|rsync '"$dernier_backup" postgres@10.42.124.2:/var/lib/postgresql/
            echo "${bleu_clair}Création de la nouvelle base avec la sauvegarde${reset}"
            ssh postgres1 'echo postgres |su --login postgres -c "psql -U postgres -f $(ls -1 -r /var/lib/postgresql/|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1) 1>/dev/null 2>&1 "' 1>/dev/null 2>&1
        fi
    fi
fi 
echo fin