#!/bin/bash

ssh odoo1 "su --login -c 'apt-get install docker.io && apt-get install docker-compose'"
ssh odoo1 '{\
"registry-mirrors": ["http://172.18.48.9:5000"],\
"default-address-pools": [{ "base": "172.20.0.0/16", "size": 24 }]\
}" > /etc/docker/daemon.json'

echo "Vérification installation docker"
ssh odoo1 "sudo -S 'docker run --rm hello-world'"

ssh odoo1 "mkdir ~/traefik"
ssh odoo1 '"
version: "3.3"\
\
services:\
\ttraefik:
\t\timage: "traefik:v2.5"\
\t\tcontainer_name: "traefik"\
\
\t\tports:\
\t- "8000:80"
      - "8080:8080"
      - "4430:443"

    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./traefik.yml:/etc/traefik/traefik.yml"

    networks:
      - "proxy"

    command:
      - "--providers.docker.network=proxy"

    labels:
      - "traefik.enable=true"

networks:
  proxy:
    name: "proxy"
"'




ssh odoo1 "sudo -S 'curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"'"
sudo odoo1 "sudo -S 'cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert'"
sudo odoo1 "sudo -S 'mkcert -install'"