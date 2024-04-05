#!/bin/bash

while [[ $nomclient =~ " " ]]
do
  echo Entrez le nom de l\'entreprise du client avec des _ à la place des espaces
  read nomclient
done

while [[ versionodoo =~ [a-zA-Z ] ]]
do
  echo Entrez la version odoo, elle est comprise entre 8 et 17
  read versionodoo
done

clientversion=$nomclient:$versionodoo

clientversion >> $HOME/client-version