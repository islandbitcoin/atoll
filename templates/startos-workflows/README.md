# StartOS package CI/CD template

Drop-in GitHub Actions for any **`<app>-startos`** package repo so it builds and (optionally)
publishes to the Island Bitcoin Start9 registry automatically. These wrap Start9's official
reusable workflows (`start9labs/shared-workflows`).

## What's here

| File | Trigger | Does |
|------|---------|------|
| `build.yml` | PR to `main` / manual | CI build check (no publish) |
| `tagAndRelease.yml` | push to `main` | reads version, checks the reference registry, tags the commit |
| `release.yml` | tag `v*.*` | builds the `.s9pk`, creates a GitHub Release, and registers the package into the registry |

> Triggers are set to **`main`** (Start9's upstream defaults to `master` — already adjusted here).

## Set up a new `<app>-startos` repo

1. Copy these three files into `<app>-startos/.github/workflows/`:
   ```
   cp templates/startos-workflows/{build,release,tagAndRelease}.yml \
      ../<app>-startos/.github/workflows/
   ```
2. Set the repo **variables** (Settings → Secrets and variables → Actions → Variables), or via gh:
   ```
   gh variable set REFERENCE_REGISTRY --body "https://start9.bobodread.com" --repo <owner>/<app>-startos
   gh variable set RELEASE_REGISTRY   --body "https://start9.bobodread.com" --repo <owner>/<app>-startos
   ```
3. Handle the signing key — see below.

## Signing key (the important part)

The publish step signs the `.s9pk` with the developer key whose **public key is registered as a
signer on the registry**. The workflow expects a `DEV_KEY` secret, which it writes to
`~/.startos/developer.key.pem` and signs with.

We deliberately **do not** put the private `developer.key.pem` into GitHub secrets. That leaves
two ways to actually publish:

- **Manual / local publish (current default):** let CI build if you want, but run the publish
  yourself from a machine that holds the key — the key never leaves your hardware:
  ```
  start-cli -r https://start9.bobodread.com registry package add \
    ./<pkg>_x86_64.s9pk --url <github-release-asset-url>
  ```
- **Self-hosted runner (full automation, key stays local):** register a self-hosted Actions
  runner on a trusted machine that has `~/.startos/developer.key.pem`, and use a *forked* copy of
  `release.yml` that reads the local key instead of overwriting it from the `DEV_KEY` secret. This
  is the only way to get push-to-`main` → published while keeping the key off GitHub.

Until one of those is in place, pushes to `main` will trigger runs that **fail at the signing
step** — that's expected, not a misconfiguration.

S3 hosting is optional (only needed for `.s9pk` files > 2 GB); leave `S3_S9PKS_BASE_URL` unset to
host the artifact on the GitHub Release and register it via `--url`.
