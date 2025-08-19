FROM debian:bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

# Apache + MapServer (CGI) + GDAL + utilitaires
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver mapserver-bin \
    gdal-bin unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Activer CGI & CORS, désactiver la conf packagée "mapserver" (sinon msLoadConfig)
RUN a2enmod cgid headers && a2disconf mapserver || true && rm -f /etc/apache2/conf-enabled/mapserver.conf || true


# Répertoire de travail & arborescence
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data/rasters /srv/data/vectors /srv/ms_tmp
RUN chmod -R 777 /srv/ms_tmp

# Copie de tes fichiers
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Adapter Apache au port Railway + activer CGI & CORS dans le vhost
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf && \
    sed -i 's|<VirtualHost \\*:80>|<VirtualHost *:${PORT}>|' /etc/apache2/sites-available/000-default.conf && \
    printf '\n# CGI\nScriptAlias /cgi-bin/ /usr/lib/cgi-bin/\n<Directory "/usr/lib/cgi-bin">\n  AllowOverride None\n  Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch\n  Require all granted\n</Directory>\n\n# CORS\n<IfModule mod_headers.c>\n  Header always set Access-Control-Allow-Origin "*"\n  Header always set Access-Control-Allow-Methods "GET, POST, OPTIONS"\n  Header always set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept"\n</IfModule>\n' >> /etc/apache2/sites-available/000-default.conf

# Variables utiles
ENV MAPSERV_PATH=/usr/lib/cgi-bin/mapserv
# -> On utilisera MS_MAPFILE pour éviter de passer ?map= dans l’URL
ENV MS_MAP_NO_PATH=0
ENV MS_CONFIG_FILE=

# Pas de EXPOSE nécessaire sur Railway
CMD ["/usr/local/bin/start.sh"]
