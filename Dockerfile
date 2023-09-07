FROM debian:12-slim AS build

LABEL org.opencontainers.image.source https://github.com/dfukagaw28/docker-iipsrv

ENV PYTHONUNBUFFERED 1

ENV IIPSRV_BUILD_DEPS \
        autoconf \
        automake \
        ca-certificates \
        curl \
        g++ \
        gawk \
        git \
        libtool \
        make \
        pkg-config

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        $IIPSRV_BUILD_DEPS \
        libfcgi-dev \
        libjpeg-dev \
        libmemcached-dev \
        libopenjp2-7-dev \
        libpng-dev \
        libtiff-dev \
        libwebp-dev

RUN set -ex \
    && git clone https://github.com/ruven/iipsrv /usr/local/src/iipsrv -b iipsrv-1.2 --depth 1

WORKDIR /usr/local/src/iipsrv

RUN set -ex \
    && ./autogen.sh \
    && ./configure --enable-openjpeg \
    && make


FROM debian:12-slim

COPY --from=build /usr/local/src/iipsrv/src/iipsrv.fcgi /usr/local/bin/iipsrv.fcgi

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libfcgi \
        libgomp1 \
        libjpeg62-turbo \
        libmemcached11 \
        libopenjp2-7 \
        libpng16-16 \
        libtiff6 \
        libwebp7 \
        libwebpmux3 \
        lighttpd \
    && mkdir -p /run/lighttpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

EXPOSE 80

RUN set -ex \
    && ln -sfT /dev/stderr "/var/log/lighttpd/error.log" \
    && ln -sfT /dev/stderr "/var/log/lighttpd/access.log" \
    && ln -sfT /dev/stderr "/var/log/iipsrv.log"
