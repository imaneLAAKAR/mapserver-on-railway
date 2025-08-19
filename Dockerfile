# Image MapServer déjà prête (Apache + CGI configurés)
FROM camptocamp/mapserver:latest
USER root

# On ajoutera juste GDAL utils (pratique) et unzip
RUN apt-get update && apt-get install -y --no-install-recommends gdal-bin unzip \
 && rm -rf /var/lib/apt/lists/*

# Dossiers pour tes cartes/données/temp
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp \
 && chmod -R 777 /srv/ms_tmp

# Copie de tes fichiers (assure-toi qu'ils existent dans le repo)
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/
COPY start.sh /srv/start.sh
RUN chmod +x /srv/start.sh

# Page d'accueil pour vérifier Apache
RUN printf '%s\n' \
  '<!doctype html><html><body style="font-family:sans-serif">' \
  '<h1>Apache OK</h1>' \
  '<p>If you can see this, Apache is running.</p>' \
  '<p>WMS Capabilities:</p>' \
  '<code>/cgi-bin/ms?SERVICE=WMS&REQUEST=GetCapabilities</code>' \
  '</body></html>' \
  > /var/www/html/index.html

# Petit wrapper CGI qui fixe le MAPFILE (évite les soucis d'ENV)
# => on appelle /cgi-bin/ms au lieu de /cgi-bin/mapserv
RUN printf '%s\n' \
  '#!/bin/sh' \
  'unset MS_CONFIG_FILE' \
  'export MS_MAPFILE=/srv/mapfiles/project.map' \
  'exec /usr/lib/cgi-bin/mapserv' \
  > /usr/lib/cgi-bin/ms && chmod +x /usr/lib/cgi-bin/ms

# (Option sûreté) si project.map n'existe pas, on en crée un minimal
# Cela évite l'erreur au premier démarrage; remplace-le ensuite par le tien.
RUN test -f /srv/mapfiles/project.map || ( \
  printf '%s\n' \
  'MAP' \
  '  NAME "project"' \
  '  STATUS ON' \
  '  EXTENT -180 -90 180 90' \
  '  UNITS DD' \
  '  PROJECTION "init=epsg:4326" END' \
  '  WEB METADATA "wms_title" "Project WMS" "wms_enable_request" "*" "wms_srs" "EPSG:4326 EPSG:3857" END END' \
  'END' \
  > /srv/mapfiles/project.map )

# Variables MapServer utiles (logs / temp)
ENV MS_ERRORFILE=/dev/stderr \
    MS_DEBUGLEVEL=1 \
    MS_MAP_PATTERN=".*" \
    MS_TEMPPATH=/srv/ms_tmp

EXPOSE 8080
CMD ["/srv/start.sh"]
