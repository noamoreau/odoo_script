#!/bin/bash

./sshpass -p user odoo1 ''

while
do
  ajout_addon=$(read)

done

for addon in $(cat liste_addon)
do
  ./sshpass -p user odoo1 'wget https://apps.odoo.com/loempia/download/"$addon"/<version de odoo>/<nom technique du module>.zip'
done