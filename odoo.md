# Mise en place de la machine odoo

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
  "default-address-pools":
  [
    {"base":"172.20.0.0/16","size":24}
  ]  
}
```
Vérifier que le service est bien actif :
```sh
docker run --rm hello-world
```

## Création du container odoo
```
docker run --rm -p 8080:8069 --name odoo -e HOST=10.42.124.2 -e USER=odoo -e PASSWORD=odoo  -d odoo
```

Si erreur : 
- retirer `--rm`
- faire la commande `docker logs odoo` pour voir l'erreur