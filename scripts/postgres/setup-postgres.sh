#!/bin/bash

ssh postgres1 "su --login -c 'apt-get install postgresql'"
ssh postgres1 "su --login -c 'apt-get install rsync"
ssh postgres1 "sudo -S sed -i 's/debian/postgres\n10.42.124.1\todoo/g' /etc/hosts'"
ssh postgres1 "sudo -S sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    postgres             odoo             odoo            scram-sha-256/g' /etc/postgresql/15/main/pg_hba.conf"

ssh postgres1 "sudo -S sed -i 's/#listen_addresses = 'localhost'/listen_addresses = '*'/g' /etc/postgresql/15/main/postgresql.conf"
ssh postgres1 "su --login -c 'systemctl restart postgresql'"

ssh postgres1 "su --login -c 'echo Modification du mot de passe de l'utilisateur postgres'"
ssh postgres1 "su --login -c 'passwd postgres'"
ssh postgres1 "su --login postgres -c 'createuser --interactive --pwprompt --createdb --no-superuser --no-createrole odoo'"

ssh postgres1 "su --login postgres -c 'pg_dump > backup-odoo.sql'"

premiercron="echo '0 0 * * * pg_dumpall > /var/lib/postgresql/testfile'"
deuxiemecron="echo '1 0 * * * rsync postgres@10.42.124.2:/var/lib/postgresql/test.sql /home/user/test'"

ssh postgres1 "sudo -S '(crontab -l 2>/dev/null; '$premiercron') | crontab -'"
ssh postgres1 "sudo -S '(crontab -l 2>/dev/null; '$deuxiemecron') | crontab -'"

echo "postgres terminé"