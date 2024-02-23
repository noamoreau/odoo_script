# Mise en place des machines virtuelles

## Céation des machines virtuelles sur Dattier

Se rendre sur Dattier :

```
ssh dattier
```

Créer les machines virtuelles :

```
vmiut create odoo
```

```
vmiut create postgres
```

```
vmiut create sauvegardes
```

Démarrer les machines virtuelles :

```
vmiut start odoo
```

```
vmiut start postgres
```

```
vmiut start sauvegardes
```

Changer les ip des machines virtuelles :

- **odoo** : 10.42.162.1
- **postgres** : 10.42.162.2
- **sauvegardes** : 10.42.162.3

Se connecter à Dattier en mode graphique :

```
ssh -X dattier
```

Allumer les machines virtuelles en mode graphique:
(Exemple avec Odoo)

```
vmiut console odoo
```

Se connecter en root (mdp: root).

Vérifier l'interface :

```
ip a
```

Couper l'interface :

```sh
ifdown enp0s3 #<=== si l'interface était enp0s3
```

Modifier l'ip :

```
nano /etc/network/interfaces
```

```sh
allow-hotplug enp0s3
iface enp0s3 inet static        #<=== je change dhcp par static
        address 10.42.xx.1/16   #<=== j'ajoute cette ligne en précisant l'IP de ma machine virtuelle
        gateway 10.42.0.1       #<=== je précise l'IP du routeur
```

Redémarrer l'interface :

```sh
ifup enp0s3
```

Fermer la machine virtuelle (en appuyant sur la croix).

Tenter de se connecter à la machine virtuelle avec l'ip modifiée :

```
ssh user@10.42.xx.1
```

Changer le nom de la machine :
Mettez vous en root

```sh
su -
#mdp = root
```

puis

```sh
hostnamectl set-hostname odoo
```

Changer le DNS de la machine:

```sh
nano /etc/hosts
```

Pour odoo:

```sh
127.0.0.1       localhost
127.0.1.1       odoo
10.42.xx.2      postgres

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Pour postgres:

```sh
127.0.0.1       localhost
127.0.1.1       postgres
10.42.xx.1      odoo

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Pour sauvegardes:

```sh
127.0.0.1       localhost
127.0.1.1       sauvegardes
10.42.xx.1      postgres

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

Répéter l'opération pour les autres machines virtuelles avec les ip indiquées plus haut.

Tester si tout fonctionnent:
Pour odoo:

```sh
ping -c3 odoo
```

```sh
ping -c3 postgres
```

```sh
host www.univ-lille.fr
```

Pour postgress:

```sh
ping -c3 postgres
```

```sh
ping -c3 odoo
```

```sh
host www.univ-lille.fr
```

Pour sauvegardes:

```sh
ping -c3 sauvegardes
```

```sh
ping -c3 postgres
```

```sh
host www.univ-lille.fr
```