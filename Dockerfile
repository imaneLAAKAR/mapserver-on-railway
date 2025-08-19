FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive
USER root

# Apache + MapServer (CGI & FastCGI) + GDAL + unzip
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    libapache2-mod-fcgid \
    gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Modules nécessaires
RUN a2enmod cgid fcgid headers

# ⚠️ Supprimer la conf mapserver par défaut (elle référence /tmp/pass-env)
RUN a2disconf mapserver || true && \
    rm -f /etc/apache2/conf-enabled/mapserver.conf /etc/apache2/conf-available/mapserver.conf

# Arborescence appli
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && chmod -R 777 /srv/ms_tmp

# Fichiers appli
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

# Page d'accueil
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>WMS Capabilities :</p>' \
  '<code>/cgi-bin/ms?SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# VirtualHost minimal + CORS (aucun Include exotique)
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

# 🔧 Wrapper CGI : fixe le MAPFILE et lance le binaire disponible
RUN printf '%s\n' \
  '#!/bin/sh' \
  'export MS_ERRORFILE=/dev/stderr' \
  'export MS_DEBUGLEVEL=5' \
  'export MS_MAP_PATTERN=.*' \
  'export MS_TEMPPATH=/srv/ms_tmp' \
  'export MS_CONFIG_FILE=' \
  'export MS_MAPFILE=/srv/mapfiles/project.map' \
  'if [ -x /usr/lib/cgi-bin/mapserv ]; then' \
  '  exec /usr/lib/cgi-bin/mapserv' \
  'elif [ -x /usr/lib/cgi-bin/mapserv.fcgi ]; then' \
  '  exec /usr/lib/cgi-bin/mapserv.fcgi' \
  'else' \
  '  echo "Status: 500 Internal Server Error"' \
  '  echo "Content-Type: text/plain"' \
  '  echo' \
  '  echo "MapServer CGI introuvable (mapserv / mapserv.fcgi)."' \
  '  exit 1' \
  'fi' \
  > /usr/lib/cgi-bin/ms && chmod +x /usr/lib/cgi-bin/ms

# start.sh : adapte le port Railway et lance Apache
COPY <<'SH' /srv/start.sh
#!/usr/bin/env bash
set -euo pipefail
PORT_ENV="${PORT:-8080}"

# Adapter Apache au port Railway
[ -f /etc/apache2/ports.conf ] && sed -i "s/Listen 80/Listen ${PORT_ENV}/" /etc/apache2/ports.conf || true
for F in /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-enabled/000-default.conf; do
  [ -f "$F" ] && sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT_ENV}>#" "$F" || true
done

echo "== /usr/lib/cgi-bin =="
ls -la /usr/lib/cgi-bin || true
echo "== /srv/mapfiles =="
ls -la /srv/mapfiles || true

exec apachectl -DFOREGROUND
SH
RUN chmod +x /srv/start.sh

EXPOSE 8080
CMD ["/srv/start.sh"]
