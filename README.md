# Documentation des scripts

## Organisation des fichiers

- `install-a-la-main` : les trace écrite des installations à la main (faites en découverte de la saé) 
- `scripts` contient tout le nécessaire au déroulement des installations
    - dossiers avec les noms de machines : contiennent des scripts en rapport avec la machine 
    - `main`: contient les scripts de démarrage et nettoyage de l'installation et l'installation de sshpass sur la machine physique.

Nous avons trois machines virtuelles : 
- `odoo1` : avec un docker pour traefik et un docker odoo par client. 
- `postgres1` : avec postgres pour stocker les bases des instances de odoo. 
- `sauvegardes1` : Qui contient juste le backup quotidien. 

Les machines odoo, postgres et sauvegardes portent toutes un "1" car nous souhaitions conserver les machines sur lesquelles nous avions fait les installations manuellement. Dans un contexte professionnel nous aurions retiré le chiffre.

Le texte apparaissant en jaune signifie qu'une intervention de l'utilisateur est requise, en bleu clair un message d'état, en rouge un choix important. 

## Deroulement des scripts

### main.sh
Le script initial est [main.sh](./scripts/main/main.sh) . Ce script lance le menu principal, les choix sont :
1) Installer des addons
2) Ajouter un client
3) Récupérer les données sur la sauvegarde quotidienne
4) Refaire toute l'installation et perdre toutes les données

Commençons par le dernier choix qui lance le script [init-all.sh](./scripts/main/init-all.sh).

### Déploiement global

#### init-all.sh

##### Clef ssh
Le script demande si l'utilisateur souhaite une nouvelle clef. Si oui `ssh-keygen` est lancé.

##### creation-vm.sh

Le script [creation-vm.sh](./scripts/dattier/creation-vm.sh) est envoyé sur Dattier en `scp`.

Les machines odoo1, postgres1 et sauvegardes1 dont stoppées et supprimées si elles existent déjà, puis recrées et démarrées.

Un sleep de 30 secondes le temps que les ip soient attribuées aux machines.

Les ip sont ensuite récupérée puis stockées dans des variables.

##### Alias, partage de clef, hostname, ip statique, installation logicielle

De retour sur [init-all.sh](./scripts/main/init-all.sh) , les configurations de base communes à toutes les machines vont être effectuées une part une avec un  `for` bouclant sur une liste contenant les noms des machines (odoo&, postgres1, sauvegardes1).

Le script va d'abord détecter s'il existe un alias dans `.ssh/config` pour la machine et laisser le choix à l'utilisateur de réécrire dessus où de le laisser.

Avec l'option `StrictHostKeyChecking no` nous ne vérifions pas l'empreinte du serveur.

La machine est mise à jouur puis `sudo` est installé.

`user` est ajouté au groupe `sudo`. Puis redémarrage.

Le `hostname` est modifié pour correspondre à la machine.

L'adresse est ip est modifiée par une adresse statique :
- 10.42.124.1 pour odoo1
- 10.42.124.2 pour postgres1
- 10.42.124.3 pour sauvegardes1

Le fichier `.ssh/config` de la machine physique est de nouveau modifié pour remplacer les ip attribuées par dhcp par les statiques.

Le script [setup-postgres.sh](../postgres/setup-postgres.sh) est ensuite lancé.

#### setup-postgres.sh

Sur la machine postgres1.

Installation de rsync.

Modification des fichiers `pg_hba.conf` et `postgresql.conf` avec un `sed` pour autoriser les connexions de l'extérieur.

Modification du mot de passe (`chpasswd`) de l'utilisateur postgres pour éviter des erreur par la suite.

Configuration du premier `crontab` sur la machine postgres1 pour créer le `dump` de la base de données. Puis configuration du second sur la machine sauvegardes1 pour récupérer le `dump`. Le crontab est géré de manière non-interactive en redirigeant l'erreur "no crontab for postgres" vers `/dev/null`.

`setup-postgres.sh` est fini `init-all.sh` reprend la main et lance `setup-sauvegardes.sh`.

#### setup-sauvegardes.sh

Sur la machine sauvegardes1.

`rsync` est installé.

Puis une clef est générée et partagée sur la machine postgres1 pour permettre le rsync en non interactif.

`setup-sauvegardes.sh` est fini `init-all.sh` reprend la main et lance [setup-odoo.sh](./scripts/odoo/setup-odoo.sh)

#### setup-odoo.sh

Sur la machine odoo1

Installations de docker-compose , unzip et curl

Ajout de l'utilisateur user dans le groupe docker
Création du fichier daemon.json pour ajouter le miroir de l'IUT et corriger la base de sous réseaux utilisés (pour ne pas entrer en conflit avec le réseau de l'IUT)

Création du docker-compose 
Traefik est sur un réseau pour qu'il puisse detecter tout les containers de ce réseau

On télécharge le binaire de mkcert via curl 
on créer un certificat d'authorité 
ensuite on creer les certificats des noms domaines *.<phys>.locahost
> **Note** : Pour des raisons nous dépassant le domaine en .iutinfo.fr ne fonctionne pas, nous avons donc utilisé .localhost

