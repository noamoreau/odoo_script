# Mise en place de la machine odoo

## Création de l'alias pour se connecter à la machine odoo

Pour cela il faut autoriser les connections ssh pour root

```sh
nano /etc/ssh/sshd_config
```

```sh
# Authentication:

#LoginGraceTime 2m
PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10
```

```sh
systemctl restart sshd.service
```

```sh
nano ~/.ssh/config
```

```sh
Host odoo
    HostName 10.42.xx.1
    User root
    ProxyJump dattier
    LocalForward localhost:8080 localhost:8080
```

## Mise à jour de la machine et installation de docker

Si cela n'a jamais été fait, mettre à jour la machine :

```sh
apt update && apt full-upgrade
```

Installation de docker :

```sh
apt install docker.io
apt install docker-compose
```

Modifier ou créer le fichier `/etc/docker/daemon.json` :

```json
{
  "registry-mirrors": ["http://172.18.48.9:5000"],
  "default-address-pools": [{ "base": "172.20.0.0/16", "size": 24 }]
}
```

Vérifier que le service est bien actif :

```sh
docker run --rm hello-world
```

## Création du container odoo

```
docker run --rm -p 8080:8069 --name odoo -e HOST=postgres -e USER=odoo -e PASSWORD=odoo -d odoo
```

Si erreur :

- retirer `--rm`
- faire la commande `docker logs odoo` pour voir l'erreur

Se connecter avec cet alias puis créer le container et sur firefox `localhost:8080`, la page d'odoo doit s'afficher.

## Pour ajouter un utilisateur

Il faut anticiper la création de la base en modifiant le `pg_hba.conf` et ajouter la base.

Sur la machine postgres :

```sh
nano /etc/postgresql/15/main/pg_hba.conf
```

```sh
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    test            odoo            odoo          scram-sha-256
```

Puis redémarrer le service :

```sh
systemctl restart postgresql
```

Puis sur firefox `localhost:8080`, créer l'utilisateur `test`.

## Installer Traefik

Documentation de traefik : https://hub.docker.com/_/traefik (car la doc sur le site de traefik est une purge)

Pour cela nous allons créer un Docker compose.

Créer le dossier `traefik` sur `~/` :

```sh
mkdir ~/traefik
```

puis créer les fichier `docker-compose.yml` et `traefik.yml` :

1. docker-compose.yml :

Exemple Récupéré sur https://doc.traefik.io/traefik/master/user-guides/docker-compose/basic-example/ :
Ici le document est modifié de celui trouvable sur internet.

```yml
version: "3.3" #la version de docker compose, si trop vieux marche pas

services: #Le paramétrage
  traefik: # précise que l'on va traiter du service traefik
    image: "traefik:v2.5" # l'image que l'on va utiliser, la version peut être n'importe laquelle pour notre cas
    container_name: "traefik" # le nom du container équivalent du --name

    ports: ## ordre host:container
      - "8000:80" # http  => pour accéder au dashboard, le port 80 de la machine hôte est redirigé vers le port 80 du container
      - "8080:8080" # reverse-proxy => pour accéder à chaque docker
      - "4430:443" # https

    volumes: # pour préciser où se trouve le volume
      - "/var/run/docker.sock:/var/run/docker.sock" # pour que traefik communique avec les différents containers, docker.sock est le socket de docker. On va monter le fichier docker.sock de la machine hôte dans le container traefik sur le même chemin.
      - "./traefik.yml:/etc/traefik/traefik.yml" #dans le docker il y a un fichier de conf par défaut, on va donc le remplacer par le notre

    networks: # pour préciser le réseau, on va rassembler tous les dockers dans un seul réseau docker
      - "proxy" #le nom du network

    command:
      - "--providers.docker.network=proxy" #dis au container de se réferrer au proxy dorénavant

    labels:
      - "traefik.enable=true" # pour activer traefik (pas sûr de pourquoi c'est dans label)

networks: # pour créer le réseau
  proxy: # le nom du réseau sur le fichier
    name: "proxy" # nom réel du proxy dans docker

# ALORS
# Dans docker il existe des réseaux, ici nous connectons les dockers odoo ensemble dans le même réseau nommé proxy que l'on va créer
# Dans le fichier docker-compose.yml, dans la partie

#traefik:
#    networks:
#        - michel

#On dit au container qu'il va se réferer au réseau proxy
#Puis dans la partie :

#networks:
#    michel:
#        name: proxy

#le container va chercher à quoi correspond le réseaux michel, qui porte le nom réel de proxy

#Ici on a tout nommé proxy parce que c'est plus simple à comprendre
```

Ce fichier est l'équivalent de la commande :

```sh
docker run -d -p 8080:8080 -p 8000:80 -p 4430:443 -v $PWD/traefik.yml:/etc/traefik/traefik.yml -v /var/run/docker.sock:/var/run/docker.sock --name traefik traefik:v2.5
```

2. traefik.yml :

```yml
## traefik.yml

# Docker configuration backend
providers:
  docker:
    defaultRule: "Host(`{{ trimPrefix `/` .Name }}.docker.localhost`)"

# API and dashboard configuration
api:
  insecure: true #pour se co en http (on croit)
```

Créer le network `proxy` :

Il existe plusieurs type de network, on va utiliser le bridge (qui est par défaut mais on va le préciser quand même) :

```sh
docker network create -d bridge proxy
```

> -d : préciser le driver, cad le type de network
>
> proxy : son nom

Modifier le .ssh/config sur la machine physique pour ajouter un LocalForward :

```sh
Host odooTest
  #ajouter :
  LocalForward localhost:8080 localhost:8080
  LocalForward localhost:8000 localhost:8000
  LocalForward localhost:4430 localhost:4430
```

