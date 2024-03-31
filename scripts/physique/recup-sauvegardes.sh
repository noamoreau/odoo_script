#!/bin/bash
if [[ -n $(./sshpass -p user ssh virt 'vmiut list|grep "sauvegardes"') ]]; then
    while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
    do read -p "Souhaitez-vous récuperer les dernières sauvegardes ? (y/n) : " reponse
        clear
        reponse=$(echo "$reponse"|tr '[:upper:]' '[:lower:]')
    done
    if([ "$reponse" == "y" ])
    then
        echo "On recupere la derniere backup"
        dernier_backup=$(./sshpass -p user ssh sauvegardes 'ls -1 -r|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1')
        if [[ -n $dernier_backup ]]; then
            echo "On envoit la derniere backup"
            ./sshpass -p user ssh sauvegardes 'rsync '"$dernier_backup" postgres@10.42.162.2:/var/lib/postgresql/
            echo "On recreer la base grâce a la backup"
            ./sshpass -p user ssh postgres 'echo postgres |su --login postgres -c "psql -U postgres -f $(ls -1 -r /var/lib/postgresql/|grep -E [0-9]{4}-[0-9]{2}-[0-9]{2}|head -n1) 1>/dev/null 2>&1 "' 1>/dev/null 2>&1
        fi
    fi
fi 
echo fin