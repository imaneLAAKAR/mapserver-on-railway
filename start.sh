#!/usr/bin/env bash
set -euo pipefail

export PORT="${PORT:-8080}"

# Mapfile par défaut (si variable absente)
export MAPFILE_PATH="${MAPFILE_PATH:-/srv/mapfiles/project.map}"
export MS_MAPFILE="${MAPFILE_PATH}"

# Désactiver tout fichier de config global packagé
unset MS_CONFIG_FILE

echo "Using PORT=$PORT"
echo "MS_MAPFILE=$MS_MAPFILE"
echo "MS_CONFIG_FILE=${MS_CONFIG_FILE-<unset>}"

echo "== ls /usr/lib/cgi-bin =="
ls -al /usr/lib/cgi-bin/ || true
echo "== ls /srv/mapfiles =="
ls -al /srv/mapfiles || true

apachectl -D FOREGROUND
