# Start9 Marketplace registry

This directory holds config and scripts for **bobodread's self-hosted Start9 registry**.

- **Software**: Start9 Marketplace package (`startos-registry-startos`, StartOS v0.4.0)
  — https://github.com/Start9Labs/startos-registry-startos/
- **Host**: running on **Zion**
- **Public URL (planned)**: `start9.bobodread.com`
- **Status**: running but **setup not finished**

## How the Start9 "store" works

Unlike Umbrel (a git repo of apps), a Start9 store is this **registry server**. You publish
each app's `.s9pk` into it, and users add `start9.bobodread.com` as a marketplace to see and
install every published app.

## TODO

- [ ] Finish registry setup on Zion
- [ ] Point `start9.bobodread.com` DNS → Zion and confirm TLS
- [ ] Confirm the StartOS v0.4.0 publish command and wire it into `publish.sh`
- [ ] Publish `pact` and `kathreftestr` `.s9pk` artifacts
