#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

if [[ ! -f "./sshpass" ]]
then
  ./install-sshpass.sh
fi

echo -e "${bleu_clair}Connexion à Dattier${reset}"
echo -e "${jaune_clair}Souhaitez-vous générer une paire de clefs SSH ? (y/n)${reset}"
while ([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
do read reponse
done
if ([ "$reponse" == "y" ])
then
    echo -e "${bleu_clair}Génération de la paire de clefs SSH${reset}"
    ssh-keygen -N "" 1>/dev/null 2>&1
fi

ssh-copy-id dattier.iutinfo.fr 1>/dev/null 2>&1

scp ../dattier/creation-vm.sh dattier.iutinfo.fr:~/. 1>/dev/null 2>&1
ssh dattier.iutinfo.fr 'chmod u+x creation-vm.sh && ./creation-vm.sh' 

liste_nom_machines=("odoo1" "postgres1" "sauvegardes1")

for i in 0 1 2
do
  ip=$(ssh dattier.iutinfo.fr 'cat ip_'${liste_nom_machines[$i]})  
  if [[ $(grep -o -i "host ${liste_nom_machines[$i]}" $HOME/.ssh/config ) ]]
  then
    nb=$(expr $(wc -l $HOME/.ssh/config | cut -d " " -f 1) - $(grep -o -n -i "host ${liste_nom_machines[$i]}" $HOME/.ssh/config | cut -d : -f 1))
    nb=$((nb+1))
    fichier=$(tail -n $nb $HOME/.ssh/config)
    alias=""
    while read ligne; do
      if [[ -z "$ligne" ]]; then
        break
      fi
      alias="$alias""$ligne"$'@&'
    done <<< "$fichier"
    alias=${alias%?}

    echo -e "${jaune_clair}Un alias pour ${liste_nom_machines[$i]} a été détecté souhaitez-vous le remplacer ? (y/n)${reset}" 
    echo $alias | tr "@" "\n" | tr "&" "\t" 
    read reponse
    while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
    do read reponse
    done
    if ([ "$reponse" == "y" ])
    then
        cat ~/.ssh/config |tr "\n" "@" | tr "\t" "&" | sed "s|$alias|@Host ${liste_nom_machines[$i]}@\&Hostname $ip\@\&user user@\&ProxyJump dattier@\&LocalForward localhost:9090 localhost:9090@\&LocalForward localhost:9091 localhost:9091@|g" | tr "@" "\n" | tr "&" "\t" > config
        cp config ~/.ssh/config 1>/dev/null 2>&1
    fi
  else
    echo -e "\nHost ${liste_nom_machines[$i]}\n\tHostname $ip\n\tuser user\n\tProxyJump dattier\n\tLocalForward localhost:9090 localhost:9090\n\tLocalForward localhost:9091 localhost:9091" >> ~/.ssh/config
  fi

  ./sshpass -p user ssh-copy-id -o "StrictHostKeyChecking no" "${liste_nom_machines[$i]}" 1>/dev/null 2>&1
  echo -e "${bleu_clair}Configuration de base de la vm ${liste_nom_machines[$i]}${reset}"
  ssh "${liste_nom_machines[$i]}" 'echo root | su -c "apt-get -y update && apt -y full-upgrade && apt-get install -y sudo"' 1>/dev/null 2>&1
  ssh "${liste_nom_machines[$i]}" 'echo root |su --login -c "adduser user sudo"' 1>/dev/null 2>&1
  ssh "${liste_nom_machines[$i]}" 'echo root |su --login -c "reboot"' 1>/dev/null 2>&1
  echo -e "${bleu_clair}Redémarrage de la vm ${liste_nom_machines[$i]} après installation des commandes de base${reset}"
  sleep 10s
  ssh "${liste_nom_machines[$i]}" "echo root |su --login -c 'hostnamectl set-hostname ${liste_nom_machines[$i]}'" 1>/dev/null 2>&1
  ssh "${liste_nom_machines[$i]}" "echo user |sudo -S sed -i 's/iface enp0s3 inet dhcp/iface enp0s3 inet static\n\taddress 10.42.124.$(($i+1))\/16\n\tgateway 10.42.0.1/g' /etc/network/interfaces && echo user|sudo -S reboot" 1>/dev/null 2>&1
  sed -i s/$ip/10.42.124.$(($i+1))/g ~/.ssh/config
done

chmod u+x ../postgres/setup-postgres.sh 1>/dev/null 2>&1
../postgres/setup-postgres.sh

chmod u+x ../sauvegardes/setup-sauvegardes.sh 1>/dev/null 2>&1
../sauvegardes/setup-sauvegardes.sh

chmod u+x ../odoo/setup-odoo.sh 1>/dev/null 2>&1
../odoo/setup-odoo.sh



chmod u+x cleanup.sh
./cleanup.sh