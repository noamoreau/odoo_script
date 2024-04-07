#!/bin/bash

esc='\e'
rouge_fonce=${esc}'[91m'
bleu_clair=${esc}'[94m'
jaune_clair=${esc}'[33m'
reset=${esc}'[0m'

echo -e "${bleu_clair}Configuration d'odoo1...${reset}"

ssh odoo1 "echo root | su --login -c 'apt-get install -y docker-compose unzip curl'"
ssh odoo1 'echo root | su --login -c "adduser user docker"'
ssh odoo1 'cat <<EOF > ~/daemon.json
{
"registry-mirrors": ["http://172.18.48.9:5000"],
"default-address-pools": [{ "base": "172.20.0.0/16", "size": 24 }]
}
EOF'

ssh odoo1 'echo root | su --login -c "cp /home/user/daemon.json /etc/docker/daemon.json"'



ssh odoo1 "mkdir ~/traefik"
ssh odoo1 "cat <<EOF > ~/traefik/docker-compose.yml
version: '3.3'
services:
  traefik:
    image: traefik:v3.0
    ports:
      - 9090:80
      - 9091:443
    networks:
      - proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./conf/traefik.yml:/etc/traefik/traefik.yml
      - ./conf/config.yml:/etc/traefik/config.yml:ro
      - ./certs:/etc/certs:ro
    labels:
      - traefik.enable=true
      - traefik.http.routers.traefik=true
networks:
  proxy:
    external: true
EOF"

ssh odoo1 "curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64""
ssh odoo1 'echo user |sudo -S bash -c "chmod u+x $(ls ~|grep mkcert)"'
ssh odoo1 'echo user |sudo -S bash -c "./$(ls ~|grep mkcert) -install"'

ssh odoo1 "mkdir ~/traefik/{conf,certs}"
ssh odoo1 './$(ls ~|grep mkcert) -cert-file ~/traefik/certs/local-cert.pem -key-file ~/traefik/certs/local-key.pem "*.'$(hostname)'.localhost"'
sed "s/@/$(hostname)/g" ../odoo/template_traefik.yml > ../odoo/traefik.yml 
scp ../odoo/traefik.yml odoo1:~/traefik/conf/traefik.yml

sed "s/&/$(hostname)/g" ../odoo/template_config.yml > ../odoo/config.yml 
scp ../odoo/config.yml odoo1:~/traefik/conf/config.yml

ssh odoo1 'docker network create proxy'

ssh odoo1 "cd "'$HOME'"/traefik && docker-compose up -d"

chmod 777 ../odoo/template-docker-compose-odoo.yml
scp ../odoo/template-docker-compose-odoo.yml odoo1:~/
chmod 700 ../odoo/ajout-client.sh
../odoo/ajout-client.sh



echo -e "${bleu_clair}Configuration d'odoo1 terminée${reset}"