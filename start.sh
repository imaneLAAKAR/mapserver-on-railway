#!/usr/bin/env bash
set -e

# Dossier temporaire + logs MapServer (facultatif mais utile)
export MS_TMPDIR=/srv/ms_tmp
export MS_ERRORFILE=stderr
export MS_DEBUGLEVEL=3

# (FACULTATIF) Si tu veux appeler sans `map=` dans l’URL,
# mets ici le mapfile par défaut (remplacer NOM.map).
# Sinon, commente cette ligne.
export MS_MAPFILE=/srv/mapfiles/NOM.map

# Sécurité : s’assurer qu’aucune ancienne variable "config" parasite
unset MS_MAPSERVER_CONFIG_FILE
unset MS_CONFIG_FILE

# Apache en avant-plan
apachectl -D FOREGROUND
