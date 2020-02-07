# aasmith/docker-haproxy
HAProxy + *LUA* compiled against newer/faster libraries (PCRE w/ JIT, SLZ, and LibreSSL).

This haproxy docker image uses statically-linked modern libraries where
possible. Otherwise, it attempts to follow the official docker image as
closely as possible. Substitute the image name where needed, as in the example
below.

## Available Versions

For a complete list of docker tags you can use, see: https://hub.docker.com/r/aasmith/haproxy/tags/

### Branches

[2.0](https://github.com/aasmith/docker-haproxy/tree/2.0) |
[1.9](https://github.com/aasmith/docker-haproxy/tree/1.9) |
[1.8](https://github.com/aasmith/docker-haproxy/tree/1.8) |
[1.7](https://github.com/aasmith/docker-haproxy/tree/1.7) |
[1.6](https://github.com/aasmith/docker-haproxy/tree/1.6) |
--- | --- | --- | --- | ---

## Usage

Example `Dockerfile`:

```Dockerfile
FROM aasmith/haproxy
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
```

To pin to a specific version, use the branch or tag:

```
FROM aasmith/haproxy:1.8 # stay on the latest the 1.8 line
```

```
FROM aasmith/haproxy:1.8.0 # use exactly 1.8.0
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

