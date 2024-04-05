#!/bin/bash

echo -e "${bleu_clair}Configuration d'odoo1...${reset}"

ssh odoo1 "su --login -c 'apt-get install -y docker-compose unzip curl'"
ssh odoo1 'su --login -c "adduser user docker"'
ssh odoo1 'cat <<EOF > ~/daemon.json
{
"registry-mirrors": ["http://172.18.48.9:5000"],
"default-address-pools": [{ "base": "172.20.0.0/16", "size": 24 }]
}
EOF'

ssh odoo1 'su --login -c "cp /home/user/daemon.json /etc/docker/daemon.json"'

chmod 777 template-docker-compose-odoo.yml
scp template-docker-compose-odoo.yml odoo1:$HOME
chmod 700 ajout-client.sh
./ajout-client.sh

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
ssh odoo1 'sudo -S bash -c "echo $(ls ~|grep mkcert)"'
ssh odoo1 'sudo -S bash -c "chmod u+x $(ls ~|grep mkcert)"'
ssh odoo1 'sudo -S bash -c "./$(ls ~|grep mkcert) -install"'

ssh odoo1 "mkdir ~/traefik/{conf,certs}"
ssh odoo1 './$(ls ~|grep mkcert) -cert-file ~/traefik/certs/local-cert.pem -key-file ~/traefik/certs/local-key.pem "*.'$(hostname)'.iutinfo.fr"'
cp ./template_traefik.yml ./traefik.yml
sed "s/@/$(hostname)/g" ./template_traefik.yml > ./traefik.yml 
scp ./traefik.yml odoo1:~/traefik/conf/traefik.yml

ssh odoo1 'cat <<EOF > ~/traefik/conf/config.yml
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
EOF
'

echo -e "${bleu_clair}Configuration d'odoo1 terminée${reset}"