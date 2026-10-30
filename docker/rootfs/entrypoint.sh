#!/usr/bin/env bash
# Demarrage du conteneur : VPN HTB, bureau noVNC, base Metasploit.

if [ "${AUTO_VPN:-1}" = "1" ]; then
  htb-vpn up || echo "[!] VPN non connecte (voir: htb-vpn log)"
fi

if [ "${ENABLE_GUI:-1}" = "1" ]; then
  htb-gui start || echo "[!] Bureau noVNC non demarre (voir: /var/log/vnc.log)"
fi

# Base PostgreSQL pour Metasploit (en arriere-plan, idempotent)
( service postgresql start && msfdb init ) >/var/log/msfdb.log 2>&1 &

if [ $# -gt 0 ]; then
  exec "$@"
fi
exec sleep infinity
