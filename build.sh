#!/bin/bash

set -e

export OPENSSL_VERSION=1.1.1k
export OPENSSL_SHA256=892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5

export PCRE2_VERSION=10.36
export PCRE2_SHA256=b95ddb9414f91a967a887d69617059fb672b914f56fa3d613812c1ee8e8a1a37

export HAPROXY_MAJOR=2.4
export HAPROXY_VERSION=2.4-dev17
export HAPROXY_SHA256=045cf3fd29394550dc073090a2b171816aa804323a336435a840977eb6435d87

export LUA_VERSION=5.4.2
export LUA_MD5=49c92d6a49faba342c35c52e1ac3f81e

BASE=aasmith/haproxy
MANIFEST_NAME=$BASE:$HAPROXY_VERSION

# Build images that require cross-compliation

for buildspec in buildspec.*; do

  set -o allexport
  source "$buildspec"
  set +o allexport

  echo "Building $buildspec..."

  IMAGE_NAME=$BASE:$HAPROXY_VERSION-$ARCH$VARIANT

  docker build -f Dockerfile.multiarch -t $IMAGE_NAME \
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
    .

  docker push $IMAGE_NAME
  docker manifest create $MANIFEST_NAME --amend $IMAGE_NAME
  docker manifest annotate --arch=$ARCH --variant=$VARIANT $MANIFEST_NAME $IMAGE_NAME
  docker manifest inspect $MANIFEST_NAME

done

# Build "native" amd64 image

ARCH=amd64
IMAGE_NAME=$BASE:$HAPROXY_VERSION-$ARCH

docker build -f Dockerfile -t $IMAGE_NAME \
  --build-arg OPENSSL_VERSION \
  --build-arg OPENSSL_SHA256 \
  --build-arg PCRE2_VERSION \
  --build-arg PCRE2_SHA256 \
  --build-arg LUA_VERSION \
  --build-arg LUA_MD5 \
  --build-arg HAPROXY_MAJOR \
  --build-arg HAPROXY_VERSION \
  --build-arg HAPROXY_SHA256 \
  .

docker push $IMAGE_NAME
docker manifest create $MANIFEST_NAME --amend $IMAGE_NAME
docker manifest annotate --arch=$ARCH $MANIFEST_NAME $IMAGE_NAME
docker manifest inspect $MANIFEST_NAME

# Push the complete manifest

docker manifest push $MANIFEST_NAME
docker manifest inspect --verbose $MANIFEST_NAME

