FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Apache + MapServer (CGI et FastCGI) + GDAL + unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    libapache2-mod-fcgid \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Activer modules nécessaires (CGI + FastCGI + CORS)
RUN a2enmod cgid fcgid headers

# Arborescence appli
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp \
 && chmod -R 777 /srv/ms_tmp

# Tes fichiers
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/
COPY start.sh /srv/start.sh
RUN chmod +x /srv/start.sh

# Page d'accueil
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>WMS Capabilities :</p>' \
  '<code>/cgi-bin/ms?SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# VirtualHost minimal + CORS
RUN printf '%s\n' \
  'ServerName localhost' \
  '<VirtualHost *:80>' \
  '  DocumentRoot /var/www/html' \
  '  ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/' \
  '  <Directory "/usr/lib/cgi-bin">' \
  '    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch' \
  '    Require all granted' \
  '  </Directory>' \
  '  <IfModule mod_headers.c>' \
  '    Header always set Access-Control-Allow-Origin "*"' \
  '    Header always set Access-Control-Allow-Methods "GET, OPTIONS"' \
  '    Header always set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"' \
  '  </IfModule>' \
  '</VirtualHost>' \
  > /etc/apache2/sites-available/000-default.conf

# ⚡ Wrapper CGI : détecte le bon binaire et l'exécute
RUN printf '%s\n' \
  '#!/bin/sh' \
  'unset MS_CONFIG_FILE' \
  'export MS_MAPFILE=/srv/mapfiles/project.map' \
  'if [ -x /usr/lib/cgi-bin/mapserv ]; then' \
  '  exec /usr/lib/cgi-bin/mapserv' \
  'elif [ -x /usr/lib/cgi-bin/mapserv.fcgi ]; then' \
  '  exec /usr/lib/cgi-bin/mapserv.fcgi' \
  'else' \
  '  echo "Status: 500 Internal Server Error"' \
  '  echo "Content-Type: text/plain"' \
  '  echo' \
  '  echo "MapServer CGI introuvable (mapserv/mapserv.fcgi)."' \
  '  exit 1' \
  'fi' \
  > /usr/lib/cgi-bin/ms && chmod +x /usr/lib/cgi-bin/ms

# Variables utiles (logs/temp)
ENV MS_ERRORFILE=/dev/stderr \
    MS_DEBUGLEVEL=1 \
    MS_MAP_PATTERN=".*" \
    MS_TEMPPATH=/srv/ms_tmp

EXPOSE 8080
CMD ["/srv/start.sh"]
