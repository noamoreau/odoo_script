#!/bin/bash

echo "Connexion à Dattier"
echo "Souhaitez-vous générer une paire de clefs SSH ? (y/n)"
while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
do read reponse
done
if([ "$reponse" == "y" ])
then
    echo "Génération de la paire de clefs SSH"
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
  echo -e "\nHost ${liste_fichier_ip[$i]}\n\tHostname $ip\n\tuser user\n\tProxyJump dattier" >> $HOME/.ssh/config

  ssh-copy-id "${liste_fichier_ip[$i]}"

  ssh "${liste_fichier_ip[$i]}" 'su -c "apt-get -y update && apt -y full-upgrade && apt-get install -y sudo"'
  ssh "${liste_fichier_ip[$i]}" 'su --login -c "adduser user sudo"'
  ssh "${liste_fichier_ip[$i]}" 'su --login -c "reboot"'
  echo "Redémarrage de la vm après installation des commandes"
  sleep 10s
  ssh "${liste_fichier_ip[$i]}" "su --login -c 'hostnamectl set-hostname ${liste_fichier_ip[$i]}'"
  ssh "${liste_fichier_ip[$i]}" "sudo -S sed -i 's/iface enp0s3 inet dhcp/iface enp0s3 inet static\n\taddress 10.42.124.$(($i+1))\/16\n\tgateway 10.42.0.1/g' /etc/network/interfaces && sudo -S reboot"
  sed -i s/$ip/10.42.124.$(($i+1))/g $HOME/.ssh/config
done

chmod u+x ../postgres/setup-postgres.sh
../postgres/setup-postgres.sh