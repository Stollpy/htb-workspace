# 🧩 Writeups HTB — ma progression

Mes comptes rendus de machines [Hack The Box](https://www.hackthebox.com/), rédigés au fil de mon apprentissage de la sécurité offensive. Chaque writeup suit le même format : chaîne d'attaque résumée, étapes détaillées, concepts expliqués et leçons à retenir.

> ⚠️ Conformément aux règles HTB, ce dépôt ne contient que des writeups de machines **Starting Point** et **retirées**. Jamais de machine active. Les flags sont masqués.

## 📊 Progression

**Starting Point — Tier 0** (un service exposé)

| Box | OS | Service / faille | Concept clé | Writeup |
|---|---|---|---|---|
| Meow | 🐧 Linux | Telnet (23) | Login `root` sans mot de passe | [meow.md](starting-point/meow.md) |
| Fawn | 🐧 Linux | FTP (21) | Login anonyme | [fawn.md](starting-point/fawn.md) |
| Redeemer | 🐧 Linux | Redis (6379) | Base sans authentification + full scan `-p-` | [redeemer.md](starting-point/redeemer.md) |
| Dancing | 🪟 Windows | SMB (445) | Null session | [dancing.md](starting-point/dancing.md) |

**Starting Point — Tier 1** (une vulnérabilité à exploiter)

| Box | OS | Service / faille | Concept clé | Writeup |
|---|---|---|---|---|
| Appointment | 🐧 Linux | HTTP (80) | Injection SQL (contournement d'auth) | [appointment.md](starting-point/appointment.md) |
| Sequel | 🐧 Linux | MariaDB (3306) | Identifiants par défaut | [sequel.md](starting-point/sequel.md) |
| Crocodile | 🐧 Linux | FTP + HTTP | **Chaînage** : creds FTP → login web | [crocodile.md](starting-point/crocodile.md) |
| Responder | 🪟 Windows | HTTP + WinRM | LFI → vol de hash NTLM → crack → WinRM | [responder.md](starting-point/responder.md) |
| Three | 🐧 Linux | HTTP + S3 | Bucket AWS S3 inscriptible → webshell → RCE | [three.md](starting-point/three.md) |

**Labs — machines retirées**

| Box | OS | Difficulté | Concept clé | Writeup |
|---|---|---|---|---|
| Cap | 🐧 Linux | Easy | IDOR → sniff FTP → privesc par capability | [cap.md](labs/cap.md) |

## 🧰 Boîte à outils acquise

- **Reconnaissance** : `nmap` (`-sV -sC`, `-p-`, `-Pn`), lecture des scripts NSE (`ftp-anon`, `mysql-info`), énumération web (`gobuster`, `ffuf` en mode vhost).
- **Services** : `telnet`, `ftp`, `smbclient`/`smbmap`, `redis-cli`, `mysql`/`mariadb`, `aws` (S3).
- **Exploitation web** : injection SQL, LFI, webshells PHP, upload via S3.
- **Windows / AD** : vol de hash NTLMv2 avec `responder`, crack `hashcat -m 5600`, accès `evil-winrm` (WinRM 5985).
- **Privesc Linux** : `sudo -l`, `find -perm -4000`, capabilities (`getcap -r /`), [GTFOBins](https://gtfobins.github.io/).

## 🔑 Méthode

> **Énumérer → identifier le service → chercher l'accès le plus simple → exploiter → chaîner.**

Réflexe d'or : lancer un **full scan `-p-` en arrière-plan** pendant de démarrer avec un scan ciblé — un service peut tourner sur un port exotique (ex. Redis sur 6379, hors top-1000).

---

*Environnement : Kali Linux dans Docker (arm64) avec VPN HTB intégré — voir le [README du dépôt](../README.md).*
