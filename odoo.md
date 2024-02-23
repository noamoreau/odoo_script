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
