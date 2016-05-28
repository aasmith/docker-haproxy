FROM debian:jessie

ENV HAPROXY_MAJOR 1.6
ENV HAPROXY_VERSION 1.6.4
ENV HAPROXY_MD5 ee107312ef58432859ee12bf048025ab

ENV LIBSLZ_VERSION v1.0.0
# No md5 for libslz yet -- the tarball is dynamically
# generated and it differs every time.

ENV PCRE_VERSION 8.38
ENV PCRE_MD5 8a353fe1450216b6655dfcf3561716d9

ENV LIBRESSL_VERSION 2.2.7
ENV LIBRESSL_MD5 6dd2cb36d4d60e24e26800759bc010b8

RUN buildDeps='curl gcc make file libc-dev' \
    set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y ${buildDeps} && \

    # SLZ

    curl -OJ "http://git.1wt.eu/web?p=libslz.git;a=snapshot;h=v1.0.0;sf=tgz" && \
    tar zxvf libslz-${LIBSLZ_VERSION}.tar.gz && \
    make -C libslz static && \

    # PCRE

    curl -OJ "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.gz" && \
    echo ${PCRE_MD5} pcre-${PCRE_VERSION}.tar.gz | md5sum -c && \
    tar zxvf pcre-${PCRE_VERSION}.tar.gz && \
    cd pcre-${PCRE_VERSION} && \

    CPPFLAGS="-D_FORTIFY_SOURCE=2" \
    LDFLAGS="-fPIE -pie -Wl,-z,relro -Wl,-z,now" \
    CFLAGS="-pthread -g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wall -fvisibility=hidden" \
    ./configure --prefix=/tmp/pcre --disable-shared --enable-utf8 --enable-jit --enable-unicode-properties --disable-cpp && \
    make install && \
    ./pcre_jit_test && \
    cd .. && \

    # LibreSSL

    curl -OJ http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz && \
    echo ${LIBRESSL_MD5} libressl-${LIBRESSL_VERSION}.tar.gz | md5sum -c && \
    tar zxvf libressl-${LIBRESSL_VERSION}.tar.gz && \
    cd libressl-${LIBRESSL_VERSION} && \
    ./configure --disable-shared --prefix=/tmp/libressl && \
    make check && \
    make install && \
    cd .. && \

    # HAProxy

    curl -OJL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" && \
    echo "${HAPROXY_MD5} haproxy-${HAPROXY_VERSION}.tar.gz" | md5sum -c && \
    tar zxvf haproxy-${HAPROXY_VERSION}.tar.gz && \
    make -C haproxy-${HAPROXY_VERSION} \
      TARGET=linux2628 \
      USE_SLZ=1 SLZ_INC=../libslz/src SLZ_LIB=../libslz \
      USE_STATIC_PCRE=1 USE_PCRE_JIT=1 PCREDIR=/tmp/pcre \
      USE_OPENSSL=1 SSL_INC=/tmp/libressl/include SSL_LIB=/tmp/libressl/lib \
      all \
      install-bin && \
    mkdir -p /usr/local/etc/haproxy && \
    cp -R haproxy-${HAPROXY_VERSION}/examples/errorfiles /usr/local/etc/haproxy/errors && \

    # Clean up
    rm -rf /var/lib/apt/lists/* /tmp/* haproxy* pcre* libressl* libslz* && \
    apt-get purge -y --auto-remove ${buildDeps}


CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
