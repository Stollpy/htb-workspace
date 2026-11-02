# ~/.zshrc — Kali HTB (oh-my-zsh + powerlevel10k)
# Gere par le Dockerfile. Les helpers HTB (box, htb-vpn, myip, $ROCKYOU...)
# et l'historique persistant sont dans /etc/zsh/htb.zsh, source a la fin.

# --- Quelques raccourcis clavier confort (repris du zshrc Kali) ---
bindkey -e
bindkey '^[[3~'   delete-char          # Suppr
bindkey '^[[1;5C' forward-word         # Ctrl + fleche droite
bindkey '^[[1;5D' backward-word        # Ctrl + fleche gauche
bindkey '^[[H'    beginning-of-line    # Debut
bindkey '^[[F'    end-of-line          # Fin
bindkey '^[[Z'    undo                 # Shift + Tab

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled                 # pas d'auto-update dans un conteneur
HISTFILE=/root/workspace/.zsh_history               # (re)confirme par htb.zsh
plugins=(
  git
  sudo                    # Echap Echap pour prefixer la commande par sudo
  colored-man-pages
  command-not-found
  zsh-autosuggestions     # suggestions grises depuis l'historique (Fleche droite / Fin pour accepter)
  zsh-syntax-highlighting # coloration des commandes valides/invalides (doit rester en dernier)
)
source "$ZSH/oh-my-zsh.sh"

# --- Powerlevel10k : config compacte en ligne (pas de fichier .p10k.zsh geant) ---
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir vcs)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time vpn time)
typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=true
typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=red
typeset -g POWERLEVEL9K_DIR_FOREGROUND=blue
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

# Segment custom "vpn" : IP de tun0 (= ton LHOST pour les reverse shells),
# cyan si connecte, rouge "no-vpn" sinon.
function prompt_vpn() {
  local ip
  ip=$(ip -4 -o addr show dev tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
  if [[ -n $ip ]]; then
    p10k segment -f cyan -t "VPN ${ip}"
  else
    p10k segment -f red -t 'no-vpn'
  fi
}

# --- Helpers HTB + historique persistant ---
source /etc/zsh/htb.zsh
