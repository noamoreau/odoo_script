#!/bin/bash

echo -e "${bleu_clair}Configuration de postgres1...${reset}"

ssh postgres1 "echo root|su --login -c 'apt-get install -y postgresql rsync'"
ssh postgres1 "echo user|sudo -S sed -i 's/debian/postgres\n10.42.124.1\todoo/g' /etc/hosts"
ssh postgres1 "echo user|sudo -S sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "echo user|sudo -S sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "echo user|sudo -S sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    postgres             odoo             odoo            scram-sha-256/g' /etc/postgresql/15/main/pg_hba.conf"

ssh postgres1 "echo user|sudo -S sed -i -e 's/#listen_addresses/listen_addresses/g' -e 's/localhost/*/g' /etc/postgresql/15/main/postgresql.conf"
ssh postgres1 "echo root|su --login -c 'systemctl restart postgresql'"

echo -e "${jaune_clair}Entrez le nouveau mot de passe de l\'utilisateur postgres\nEntrez le mot de passe de root${reset}"
ssh postgres1 "su --login -c 'passwd postgres'"
ssh postgres1 "echo postgres|su --login postgres -c 'createuser --interactive --pwprompt --createdb --no-superuser --no-createrole odoo'"

#ssh postgres1 "su --login postgres -c 'pg_dump > backup-odoo.sql'"
today=$(date '+%Y-%m-%d')
premiercron="0 0 * * * pg_dumpall > /var/lib/postgresql/$today"
deuxiemecron="1 0 * * * rsync postgres@10.42.124.2:/var/lib/postgresql/test.sql /home/user/test"

ssh postgres1 '(crontab -l 2>/dev/null; echo "'"$premiercron"'" | crontab -)'

ssh sauvegardes1 '(crontab -l 2>/dev/null; echo "'"$deuxiemecron"'"| crontab -)'

echo -e "${bleu_clair}Configuration de postgres1 terminée${reset}"


