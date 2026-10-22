# atoll

Parent / meta repo that ties together **Island Bitcoin's community app stores** across both
**Umbrel** and **Start9 (StartOS)**.

It exists so that every app follows the same shared pattern and can be built and published
from one place. Store id across both platforms: **`atoll`**; display name: **Island Bitcoin**.

🌐 Landing page: served from [`docs/`](docs/) via GitHub Pages.

## Layout

```
atoll/
├── docs/          # GitHub Pages landing page (apps + install instructions)
├── umbrel/        # the single multi-app Umbrel community store (atoll-store)
├── packages/      # one StartOS .s9pk builder per app (git submodules)
│   ├── pact-startos/
│   ├── kathreftestr-startos/
│   ├── maple-proxy-startos/
│   ├── phoenixd-startos/
│   └── atoll-recovery-startos/
├── registry/      # config + publish scripts for the Start9 Marketplace registry
├── Makefile       # build-all / publish-all orchestration
└── README.md
```

## The two platforms have different native models

This is the key thing to keep straight — they are **not** the same mechanism:

| | Umbrel | Start9 (v0.4.0 Marketplace) |
|---|---|---|
| What a "store" is | A **git repo** with `umbrel-app-store.yml` at the root and one subfolder per app | A **registry server** you host (here: on Zion at `start9.bobodread.com`) |
| How apps are added | Subfolder `atoll-<appid>/` inside the one store repo | Publish each app's `.s9pk` into the registry |
| How a user installs | Adds the store's git URL once → sees every app | Adds the registry URL once → sees every published app |

Consequence:
- **Umbrel** → all apps in a *single* store repo (`atoll-store`, tracked under `umbrel/`). One repo, many apps.
- **Start9** → keep one `.s9pk` *builder* per app under `packages/`; they all publish to the
  one registry. There is no "merge" of builders — the registry is the store.

## Adding a new app

1. **Umbrel**: add a subfolder `atoll-<appid>/` to the `atoll-store` repo containing
   `umbrel-app.yml`, `docker-compose.yml`, and `icon.svg`. The folder name MUST be
   `atoll-<appid>` (store id is `atoll`), `id:` inside `umbrel-app.yml` must match the folder
   name, and `APP_HOST` must be `atoll-<appid>_web_1`.
2. **Start9**: create a `<app>-startos` builder repo (from the Start9 SDK template) and add
   it here as a submodule under `packages/`.
3. **Build & publish**: `make build` produces every `.s9pk`; `make publish` pushes them to
   the registry at `start9.bobodread.com`.

## Status (2026-06-16) — ✅ live in production

- [x] Parent repo scaffolded
- [x] Umbrel stores consolidated into the single `atoll-store` (id: atoll, "Island Bitcoin")
- [x] Landing page added under `docs/`
- [x] `atoll-store` pushed to GitHub and wired in as a submodule under `umbrel/`
- [x] GitHub Pages enabled — https://islandbitcoin.github.io/atoll/
- [x] Start9 registry `start9.bobodread.com` live on Zion (end users confirmed installing)
- [x] `make publish` wired to the registry's publish command (`make sync` regenerates the marketplace catalog)
- [x] 4 packages published & consistent: `pactd` 0.18.0, `kathreftestr` 0.1.1, `maple-proxy` 0.1.8, `phoenixd` 0.8.0

Publishing/admin ops run on the registered-signer machine (MacMax) using the LAN signing-context
workaround (`--registry-hostname embassy-5004a3db.local`); see [`registry/README.md`](registry/README.md).

## Atoll Recovery prerelease

Atoll Recovery copies encrypted Cashu ops backups to dedicated Nextcloud storage,
verifies destination read-back and optionally sends HTTPS health notifications.
It carries no recovery private identity or issuance authority. The ops-service
will be packaged separately.

Beta.5 is installed on Zion running StartOS 0.4.0.3 with setup retained.
Its runner copied a real staging cron export into Nextcloud and verified
read-back. An independent download matched the R2 ciphertext digest; isolated
restoration recovered all escrow keys, retained the recovery fence, disabled
operator credentials and omitted sessions. The temporary plaintext database
was removed. The original 03:17 UTC nightly schedule is restored.

The NTFY dependency supplied a scoped publisher automatically; its authenticated
read-only subscription received failure and healthy transitions. Phone/desktop
push, human acknowledgement, separate-machine recovery, offline key custody and
a StartOS backup/restore round trip remain unverified. This is staging evidence.
Beta.3 is indexed in the registry; beta.4 imports failed with GitHub connection
resets. Beta.5 was sideloaded from the signed package.
See [the package instructions](https://github.com/islandbitcoin/atoll-recovery-startos/blob/main/instructions.md).

Publish only its reviewed, locally signed release assets to the registry; the
GitHub build workflow creates test artifacts and holds no registry signing key.
