FROM debian:bookworm-slim
USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 cgi-mapserver gdal-bin unzip ca-certificates libapache2-mod-headers \
 && rm -rf /var/lib/apt/lists/*

RUN a2enmod cgi && a2enmod headers

WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && \
    chown -R www-data:www-data /srv && \
    chmod -R 777 /srv/ms_tmp

ENV MS_ERRORFILE=/tmp/ms_error.txt \
    MS_DEBUGLEVEL=1 \
    MS_MAP_PATTERN=".+"
ENV MS_TEMPPATH=/srv/ms_tmp

COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

RUN printf '%s\n' \
  '<IfModule mod_headers.c>' \
  '  Header always set Access-Control-Allow-Origin "*"' \
  '  Header always set Access-Control-Allow-Methods "GET, OPTIONS"' \
  '  Header always set Access-Control-Allow-Headers "Origin, X-Requested-With, Content-Type, Accept, Authorization"' \
  '</IfModule>' \
  > /etc/apache2/conf-available/cors.conf && a2enconf cors

EXPOSE 8080

CMD bash -lc '\
  export PORT=${PORT:-8080}; \
  sed -ri "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf; \
  sed -ri "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf; \
  a2enconf serve-cgi-bin >/dev/null 2>&1 || true; \
  apache2ctl -D FOREGROUND'
