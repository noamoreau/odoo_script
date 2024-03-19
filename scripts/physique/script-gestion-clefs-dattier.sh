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