#!/bin/bash

#vmiut stop odoo postgres sauvegardes
#vmiut remove odoo postgres sauvegardes
vmiut creer odoo1 postgres1 sauvegardes1
vmiut start odoo1 postgres1 sauvegardes1

ip=$(vmiut info odoo1 |grep ip-possible |cut -d "=" -f 2)

echo "$ip"

echo "Connexion à Dattier"
echo "Souhaitez-vous générer une paire de clefs SSH ? (y/n)"
while([ "$reponse" != "y" ] && [ "$reponse" != "n" ])
do read reponse
done
if([ "$reponse" == "y" ])
then
    echo "Génération de la paire de clefs SSH"
    ssh-keygen -C "clef-ssh"
fi

ssh-copy-id user@"$ip"


scp -v changer-ip.sh user@"$ip":/home/user


echo pouet 

ssh -o StrictHostKeyChecking=no user@"$ip" 'chmod u+x changer-ip.sh && ./changer-ip.sh 10.42.124.1 odoo1'



