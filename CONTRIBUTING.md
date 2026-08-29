# Contributing

This file is for whoever changes this template. The
[README](README.md) is for whoever stamps a project out of it.

## Getting set up

- **[bun](https://bun.sh)** for the tooling — commitlint, Prettier,
  markdownlint, and the [lefthook](https://lefthook.dev) that runs the git
  hooks. There's a `package.json`, but nothing here is JavaScript; it exists
  only so those tools resolve and stay pinned.
- **[Docker](https://docs.docker.com/get-docker/)** to build and lint the
  package the same way CI does — inside the pinned `debian:bookworm-slim`
  container `scripts/build-deb.sh` runs.
- Nothing else to install by hand. Vale and `ltex-cli-plus`, the two prose
  linters, fetch and cache their own pinned binaries on first use — there's
  no Go toolchain in this repo to `go install` them with.

One command installs the linters and the git hooks:

```sh
bun install
```

An uninstalled hook silently does nothing, which is worse than not having
one, so the `prepare` script runs `lefthook install` for you. You find out
at the pipeline otherwise, not at the commit.

## Everyday commands

Every one of these is what a hook or CI runs — see `lefthook.yml` and
`.github/workflows/*.yml` for exactly which.

```sh
bun run format:check       # prettier --check, add --write to fix
bun run lint:md
bun run lint:prose         # vale
bun run lint:mechanics     # ltex-cli-plus
bun run build:deb          # dpkg-buildpackage + lintian, in the pinned container
```

## How it fits together

`debian/` is the actual packaging template — `control`, `rules`, `changelog`,
`copyright`, `source/format` — all real, working DEP-5/policy-compliant
files for a placeholder package named `example`, not stubs with `TODO`s in
place of content. `src/example` is the trivial payload it installs, wired up
through `debian/example.install`. Renaming the placeholder is the first
thing a project stamped from this template does — see the README's
"Adapting this template" section, which is the one this repo itself hasn't
done yet.

`scripts/build-deb.sh` is the single source of truth for how the package
gets built and linted: the pre-push hook, `ci.yml`, and `release.yml`'s
artefact job all call it rather than each spelling out the same
`dpkg-buildpackage`/`lintian` invocation, so the three can't quietly drift
apart.

## The two version numbers

This repo tracks two version numbers that are deliberately independent:

- **`debian/changelog`**'s own version (`0.1.0-1` to start), which is what
  actually ships inside the `.deb` and what `dpkg-buildpackage` reads.
  Bump it by hand — `dch -i` is the usual tool — as part of whatever change
  is being packaged, the same way real Debian packaging works: a package's
  revision often has nothing to do with its upstream project's release
  cadence.
- **This repository's own release**, tracked by
  [release-please](https://github.com/googleapis/release-please) off
  `release-please-config.json`/`.release-please-manifest.json` and cut from
  the Conventional Commits landing on `main`. That's the version in
  `CHANGELOG.md` and the GitHub Release — it's the scaffold's own version,
  not the placeholder package's.

`release.yml`'s artefact job rebuilds and attaches whatever `.deb`
`debian/changelog` currently describes to whichever release-please just cut
— it does not try to keep the two numbers in sync, and neither should you.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/):
`type(scope): description`, types `feat`/`fix`/`docs`/`style`/`refactor`/
`perf`/`test`/`build`/`ci`/`chore`/`revert`. Subject under 50 characters,
lowercase, no trailing full stop. commitlint enforces the shape at
commit-msg and again in CI; the length and case rules are tighter than
what it checks, so hold to them anyway.

## Branching, review, and release

Every change goes through a pull request — nothing is pushed straight to
`main`, save for the bootstrapping that built this repo (there was nothing
to review against, and branch protection wasn't switched on yet).

The pull request **title** has to be a valid Conventional Commit too —
`pr-title.yml` checks it. commitlint only ever reads commit objects, and a
squash merge defaults its commit message to the pull request title, so this
is the only check standing between a badly titled pull request and a bad
message on `main`.

Once a pull request's checks are green, squash-merge it and delete the
branch. release-please keeps a release pull request open with the next
version and changelog entry; merging that one tags the release and
`release.yml`'s artefact job attaches the built `.deb`. Nobody picks a
version by hand.
