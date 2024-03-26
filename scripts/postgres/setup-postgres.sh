#!/bin/bash

ssh postgres1 "su --login -c 'apt-get install postgresql'"
ssh postgres1 "sudo -S sed -i 's/127.0.1.1\tdebian/127.0.1.1\tpostgres\n10.42.124.1\todoo/g' /etc/hosts'"
ssh postgres1 "sudo -S sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/15/main/pg_hba.conf"
ssh postgres1 "sudo -S sed -i 's/# IPv4 local connections:/# IPv4 local connections:\nhost    postgres             odoo             odoo            scram-sha-256/g' /etc/postgresql/15/main/pg_hba.conf"

ssh postgres1 "sudo -S sed -i 's/#listen_addresses = 'localhost' \t# what IP address(es) to listen on;/listen_addresses = '*' \t# what IP address(es) to listen on;/g' /etc/postgresql/15/main/postgresql.conf"
ssh postgres1 "su --login -c 'systemctl restart postgresql'"

ssh postgres1 "su --login -c 'passwd postgres'"
ssh postgres1 "su --login postgres -c 'createuser --interactive --pwprompt --createdb --no-superuser --no-createrole odoo'"

echo "postgres terminé"