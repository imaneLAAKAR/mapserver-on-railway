FROM camptocamp/mapserver:latest
USER root

# Dossiers & droits
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && chmod -R 777 /srv/ms_tmp

# Tes fichiers
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

# Page d'accueil (juste pour check)
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>Capabilities :</p>' \
  '<code>/cgi-bin/ms?SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# Wrapper CGI qui fixe le MAPFILE et lance mapserv fourni par l'image
# (pas de config-file, pas d'ENV Apache capricieux)
RUN printf '%s\n' \
  '#!/bin/sh' \
  'export MS_ERRORFILE=/dev/stderr' \
  'export MS_DEBUGLEVEL=5' \
  'export MS_MAP_PATTERN=.*' \
  'export MS_TEMPPATH=/srv/ms_tmp' \
  'export MS_CONFIG_FILE=' \
  'export MS_MAPFILE=/srv/mapfiles/project.map' \
  'exec /usr/lib/cgi-bin/mapserv' \
  > /usr/lib/cgi-bin/ms && chmod +x /usr/lib/cgi-bin/ms

# Adapter Apache au port Railway au démarrage
COPY <<'SH' /srv/start.sh
#!/usr/bin/env bash
set -euo pipefail
PORT_ENV="${PORT:-8080}"
sed -i "s/Listen 80/Listen ${PORT_ENV}/" /etc/apache2/ports.conf || true
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
