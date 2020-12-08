# aasmith/docker-haproxy
HAProxy + *LUA* compiled against newer/faster libraries (PCRE w/ JIT, SLZ, OpenSSL).

This haproxy docker image uses statically-linked modern libraries where
possible. Otherwise, it attempts to follow the official docker image as
closely as possible. Substitute the image name where needed, as in the example
below.

## Available Versions

For a complete list of docker tags you can use, see the list of tags provided by
[GitHub](https://github.com/aasmith/docker-haproxy/tags), or
[DockerHub](https://hub.docker.com/r/aasmith/haproxy/tags).



## Usage

Display the HAProxy version from the CLI:

```
docker run -it --rm aasmith/haproxy:2.3.2 haproxy -vv
```

Example `Dockerfile`:

```Dockerfile
FROM aasmith/haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

To pin to a specific version, use the branch or tag:

```
FROM aasmith/haproxy:2.3 # stay on the latest the 2.3 line
```

```
FROM aasmith/haproxy:2.3.2 # use exactly 2.3.2
```

## Libraries

### Lua

Since HAProxy 1.6, [Lua support][4] has been available for adding in extra features
that do not require re-compilation, or knowledge of C.

[4]: http://blog.haproxy.com/2015/03/12/haproxy-1-6-dev1-and-lua/

### PCRE

Enables PCRE JIT compilation for faster regular expression parsing. The [PCRE
Peformance Project][0] has more information on benchmarks, etc.

Compilation follows as close as possible to the [debian package][1], excluding
C++ support and dynamic linking.

[0]: http://sljit.sourceforge.net/pcre.html
[1]: https://buildd.debian.org/status/fetch.php?pkg=pcre3&arch=i386&ver=2%3A8.35-3.3%2Bdeb8u2&stamp=1452484092

### Stateless Zip (SLZ)

Created by the HAProxy maintainer, SLZ is a stream compressor for producing
gzip-compatible output. It has lower memory usage, no dictionary persistence,
and runs about 3x faster than zlib.

See the [Stateless Zip project][2] for background, benchmarks, etc.

[2]: http://1wt.eu/projects/libslz/

### Prometheus

[Prometheus exporter functionality](http://git.haproxy.org/?p=haproxy-2.0.git;a=blob_plain;f=contrib/prometheus-exporter/README;hb=HEAD) is compiled in by default from version 2.0.5 onwards.

## Compilation Details

Output from `haproxy -vv`:

```
HA-Proxy version 2.2.6-3709bd4 2020/11/30 - https://haproxy.org/
Status: long-term supported branch - will stop receiving fixes around Q2 2025.
Known bugs: http://www.haproxy.org/bugs/bugs-2.2.6.html
Running on: Linux 4.9.184-linuxkit #1 SMP Tue Jul 2 22:58:16 UTC 2019 x86_64
Build options :
  TARGET  = linux-glibc
  CPU     = generic
  CC      = gcc
  CFLAGS  = -m64 -march=x86-64 -O2 -g -Wall -Wextra -Wdeclaration-after-statement -fwrapv -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-stringop-overflow -Wno-cast-function-type -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference
  OPTIONS = USE_PCRE2_JIT=1 USE_STATIC_PCRE2=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1
  DEBUG   = 

Feature list : +EPOLL -KQUEUE +NETFILTER -PCRE -PCRE_JIT -PCRE2 +PCRE2_JIT +POLL -PRIVATE_CACHE +THREAD -PTHREAD_PSHARED +BACKTRACE -STATIC_PCRE +STATIC_PCRE2 +TPROXY +LINUX_TPROXY +LINUX_SPLICE +LIBCRYPT +CRYPT_H +GETADDRINFO +OPENSSL +LUA +FUTEX +ACCEPT4 -CLOSEFROM -ZLIB +SLZ +CPU_AFFINITY +TFO +NS +DL +RT -DEVICEATLAS -51DEGREES -WURFL -SYSTEMD -OBSOLETE_LINKER +PRCTL +THREAD_DUMP -EVPORTS

Default settings :
  bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Built with multi-threading support (MAX_THREADS=64, default=4).
Built with OpenSSL version : OpenSSL 1.1.1i  8 Dec 2020
Running on OpenSSL version : OpenSSL 1.1.1i  8 Dec 2020
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports : TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3
Built with Lua version : Lua 5.4.2
Built with network namespace support.
Built with libslz for stateless compression.
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND
Built with PCRE2 version : 10.36 2020-12-04
PCRE2 library supports JIT : yes
Encrypted password support via crypt(3): yes
Built with gcc compiler version 8.3.0
Built with the Prometheus exporter as a service

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available multiplexer protocols :
(protocols marked as <default> cannot be specified using 'proto' keyword)
            fcgi : mode=HTTP       side=BE        mux=FCGI
       <default> : mode=HTTP       side=FE|BE     mux=H1
              h2 : mode=HTTP       side=FE|BE     mux=H2
       <default> : mode=TCP        side=FE|BE     mux=PASS

Available services :
	prometheus-exporter

Available filters :
	[SPOE] spoe
	[COMP] compression
	[TRACE] trace
	[CACHE] cache
	[FCGI] fcgi-app

```
