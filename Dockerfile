FROM alpine:3.4

MAINTAINER Dmitriy Lekomtsev <lekomtsev@gmail.com>

# Based on Xe/docker-lapis

ENV OPENRESTY_VERSION 1.9.15.1
ENV LAPIS_VERSION 1.4.3
ENV LUAROCKS_VERSION 2.3.0

ENV SRC_DIR /opt
ENV OPENRESTY_PREFIX /opt/openresty
ENV LAPIS_ENVIRONMENT docker
ENV LAPIS_OPENRESTY $OPENRESTY_PREFIX/nginx/sbin/nginx

RUN   mkdir -p $SRC_DIR \
  &&  mkdir -p /app/src \
  &&  mkdir -p /app/src/logs \
# Create temp folders for nginx
  &&  mkdir -p /app/tmp/client_temp \
  &&  mkdir -p /app/tmp/proxy_temp \
  &&  mkdir -p /app/tmp/fastcgi_temp \
  &&  mkdir -p /app/tmp/uwsgi_temp \
  &&  mkdir -p /app/tmp/scgi_temp \
# Installing runtime dependecies of openresty, luarocks
  &&  apk --no-cache add \
        pcre \
        openssl \
        readline \
        curl \
        libgcc \
        unzip \
        libstdc++ \
# Temporary installing build dependencies for openresty and luarocks
  &&  apk --no-cache add --virtual build-dependencies \
        build-base \
        cmake \
        openssl-dev \
        git \
        readline-dev \
        curl-dev \
        perl \
        pcre-dev \
  &&  cd $SRC_DIR \
# Installing openresty
  &&  curl -LO https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz \
  &&  tar xzf openresty-$OPENRESTY_VERSION.tar.gz \
  &&  cd openresty-$OPENRESTY_VERSION \
  &&  ./configure --prefix=$OPENRESTY_PREFIX \
        --with-luajit \
        --with-pcre-jit \
        --with-ipv6 \
        --with-http_realip_module \
        --http-client-body-temp-path=/app/tmp/client_temp \
        --http-proxy-temp-path=/app/tmp/proxy_temp \
        --http-fastcgi-temp-path=/app/tmp/fastcgi_temp \
        --http-uwsgi-temp-path=/app/tmp/uwsgi_temp \
        --http-scgi-temp-path=/app/tmp/scgi_temp \
  &&  make \
  &&  make install \
  &&  cd $SRC_DIR \
  &&  rm -rf openresty-$OPENRESTY_VERSION* \
# Installing luarocks
  &&  curl -LO http://keplerproject.github.io/luarocks/releases/luarocks-$LUAROCKS_VERSION.tar.gz \
  &&  tar xzf luarocks-$LUAROCKS_VERSION.tar.gz \
  &&  cd luarocks-$LUAROCKS_VERSION \
  &&  ./configure \
        --lua-suffix=jit \
        --with-lua=/opt/openresty/luajit \
        --with-lua-include=/opt/openresty/luajit/include/luajit-2.1 \
        --with-downloader=curl \
  &&  make build \
  &&  make install \
  &&  cd $SRC_DIR \
  &&  rm -rf luarocks-$LUAROCKS_VERSION* \
# Installing lapis, moonscript, yaml
  &&  luarocks install luasec \
  &&  luarocks install --server=http://rocks.moonscript.org/manifests/leafo lapis $LAPIS_VERSION \
  &&  luarocks install moonscript \
  &&  luarocks install lapis-console \
  &&  luarocks install yaml \
  &&  apk del build-dependencies \
# Installing minimal init system for container
# as defence from https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
  &&  curl -L https://github.com/krallin/tini/releases/download/v0.9.0/tini-static -o tini \
  &&  mv tini /usr/local/bin/tini \
  &&  chmod +x /usr/local/bin/tini

COPY prepare.moon /app/prepare.moon
# COPY lapis /app/lapis

WORKDIR /app/src

# Due lapis's architecture bug it is always create logs folder under app folder
# That is why I'm creating volume under app/src subfolder
VOLUME ["/app/src/logs"]

EXPOSE 8080
EXPOSE 80

ENTRYPOINT ["tini", "--", "lapis"]

ONBUILD ADD app.yml /app/
ONBUILD RUN moon /app/prepare.moon /app/app.yml
ONBUILD ADD . /app/src
ONBUILD RUN moonc /app/src

CMD ["server", "production"]
