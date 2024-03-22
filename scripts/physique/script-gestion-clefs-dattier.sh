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

ip_odoo=$(ssh dattier.iutinfo.fr 'cat ip_odoo')

echo "$ip_odoo"

echo -e "\nHost odoo1\n\tHostname $ip_odoo\n\tuser user\n\tProxyJump dattier" >> $HOME/.ssh/config

ssh-copy-id odoo1

scp ../dattier/changer-ip.sh odoo1:.

ssh odoo1 'chmod u+x changer-ip.sh && ./changer-ip.sh 10.42.124.1 odoo1'

echo "terminado"

