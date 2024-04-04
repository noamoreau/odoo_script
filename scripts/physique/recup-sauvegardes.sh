#!/bin/bash
if [[ -n $(ssh virt 'vmiut list|grep "sauvegardes"') ]]; then
    while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
    do 
        echo -e "${jaune_clair}Souhaitez-vous récuperer la dernière sauvegarde ? (y/n) : ${reset}"
        read -p reponse
        clear
        reponse=$(echo "$reponse"|tr '[:upper:]' '[:lower:]')
    done
    if([ "$reponse" == "y" ])
    then
        echo "${bleu_clair}Récupération de la derniere sauvegarde${reset}"
        dernier_backup=$(./sshpass -p user ssh sauvegardes1 'ls -1 -r|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1')
        if [[ -n $dernier_backup ]]; then
            echo -e "${bleu_clair}Envoit la derniere sauvegarde à postgres1 ${reset}"
            ./sshpass -p user ssh sauvegardes1 'rsync '"$dernier_backup" postgres@10.42.162.2:/var/lib/postgresql/
            echo "${bleu_clair}Création de la nouvelle base avec la sauvegarde${reset}"
            ./sshpass -p user ssh postgres1 'echo postgres |su --login postgres -c "psql -U postgres -f $(ls -1 -r /var/lib/postgresql/|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1) 1>/dev/null 2>&1 "' 1>/dev/null 2>&1
        fi
    fi
fi 
echo fin