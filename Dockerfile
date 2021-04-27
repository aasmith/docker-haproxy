ARG OS=debian:buster-slim

ARG OPENSSL_VERSION=1.1.1k
ARG OPENSSL_SHA256=892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5

ARG PCRE2_VERSION=10.36
ARG PCRE2_SHA256=b95ddb9414f91a967a887d69617059fb672b914f56fa3d613812c1ee8e8a1a37

ARG HAPROXY_MAJOR=2.4
ARG HAPROXY_VERSION=2.4-dev17
ARG HAPROXY_SHA256=045cf3fd29394550dc073090a2b171816aa804323a336435a840977eb6435d87

ARG LUA_VERSION=5.4.2
ARG LUA_MD5=49c92d6a49faba342c35c52e1ac3f81e

### Runtime -- the base image for all others

FROM $OS as runtime

RUN apt-get update && \
    apt-get install --no-install-recommends -y curl ca-certificates


### Builder -- adds common utils needed for all build images

FROM runtime as builder

RUN apt-get update && \
    apt-get install --no-install-recommends -y gcc make file libc6-dev perl libtext-template-perl libreadline-dev


### OpenSSL

FROM builder as ssl

ARG OPENSSL_VERSION
ARG OPENSSL_SHA256

RUN curl -OJ https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    echo ${OPENSSL_SHA256} openssl-${OPENSSL_VERSION}.tar.gz | sha256sum -c && \
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config no-shared --prefix=/tmp/openssl --openssldir=/tmp/openssl && \
    make && \
    make test && \
    make install_sw


### PCRE2

FROM builder as pcre2

ARG PCRE2_VERSION
ARG PCRE2_SHA256

RUN curl -OJ "https://ftp.pcre.org/pub/pcre/pcre2-${PCRE2_VERSION}.tar.gz" && \
    echo ${PCRE2_SHA256} pcre2-${PCRE2_VERSION}.tar.gz | sha256sum -c && \
    tar zxvf pcre2-${PCRE2_VERSION}.tar.gz && \
    cd pcre2-${PCRE2_VERSION} && \
    LDFLAGS="-fPIE -pie -Wl,-z,relro -Wl,-z,now" \
    CFLAGS="-pthread -g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wall -fvisibility=hidden" \
    ./configure --prefix=/tmp/pcre2 --disable-shared --enable-utf8 --enable-jit --enable-unicode-properties --disable-cpp && \
    make check && \
    make install


# Lua

FROM builder as lua

ARG LUA_VERSION
ARG LUA_MD5

RUN curl -OJ "http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz" && \
    echo "${LUA_MD5} lua-${LUA_VERSION}.tar.gz" | md5sum -c && \
    tar zxf lua-${LUA_VERSION}.tar.gz && \
    cd lua-${LUA_VERSION} && \
    make linux && \
    make install INSTALL_TOP=/tmp/lua

### HAProxy

FROM builder as haproxy

COPY --from=ssl   /tmp/openssl /tmp/openssl
COPY --from=pcre2 /tmp/pcre2   /tmp/pcre2

COPY --from=lua   /tmp/lua/bin     /usr/local/bin
COPY --from=lua   /tmp/lua/include /usr/local/include
COPY --from=lua   /tmp/lua/lib     /usr/local/lib

ARG HAPROXY_MAJOR
ARG HAPROXY_VERSION
ARG HAPROXY_SHA256

RUN curl -OJL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/devel/haproxy-${HAPROXY_VERSION}.tar.gz" && \
    echo "${HAPROXY_SHA256} haproxy-${HAPROXY_VERSION}.tar.gz" | sha256sum -c && \
    tar zxvf haproxy-${HAPROXY_VERSION}.tar.gz && \
    make -C haproxy-${HAPROXY_VERSION} \
      TARGET=linux-glibc ARCH=x86_64 \
      USE_SLZ=1 \
      USE_STATIC_PCRE2=1 USE_PCRE2_JIT=1 PCRE2DIR=/tmp/pcre2 \
      USE_OPENSSL=1 SSL_INC=/tmp/openssl/include SSL_LIB=/tmp/openssl/lib \
      USE_LUA=1 \
      USE_PROMEX=1 \
      DESTDIR=/tmp/haproxy PREFIX= \
      all \
      install-bin && \
    mkdir -p /tmp/haproxy/etc/haproxy && \
    cp -R haproxy-${HAPROXY_VERSION}/examples/errorfiles /tmp/haproxy/etc/haproxy/errors


### HAProxy runtime image

FROM runtime

COPY --from=haproxy /tmp/haproxy /usr/local/

RUN rm -rf /var/lib/apt/lists/*

CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
