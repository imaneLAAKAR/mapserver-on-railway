#!/usr/bin/env bash
set -e

# Railway impose $PORT (sinon 8080 en local)
PORT="${PORT:-8080}"
sed -ri "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf || true
sed -ri "s#<VirtualHost \*:80>#<VirtualHost *:${PORT}>#" /etc/apache2/sites-available/000-default.conf || true

# 🔒 Désactiver toute tentative de "config file" global
unset MS_MAPSERVER_CONFIG
unset MS_MAPSERVER_CONFIG_FILE
unset MS_CONFIG_FILE

# 🗺️ Mapfile par défaut (évite d’écrire map= dans l’URL)
export MS_MAPFILE="/srv/mapfiles/project.map"

# Temp + logs MapServer (dans les logs Railway)
export MS_TMPDIR="/srv/ms_tmp"
export MS_ERRORFILE=stderr
export MS_DEBUGLEVEL=3

# S'assurer que CGI est bien actif (idempotent)
a2enmod cgid headers >/dev/null 2>&1 || true
a2enconf serve-cgi-bin >/dev/null 2>&1 || true

# Démarrer Apache en avant-plan
apachectl -D FOREGROUND
