FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# 1) Base Kali "headless" : le gros des outils pentest en CLI
RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get install -y --no-install-recommends kali-linux-headless && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2) Outils HTB / Academy en plus (web, AD, pivot, privesc, wordlists...)
RUN apt-get update && apt-get install -y \
      # VPN / reseau
      openvpn iproute2 iputils-ping dnsutils net-tools traceroute \
      netcat-traditional socat proxychains4 openssh-client sshpass \
      ftp telnet smbclient snmp onesixtyone tcpdump tshark \
      # clients bases de donnees / cloud (Redis, AWS S3...)
      redis-tools awscli \
      # scan / enumeration
      nmap masscan rustscan whatweb nikto wpscan nuclei httpx-toolkit \
      subfinder gobuster ffuf feroxbuster dirb wfuzz cewl \
      enum4linux-ng \
      # exploitation
      metasploit-framework exploitdb sqlmap hydra john hashcat \
      # Active Directory / Windows
      netexec impacket-scripts python3-impacket evil-winrm responder \
      bloodhound.py certipy-ad mimikatz \
      # pivot / privesc / transferts
      ligolo-ng chisel peass \
      # wordlists
      seclists wordlists \
      # confort shell / dev
      zsh tmux vim nano rlwrap git curl wget jq unzip 7zip file \
      python3-pip pipx gdb \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 3) Bureau XFCE accessible dans le navigateur (noVNC) : Firefox + Burp Suite
RUN apt-get update && apt-get install -y \
      kali-desktop-xfce dbus-x11 xclip \
      tigervnc-standalone-server tigervnc-tools novnc websockify \
      firefox-esr burpsuite \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    # pas d'ecran de verrouillage ni de gestion d'energie dans le conteneur
    && rm -f /etc/xdg/autostart/xfce4-screensaver.desktop \
             /etc/xdg/autostart/light-locker.desktop \
             /etc/xdg/autostart/xfce4-power-manager.desktop

# rockyou decompresse, pret a l'emploi
RUN if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then gunzip /usr/share/wordlists/rockyou.txt.gz; fi

# 4) Shell confort : oh-my-zsh + powerlevel10k + plugins + Nerd Font (MesloLGS NF)
#    Le .zshrc manage est fourni via rootfs/root/.zshrc (COPY ci-dessous).
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /root/.oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      /root/.oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    mkdir -p /usr/share/fonts/truetype/meslo && cd /usr/share/fonts/truetype/meslo && \
    base='https://github.com/romkatv/powerlevel10k-media/raw/master' && \
    curl -fsSLo 'MesloLGS NF Regular.ttf'     "$base/MesloLGS%20NF%20Regular.ttf" && \
    curl -fsSLo 'MesloLGS NF Bold.ttf'        "$base/MesloLGS%20NF%20Bold.ttf" && \
    curl -fsSLo 'MesloLGS NF Italic.ttf'      "$base/MesloLGS%20NF%20Italic.ttf" && \
    curl -fsSLo 'MesloLGS NF Bold Italic.ttf' "$base/MesloLGS%20NF%20Bold%20Italic.ttf" && \
    fc-cache -f >/dev/null 2>&1 || true

COPY rootfs/ /
RUN chmod +x /usr/local/bin/* /entrypoint.sh && \
    chsh -s /usr/bin/zsh root && \
    mkdir -p /root/workspace

WORKDIR /root/workspace
ENTRYPOINT ["/entrypoint.sh"]
