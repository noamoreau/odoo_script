#!/bin/bash

# menu 1. tout reinstall perdre données 2. Ajouter un client 3. Récupérer backup 4. installer addon

# verif ssh config
# demander si remplace = tout perdre 

rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'

if [[ ! -f "./sshpass" ]]
then
  ./install-sshpass.sh
fi

echo -e "${bleu_clair} Connexion à Dattier${reset}"
echo -e "${jaune_clair} Souhaitez-vous générer une paire de clefs SSH ? (y/n)${reset}"
while ([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
do read reponse
done
if ([ "$reponse" == "y" ])
then
    echo -e "${bleu_clair}Génération de la paire de clefs SSH${reset}"
    ssh-keygen -C "clef-ssh-dattier"
fi

ssh-copy-id dattier.iutinfo.fr

scp ../dattier/creation-vm.sh dattier.iutinfo.fr:$HOME
ssh dattier.iutinfo.fr 'chmod u+x creation-vm.sh && ./creation-vm.sh'

liste_fichier_ip=("odoo1" "postgres1" "sauvegardes1")

for i in 0 1 2
do
  ip=$(ssh dattier.iutinfo.fr 'cat ip_'${liste_fichier_ip[$i]})
  #ssh dattier.iutinfo.fr 'echo ip_${liste_fichier_ip[$i]}'
  
  if [[ $(grep -o -i "host odoo1" $HOME/.ssh/config ) ]]
  then
    echo -p -e "${jaune_clair}Un alias pour ${liste_fichier_ip[$i]} a été détecté souhaitez-vous le remplacer ? (y/n)${reset}" 
    nb=$(expr $(wc -l ./config | cut -d " " -f 1) - $(grep -o -n -E -e "(H|h)ost $1" ./config | cut -d : -f 1))
    nb=$((nb+1))

    fichier=$(tail -n $nb ./config)
    alias=""

    while read ligne; do
      if [[ -z "$ligne" ]]; then
        break
      fi
      alias="$alias""$ligne"$'@&'
    done <<< "$fichier"
    alias=${alias%?}

    echo $alias | tr "@" "\n" | tr "&" "\t" 
    while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
    do read reponse
    done
    if ([ "$reponse" == "y" ])
    then
        cat $HOME/.ssh/config |tr "\n" "@" | tr "\t" "&" | sed "s|$alias|\nHost ${liste_fichier_ip[$i]}\n\tHostname $ip\n\tuser user\n\tProxyJump dattier|g" | tr "@" "\n" | tr "&" "\t" > $HOME/.ssh/config
    fi
  else

    echo -e "\nHost ${liste_fichier_ip[$i]}\n\tHostname $ip\n\tuser user\n\tProxyJump dattier" >> $HOME/.ssh/config
  fi

  ./sshpass -p user ssh-copy-id "${liste_fichier_ip[$i]}"

  ssh "${liste_fichier_ip[$i]}" 'echo root | su -c "apt-get -y update && apt -y full-upgrade && apt-get install -y sudo"'
  ssh "${liste_fichier_ip[$i]}" 'echo root |su --login -c "adduser user sudo"'
  ssh "${liste_fichier_ip[$i]}" 'echo root |su --login -c "reboot"'
  echo -e "${bleu_clair}Redémarrage de la vm ${liste_fichier_ip[$i]} après installation des commandes de base${reset}"
  sleep 10s
  ssh "${liste_fichier_ip[$i]}" "echo root |su --login -c 'hostnamectl set-hostname ${liste_fichier_ip[$i]}'"
  ssh "${liste_fichier_ip[$i]}" "echo user |sudo -S sed -i 's/iface enp0s3 inet dhcp/iface enp0s3 inet static\n\taddress 10.42.124.$(($i+1))\/16\n\tgateway 10.42.0.1/g' /etc/network/interfaces && sudo -S reboot"
  sed -i s/$ip/10.42.124.$(($i+1))/g $HOME/.ssh/config
done

chmod u+x ../postgres/setup-postgres.sh
../postgres/setup-postgres.sh

chmod u+x cleanup.sh
./cleanup.sh