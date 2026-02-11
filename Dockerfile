# Use Alpine Linux as the base image
FROM alpine:latest

# Set Nginx version and module version
ARG NGINX_VERSION=1.24.0
ARG NGINX_CONNECT_MODULE_VERSION=v0.0.3

# Install build dependencies and apache2-utils
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    pcre \
    zlib-dev \
    openssl-dev \
    linux-headers \
    curl \
    patch \
    apache2-utils

# Download Nginx source
WORKDIR /usr/src
RUN curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && tar -zxvf nginx.tar.gz \
    && rm nginx.tar.gz

# Download ngx_http_proxy_connect_module source
RUN curl -fSL https://github.com/chobits/ngx_http_proxy_connect_module/archive/${NGINX_CONNECT_MODULE_VERSION}.tar.gz -o ngx_http_proxy_connect_module.tar.gz     && tar -zxvf ngx_http_proxy_connect_module.tar.gz     && rm ngx_http_proxy_connect_module.tar.gz

# Apply patch for ngx_http_proxy_connect_module
WORKDIR /usr/src/nginx-${NGINX_VERSION}
RUN patch -p1 < ../ngx_http_proxy_connect_module-0.0.3/patch/proxy_connect_rewrite_102101.patch
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --add-module=../ngx_http_proxy_connect_module-0.0.3 \
    && make \
    && make install \
    && rm -rf /usr/src/nginx-${NGINX_VERSION} \
    && rm -rf /usr/src/ngx_http_proxy_connect_module-${NGINX_CONNECT_MODULE_VERSION} \
    && apk del build-base zlib-dev openssl-dev patch

RUN addgroup -S nginx     && adduser -S -D -H -u 1000 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Create necessary directories and set permissions
RUN mkdir -p /var/cache/nginx /etc/nginx/conf.d     && chown -R nginx:nginx /var/cache/nginx     && chown -R nginx:nginx /var/log/nginx     && touch /var/run/nginx.pid     && chown nginx:nginx /var/run/nginx.pid

# Expose the proxy port
EXPOSE 8080

# Run Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]