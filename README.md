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
│   └── phoenixd-startos/
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
