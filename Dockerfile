FROM debian:stretch-slim

LABEL maintainer "Daiji Fukagawa <dfukagaw28@gmail.com>"

ENV PYTHONUNBUFFERED 1

#ENV IIPSRV_VERSION iipsrv-1.0
ENV IIPSRV_VERSION eb8602ae40ff03aadf6abdc9fb8ef0f54c71c577
ENV IIPSRV_SHA256 646afb9953619694115f050ec45d83cb28d4895a4d2a2415977fd63705ae1139
ENV IIPSRV_BUILD_DEPS \
        autoconf \
        automake \
        ca-certificates \
        curl \
        g++ \
        gawk \
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
        libtiff-dev \
    && cd /usr/local/src \
    && curl -sL -o iipsrv.tar.gz \
        https://github.com/ruven/iipsrv/archive/${IIPSRV_VERSION}.tar.gz \
    && echo ${IIPSRV_SHA256}  iipsrv.tar.gz | sha256sum -c \
    && tar zxf iipsrv.tar.gz
WORKDIR /usr/local/src/iipsrv-${IIPSRV_VERSION}
RUN set -ex \
    && ./autogen.sh \
    && ./configure --enable-openjpeg \
    && make
RUN set -ex \
    && cp src/iipsrv.fcgi /usr/local/bin/ \
#    && rm -rf /usr/local/src/iipsrv-${IIPSRV_VERSION} \
    && DEBIAN_FRONTEND=noninteractive apt-get purge -y $IIPSRV_BUILD_DEPS \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        lighttpd \
    && mkdir -p /var/run/lighttpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf

CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]

EXPOSE 80

RUN set -ex \
    && ln -sfT /dev/stderr "/var/log/lighttpd/error.log" \
    && ln -sfT /dev/stderr "/var/log/lighttpd/access.log" \
    && ln -sfT /dev/stderr "/var/log/iipsrv.log"
