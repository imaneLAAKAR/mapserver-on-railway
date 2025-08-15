FROM mapserver/mapserver:latest
USER root

WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && \
    chown -R www-data:www-data /srv/ms_tmp

ENV MS_ERRORFILE=/tmp/ms_error.txt
ENV MS_DEBUGLEVEL=1
ENV MS_MAP_PATTERN=.+

COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

EXPOSE 8080

# Important : ajuster le port APACHE au runtime (Railway fixe $PORT)
CMD ["bash", "-lc", "\
  export PORT=${PORT:-8080}; \
  sed -ri \"s/Listen 80/Listen ${PORT}/\" /etc/apache2/ports.conf; \
  sed -ri \"s/:80>/:${PORT}>/\" /etc/apache2/sites-available/000-default.conf; \
  apache2-foreground"]
