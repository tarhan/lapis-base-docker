FROM openresty/openresty:alpine

MAINTAINER Dmitriy Lekomtsev <lekomtsev@gmail.com>

ENV LAPIS_VERSION 1.6.0-1
ENV RESTY_LUAROCKS_VERSION="2.3.0"

ENV SRC_DIR /opt
ENV OPENRESTY_PREFIX /opt/openresty
ENV LAPIS_ENVIRONMENT docker
ENV LAPIS_OPENRESTY $OPENRESTY_PREFIX/nginx/sbin/nginx

RUN mkdir -p /app/src \
 && cd tmp/ \
# Installing build dependencies for Lapis and luarocks
 && echo "#### Installing build dependencies" \
 && apk --no-cache add \
      openssl \
 && apk --no-cache add --virtual .build-deps \
      curl \
      build-base \
      cmake \
      git \
      unzip \
      openssl-dev \
# Installing luarocks
 && echo "#### Installing luarocks" \
 && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
      -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && cd luarocks-${RESTY_LUAROCKS_VERSION} \
 && ./configure --prefix=/usr/local/openresty/luajit \
      --with-lua=/usr/local/openresty/luajit \
      --lua-suffix=jit-2.1.0-beta3 \
      --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
 && make build \
 && make install \
 && cd /tmp \
 && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} \
      luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && echo "#### Installing lua-cjson" \
# Installing lua-cjson from master branch of its git repo
 && git clone https://github.com/openresty/lua-cjson.git \
 && cd lua-cjson \
 && luarocks make \
 && cd /tmp \
 && rm -rf lua-cjson \
 && echo "#### Installing Lapis" \
# Installing Lapis via luarocks
 && luarocks install lapis \
 && apk del .build-deps

COPY preinstall.moon /app/preinstall.moon

WORKDIR /app/src

EXPOSE 8080

ENTRYPOINT ["lapis"]
ONBUILD ADD app.yml /app/
ONBUILD RUN cd /tmp \
# Installing luarocks
 && echo "#### Installing luarocks" \
 && apk --no-cache add --virtual .build-deps \
      curl \
      build-base \
      cmake \
      git \
      unzip \
      tar \
 && curl -fSL http://luarocks.org/releases/luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
      -o luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && tar xzf luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && cd luarocks-${RESTY_LUAROCKS_VERSION} \
 && ./configure --prefix=/usr/local/openresty/luajit \
      --with-lua=/usr/local/openresty/luajit \
      --lua-suffix=jit-2.1.0-beta3 \
      --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
 && make build \
 && make install \
 && cd /tmp \
 && rm -rf luarocks-${RESTY_LUAROCKS_VERSION} \
      luarocks-${RESTY_LUAROCKS_VERSION}.tar.gz \
 && echo "#### Installing lua-cjson" \
# Installing lua-cjson from master branch of its git repo
 && git clone https://github.com/openresty/lua-cjson.git \
 && cd lua-cjson \
 && luarocks make \
 && cd /tmp \
 && rm -rf lua-cjson \
 && echo "#### Installing Lapis" \
# Installing Lapis via luarocks
 && luarocks install lapis \
 && luarocks install moonscript \
 && moon /app/preinstall.moon /app/app.yml \
 && apk del .build-deps
ONBUILD ADD . /app/src
ONBUILD RUN moonc /app/src

CMD ["server", "production"]
