# scaffold-deb-package

A GitHub template repo, not a real package. It's built from
`~/.config/claude/CLAUDE.md` and `~/.config/claude/rules/*.md` — read those
for the "why" behind everything below. This file only says what's specific
to this repo.

## What this is

The GitHub-native sibling of `alrayyes/scaffold-deb-package` on
git.higherlearning.eu (Forgejo): same brief, built independently, translated
to GitHub-native tooling — `.github/workflows/` instead of
`.forgejo/workflows/`, release-please instead of semantic-release,
Dependabot instead of Renovate. The two aren't meant to be byte-identical,
just equivalent in what they cover.

## Commands

```sh
bun run format:check       # bun run lint:md, lint:prose, lint:mechanics too
./scripts/build-deb.sh     # dpkg-buildpackage + lintian, pinned container
```

Full list and what each one does: [CONTRIBUTING.md](CONTRIBUTING.md).

## Gotchas

- **This repo has branch protection turned on** (`required_pull_request_reviews`
  at 0 approvals, no status-check requirement) — unlike some sibling
  scaffolds, GitHub doesn't paywall it here since this account owns the
  repo outright. Still never push straight to `main`; protection is there
  as a backstop, not a replacement for the discipline.
- **No Go toolchain anywhere in this repo, deliberately.** The other Go
  scaffolds `go install` Vale, `ltex-cli-plus`, and gitleaks; this one has
  no `go.mod` to justify a Go install, so all three are plain pinned
  release-archive downloads instead — see `scripts/lint-prose.sh`,
  `scripts/lint-mechanics.sh`, and `.github/workflows/gitleaks.yml`.
- **`scripts/build-deb.sh` is the one script the hook, `ci.yml`, and
  `release.yml`'s artefact job all call.** Never spell out
  `dpkg-buildpackage`/`lintian` a second time somewhere else — that's
  exactly the drift this scaffold's chassis is built to prevent.
- **`debian:bookworm-slim`'s digest in `scripts/build-deb.sh` is pinned by
  hand, not by Dependabot.** It's digest-pinned like any other container
  image, but it doesn't live in a manifest any of Dependabot's ecosystems
  watch — re-resolve it from the registry API when it needs bumping (see
  the file's own comment for how this one was resolved).
- **`debian/changelog`'s version and this repo's release-please version
  are deliberately independent** — see CONTRIBUTING.md's "The two version
  numbers" section. Don't try to make release-please bump
  `debian/changelog`; that's not what it's for here.
- **`LICENSE` and `debian/copyright`'s `License` stanzas are two separate
  placeholders.** Replacing one doesn't replace the other — a project
  stamped from this template has to update both.
- **The `example` placeholder package is meant to be renamed wholesale**,
  not extended in place — see the README's "Adapting this template" list.
