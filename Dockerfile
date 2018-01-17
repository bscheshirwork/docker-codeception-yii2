FROM bscheshir/php:fpm-alpine-4yii2-xdebug
# docker build -t bscheshir/codeception:php-fpm-alpine-yii2 .
MAINTAINER BSCheshir <bscheshir.work@gmail.com>

RUN set -xe \
	&& apk add --no-cache --virtual \
		zlib1g-dev \
    && docker-php-ext-install \
    bcmath

# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Prepare application
WORKDIR /repo

# Install vendor
COPY ./composer.json /repo/composer.json
RUN composer install --prefer-dist --optimize-autoloader

# Add source-code
COPY . /repo

ENV PATH /repo:${PATH}
ENTRYPOINT ["codecept"]

# Prepare host-volume working directory
RUN mkdir -p /var/www/html
WORKDIR /var/www/html