#!/bin/bash

set -eu

export OPENSSL_VERSION=1.1.1l
export OPENSSL_SHA256=0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1

export PCRE2_VERSION=10.37
export PCRE2_SHA256=04e214c0c40a97b8a5c2b4ae88a3aa8a93e6f2e45c6b3534ddac351f26548577

export HAPROXY_MAJOR=2.4
export HAPROXY_VERSION=2.4.7
export HAPROXY_SHA256=52af97f72f22ffd8a7a995fafc696291d37818feda50a23caef7dc0622421845

export LUA_VERSION=5.4.3
export LUA_MD5=ef63ed2ecfb713646a7fcc583cf5f352

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

