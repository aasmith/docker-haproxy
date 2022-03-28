#!/bin/bash

set -eu

export OS=debian:bullseye-slim
export OPENSSL_VERSION=1.1.1n
export OPENSSL_SHA256=40dceb51a4f6a5275bde0e6bf20ef4b91bfc32ed57c0552e2e8e15463372b17a

export PCRE2_VERSION=10.39
export PCRE2_SHA256=0781bd2536ef5279b1943471fdcdbd9961a2845e1d2c9ad849b9bd98ba1a9bd4

export HAPROXY_MAJOR=2.4
export HAPROXY_VERSION=2.4.10
export HAPROXY_SHA256=4838dcc961a4544ef2d1e1aa7a7624cffdc4dda731d9cb66e46114819a3b1c5c

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

