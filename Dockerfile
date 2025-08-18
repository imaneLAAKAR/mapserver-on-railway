FROM debian:bullseye-slim

# Installer Apache + MapServer
RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 \
    cgi-mapserver \
    mapserver-bin \
    libapache2-mod-fcgid \
    && rm -rf /var/lib/apt/lists/*

# Activer CGI et MapServer
RUN a2enmod cgi && a2enmod headers && a2enmod rewrite && a2enmod fcgid

# Copier ton mapfile et données
WORKDIR /srv
COPY mapfiles /srv/mapfiles
COPY data /srv/data

# Configurer Apache pour exposer MapServer
RUN echo 'ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/' >> /etc/apache2/sites-available/000-default.conf \
 && echo '<Directory "/usr/lib/cgi-bin">' >> /etc/apache2/sites-available/000-default.conf \
 && echo '    AllowOverride None' >> /etc/apache2/sites-available/000-default.conf \
 && echo '    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch' >> /etc/apache2/sites-available/000-default.conf \
 && echo '    Require all granted' >> /etc/apache2/sites-available/000-default.conf \
 && echo '</Directory>' >> /etc/apache2/sites-available/000-default.conf

EXPOSE 8080
CMD ["apache2ctl", "-D", "FOREGROUND"]
