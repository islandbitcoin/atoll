# bobodread-stores

Parent / meta repo that ties together **bobodread's community app stores** across both
**Umbrel** and **Start9 (StartOS)**.

It exists so that every app follows the same **"pact pattern"** and can be built and
published from one place.

## Layout

```
bobodread-stores/
├── umbrel/        # the single multi-app Umbrel community store (bobodread-umbrel-store)
├── packages/      # one StartOS .s9pk builder per app (git submodules)
│   ├── pact-startos/
│   └── kathreftestr-startos/
├── registry/      # config + publish scripts for the Start9 Marketplace registry
├── Makefile       # build-all / publish-all orchestration
└── README.md
```

## The two platforms have different native models

This is the key thing to keep straight — they are **not** the same mechanism:

| | Umbrel | Start9 (v0.4.0 Marketplace) |
|---|---|---|
| What a "store" is | A **git repo** with `umbrel-app-store.yml` at the root and one subfolder per app | A **registry server** you host (here: on Zion at `start9.bobodread.com`) |
| How apps are added | Subfolder `<store-id>-<appid>/` inside the one store repo | Publish each app's `.s9pk` into the registry |
| How a user installs | Adds the store's git URL once → sees every app | Adds the registry URL once → sees every published app |

Consequence:
- **Umbrel** → consolidate all apps into a *single* store repo (`umbrel/`). One repo, many apps.
- **Start9** → keep one `.s9pk` *builder* per app under `packages/`; they all publish to the
  one registry. There is no "merge" of builders — the registry is the store.

## The "pact pattern" — adding a new app

1. **Umbrel**: add a subfolder `umbrel/bobodread-<appid>/` containing `umbrel-app.yml`,
   `docker-compose.yml`, and `icon.svg`. The folder name MUST be `<store-id>-<appid>`
   (store id is `bobodread`), and `id:` inside `umbrel-app.yml` must match the folder name.
2. **Start9**: create a `<app>-startos` builder repo (from the Start9 SDK template) and add
   it here as a submodule under `packages/`.
3. **Build & publish**: `make build` produces every `.s9pk`; `make publish` pushes them to
   the registry at `start9.bobodread.com`.

## Status (2026-06-14)

- [x] Parent repo scaffolded
- [ ] Umbrel stores consolidated into `umbrel/` (currently still per-app repos:
      `pact-umbrel-store`, `kathreftestr-umbrel-store`)
- [ ] Start9 registry `start9.bobodread.com` finished (running on Zion, setup incomplete)
- [ ] `make publish` wired to the registry's publish command
