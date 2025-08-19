#!/usr/bin/env bash
set -euo pipefail

# Valeur par défaut si Railway n'injecte pas PORT (tests locaux)
export PORT="${PORT:-8080}"

# Définit le mapfile à utiliser sans passer ?map= dans l’URL
# (à définir aussi dans Railway > Variables si tu veux en changer)
export MAPFILE_PATH="${MAPFILE_PATH:-/srv/mapfiles/project.map}"
export MS_MAPFILE="${MAPFILE_PATH}"

echo "Using PORT=$PORT"
echo "MS_MAPFILE=$MS_MAPFILE"
echo "MapServer binary: $(command -v mapserv || true)"

echo "== ls /usr/lib/cgi-bin =="
ls -al /usr/lib/cgi-bin/ || true
echo "== ls /srv/mapfiles =="
ls -al /srv/mapfiles || true

# Démarrage Apache en foreground (obligatoire sur Railway)
apachectl -D FOREGROUND
