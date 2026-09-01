#!/usr/bin/env bash
# Installs the .deb scripts/build-deb.sh just produced and proves it
# actually works — not just that dpkg-buildpackage/lintian were happy with
# it. Runs in a *non-slim* debian:bookworm image, deliberately different
# from the -slim one build-deb.sh builds and lints in:
# /etc/dpkg/dpkg.cfg.d/docker in the slim variant path-excludes
# /usr/share/man/* and /usr/share/doc/* from every install, so `dpkg -i`/
# `dpkg -L` both report success and list those files as belonging to the
# package even when they never land on disk. Installing in the same -slim
# image the build already uses would pass even when a doc/man file silently
# never installed; the full image is what actually catches that.
#
# The same script runs from the pre-push hook, ci.yml, and release.yml's
# artefact job, right after build-deb.sh — the same single-source-of-truth
# reason build-deb.sh itself is one script rather than three copies of the
# same dpkg-buildpackage/lintian invocation.
set -euo pipefail

cd "$(dirname "$0")/.."

# Pinned by digest, not just tag — dependencies.md's rule for container
# images. Resolved from the manifest list for debian:bookworm (non-slim);
# bump by re-resolving the tag, not by hand-editing the hex.
IMAGE="debian:bookworm@sha256:6ebd97fa83deb272194a2cf015b3d26a4d538e9ad3a7a79d544c8af5b0a01443"

if ! compgen -G "dist/*.deb" >/dev/null; then
  echo "No .deb in dist/ — run scripts/build-deb.sh first." >&2
  exit 1
fi

# Every file debian/*.install ships, as an absolute installed path —
# <destdir>/<basename of source>. Read on the host: the install files are
# plain text, and the container only needs the resulting path list, not the
# repository's build tooling.
EXPECTED_FILES=""
for install_file in debian/*.install; do
  [ -e "$install_file" ] || continue
  while read -r src destdir; do
    [ -z "$src" ] && continue
    case "$src" in \#*) continue ;; esac
    EXPECTED_FILES="$EXPECTED_FILES /${destdir%/}/$(basename "$src")"
  done <"$install_file"
done

if [ -z "$EXPECTED_FILES" ]; then
  echo "No debian/*.install entries found — nothing to verify." >&2
  exit 1
fi

docker run --rm -v "$PWD/dist:/dist:ro" -e EXPECTED_FILES="$EXPECTED_FILES" "$IMAGE" bash -c '
  set -euo pipefail
  apt-get update
  # dpkg -i does not resolve dependencies; apt-get -f install afterwards
  # pulls in whatever it left unconfigured. This package currently declares
  # none, but the next one stamped from this template might.
  dpkg -i /dist/*.deb || apt-get install -y -f

  status=0
  for f in $EXPECTED_FILES; do
    # debhelper compresses man pages and changelogs (dh_compress) on
    # install, so the on-disk name can carry a .gz debhelper itself added —
    # check both.
    if [ -f "$f" ] || [ -f "$f.gz" ]; then
      echo "present: $f"
    else
      echo "MISSING on disk (dpkg thinks this installed, it did not): $f" >&2
      status=1
    fi
  done
  [ "$status" -eq 0 ] || exit 1

  # The package-specific smoke test: run the installed binary and check both
  # its exit code and its actual output, not just that the file exists.
  if [ -x /usr/bin/example ]; then
    output=$(/usr/bin/example)
    echo "output: $output"
    if [ "$output" != "Hello from the example package" ]; then
      echo "unexpected output from /usr/bin/example: $output" >&2
      exit 1
    fi
  fi
'

echo "Verified: installed package matches what debian/*.install shipped, and /usr/bin/example runs."
