#!/bin/bash

if [ $# != 3 ]; then
    >&2 echo "usage: $0 <major> <version> <sha256>"
    exit 1
fi

set -eu
shopt -s extglob

export OS=debian:bookworm-slim
export AWS_LC_VERSION=v1.66.2
export AWS_LC_SHA256=d64a46b4f75fa5362da412f1e96ff5b77eed76b3a95685651f81a558c5c9e126

export PCRE2_VERSION=10.47
export PCRE2_SHA256=c08ae2388ef333e8403e670ad70c0a11f1eed021fd88308d7e02f596fcd9dc16

# See the 'current-version' file for values used for the current build and to reproduce.
export HAPROXY_MAJOR=$1
export HAPROXY_VERSION=$2
export HAPROXY_SHA256=$3

export LUA_VERSION=5.4.7
export LUA_MD5=fc3f3291353bbe6ee6dec85ee61331e8

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

echo "Builder is an $(uname -m)"

case "$(uname -m)" in
	arm64)
		CROSS_SPECS=buildspec.!(aarch64)
		NATIVE_DOCKER_ARCH=arm64
		;;
	x86_64)
		CROSS_SPECS=buildspec.!(x86_64)
		NATIVE_DOCKER_ARCH=amd64
		;;
	*)
		echo "unknown arch"
		exit 1
		;;
esac

for buildspec in $CROSS_SPECS; do

  set -o allexport
  source "$buildspec"
  set +o allexport

  IMAGE_NAME=$BASE:$IMAGE_TAG-$ARCH$VARIANT

  echo "Building $buildspec as '$IMAGE_NAME'..."

  docker buildx build -f Dockerfile.multiarch -t "$IMAGE_NAME" \
    --build-arg OS \
    --build-arg AWS_LC_VERSION \
    --build-arg AWS_LC_SHA256 \
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
    --build-arg TOOLCHAIN_PREFIX \
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

IMAGE_NAME=$BASE:$IMAGE_TAG-$NATIVE_DOCKER_ARCH

echo "Building '$IMAGE_NAME'..."

docker buildx build -f Dockerfile.native -t "$IMAGE_NAME" \
  --build-arg OS \
  --build-arg AWS_LC_VERSION \
  --build-arg AWS_LC_SHA256 \
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
  docker manifest annotate --arch=$NATIVE_DOCKER_ARCH "$MANIFEST_NAME" "$IMAGE_NAME"
  docker manifest inspect "$MANIFEST_NAME"

  # Push the complete manifest

  docker manifest push "$MANIFEST_NAME"
  docker manifest inspect --verbose "$MANIFEST_NAME"
fi

