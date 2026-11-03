# Image de base = la techno/version que tu veux rendre vulnérable.
FROM php:8.3.10-apache

COPY app/ /var/www/html/

# flags façon HTB (régénérés à chaque build/reset)
RUN set -eux; \
    head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n' > /var/www/user.txt; \
    head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n' > /root/root.txt; \
    chmod 0644 /var/www/user.txt; chmod 0600 /root/root.txt

# TODO: introduis ici ta vulnérabilité / ton misconfig volontaire.

EXPOSE 80
