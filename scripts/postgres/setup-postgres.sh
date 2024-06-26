#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'


echo -e "${bleu_clair}Configuration de postgres1...${reset}"

ssh postgres1 "echo root|su --login -c 'apt-get install -y postgresql rsync'" 1>/dev/null 2>&1
ssh postgres1 "echo user|sudo -S sed -i 's/debian/postgres\n10.42.124.1\todoo/g' /etc/hosts" 1>/dev/null 2>&1
ssh postgres1 "echo user|sudo -S sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/15/main/pg_hba.conf" 1>/dev/null 2>&1
ssh postgres1 "echo user|sudo -S sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/15/main/pg_hba.conf" 1>/dev/null 2>&1

ssh postgres1 "echo user|sudo -S sed -i -e 's/#listen_addresses/listen_addresses/g' -e 's/localhost/*/g' /etc/postgresql/15/main/postgresql.conf" 1>/dev/null 2>&1
ssh postgres1 "echo root|su --login -c 'systemctl restart postgresql'" 1>/dev/null 2>&1

ssh postgres1 "echo root |su --login -c 'echo postgres:postgres|chpasswd'" 1>/dev/null 2>&1

premiercron="0 0 * * * pg_dumpall > /var/lib/postgresql/backup"
deuxiemecron="1 0 * * * rsync postgres@10.42.124.2:/var/lib/postgresql/backup /home/user/backup"
../main/sshpass -p postgres ssh -J dattier postgres@10.42.124.2 '(crontab -l 2>/dev/null; echo "'"$premiercron"'" | crontab -)' 1>/dev/null 2>&1

ssh sauvegardes1 '(crontab -l 2>/dev/null; echo "'"$deuxiemecron"'"| crontab -)' 1>/dev/null 2>&1

echo -e "${bleu_clair}Configuration de postgres1 terminée${reset}"