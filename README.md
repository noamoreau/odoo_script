# Documentation des scripts

Table des matières


## Organisation des fichiers

- `install-a-la-main` : les trace écrite des installations à la main (faites en découverte de la saé) 
- `scripts` contient tout le nécessaire au déroulement des installations
    - dossiers avec les noms de machines : contiennent des scripts en rapport avec la machine 
    - `main`: contient les scripts de démarrage et nettoyage de l'installation et l'installation de sshpass sur la machine physique.

Nous avons trois machines virtuelles : 
- `odoo1` : avec un docker pour traefik et un docker odoo par client. 

Les machines odoo, postgres et sauvegardes portent toutes un "1" car nous souhaitions conserver les machines sur lesquelles nous avions fait les installations manuellement. Dans un contexte professionnel nous aurions retiré le chiffre.

Le texte apparaissant en jaune signifie qu'une intervention de l'utilisateur est requise, en bleu clair un message d'état, en rouge un choix important. 

## Déroulement des scripts

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

La clef publique de l'utilisateur va être partagée sur la machine virtuelle. Avec l'option `StrictHostKeyChecking no` pour ne pas déclencher le message nous demandant confirmation sur le hash de la clef.

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

#### setup-odoo.sh

### Ajouter un client

Le deuxième choix du menu permet de lancer le script [ajout-client.sh](./scripts/odoo/ajout-client.sh) décrit plus haut.

### Installer des addons

### Récupérer les données sur la sauvegarde quotidienne


## Nos choix

Nous souhaitions initialement envoyer aux machines les scripts les concernant mais Dattier ayant une protection sur les scripts (pas de terminal interactif pour écrire un mot de passe) nous avons préféré envoyer les commandes en ssh depuis la machine physique, sauf pour le script creation-vm qui était déjà rédigée et toujours exploitable.

Afin d'éviter au maximum les interventions de l'utilisateur nous avons décidé d'utiliser `sshpass`. Installer un programme n'étant pas possible sur nos sessions nous avons fais en sorte que le script récupère le code source et le compile. 

> **Note** : pour des raisons nous dépassant la compilation peut échouer selon la session. Elle fonctionne sur la session à Noa mais pas celle d'Elise.

Il y a un docker odoo par client car cela leur permet d'avoir plusieurs base de données s'ils veulent. Nous avons fait ce choix suite à notre travail sur Odoo en management des SI où nous manipulions plusieurs bases pour plusieurs scénarios.