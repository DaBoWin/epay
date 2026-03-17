FROM php:8.1-fpm-bullseye

# 可选代理（用于构建期 apt/composer 等下载）。
# 若不传入，这些变量将为空，从而避免构建环境继承到错误的代理设置。
ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY
ENV http_proxy=${http_proxy} \
    https_proxy=${https_proxy} \
    no_proxy=${no_proxy} \
    HTTP_PROXY=${HTTP_PROXY} \
    HTTPS_PROXY=${HTTPS_PROXY} \
    NO_PROXY=${NO_PROXY}

# 安装依赖
RUN set -eux; \
    # 某些网络环境会对 HTTP 做劫持/代理，改用 HTTPS 源更稳
    sed -i \
      -e 's|http://deb.debian.org/debian|https://deb.debian.org/debian|g' \
      -e 's|http://security.debian.org/debian-security|https://security.debian.org/debian-security|g' \
      -e 's|http://deb.debian.org/debian-security|https://security.debian.org/debian-security|g' \
      /etc/apt/sources.list; \
    apt-get -o Acquire::Retries=5 update; \
    apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
      ca-certificates \
      nginx \
      default-mysql-client \
      curl \
      libpng-dev \
      libjpeg62-turbo-dev \
      libfreetype6-dev \
      libzip-dev \
      libonig-dev \
      supervisor \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
      pdo_mysql \
      mysqli \
      gd \
      zip \
      mbstring \
      opcache \
      bcmath \
    ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# nginx 配置
COPY docker/nginx.conf /etc/nginx/nginx.conf

# supervisor 配置（同时管理 nginx + php-fpm）
COPY docker/supervisord.conf /etc/supervisord.conf

# 入口脚本（等待 MySQL 就绪后自动初始化数据库）
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 复制源码
COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/assets \
    && chmod -R 777 /var/www/html/plugins

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
