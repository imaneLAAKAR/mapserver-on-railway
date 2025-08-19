#!/usr/bin/env bash
set -euo pipefail

PORT_ENV="${PORT:-8080}"

# Adapter Apache au port Railway
if [ -f /etc/apache2/ports.conf ]; then
  sed -i "s/Listen 80/Listen ${PORT_ENV}/" /etc/apache2/ports.conf || true
fi
if [ -f /etc/apache2/sites-available/000-default.conf ]; then
  sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT_ENV}>#" /etc/apache2/sites-available/000-default.conf || true
fi
if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
  sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT_ENV}>#" /etc/apache2/sites-enabled/000-default.conf || true
fi

echo "== Présence mapfiles =="
ls -la /srv/mapfiles || true
echo "== mapserv -v =="
/usr/lib/cgi-bin/mapserv -v || true
echo "Démarrage Apache sur le port ${PORT_ENV}…"

# Lancer Apache en avant-plan (image camptocamp fournit apachectl)
exec apachectl -DFOREGROUND
