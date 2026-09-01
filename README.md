# scaffold-deb-package

[![CI](https://github.com/alrayyes/scaffold-deb-package/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/alrayyes/scaffold-deb-package/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/alrayyes/scaffold-deb-package?sort=semver)](https://github.com/alrayyes/scaffold-deb-package/releases/latest)
[![licence](https://img.shields.io/badge/licence-unlicensed-lightgrey)](LICENSE)

A GitHub template for packaging a project as a Debian (`.deb`) package. Run
`gh repo create my-real-project --template alrayyes/scaffold-deb-package`
and you get a real, working `debian/` directory — not stubs — plus pinned
tooling, prose linting, secret scanning, and release automation already
wired in, rather than a blank directory and a checklist to work through by
hand.

It isn't a real package on its own. The placeholder it ships, `example`,
installs one trivial script to `/usr/bin/example` so the whole chain — the
`debian/` metadata, the pinned build container, `lintian`, the hooks, CI —
has something real to build and lint against. Replace it with your actual
project and delete this paragraph.

## Adapting this template

1. Rename every `example` under `debian/` (`debian/example.install`, and
   every mention inside `debian/control`, `debian/changelog`,
   `debian/copyright`) to your real package name, and replace `src/` with
   whatever your project actually installs — update
   `debian/example.install`'s source/destination lines to match.
2. Fill in `debian/control`'s `Maintainer`, `Homepage`, and `Description`
   fields, and its `Build-Depends` if your package needs more than
   `debhelper-compat (= 13)` to build.
3. Replace `debian/copyright`'s placeholder `License` stanzas with your
   real licence — a DEP-5 short-name (`MIT`, `Apache-2.0`,
   `GPL-3.0-or-later`, …) if it's a standard one, or the licence's own text
   otherwise. Do the same for the top-level [`LICENSE`](LICENSE) file and
   this README's [Licence](#licence) section — those are a separate
   placeholder from `debian/copyright`'s, and both need replacing.
4. If your project has a real upstream release process — source tarballs
   published independently of the Debian packaging that wraps them — switch
   `debian/source/format` from `3.0 (native)` to `3.0 (quilt)` and set up an
   orig tarball and a `debian/patches/` directory. Native format assumes the
   packaging and the project are the same source tree with no separation
   between them, which is right for a project that only ever ships as a
   `.deb` and wrong for one with its own release cadence.
5. Re-resolve `scripts/build-deb.sh`'s pinned `debian:bookworm-slim` digest
   and `scripts/verify-deb.sh`'s pinned `debian:bookworm` digest if you want
   a different Debian release as the build/install environment — the two
   have to move together.

## Building, linting, and install-testing locally

```sh
git clone https://github.com/alrayyes/scaffold-deb-package.git
cd scaffold-deb-package
./scripts/build-deb.sh
./scripts/verify-deb.sh
```

`build-deb.sh` builds the package with `dpkg-buildpackage -us -uc -b` and
lints the result with `lintian`, both inside the same pinned
`debian:bookworm-slim` container CI and the release job use — nothing has
to be installed on the host beyond Docker. The `.deb` lands in `dist/`.

`verify-deb.sh` then installs that `.deb` with `dpkg -i` in a separate,
**non-slim** `debian:bookworm` container and proves it actually works: every
file `debian/*.install` says should exist gets read back from disk (not
just checked against `dpkg -L`'s metadata), and the installed binary is run
and its output checked. The non-slim image matters on its own —
`debian:*-slim` path-excludes `/usr/share/man/*` and `/usr/share/doc/*`
from every install, so installing inside the same `-slim` image the build
uses would report success even when a doc or man page silently never
landed on disk.

[CONTRIBUTING.md](CONTRIBUTING.md) covers the rest of the toolchain — the
prose linters, the git hooks, and how a change gets reviewed and released.

## Publishing to a Debian/Ubuntu repository

Building a `.deb` and getting it somewhere users can `apt install` it from
are two different problems. Three routes, roughly in order of how much
process stands between you and a working package:

### Official Debian

Getting a package into Debian itself means it goes through the
[New Member process](https://nm.debian.org/) or, more directly, finding a
sponsor — an existing Debian Developer or Debian Maintainer who reviews
your package and uploads it on your behalf. The usual path:

1. Package your project and upload the source package to
   [mentors.debian.net](https://mentors.debian.net/), which exists
   specifically to host packages awaiting review and sponsorship.
2. Ask for review and sponsorship — the `debian-mentors` mailing list and
   the `#debian-mentors` IRC channel (OFTC) are the usual places.
3. Once sponsored, the package goes through the normal Debian archive
   process: the `NEW` queue for ftpmasters to check licensing and policy
   compliance, then it lands in `unstable` and migrates from there.

This is thorough and slow — realistically months, sometimes longer for a
first package — because it's a whole distribution's quality bar, not just
yours. Becoming a Debian Maintainer or Developer yourself (so you can
upload without a sponsor on future packages) is its own, separate process
through the same New Member Process, gated on an identity check via a
GPG key signed by an existing DD and a Tasks & Skills review.

### Ubuntu PPA (lower barrier)

A [Launchpad](https://launchpad.net/) Personal Package Archive is
self-service — no sponsor, no review queue:

1. Create a Launchpad account and register a GPG key against it.
2. Create a PPA from your Launchpad profile.
3. Build a **source** package (`dpkg-buildpackage -S -sa`, not `-b` —
   Launchpad's builders compile the binary themselves) and sign it with
   `debsign`.
4. Upload with [`dput`](https://manpages.debian.org/dput) targeting your
   PPA. Launchpad builds it for each supported Ubuntu release and publishes
   the result; users add your PPA with `add-apt-repository` and install
   normally.

Minutes to set up rather than months, at the cost of it being an
Ubuntu-specific, unofficial channel rather than Debian's own archive.

### Self-hosted apt repository

For full control and no third party's process at all,
[`aptly`](https://www.aptly.info/) or
[`reprepro`](https://salsa.debian.org/brlink/reprepro) manage a local apt
repository: import your built `.deb`s, sign the resulting `Release` file
with your own GPG key, and serve the directory over HTTPS. Users add your
URL and public key to their `/etc/apt/sources.list.d/`. No approval process
and no review, which is also the downside — you're the only one vouching for
the package, so this suits internal or personal use more than public
distribution.

Double-check these specifics against current Debian and Launchpad
documentation before relying on them — process details (queue names,
identity-check requirements, tooling) shift over time and this is a
snapshot, not a guarantee.

## Licence

No licence has been chosen yet — see [`LICENSE`](LICENSE). Pick one before
a project stamped from this template goes anywhere public, and update
`debian/copyright` to match — that's a separate, machine-readable
placeholder of its own.
