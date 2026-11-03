# vulnforge 🔥

Catalogue **maison** de machines volontairement vulnérables, lançables à la
demande **par nom ou par CVE**, en conteneurs Docker isolés — l'esprit
HackTheBox / [vulhub](https://github.com/vulhub/vulhub), mais c'est *ton*
framework, que tu étends au fil de tes découvertes (et de ton futur job).

```
./vulnforge list
./vulnforge search CVE-2026-109618
./vulnforge start php2shell
```

## ⚠️ À lire une fois (important)

Ces images contiennent des **vulnérabilités réelles, intentionnelles**. Elles
sont faites pour s'entraîner, **chez toi, en local**.

- **Jamais** sur une machine exposée à Internet, ni sur le réseau de ton futur
  employeur, ni en prod. Une box lancée = une cible exploitable.
- Par défaut chaque box n'écoute que sur `127.0.0.1` (loopback) et vit sur un
  réseau docker dédié `vulnforge-net`.
- Tu n'attaques que **tes propres box**. Les techniques apprises ici ne
  s'utilisent ailleurs qu'avec une **autorisation écrite** (pentest, CTF, ton
  propre lab). C'est la seule différence entre un pentester et un délinquant.

## Prérequis

- Docker Desktop (testé : Docker 29 / Compose v5, Apple Silicon arm64).
- C'est tout. `jq`/`python3` ne sont pas requis par le CLI.

## Commandes

| Commande | Effet |
|---|---|
| `list` | liste le catalogue + l'état de chaque box |
| `search <terme\|CVE>` | cherche par nom, CVE, tag ou description |
| `info <box>` | fiche détaillée d'une box |
| `start <box>` | build + démarre la box (isolée) |
| `stop <box>` | arrête la box |
| `restart <box>` | stop puis start |
| `reset <box>` | remet la box à neuf (flags régénérés) |
| `status` | box actuellement en ligne |
| `stop-all` | arrête toutes les box |
| `logs <box>` | suit les logs de la cible |
| `shell <box>` | shell dans la cible (debug / étude du lab) |

Astuce — un alias pratique :

```bash
echo "alias vf=\"$PWD/vulnforge\"" >> ~/.zshrc && source ~/.zshrc
vf list
```

## Attaquer depuis ton conteneur Kali (htb-kali)

Ton attaquant Kali existe déjà (`docker compose up` à la racine du repo). Pour
qu'il atteigne une cible vulnforge comme sur une vraie box HTB :

```bash
# une seule fois : on branche Kali sur le réseau du lab
docker network connect vulnforge-net htb-kali

# ensuite, depuis Kali, la cible est joignable par son hostname (= nom de la box)
docker compose exec kali zsh
#   kali> curl -I http://php2shell/
#   kali> nmap php2shell
```

Depuis le **host** (ton Mac), la box reste aussi joignable via l'URL affichée au
démarrage (ex. `http://127.0.0.1:8080`).

## Anatomie d'une box

```
boxes/<nom>/
├── box.env            # métadonnées (NAME, CVE, DIFFICULTY, PORTS, URL, TAGS, SUMMARY)
├── docker-compose.yml # service + rattachement au réseau vulnforge-net (externe)
├── Dockerfile         # construction de l'image vulnérable
├── app/               # code / contenu de la cible
└── README.md          # briefing façon HTB + walkthrough (replié) + contexte CVE
```

## Ajouter une nouvelle box

1. `cp -r boxes/_TEMPLATE boxes/ma-box`
2. Édite `box.env` (nom, CVE, difficulté, ports…), le `Dockerfile` et l'`app/`.
3. Choisis un **port host libre** distinct dans `docker-compose.yml`
   (`127.0.0.1:<port>:…`) et reporte-le dans `box.env`.
4. `./vulnforge start ma-box` 🎯

## Catalogue

| Box | Difficulté | Thème |
|---|---|---|
| `php2shell` | Easy | PHP (CVE-2026-109618 / -109619) · upload → webshell → RCE, privesc sudo |

> La prochaine ? Dis-moi une CVE ou une techno et on l'ajoute au catalogue.
