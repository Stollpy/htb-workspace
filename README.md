# Kali HTB (Docker)

Kali Linux sur Docker (arm64), connectée au VPN HTB, avec les outils HTB/Academy et un bureau XFCE dans le navigateur.

## Démarrage

```bash
make up       # construit l'image au premier lancement, puis démarre le conteneur + VPN
make shell    # shell zsh dans Kali
make gui      # bureau Kali (Firefox, Burp Suite) : http://localhost:6080  (mot de passe : htb)
make vpn      # état du VPN
make down     # arrête le conteneur (workspace/ est conservé)
make rebuild  # reconstruit avec les derniers paquets Kali
```

Sans `make` : `docker compose up -d` puis `docker compose exec kali zsh`.

## Dans le conteneur

| Commande | Rôle |
|---|---|
| `htb-vpn up / down / restart / status / log` | gestion du VPN (`htb-vpn up autre.ovpn` pour changer de fichier) |
| `tun0` / `myip` | ton IP VPN (le LHOST de tes reverse shells), aussi affichée à droite du prompt |
| `box <nom> [ip]` | crée `workspace/boxes/<nom>/{nmap,loot,exploits}`, s'y place et exporte `$IP` |
| `listen 4444` | `rlwrap nc -lvnp 4444` |
| `serve` | `python3 -m http.server 8000` pour transférer des fichiers vers la cible |
| `$ROCKYOU`, `$SECLISTS` | wordlists |

## Fichiers

- `vpn/` : tes `.ovpn` (montés en lecture seule). Le fichier utilisé est `VPN_FILE` dans `docker-compose.yml`.
- `workspace/` : monté dans `/root/workspace`. Notes, scans, loot et historique zsh y sont conservés.

Un seul VPN HTB actif à la fois : déconnecte celui du Mac si tu en as un.
Pour les machines du Labs (pas Academy), télécharge le `.ovpn` "Labs", mets-le dans `vpn/` et lance `htb-vpn restart lab.ovpn`.
