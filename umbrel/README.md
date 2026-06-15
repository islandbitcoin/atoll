# Umbrel community store (placeholder)

This directory will hold the **single, multi-app** Umbrel community store
(`bobodread-umbrel-store`) — added here as a submodule once it is created.

## Why consolidate

An Umbrel community store repo is natively multi-app: one `umbrel-app-store.yml` at the root,
plus one subfolder per app. The current setup uses a separate repo per app
(`pact-umbrel-store`, `kathreftestr-umbrel-store`), which fights that model. Collapsing them
into one store means users add a single store URL and get every app.

## Target structure

```
bobodread-umbrel-store/
├── umbrel-app-store.yml      # id: bobodread, name: BoboDread
├── bobodread-pactd/          # migrated from pact-umbrel-store/pact-pactd
│   ├── umbrel-app.yml         # id: bobodread-pactd  (must match folder name)
│   ├── docker-compose.yml
│   └── icon.svg
└── bobodread-kathreftestr/   # migrated from kathreftestr-umbrel-store/kathreftestr
    ├── umbrel-app.yml         # id: bobodread-kathreftestr
    ├── docker-compose.yml
    └── icon.svg
```

## Migration note

Folder names and the `id:` field in each `umbrel-app.yml` must be re-prefixed with the new
store id (`bobodread`). Done as a separate task — see the project memory.
