# aasmith/docker-haproxy
HAProxy + LUA + Prometheus Exporter compiled for x86-64 and ARM64

This haproxy docker image uses statically-linked modern libraries where
possible. Otherwise, it attempts to follow the official docker image as
closely as possible. Substitute the image name where needed, as in the example
below.

## aarch64 / ARM64 v8.2+ Support

The ARM64v8 version of the image is compiled specifically for ARM v8.2 and
above in order to make use of atomic processor optimizations, something that
HAProxy takes advantage of.

ARM64v8.2 compatible processors include AWS "Gravition2" processors, and the
Apple M1.

## Available Versions

For a complete list of docker tags you can use, see the list of tags provided by
[GitHub](https://github.com/aasmith/docker-haproxy/tags), or
[DockerHub](https://hub.docker.com/r/aasmith/haproxy/tags).

## Usage

Example showing the compilation flags and features:

```
docker run -it --rm aasmith/haproxy:2.6.9 haproxy -vv
```

### Multi-arch support

Docker should select the correct architecture for the current machine. If it
does not, or if you want to try a specific architecture, append the architecture
to the tag name, for instance:

```
docker run -it --rm aasmith/haproxy:2.6.9-arm64v8 haproxy -vv
```

Supported architecture labels are `amd64` and `arm64v8`, since versions 2.3.10, and 2.4.0.

### Basic example

Example `Dockerfile`:

```Dockerfile
FROM aasmith/haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

To pin to a specific version, use the branch or tag:

```
FROM aasmith/haproxy:2.6 # stay on the latest the 2.6 line
```

```
FROM aasmith/haproxy:2.6.9 # use exactly 2.6.9
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

Output from `haproxy -vv` for each architecture:

### amd64

```
HAProxy version 2.6.9-3a3700a 2023/02/14 - https://haproxy.org/
Status: long-term supported branch - will stop receiving fixes around Q2 2027.
Known bugs: http://www.haproxy.org/bugs/bugs-2.6.9.html
Running on: Linux 5.10.25-linuxkit #1 SMP Tue Mar 23 09:27:39 UTC 2021 x86_64
Build options :
  TARGET  = linux-glibc
  CPU     = generic
  CC      = cc
  CFLAGS  = -m64 -march=x86-64 -O2 -g -Wall -Wextra -Wundef -Wdeclaration-after-statement -Wfatal-errors -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference -fwrapv -Wno-address-of-packed-member -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-cast-function-type -Wno-string-plus-int -Wno-atomic-alignment
  OPTIONS = USE_PCRE2_JIT=1 USE_STATIC_PCRE2=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1 USE_PROMEX=1
  DEBUG   = -DDEBUG_STRICT -DDEBUG_MEMORY_POOLS

Feature list : -51DEGREES +ACCEPT4 +BACKTRACE -CLOSEFROM +CPU_AFFINITY +CRYPT_H -DEVICEATLAS +DL -ENGINE +EPOLL -EVPORTS +GETADDRINFO -KQUEUE +LIBCRYPT +LINUX_SPLICE +LINUX_TPROXY +LUA -MEMORY_PROFILING +NETFILTER +NS -OBSOLETE_LINKER +OPENSSL -OT -PCRE -PCRE2 +PCRE2_JIT -PCRE_JIT +POLL +PRCTL -PROCCTL +PROMEX -QUIC +RT +SLZ -STATIC_PCRE +STATIC_PCRE2 -SYSTEMD +TFO +THREAD +THREAD_DUMP +TPROXY -WURFL -ZLIB

Default settings :
  bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Built with multi-threading support (MAX_THREADS=64, default=4).
Built with OpenSSL version : OpenSSL 3.0.8 7 Feb 2023
Running on OpenSSL version : OpenSSL 3.0.8 7 Feb 2023
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports : TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3
OpenSSL providers loaded : default
Built with Lua version : Lua 5.4.4
Built with the Prometheus exporter as a service
Built with network namespace support.
Support for malloc_trim() is enabled.
Built with libslz for stateless compression.
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND
Built with PCRE2 version : 10.42 2022-12-11
PCRE2 library supports JIT : yes
Encrypted password support via crypt(3): yes
Built with gcc compiler version 10.2.1 20210110

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available multiplexer protocols :
(protocols marked as <default> cannot be specified using 'proto' keyword)
         h2 : mode=HTTP  side=FE|BE  mux=H2    flags=HTX|HOL_RISK|NO_UPG
       fcgi : mode=HTTP  side=BE     mux=FCGI  flags=HTX|HOL_RISK|NO_UPG
  <default> : mode=HTTP  side=FE|BE  mux=H1    flags=HTX
         h1 : mode=HTTP  side=FE|BE  mux=H1    flags=HTX|NO_UPG
  <default> : mode=TCP   side=FE|BE  mux=PASS  flags=
       none : mode=TCP   side=FE|BE  mux=PASS  flags=NO_UPG

Available services : prometheus-exporter
Available filters :
	[CACHE] cache
	[COMP] compression
	[FCGI] fcgi-app
	[SPOE] spoe
	[TRACE] trace

```

### arm64v8

```
HAProxy version 2.6.9-3a3700a 2023/02/14 - https://haproxy.org/
Status: long-term supported branch - will stop receiving fixes around Q2 2027.
Known bugs: http://www.haproxy.org/bugs/bugs-2.6.9.html
Running on: Linux 5.10.25-linuxkit #1 SMP Tue Mar 23 09:27:39 UTC 2021 aarch64
Build options :
  TARGET  = linux-glibc
  CPU     = generic
  CC      = /usr/bin/aarch64-linux-gnu-gcc-10
  CFLAGS  = -march=armv8.2-a+fp16+rcpc+dotprod+crypto -O2 -g -Wall -Wextra -Wundef -Wdeclaration-after-statement -Wfatal-errors -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference -fwrapv -Wno-address-of-packed-member -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-cast-function-type -Wno-string-plus-int -Wno-atomic-alignment
  OPTIONS = USE_PCRE2_JIT=1 USE_STATIC_PCRE2=1 USE_OPENSSL=1 USE_LUA=1 USE_SLZ=1 USE_PROMEX=1
  DEBUG   = -DDEBUG_STRICT -DDEBUG_MEMORY_POOLS

Feature list : -51DEGREES +ACCEPT4 +BACKTRACE -CLOSEFROM +CPU_AFFINITY +CRYPT_H -DEVICEATLAS +DL -ENGINE +EPOLL -EVPORTS +GETADDRINFO -KQUEUE +LIBCRYPT +LINUX_SPLICE +LINUX_TPROXY +LUA -MEMORY_PROFILING +NETFILTER +NS -OBSOLETE_LINKER +OPENSSL -OT -PCRE -PCRE2 +PCRE2_JIT -PCRE_JIT +POLL +PRCTL -PROCCTL +PROMEX -QUIC +RT +SLZ -STATIC_PCRE +STATIC_PCRE2 -SYSTEMD +TFO +THREAD +THREAD_DUMP +TPROXY -WURFL -ZLIB

Default settings :
  bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Built with multi-threading support (MAX_THREADS=64, default=4).
Built with OpenSSL version : OpenSSL 3.0.8 7 Feb 2023
Running on OpenSSL version : OpenSSL 3.0.8 7 Feb 2023
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports : TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3
OpenSSL providers loaded : default
Built with Lua version : Lua 5.4.4
Built with the Prometheus exporter as a service
Built with network namespace support.
Support for malloc_trim() is enabled.
Built with libslz for stateless compression.
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND
Built with PCRE2 version : 10.42 2022-12-11
PCRE2 library supports JIT : yes
Encrypted password support via crypt(3): yes
Built with gcc compiler version 10.2.1 20210110

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available multiplexer protocols :
(protocols marked as <default> cannot be specified using 'proto' keyword)
         h2 : mode=HTTP  side=FE|BE  mux=H2    flags=HTX|HOL_RISK|NO_UPG
       fcgi : mode=HTTP  side=BE     mux=FCGI  flags=HTX|HOL_RISK|NO_UPG
  <default> : mode=HTTP  side=FE|BE  mux=H1    flags=HTX
         h1 : mode=HTTP  side=FE|BE  mux=H1    flags=HTX|NO_UPG
  <default> : mode=TCP   side=FE|BE  mux=PASS  flags=
       none : mode=TCP   side=FE|BE  mux=PASS  flags=NO_UPG

Available services : prometheus-exporter
Available filters :
	[CACHE] cache
	[COMP] compression
	[FCGI] fcgi-app
	[SPOE] spoe
	[TRACE] trace

```
