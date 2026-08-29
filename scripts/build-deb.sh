#!/usr/bin/env bash
# Builds the .deb inside the pinned Debian container this scaffold ships, and
# lints the result with lintian. The same script runs from the pre-push hook,
# ci.yml, and release.yml's artefact job, so the three cannot end up building
# — or lintian-checking — against a different image.
#
# The container never gets the repository mounted as its own source
# directory: dpkg-buildpackage always writes the .deb one level *up* from
# wherever it's invoked, so building straight from a bind mount would try to
# write outside it. A copy inside the container's own filesystem sidesteps
# that, and the result is copied back out at the end.
set -euo pipefail

cd "$(dirname "$0")/.."

# Pinned by digest, not just tag — dependencies.md's rule for container
# images. Resolved from the manifest list for debian:bookworm-slim; bump by
# re-resolving the tag, not by hand-editing the hex.
IMAGE="debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171"

mkdir -p dist

docker run --rm -v "$PWD:/host" -w /host "$IMAGE" bash -c '
  set -euxo pipefail
  apt-get update
  apt-get install -y --no-install-recommends build-essential devscripts debhelper lintian
  rm -rf /tmp/src
  cp -r /host /tmp/src
  cd /tmp/src
  dpkg-buildpackage -us -uc -b
  lintian /tmp/*.deb
  cp /tmp/*.deb /host/dist/
'

echo "Built:"
ls -1 dist/*.deb
