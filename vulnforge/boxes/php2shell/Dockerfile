# Version de PHP volontairement ANTÉRIEURE aux correctifs php2shell
# (patchés en 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12). Ici 8.3.10 : la bannière
# serveur se présente donc comme vulnérable → objet de l'étape "fingerprint".
FROM php:8.3.10-apache

# outils utiles à la box (findutils + sudo pour la leçon de privesc)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends sudo findutils ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# l'appli web vulnérable
COPY app/ /var/www/html/
RUN set -eux; \
    mkdir -p /var/www/html/uploads; \
    chown -R www-data:www-data /var/www/html/uploads; \
    chmod 0775 /var/www/html/uploads

# --- flags (régénérés à chaque build/reset) --------------------------------
RUN set -eux; \
    head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n' > /var/www/user.txt; \
    head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n' > /root/root.txt; \
    chown www-data:www-data /var/www/user.txt; chmod 0644 /var/www/user.txt; \
    chmod 0600 /root/root.txt

# --- misconfig volontaire pour la privesc (GTFOBins: find) -----------------
RUN set -eux; \
    echo 'www-data ALL=(root) NOPASSWD: /usr/bin/find' > /etc/sudoers.d/010_www-data; \
    chmod 0440 /etc/sudoers.d/010_www-data

EXPOSE 80
