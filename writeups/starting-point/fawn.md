# Fawn — HTB Starting Point (Tier 0)

| | |
|---|---|
| **Section** | Starting Point — Tier 0 |
| **Machine** | `Fawn` |
| **OS** | Linux (Unix) |
| **IP cible** | `10.129.155.204` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-01 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap -sC  →  port 21/tcp : vsftpd 3.0.3
          →  script ftp-anon : "Anonymous FTP login allowed" + flag.txt listé
          →  login anonymous (sans mot de passe)
          →  get flag.txt  →  flag
```

---

## 1. Reconnaissance

```bash
box fawn <IP>                      # crée le dossier + exporte $IP
nmap -sV -sC -oN nmap/initial $IP
```

Résultat :

| Port | Service | Version |
|---|---|---|
| 21/tcp | ftp | vsftpd 3.0.3 |

Le script NSE `ftp-anon` (inclus dans `-sC`) fait l'énumération tout seul :

```
| ftp-anon: Anonymous FTP login allowed (FTP code 230)
|_-rw-r--r--    1 0        0              32 Jun 04  2021 flag.txt
|      Control connection is plain text
|      Data connections will be plain text
```

→ login anonyme autorisé **et** le `flag.txt` est déjà visible. Le `230` = code FTP « login réussi ».

---

## 2. Accès → flag

**Le concept :** FTP possède un compte spécial **`anonymous`** destiné au partage public de fichiers. Mal configuré, il donne un accès en lecture sans aucun identifiant valide. C'est la faille de Fawn.

> Rappel syntaxe (déjà vu sur Cap) : le client `ftp` de Kali veut `ftp <user>@<ip>`, pas `ftp` tout seul.

```bash
ftp anonymous@$IP
# Password: (vide, juste Entrée) -> 230 Login successful
```

Récupération du fichier :

```bash
ftp> ls
ftp> get flag.txt       # téléchargé dans le dossier courant
ftp> exit
mv flag.txt loot/flag.txt
cat loot/flag.txt
```

---

## 3. Leçons à retenir

- **FTP anonyme** : `anonymous` + mot de passe vide = accès sans compte. Toujours tester sur un port 21 ouvert.
- **`nmap -sC` fait de l'énumération** : les scripts NSE par défaut (ici `ftp-anon`) testent déjà l'accès anonyme et listent les fichiers. Lire attentivement la sortie `-sC` avant de lancer d'autres outils.
- **FTP en clair** : `Control connection is plain text` / `Data connections will be plain text` — comme Telnet (Meow), tout circule en clair. C'est ce qui avait permis de sniffer les creds sur Cap.
- **Commandes FTP de base** : `ls`, `get <fichier>`, `put <fichier>`, `binary`/`ascii`, `mget *`. (`ls | grep` ne marche pas : le pipe shell n'existe pas dans le prompt FTP.)

---

## Commandes — récap express

```bash
box fawn <IP>
nmap -sV -sC -oN nmap/initial $IP      # ftp-anon confirme l'accès
ftp anonymous@$IP                      # mot de passe vide
# ftp> get flag.txt
cat flag.txt
```
