# Mise en place de la machine postgres

## Mise à jour de la machine et installation de postgres

Passer en root:

```sh
su -
#mdp=root
```

Si cela n'a jamais été fait, mettre à jour la machine :

```sh
apt update && apt full-upgrade
```

Installation :

```sh
apt install postgresql
```

Vérifiez ensuite le status du service avec la commande systemctl :

```sh
systemctl status postgresql
```

Il faut qu'il affiche `active`.

Editer les autorisations selon les bases (connexion à telle base avec telle ip):

```
nano /etc/postgresql/15/main/pg_hba.conf
```

```sh
# DO NOT DISABLE!
# If you change this first entry you will need to make sure that the
# database superuser can access the database using some other method.
# Noninteractive access to all databases is required during automatic
# maintenance (custom daily cronjobs, replication, and similar tasks).
#
# Database administrative login by Unix domain socket
local   all             postgres                                trust

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     md5
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
host    postgres        odoo            odoo                    scram-sha-256
```

Editer les adresses pouvant se connecter à la base de données :

```
nano /etc/postgresql/15/main/postgresql.conf
```

```sh
#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = '*'       # what IP address(es) to listen on;
```

Redémarrer le service :

```sh
systemctl restart postgresql.service
```

## Création de l'utilisateur

Passer à l'utilisateur postgres :

```sh
su - postgres
```

Créer un utilisateur :

```sh
postgres@debian:~$ createuser --interactive --pwprompt odoo
Saisir le mot de passe pour le nouveau rôle :
Saisir le mot de passe à nouveau :
Le nouveau rôle est-il super-utilisateur ? (o/n) n
Le nouveau rôle est-il autorisé à créer des bases de données ? (o/n) o
Le nouveau rôle est-il autorisé à créer de nouveaux rôles ? (o/n) n
```

## Ne pas créer de base de données sinon erreurs