Quitter le ssh et rejoindre de nouveau.

Lancer le docker-compose (il faut être dans le dossier dtraefik) :

```sh
docker-compose up -d
```

> -d : detach pour lancer en arrière plan

Une fois la commande effectuée aller sur `localhost:8000` pour voir le dashboard de traefik.

## Création du container d'odoo

Veiller à ce que postgres soit propre et le cache de firefox vidé.

Créer un fichier `docker-compose.yml` dans le dossier `~/odoo` :

```yml
version: "3.3"

services:
  odoo:
    image: odoo
    container_name: odoo
    ports:
      - "8069:8069"
    volumes:
      - "./odoo.conf:/etc/odoo/odoo.conf"
      - "./addons:/mnt/extra-addons"
    environment:
      - POSTGRES_DB=postgres
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
networks:
  proxy:
    name: proxy
```

Créer un fichier `odoo.conf` dans le dossier `~/odoo` :

```conf
[options]
addons_path = /mnt/extra-addons
db_user = odoo
db_password = odoo
db_host = 10.42.162.2
db_name = odoo
db_template = template0
proxy_mode = True
```
> `addons_path` : réglage pour que odoo vérifie ce dossier lors de la mise a jour de la liste des addons
> `db_user` : réglage pour que odoo se connecte en temps que ce user dans psql
> `db_password` : réglage pour que odoo se connecte en utilisant ce mot de passe dans psql
> `db_host` : réglage pour que odoo se connecte sur le psql de cette addresse
> `db_name` : réglage pour que odoo se connecte en temps que ce user dans psql
> `db_template` : réglage pour que odoo utilise cette template lors de la création de la base de donnée
> `proxy_mode` : réglage pour que odoo puisse utilisé https via un proxy
> Avant de créer le container, dans le fichier pg_hba.conf de postgres, ajouter la ligne suivante :

```sh
host    odoo            odoo            10.42.124.1/16          scram-sha-256
```

- Veiller à supprimer les containers odoo existants.
- Veiller à ce que le cache de firefox soit vidé.
- dropdb odoo sur postgres

Pour vérifier si tout fonctionne bien : `odoo-odoo.docker.localhost:8000` doit renvoyer sur une page de CONNEIXON (pas de création de compte)

User : admin et password : admin, doivent fonctionner

## Configurer Traefik en https avec mkcert

Sur la vm odoo :
Attention à la version de mkcert (après le v) :

```sh
curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
chmod +x mkcert-v*-linux-amd64
cp mkcert-v*-linux-amd64 /usr/local/bin/mkcert
mkcert -install
```

Dans le dossier `~/traefik/` on créer le dossier

- certs qui contient tout les certificats
- conf qui contient tout les fichiers de conf

```sh
mkdir {certs,conf}
```

Générer un clef pour le reverse proxy :

```sh
mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem "*.<phys>.iutinfo.fr"
```

cela permet d'avoir un certificat pour foo.<phys>.iutinfo.fr , bar.<phys>.iutinfo.fr , etc

Créer le fichier de conf statique `traefik.yml` dans le dossier ``~/traefik/conf/`

```yml
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
```

> `sendAnonymousUsage` réglage pour envoyer ou non des données a traefik sur notre config
> `dashboard` réglage pour activer le dashboard
> `providers` pour les sources du reverse proxy
> `defaultRule` réglage pour mettre un url par défaut
> `endpoint` réglage pour que traefik se connecte au socket de Docker
> `watch` réglage pour que traefik regarde automatiquement lors d'un changement
> `exposedByDefault` réglage pour que traefik expose les container docker
> `filename` réglage pour que traefik regarde ce fichier
> `level` réglage pour que choisir ce que contient les logs
> `format` réglage pour choisir le format des logs
> `entrypoint` pour les points d'entrée du routeur (ex odoo.epicea22.iutinfo)
> `address` réglage pour dire ou se connecter
> `redirections` réglage pour rediriger lors de la connection
> `to` la cible de la redirection
> `scheme` réglage pour le schema de l'url (https://)

Créer le fichier de conf dynamique `config.yml` dans le dossier `~/traefik/conf/`

```yml
http:
  routers:
    traefik:
      rule: "Host(`traefik.<phys>.iutinfo`)"
      service: "api@internal"
      tls:
        domains:
          - main: "<phys>.iutinfo"
            sans:
              - "*.<phys>.iutinfo"

tls:
  certificates:
    - certFile: "/etc/certs/local-cert.pem"
      keyFile: "/etc/certs/local-key.pem"
```

> `rule` réglage pour l'url d'accés au dashboard
> `main` le domaine "principale"
> `sans` les sous domaines

Créer le fichier `docker-compose.yml` dans le dossier `~/traefik/`

```yml
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
```

Dans le fichier `docker-compose.yml` dans le dossier `~/odoo/`

```yml
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
```


## Installer des addons
Télécharger l'addon voulu dans le dossier `~/odoo/addons/`
```sh
wget https://apps.odoo.com/loempia/download/<nom technique du module>/<version de odoo>/<nom technique du module>.zip
```

Ensuite dézipper le dossier 
Pour cela vous devez avoir unzip 
```sh
apt install unzip
```
Pour dezipper
```sh
unzip <le fichier en zip>
```

Maintenant lancer l'instance de odoo 
(depuis le dossier `~/odoo/`)
```sh
docker-compose up -d 
```

Allez sur la page de odoo connectez vous en admin (admin:admin)
Puis activer un addons de base pour pouvoir ensuite activer le mode développeur 
Pour cela allez dans la page settings puis tout en bas `activer le mode développeur`
Pour retourner sur la page des addons et `cliquez sur mise a jour de la liste`
Maintenant dans la liste des addons a activer vous devrez voir le addon télécharger 