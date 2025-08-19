FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# Apache + MapServer (CGI) + GDAL + utilitaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    gdal-bin unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Modules nécessaires
RUN a2enmod cgid headers

# Éviter la conf par défaut de cgi-mapserver qui appelle msLoadConfig
RUN a2disconf mapserver || true

# Préparer arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data/rasters /srv/data/vectors /srv/ms_tmp
RUN chmod -R 777 /srv/ms_tmp

# Ton app (mapfiles + éventuels scripts)
COPY mapfiles/ /srv/mapfiles/
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Remplacer le port Apache par la var Railway $PORT
# + autoriser CGI et CORS sur le vhost par défaut
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf && \
    sed -i 's|<VirtualHost \*:80>|<VirtualHost *:${PORT}>|' /etc/apache2/sites-available/000-default.conf && \
    printf '\n# CGI\nScriptAlias /cgi-bin/ /usr/lib/cgi-bin/\n<Directory "/usr/lib/cgi-bin">\n  AllowOverride None\n  Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n  Require all granted\n</Directory>\n\n# CORS\n<IfModule mod_headers.c>\n  Header always set Access-Control-Allow-Origin "*"\n  Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"\n  Header always set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept"\n</IfModule>\n' >> /etc/apache2/sites-available/000-default.conf

# Chemins utiles en ENV (facultatif)
ENV MAPSERV_PATH=/usr/lib/cgi-bin/mapserv
ENV MAPFILE_PATH=/srv/mapfiles/project.map

# Railway expose automatiquement $PORT, pas besoin de EXPOSE
CMD ["/usr/local/bin/start.sh"]
