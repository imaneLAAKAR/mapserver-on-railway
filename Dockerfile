FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# --- Apache + MapServer + GDAL ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    libapache2-mod-fcgid \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Activer CGI/FastCGI + CORS
RUN a2enmod cgid fcgid headers

# (Optionnel mais conseillé) désactiver la conf Debian par défaut
# qui pointe vers un config_file inexistant chez toi
RUN a2disconf mapserver || true

# Arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp \
 && chmod -R 777 /srv/ms_tmp

# Tes fichiers (à adapter à ton repo)
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

# --- CONFIG FILE GLOBAL MAPSERVER ---
# Copie de ton fichier de config global dans l'image
COPY mapserver.conf /etc/mapserver/mapserver.conf

# Définition de la variable d'environnement pour MapServer
ENV MS_MAPSERVER_CONFIG=/etc/mapserver/mapserver.conf

# Lien court /cgi-bin/ms -> mapserv (ou mapserv.fcgi selon le paquet)
RUN ln -sf /usr/lib/cgi-bin/mapserv /usr/lib/cgi-bin/ms || \
    ln -sf /usr/lib/cgi-bin/mapserv.fcgi /usr/lib/cgi-bin/ms

# Script de démarrage
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Lancer Apache au premier plan (Railway)
CMD ["/start.sh"]
