# Base légère Debian
FROM debian:bookworm-slim

# On veut les droits admin pendant le build
USER root

# Installer Apache + MapServer (CGI)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apache2 \
      cgi-mapserver \
      ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Activer le module CGI d'Apache
RUN a2enmod cgi

# Dossier de travail pour cartes/données
WORKDIR /srv
RUN mkdir -p /srv/mapfiles /srv/data /srv/ms_tmp && \
    chown -R www-data:www-data /srv

# Vars utiles MapServer
ENV MS_ERRORFILE=/tmp/ms_error.txt
ENV MS_DEBUGLEVEL=1
ENV MS_MAP_PATTERN=.+

# Copier tes cartes et (optionnel) données
# (Assure-toi que ces dossiers existent dans le repo; mets un .gitkeep s’ils sont vides)
COPY mapfiles/ /srv/mapfiles/
COPY data/ /srv/data/

# Exposer un port par défaut (Railway injecte $PORT)
EXPOSE 8080

# 🔑 Adapter Apache au port Railway et lancer en avant-plan
CMD bash -lc '\
  export PORT=${PORT:-8080}; \
  sed -ri "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf; \
  sed -ri "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf; \
  a2enconf serve-cgi-bin >/dev/null 2>&1 || true; \
  apache2ctl -D FOREGROUND'
