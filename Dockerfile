FROM php:5.6-apache

MAINTAINER Kristof Lünenschloß <kl@latupo.com>

RUN apt-get update && apt-get install -y \
		mysql-client \
		php5-mysql \
		php5-gd \
		libpng12-dev \
		libxml2-dev \
		libmcrypt-dev \
		libfreetype6-dev \
		libjpeg62-turbo-dev \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
	&& docker-php-ext-install pdo_mysql gd soap mcrypt

COPY config/ /config/
COPY scripts/create-patches.sh /usr/local/bin/create-patches
COPY scripts/backup-databases.sh /usr/local/bin/backup-databases

RUN usermod -u 1000 www-data

VOLUME /var/www/html
VOLUME /patches
VOLUME /backups

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

