# Umbrel community store

The single, multi-app Umbrel community store lives in its own repo, **`atoll-store`**
(store `id: atoll`, display name **Island Bitcoin**), so Umbrel can consume it by git URL.

It currently lives at `~/Repos/atoll-store` and will be added here as a git submodule
(`umbrel/atoll-store`) once it is pushed to GitHub.

## Apps

- `atoll-pactd` — Pact (migrated from `pact-umbrel-store/pact-pactd`)
- `atoll-kathreftestr` — Kathreftestr (migrated from `kathreftestr-umbrel-store/kathreftestr`)

## Add the store to Umbrel

App Store → ⋯ → Add community store → `https://github.com/bobodread876/atoll-store`

> The former per-app store repos (`pact-umbrel-store`, `kathreftestr-umbrel-store`) are
> superseded by `atoll-store` and kept only for reference.