On copie le template de traefik.yml qui la config statique 
Et on modifie pour que l'url pour acceder au dashboard soit <nom du container>.<phys>.localhost

On copie le template de config.yml qui la config dynamique 
Et on modifie pour que l'url pour acceder au dashboard soit traefik.<phys>.localhost

On copie le template du docker-compose de odoo pour me script [ajout-client.sh](./scripts/odoo/ajout-client.sh)


##### ajout-client.sh

Le script [ajout-client.sh](./scripts/odoo/ajout-client.sh) est lancé. Le script concerne les machine postgres1 et odoo1.

L'utilisateur doit d'abord renseigner le nom du client et la version d'odoo à installer. Ces information sont respectivement stockées dans des variables mais aussi dans le fichier `$HOME/client-version` utile à l'installation de traefik et des addons odoo. 

Sur postgres1, un nouvel utilisateur au nom du client est créé en l'ajoutant au fichier `pg_hba.conf` et en le créant via le commande psql. Ajouter le mot de passe d'un utilisateur postgres n'étant pas possible en non-interactif nous avons créé un fichier [changer_mdp.sql](./scripts/odoo/changer_mdp.sql) dans lequel nous insérons le nom du client pour l'utiliser comme mot de passe. Il s'agit de la solution que nous avons trouvé pour controurner ce problème.

Sur la machine odoo1, le fichier template du odoo.conf est modifié avec un `sed` pour y insérer le nom du client. Le template `docker-compose.yml` est aussi modifié pour y ajouter le nom du client et la version odoo.

Le dossier `~/nomclient/addons` est créé pour éventuellement ajouter des addons.

Enfin `docker-compose up` pour créer le container.

### Ajouter un client

Le deuxième choix du menu permet de lancer le script [ajout-client.sh](./scripts/odoo/ajout-client.sh) décrit plus haut. 

### Installer des addons

Dans le cas du premier choix, le script [install-addons.sh](./scripts/odoo/install-addons.sh) est lancé. Le script concerne la machine odoo1.

En premier lieu, l'utilisateur doit entrer le nom du client pour lequel il souhaite installer des addons.

Pour installer des addons odoo, nous avons aussi besoin des noms techniques des modules. L'utilisateur les entre un par un en les séparant par des espaces.

Les noms techinques sont enregistrés dans une liste sur laquelle on va itérer pour installer les modules. A chaque itération le `.zip` du module est récupéré par un `wget` sur https://apps.odoo.com/loempia/download/<addon>/<version>.0/<addon>.zip . <addon> étant le nom technique, <version> étant la version odoo du client récupéré dans le fichier `$HOME/client-version` sur odoo1 grâce à un grep sur le nom du client renseigné plus tôt.

Enfin, on relance le `docker-compose` étant donné que le container n'a pas été arrêté, docker se charge de faire la mise à jour sur les modifications.

Une instruction s'affiche ensuite à l'écran car l'utilisateur doit activer les addons sur l'interface web de odoo.

### Récupérer les données sur la sauvegarde quotidienne

Avec le troisième choix le script [recup-sauvegardes.sh](./scripts/sauvegardes/recup-sauvegardes.sh) est lancé.

Un `echo` demande à l'utilisateur de confirmer la récupération des sauvegardes. 

Si oui, un `rsync` est lancé depuis la machine sauvegardes1 vers postgres1 pour que postgres récupére la derniere backups.

Ensuite depuis la machine postgres1 la commande `psql` est utilisée avec l'option `-f <fichier-de-sauvegardes>` pour restaurer les données sur postgres. 

## Nos choix

Nous souhaitions initialement envoyer aux machines les scripts les concernant mais Dattier ayant une protection sur les scripts (pas de terminal interactif pour écrire un mot de passe) nous avons préféré envoyer les commandes en ssh depuis la machine physique, sauf pour le script creation-vm qui était déjà rédigée et toujours exploitable.

Afin d'éviter au maximum les interventions de l'utilisateur nous avons décidé d'utiliser `sshpass`. Installer un programme n'étant pas possible sur nos sessions nous avons fais en sorte que le script récupère le code source et le compile. 

> **Note** : pour des raisons nous dépassant la compilation peut échouer selon la session. Elle fonctionne sur la session à Noa mais pas celle d'Elise. C'est pour cela que le binaire est présent sur le dépôt git.

Il y a un docker odoo par client car cela leur permet d'avoir plusieurs base de données s'ils veulent. Nous avons fait ce choix suite à notre travail sur Odoo en management des SI où nous manipulions plusieurs bases pour plusieurs scénarios.

A l'origine nous voulions créer les fichier [odoo.conf](./scripts/odoo/odoo.conf), [docker-compose.yml](./scripts/odoo/template-docker-compose-odoo.yml) avec une redirection EOF mais n'arrivant pas à faire fonctionner la rediction nous avons préféré employer des "templates" ajoutés dans le dépôt. 