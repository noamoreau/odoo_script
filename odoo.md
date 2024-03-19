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

1) docker-compose.yml :

Exemple Récupéré sur https://doc.traefik.io/traefik/master/user-guides/docker-compose/basic-example/ :
Ici le document est modifié de celui trouvable sur internet.

```yml
version : "3.3" #la version de docker compose, si trop vieux marche pas

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
        -  "./traefik.yml:/etc/traefik/traefik.yml" #dans le docker il y a un fichier de conf par défaut, on va donc le remplacer par le notre
      
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

2) traefik.yml :

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
admin_passwd = admin
addons_path = /mnt/extra-addons
csv_internal_sep = ,
data_dir = /var/lib/odoo
db_host = 10.42.124.2
db_port = 5432
db_user = odoo
db_password = odoo
db_maxconn = 64
db_name = odoo
db_template = template0
dbfilter = .* 
debug_mode = False
email_from = False
limit_memory_hard = 2684354560  
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
list_db = True
log_db = False
logfile = None
log_handler = [':INFO']
log_level = info
longpolling_port = 8072
max_cron_threads = 2
osv_memory_age_limit = 1.0
osv_memory_count_limit = False
smtp_password = False
smtp_port = 25
smtp_server = localhost 
smtp_ssl = False
without_demo = True
```
> `-dbfilter` : réglage pour l'affichage des bases de données dans "manage database"

Avant de créer le container, dans le fichier pg_hba.conf de postgres, ajouter la ligne suivante :

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

Générer un clef pour le reverse proxy : 
```sh
mkcert localhost
```






