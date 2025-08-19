#!/usr/bin/env bash
set -euo pipefail

# Valeur par défaut si Railway n’injecte pas PORT (local)
export PORT="${PORT:-8080}"

# Vérifs utiles
echo "Using PORT=$PORT"
echo "Mapfile: ${MAPFILE_PATH:-/srv/mapfiles/project.map}"
ls -al /usr/lib/cgi-bin/ || true
ls -al /srv/mapfiles || true

# Démarrer Apache en foreground (obligatoire sur Railway)
apachectl -D FOREGROUND
