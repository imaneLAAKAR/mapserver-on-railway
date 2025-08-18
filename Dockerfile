FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Apache + MapServer + GDAL (vsicurl) + unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Modules nécessaires (ajout de env)
RUN a2enmod cgid headers env

# Arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp \
 && chmod -R 777 /srv/ms_tmp

# Fichiers appli
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/
COPY start.sh /srv/start.sh
RUN chmod +x /srv/start.sh

# Page d'accueil (test Apache)
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>If you can see this, Apache is running.</p>' \
  '<p>Try WMS Capabilities:</p>' \
  '<code>/cgi-bin/mapserv?SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# VHost minimal + CORS + SetEnv (passe MS_MAPFILE au CGI)
RUN printf '%s\n' \
  'ServerName localhost' \
  '<VirtualHost *:80>' \
  '  DocumentRoot /var/www/html' \
  '  ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/' \
  '  <Directory "/usr/lib/cgi-bin">' \
  '    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch' \
  '    Require all granted' \
  '  </Directory>' \
  '  # Passe les variables au CGI' \
  '  SetEnv MS_MAPFILE /srv/mapfiles/project.map' \
  '  SetEnv MS_CONFIG_FILE ""' \
  '  <IfModule mod_headers.c>' \
  '    Header always set Access-Control-Allow-Origin "*"' \
  '    Header always set Access-Control-Allow-Methods "GET, OPTIONS"' \
  '    Header always set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"' \
  '  </IfModule>' \
  '</VirtualHost>' \
  > /etc/apache2/sites-available/000-default.conf

# Variables MapServer (une seule fois)
ENV MS_ERRORFILE=/dev/stderr \
    MS_DEBUGLEVEL=1 \
    MS_MAP_PATTERN=".*" \
    MS_TEMPPATH=/srv/ms_tmp
    # ... (le haut de ton Dockerfile reste identique)

# Wrapper CGI qui force le MAPFILE et désactive tout config-file
RUN printf '%s\n' \
  '#!/bin/sh' \
  'unset MS_CONFIG_FILE' \
  'export MS_MAPFILE=/srv/mapfiles/project.map' \
  'exec /usr/lib/cgi-bin/mapserv' \
  > /usr/lib/cgi-bin/ms && chmod +x /usr/lib/cgi-bin/ms

# (facultatif mais conseillé) s'assurer que /srv/mapfiles contient bien les fichiers
RUN ls -la /srv/mapfiles || true




EXPOSE 8080
CMD ["/srv/start.sh"]
