#!/usr/bin/env bash
set -euo pipefail

PORT_ENV="${PORT:-8080}"

# Écrire un ports.conf propre avec le PORT Railway
printf 'Listen %s\n' "$PORT_ENV" > /etc/apache2/ports.conf

# Adapter le vhost au bon port
sed -i "s#<VirtualHost \*:80>#<VirtualHost *:${PORT_ENV}>#" /etc/apache2/sites-available/000-default.conf

# Sanity checks utiles dans les logs
echo "== MapServer CGI =="
if [ -x /usr/lib/cgi-bin/mapserv ]; then
  /usr/lib/cgi-bin/mapserv -v || true
else
  echo "ERREUR: /usr/lib/cgi-bin/mapserv introuvable"
fi

echo "== Présence mapfiles =="
ls -la /srv/mapfiles || true

echo "== Apache modules =="
apache2ctl -M | sort || true

echo "Démarrage Apache sur le port ${PORT_ENV}…"
unset MS_CONFIG_FILE || true
unset MS_MAPFILE || true

exec apache2ctl -DFOREGROUND
