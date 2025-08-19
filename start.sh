#!/usr/bin/env bash
set -e

# 1) Port Railway (sinon 8080 par défaut en local)
PORT="${PORT:-8080}"

# 2) Forcer Apache à écouter sur $PORT (et ajuster le VirtualHost)
sed -ri "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf || true
sed -ri "s/<VirtualHost \*:80>/<VirtualHost \*:${PORT}>/" /etc/apache2/sites-available/000-default.conf || true

# (Optionnel) supprimer les déclarations 443 si présentes pour éviter des warnings
sed -ri "s/Listen 443/# Listen 443/" /etc/apache2/ports.conf || true

# 3) Nom de serveur pour supprimer AH00558
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# 4) Activer CGI si besoin (idempotent)
a2enmod cgid fcgid headers >/dev/null 2>&1 || true
a2enconf serve-cgi-bin >/dev/null 2>&1 || true

# 5) Variables MapServer utiles
export MS_TMPDIR=/srv/ms_tmp
export MS_ERRORFILE=stderr         # logs dans les logs Railway
export MS_DEBUGLEVEL=3

# (si tu veux éviter &map= dans l’URL)
export MS_MAPFILE=/srv/mapfiles/NOM.map   # <-- remplace par ton .map exact

# Sécurité : pas de config_file global parasite
unset MS_MAPSERVER_CONFIG_FILE
unset MS_CONFIG_FILE

# 6) Démarrer Apache au premier plan (obligatoire pour Railway)
apachectl -D FOREGROUND
