ARG VERSION
FROM php:${VERSION}-apache

RUN apt-get update \
    && apt-get install -y \
    cron \
    wget \
    git \
    icu-devtools \
    jq \
    libfreetype6-dev libicu-dev libjpeg62-turbo-dev libpng-dev libsasl2-dev libssl-dev libwebp-dev libxpm-dev libzip-dev \
    unzip \
    zlib1g-dev \
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && yes '' | pecl install redis \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm \
    && docker-php-ext-install gd intl pdo_mysql zip \
    && docker-php-ext-enable opcache redis \
    && sed -i 's/memory_limit\ =\ 128M/memory_limit\ =\ -1/' /usr/local/etc/php/php.ini

RUN apt-get update && apt-get install -y libpq-dev && docker-php-ext-install pdo pdo_pgsql

WORKDIR /etc/apache2/sites-available
RUN echo '<VirtualHost *:80>' > symfony.conf &&\
    echo '    ServerName symfony-demo.localhost' >> symfony.conf &&\
    echo '    DocumentRoot /var/www/symfony/public' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    ErrorLog /var/log/apache2/error.log' >> symfony.conf &&\
    echo '    CustomLog /var/log/apache2/access.log combined' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    RewriteEngine On' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    # optional: redirect www to no-www' >> symfony.conf &&\
    echo '    RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]' >> symfony.conf &&\
    echo '    RewriteRule ^(.*)$ https://%1$1 [L,R=permanent]' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    # optional: redirect http to https' >> symfony.conf &&\
    echo '    RewriteCond %{HTTP:X-Forwarded-Proto} =http' >> symfony.conf &&\
    echo '    RewriteRule .* https://%{HTTP:Host}%{REQUEST_URI} [L,R=permanent]' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    RewriteCond %{HTTP:Authorization} .' >> symfony.conf &&\
    echo '    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]' >> symfony.conf &&\
    echo '' >> symfony.conf &&\
    echo '    RewriteCond "%{DOCUMENT_ROOT}%{REQUEST_FILENAME}" !-d' >> symfony.conf &&\
    echo '    RewriteCond "%{DOCUMENT_ROOT}%{REQUEST_FILENAME}" !-f' >> symfony.conf &&\
    echo '    RewriteRule "^" "/index.php" [L]' >> symfony.conf &&\
    echo '</VirtualHost>' >> symfony.conf 
    
RUN a2enmod rewrite headers \
    && a2ensite symfony \
    && a2dissite 000-default

RUN wget https://getcomposer.org/download/1.10.22/composer.phar -O /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer

WORKDIR /var/www/symfony
COPY . .
RUN /usr/local/bin/composer install

CMD ["sh", "-c", "apache2-foreground"]
