FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Apache + MapServer + GDAL (vsicurl) + unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Modules nécessaires
# - "cgid" = CGI pour l'MPM event (par défaut sur Debian)
# - "headers" = CORS
RUN a2enmod cgid headers

# Arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp \
 && chmod -R 777 /srv/ms_tmp

# Fichiers appli
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/
COPY start.sh /srv/start.sh
RUN chmod +x /srv/start.sh

# Page d'accueil pour vérifier qu'Apache tourne
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>If you can see this, Apache is running.</p>' \
  '<p>Try WMS Capabilities with your mapfile:</p>' \
  '<code>/cgi-bin/mapserv?MAP=/srv/mapfiles/project.map&SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# VHost minimal avec ScriptAlias + CORS
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

# Vars MapServer
ENV MS_ERRORFILE=/dev/stderr \
    MS_DEBUGLEVEL=1 \
    MS_MAP_PATTERN=".*" \
    MS_TEMPPATH=/srv/ms_tmp
ENV MS_CONFIG_FILE=""
ENV MS_MAPFILE=""


EXPOSE 8080
CMD ["/srv/start.sh"]
