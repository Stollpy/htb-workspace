GUI_URL = http://localhost:6080/vnc.html?autoconnect=1&resize=remote&password=htb

.PHONY: up shell gui vpn vpn-restart logs down build rebuild

up:            ## Demarre le conteneur (build au premier lancement)
	docker compose up -d

shell: up      ## Ouvre un shell zsh dans Kali
	docker compose exec kali zsh

gui: up        ## Ouvre le bureau Kali dans le navigateur
	open "$(GUI_URL)"

vpn:           ## Etat du VPN
	docker compose exec kali htb-vpn status

vpn-restart:   ## Reconnecte le VPN
	docker compose exec kali htb-vpn restart

logs:
	docker compose logs -f

down:          ## Arrete et supprime le conteneur (workspace/ est conserve)
	docker compose down

build:
	docker compose build

rebuild:       ## Reconstruit l'image avec les derniers paquets Kali
	docker compose build --pull --no-cache && docker compose up -d --force-recreate
