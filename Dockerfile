FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Apache + MapServer CGI + outils
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    libapache2-mod-fcgid \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Activer CGI
RUN a2enmod cgid headers && a2enconf serve-cgi-bin

# ⚠️ Couper TOUTE conf Debian MapServer qui impose un config_file
RUN a2disconf mapserver || true \
 && rm -f /etc/apache2/conf-enabled/mapserver.conf /etc/apache2/conf-available/mapserver.conf || true

# Arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && chmod -R 777 /srv/ms_tmp

# Tes fichiers
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

# Alias pratique /cgi-bin/ms -> mapserv (ou mapserv.fcgi selon le paquet)
RUN ln -sf /usr/lib/cgi-bin/mapserv /usr/lib/cgi-bin/ms || \
    ln -sf /usr/lib/cgi-bin/mapserv.fcgi /usr/lib/cgi-bin/ms

# Petite propreté Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Script de démarrage
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
