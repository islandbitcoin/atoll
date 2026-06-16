# Start9 Marketplace registry

This directory holds config and scripts for **Island Bitcoin's self-hosted Start9 registry**.

- **Software**: Start9 Marketplace package (`startos-registry-startos`, StartOS v0.4.0)
  — https://github.com/Start9Labs/startos-registry-startos/
- **Host**: running on **Zion**
- **Public URL**: `https://start9.bobodread.com`
- **Status**: ✅ live — both packages published and confirmed installable by remote users.

## How the Start9 "store" works

Unlike Umbrel (a git repo of apps), a Start9 store is this **registry server**. You publish
each app's `.s9pk` into it, and users add `start9.bobodread.com` as a marketplace to see and
install every published app.

## Publishing — `publish.sh`

`./registry/publish.sh [package-dir ...]` builds each package, uploads its `.s9pk`s to that
app's GitHub Release, and indexes them into the registry. From the parent repo you can also run
`make publish` (or `make publish-dry` to preview).

**Add a new package** (registers `RELEASE_OWNER/<name>-startos` as a submodule under `packages/`;
the GitHub repo must already exist):

```bash
./registry/publish.sh add-package <name> [--push]   # e.g. add-package maple-proxy
```

⚠️ **Must run on the registered-signer machine** (the one whose developer key is registered as a
registry admin/signer **and** is on the registry's LAN). StartOS signs each authenticated request
using the **registry hostname as the Ed25519 signing context**, and the server only accepts
contexts in its `registry-hostname` list — which holds **LAN hostnames**, not the public URL. So:

- `REGISTRY_HOSTNAME` must be one of those LAN names (default `embassy-5004a3db.local`); the
  `--registry-hostname` flag sets the signing context independently of the connection URL.
- The connection still goes over `REGISTRY` (`https://start9.bobodread.com`).
- `gh` must be logged in with push access to `RELEASE_OWNER` (default `islandbitcoin`).
- The `.s9pk` passed to `package add` must be byte-identical to the file at `--url`, so the script
  builds once and then uploads+indexes those same files (avoids "merkle root mismatch").

This LAN-context requirement only affects **publishing** — end users browse/install fine over the
public `start9.bobodread.com`.

### Config (env vars, with defaults)

| Var | Default | Purpose |
|-----|---------|---------|
| `REGISTRY` | `https://start9.bobodread.com` | registry connection URL |
| `REGISTRY_HOSTNAME` | `embassy-5004a3db.local` | signing context (must be in `registry-hostname`) |
| `RELEASE_OWNER` | `islandbitcoin` | GitHub owner that hosts the release assets |
| `SKIP_BUILD` | _(unset)_ | reuse existing `.s9pk`s instead of `make` |
| `FORCE` | _(unset)_ | re-publish a version already in the registry (remove + re-add) |
| `DRY_RUN` | _(unset)_ | print every command without executing |

> By default, any package whose version is **already in the registry is skipped** (no build,
> no re-upload), so re-running `make publish` only publishes new or version-bumped packages.
> Set `FORCE=1` to remove and re-add an existing version.

## Marketplace catalog (`packages.json`)

The landing page (`docs/index.html`) renders its app grid from **`docs/packages.json`**, which is
**generated from the live registry** — so the marketplace always matches what's actually published
(name, description, categories, icon, version, platforms, and each package's landing link from its
`marketingUrl`). Don't hand-edit `packages.json`.

```bash
make sync          # regenerate docs/packages.json from the registry (alias: registry/sync-marketplace.sh)
git add docs/packages.json && git commit -m "sync marketplace" && git push   # publish to GitHub Pages
```

Run `make sync` after publishing a new package/version (it has the same LAN-machine + registered-key
requirements as publishing). Per-card data comes from the registry; a package's **Website** link is
its `marketingUrl` (set it in the package's `startos/manifest/index.ts`), and **Start9/Umbrel**
badges are derived from the registry + the presence of an `umbrel/atoll-store/atoll-<id>` folder.

## Shell helpers (`ibreg` / `CAT`)

`registry/ibreg.sh` defines convenience helpers so you don't retype the registry flags.
Source it once from your shell rc (survives restarts):

```bash
# zsh (macOS default):
echo 'source ~/Documents/Start9/Repos/atoll/registry/ibreg.sh' >> ~/.zshrc
# bash:
echo 'source ~/Documents/Start9/Repos/atoll/registry/ibreg.sh' >> ~/.bashrc
```

Then in any shell:

```bash
ibreg registry package index            # raw start-cli against the registry
CAT list                                # list categories
CAT add-package ai maple-proxy          # tag a package into a category
```

It exports `REG`/`HOST` and defines `ibreg` (start-cli wrapper) + `CAT` (category shortcut),
using the same defaults as `publish.sh`. Must run on a LAN machine with the registered key.

## Outstanding / nice-to-have

- Add `start9.bobodread.com` to the registry's Web API interface **through StartOS** on Zion so it
  lands in `registry-hostname` — then publishing wouldn't need the LAN-context workaround.
- `registry-icon.png` / `registry-icon.datauri.txt` here are the registry icon source.
