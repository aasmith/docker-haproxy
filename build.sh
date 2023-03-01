#!/bin/bash

set -eu

export OS=debian:bullseye-slim
export OPENSSL_VERSION=1.1.1t
export OPENSSL_SHA256=8dee9b24bdb1dcbf0c3d1e9b02fb8f6bf22165e807f45adeb7c9677536859d3b

export PCRE2_VERSION=10.42
export PCRE2_SHA256=c33b418e3b936ee3153de2c61cc638e7e4fe3156022a5c77d0711bcbb9d64f1f

export HAPROXY_MAJOR=2.5
export HAPROXY_VERSION=2.5.5
export HAPROXY_SHA256=063c4845cdb2d76f292ef44d9c0117a853d8d10ae5d9615b406b14a4d74fe4b9

export LUA_VERSION=5.4.4
export LUA_MD5=bd8ce7069ff99a400efd14cf339a727b

BASE=aasmith/haproxy
MANIFEST_NAME=$BASE:$IMAGE_TAG

echo "Preparing manifest '$MANIFEST_NAME'"

# Build images that require cross-compliation

for buildspec in buildspec.*; do

  set -o allexport
  source "$buildspec"
  set +o allexport

  IMAGE_NAME=$BASE:$IMAGE_TAG-$ARCH$VARIANT

  echo "Building $buildspec as '$IMAGE_NAME'..."

  docker buildx build -f Dockerfile.multiarch -t "$IMAGE_NAME" \
    --build-arg OS \
    --build-arg OPENSSL_VERSION \
    --build-arg OPENSSL_SHA256 \
    --build-arg PCRE2_VERSION \
    --build-arg PCRE2_SHA256 \
    --build-arg LUA_VERSION \
    --build-arg LUA_MD5 \
    --build-arg HAPROXY_MAJOR \
    --build-arg HAPROXY_VERSION \
    --build-arg HAPROXY_SHA256 \
    --build-arg ARCH \
    --build-arg ARCH_FLAGS \
    --build-arg TOOLCHAIN \
    --build-arg OPENSSL_TARGET \
    --push \
    .

  docker manifest create "$MANIFEST_NAME" --amend "$IMAGE_NAME"
  docker manifest annotate --arch="$ARCH" --variant="$VARIANT" "$MANIFEST_NAME" "$IMAGE_NAME"
  docker manifest inspect "$MANIFEST_NAME"

done

# Build "native" amd64 image

ARCH=amd64
IMAGE_NAME=$BASE:$IMAGE_TAG-$ARCH

echo "Building '$IMAGE_NAME'..."

docker buildx build -f Dockerfile -t "$IMAGE_NAME" \
  --build-arg OS \
  --build-arg OPENSSL_VERSION \
  --build-arg OPENSSL_SHA256 \
  --build-arg PCRE2_VERSION \
  --build-arg PCRE2_SHA256 \
  --build-arg LUA_VERSION \
  --build-arg LUA_MD5 \
  --build-arg HAPROXY_MAJOR \
  --build-arg HAPROXY_VERSION \
  --build-arg HAPROXY_SHA256 \
  --push \
  .

docker manifest create "$MANIFEST_NAME" --amend "$IMAGE_NAME"
docker manifest annotate --arch=$ARCH "$MANIFEST_NAME" "$IMAGE_NAME"
docker manifest inspect "$MANIFEST_NAME"

# Push the complete manifest

docker manifest push "$MANIFEST_NAME"
docker manifest inspect --verbose "$MANIFEST_NAME"

