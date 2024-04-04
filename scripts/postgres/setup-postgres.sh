#!/bin/bash

echo -e "${bleu_clair}Configuration de postgres1...${reset}"

ssh postgres1 "su --login -c 'apt-get install -y postgresql rsync'"
ssh postgres1 "sudo -S sed -i 's/debian/postgres\n10.42.124.1\todoo/g' /etc/hosts'"
ssh postgres1 "sudo -S sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    postgres             odoo             odoo            scram-sha-256/g' /etc/postgresql/15/main/pg_hba.conf"

ssh postgres1 "sudo -S sed -i 's/#listen_addresses = 'localhost'/listen_addresses = '*'/g' /etc/postgresql/15/main/postgresql.conf"
ssh postgres1 "su --login -c 'systemctl restart postgresql'"

echo -e "${jaune_clair}Entrez le nouveau mot de passe de l\'utilisateur postgres${reset}"
ssh postgres1 "su --login -c 'passwd postgres'"
ssh postgres1 "su --login postgres -c 'createuser --interactive --pwprompt --createdb --no-superuser --no-createrole odoo'"

#ssh postgres1 "su --login postgres -c 'pg_dump > backup-odoo.sql'"
today=$(date '+%Y-%m-%d')
premiercron="echo '0 0 * * * pg_dumpall > /var/lib/postgresql/$today'"
deuxiemecron="echo '1 0 * * * rsync postgres@10.42.124.2:/var/lib/postgresql/test.sql /home/user/test'"

ssh postgres1 "sudo -S '(crontab -l 2>/dev/null; '$premiercron') | crontab -'"
ssh sauvegardes1 "sudo -S '(crontab -l 2>/dev/null; '$deuxiemecron') | crontab -'"

echo -e "${bleu_clair}Configuration de postgres1 terminée${reset}"