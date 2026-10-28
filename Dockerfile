FROM debian:13-slim AS build

ENV IIPSRV_BUILD_DEPS="\
        autoconf \
        automake \
        ca-certificates \
        curl \
        g++ \
        gawk \
        git \
        libtool \
        make \
        pkg-config"

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        $IIPSRV_BUILD_DEPS \
        libavif-dev \
        libfcgi-dev \
        libjpeg-dev \
        libmemcached-dev \
        libopenjp2-7-dev \
        libpng-dev \
        libtiff-dev \
        libwebp-dev

ARG IIPSRV_VERSION=1.3

RUN set -ex \
    && git clone https://github.com/ruven/iipsrv /usr/local/src/iipsrv -b iipsrv-${IIPSRV_VERSION} --depth 1

WORKDIR /usr/local/src/iipsrv

RUN set -ex \
    && ./autogen.sh \
    && ./configure --enable-openjpeg \
    && make


FROM debian:13-slim

LABEL org.opencontainers.image.source=https://github.com/dfukagaw28/docker-iipsrv

COPY --from=build /usr/local/src/iipsrv/src/iipsrv.fcgi /usr/local/bin/iipsrv.fcgi

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libavif16 \
        libfcgi0t64 \
        libgomp1 \
        libjpeg62-turbo \
        libmemcached11t64 \
        libopenjp2-7 \
        libpng16-16t64 \
        libtiff6 \
        libwebp7 \
        libwebpmux3 \
        lighttpd \
        media-types \
    && mkdir -p /run/lighttpd \
    && chown www-data:www-data /run/lighttpd \
    && usermod -aG tty www-data \
    && rm -f /etc/lighttpd/conf-enabled/99-unconfigured.conf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

EXPOSE 80

RUN set -ex \
    && ln -sfT /dev/stderr "/var/log/lighttpd/error.log" \
    && ln -sfT /dev/stderr "/var/log/lighttpd/access.log" \
    && ln -sfT /dev/stderr "/var/log/iipsrv.log"
