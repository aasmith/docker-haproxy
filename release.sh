#!/bin/bash

# Automates the production of each release.

#
# Given a range of haproxy versions, for each version:
#
#  * Determine the SHA256 hash of the version
#  * Run build.sh with this SHA and version specified
#  * Run haproxy -v for each platform to verify success
#  * Tag and commit (but no push)
#

# TODO: do the same for deps, i.e. openssl, pcre2, lua.

# Usage: release.sh 2.7 4 8

if [ $# != 3 ]; then
  >&2 echo "usage: $0 <major> <start-version> <end-version>"
  exit 1
fi

MAJOR=$1
VERSION_FROM=$2
VERSION_TO=$3
DOCKER_PLATFORMS="arm64 amd64"

if [[ "$(git branch --show-current)" != "$MAJOR" ]]; then
  >&2 echo "major version and branch name don't match. wrong branch?"
  exit 1
fi

set -euo pipefail

for v in $(seq "$VERSION_FROM" "$VERSION_TO"); do
  echo "Running release for $MAJOR.$v"

  sha=$(curl -JLSs "https://www.haproxy.org/download/$MAJOR/src/haproxy-$MAJOR.$v.tar.gz" | sha256sum | awk '{print $1}')

  echo ./build.sh "$MAJOR" "$MAJOR.$v" "$sha" > current-version
  ./build.sh "$MAJOR" "$MAJOR.$v" "$sha"

  # Verify
  for platform in $DOCKER_PLATFORMS; do
    docker run --rm "aasmith/haproxy:test-$platform" haproxy -v | grep "$MAJOR.$v" || (echo "failure determining build success for $MAJOR.$v / $platform"; exit 1)
  done

  # Commit and tag
  git add current-version
  git commit -m "Update to $MAJOR.$v."
  git tag "$MAJOR.$v"

done
