# Confort HTB, charge a la fin de /root/.zshrc

# Historique persistant (survit a la reconstruction du conteneur)
export HISTFILE=/root/workspace/.zsh_history
export HISTSIZE=100000 SAVEHIST=100000

export ROCKYOU=/usr/share/wordlists/rockyou.txt
export SECLISTS=/usr/share/seclists

# IP VPN (LHOST pour les reverse shells), affichee a droite du prompt
tun0() { ip -4 -o addr show dev tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1; }
setopt PROMPT_SUBST
RPROMPT='%F{cyan}[${$(tun0):-no-vpn}]%f'"$RPROMPT"

alias vpn='htb-vpn'
alias myip='tun0'
alias serve='python3 -m http.server 8000'
alias listen='rlwrap nc -lvnp'

# box <nom> [ip] : cree ~/workspace/boxes/<nom>/{nmap,loot,exploits}, s'y place et exporte $IP
box() {
  [ -z "$1" ] && { echo "Usage: box <nom> [ip]"; return 1; }
  mkdir -p /root/workspace/boxes/$1/{nmap,loot,exploits}
  cd /root/workspace/boxes/$1
  if [ -n "$2" ]; then export IP=$2; echo "IP=$IP"; fi
}

[[ -o interactive ]] && htb-vpn status
