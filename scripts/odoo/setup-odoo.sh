#!/bin/bash

echo -e "${bleu_clair}Configuration d'odoo1...${reset}"

ssh odoo1 "su --login -c 'apt-get install -y docker-compose unzip curl'"
ssh odoo1 'su --login -c "adduser user docker"'
ssh odoo1 'sudo -S cat <<EOF > /etc/docker/daemon.json
{
"registry-mirrors": ["http://172.18.48.9:5000"],
"default-address-pools": [{ "base": "172.20.0.0/16", "size": 24 }]
}
EOF'

ssh odoo1 "mkdir ~/odoo"
ssh odoo1 "cat <<EOF > ~/odoo/docker-compose.yml
version: '3.3'
services:
  odoo:
    image: odoo
    container_name: odoo
    volumes:
      - ./odoo.conf:/etc/odoo/odoo.conf
      - ./addons:/mnt/extra-addons
    networks:
      - proxy
    security_opt:
      - no-new-privileges:true
    labels:
      - traefik.enable=true
      - traefik.http.routers.odoo.tls=true

networks:
  proxy:
   external: true
EOF"

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
ssh odoo1 "sudo -S bash -c 'echo $(ls ~|grep mkcert)'"
ssh odoo1 "sudo -S bash -c 'chmod u+x $(ls ~|grep mkcert)'"
ssh odoo1 "sudo -S bash -c './$(ls ~|grep mkcert) -install'"

ssh odoo1 "mkdir ~/traefik/{conf,certs}"
ssh odoo1 './$(ls ~|grep mkcert) -cert-file ~/traefik/certs/local-cert.pem -key-file ~/traefik/certs/local-key.pem "*.<phys>.iutinfo.fr"'
ssh odoo1 'cat <<EOF > ~/traefik/conf/traefik.yml
global:
  sendAnonymousUsage: false

api:
  dashboard: true

providers:
  docker:
    defaultRule: "Host(`{{ .ContainerName }}.<phys>.iutinfo`)"
    endpoint: "unix:///var/run/docker.sock"
    watch: true
    exposedByDefault: false

  file:
    filename: /etc/traefik/config.yml
    watch: true

log:
  level: INFO
  format: common

entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
EOF
'

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
EOF'

echo -e "${bleu_clair}Configuration d'odoo1 terminée${reset}"