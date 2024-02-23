# Mise en place de la machine sauvegardes

## Mise à jour de la machine et installation de rsync

Si cela n'a jamais été fait, mettre à jour la machine :

```sh
apt update && apt full-upgrade
```

Installation de rsync :

```sh
apt install rsync
```

Installer rsync sur postgres aussi !

## Création du dump sur postgres

Sur la machine postgres :
```sh
su - postgres
pg_dump test > test.sql
```

## Copie du dump sur sauvegardes

Sur la machine sauvegardes :
```sh
rsync postgres@10.42.124.2:/var/lib/posrgresql/test.sql .
```
> Forme : rsync addrSource:fichierSource addrDestination:fichierDestination
> 
> Ici la destination est le dossier courant sur sauvegardes

## Pour restaurer le dump

Sur la machine postgres :
```sh
su - postgres
psql test < test.sql
```

## Permettre les sauvegardes périodiques

### Partager la clef ssh avec la machine postgres

Donner un mot de passe à l'utilisateur postgres :
```sh
passwd postgres
Le mdp sera postgres
```

Sur la machine sauvegardes en root :
```sh
ssh-keygen
ssh-copy-id postgres@10.42.124.2
```

### Préparer le dump à copier sur sauvegardes

Sur la machine postgres :
```sh
su - postgres
```

```sh
crontab -e
```
```sh
# m h  dom mon dow   command
0 0 * * * pg_dump test > /var/lib/postgresql/test.sql
```

### Copier le dump sur sauvegardes

```sh
crontab -e
```
```sh
# m h  dom mon dow   command
1 0 * * * rsync postgres@10.42.124.2:/var/lib/postgresql/test.sql /home/user/test
```
> Il ne faut pas préciser l'utilisateur `root` contrairement au fichier `/etc/crontab`
> 
> /!\ bien préciser le fichier de destination, sinon fonctionne pas
> 
> Ici, on copie le fichier `testfile` de la machine postgres dans le dossier `/home/user/test` de la machine sauvegardes tous les jours à minuit.
> 
> * : tous les ...
> 
> m : minute
> 
> h : heure
> 
> dom : jour du mois
> 
> mon : mois
> 
> dow : jour de la semaine
> 
> command : commande à exécuter

## Pour restaurer le dump

Sur la machine odoo :
```sh
docker container stop odoo
```
> Si le container avait été créé avec --rm, il faut le recréer sans.

Sur la machine postgres :
```sh
su - postgres
rsync user@10.42.124.3:/home/user/test .
dropdb test 
createdb -T template0 test
psql -c "ALTER DATABASE test OWNER TO odoo"
psql test < testfile
```

Vérification, retourner sur firefox et taper `http://localhost:8080/web/login` dans la barre d'adresse.




