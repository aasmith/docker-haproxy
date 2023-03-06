#!/bin/bash

set -eu

export OS=debian:bullseye-slim
export OPENSSL_VERSION=3.0.8
export OPENSSL_SHA256=6c13d2bf38fdf31eac3ce2a347073673f5d63263398f1f69d0df4a41253e4b3e

export PCRE2_VERSION=10.42
export PCRE2_SHA256=c33b418e3b936ee3153de2c61cc638e7e4fe3156022a5c77d0711bcbb9d64f1f

export HAPROXY_MAJOR=2.7
export HAPROXY_VERSION=2.7.2
export HAPROXY_SHA256=63bc6ec0302d0ebbe1fa769c19606640de834ac8cb07447b80799cb563dc0f3f

export LUA_VERSION=5.4.4
export LUA_MD5=bd8ce7069ff99a400efd14cf339a727b

# If not running in CI, then this won't be a real build that gets pushed
if [ -z "${CI-}" ]; then
  REALBUILD=
else
  REALBUILD=1
fi

if [ -n "$REALBUILD" ]; then
  echo "Real build, will be pushed to dockerhub."
  ACTION=push
else
  echo "Internal testing build"
  IMAGE_TAG=test
  ACTION=load
fi

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
    --provenance=false \
    --$ACTION \
    .

  if [ -n "$REALBUILD" ]; then
    docker manifest create "$MANIFEST_NAME" --amend "$IMAGE_NAME"
    docker manifest annotate --arch="$ARCH" --variant="$VARIANT" "$MANIFEST_NAME" "$IMAGE_NAME"
    docker manifest inspect "$MANIFEST_NAME"
  fi

done

echo "building native"

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
  --provenance=false \
  --$ACTION \
  .

if [ -n "$REALBUILD" ]; then
  docker manifest create "$MANIFEST_NAME" --amend "$IMAGE_NAME"
  docker manifest annotate --arch=$ARCH "$MANIFEST_NAME" "$IMAGE_NAME"
  docker manifest inspect "$MANIFEST_NAME"

  # Push the complete manifest

  docker manifest push "$MANIFEST_NAME"
  docker manifest inspect --verbose "$MANIFEST_NAME"
fi

