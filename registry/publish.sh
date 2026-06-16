#!/usr/bin/env bash
# registry/publish.sh — build + publish Island Bitcoin StartOS packages to the registry.
#
# Runs the full release recipe for each package:
#   build (make) -> upload s9pks to its GitHub Release -> index into the Start9 registry.
#
# ── MUST run on the REGISTERED-SIGNER machine ──────────────────────────────────────────
# StartOS signs every authenticated registry request using the *registry hostname* as the
# Ed25519 signing context, and the server only accepts contexts in its `registry-hostname`
# list (which contains LAN names, NOT the public URL). So you must:
#   * run this on the machine whose developer key is registered as a registry admin/signer,
#   * with REGISTRY_HOSTNAME set to one of the registry's LAN hostnames (default below).
# The connection itself still goes over the public REGISTRY URL.
# `gh` must be logged in with push access to the release owner (RELEASE_OWNER).
#
# Usage:
#   ./registry/publish.sh [package-dir ...]      # default: packages/*-startos
#
# Env (defaults):
#   REGISTRY=https://start9.bobodread.com         registry connection URL
#   REGISTRY_HOSTNAME=embassy-5004a3db.local      signing context (must be in registry-hostname)
#   RELEASE_OWNER=islandbitcoin                   GitHub owner (fallback if a dir has no git remote)
#   SKIP_BUILD=                                    set to skip `make` and use existing s9pks
#   DRY_RUN=                                       set to print commands without executing
#
# Examples:
#   DRY_RUN=1 ./registry/publish.sh                       # preview everything
#   ./registry/publish.sh                                 # build + publish all packages
#   ./registry/publish.sh ~/Repos/pact-startos            # just one (e.g. from MacMax)

set -euo pipefail

REGISTRY="${REGISTRY:-https://start9.bobodread.com}"
REGISTRY_HOSTNAME="${REGISTRY_HOSTNAME:-embassy-5004a3db.local}"
RELEASE_OWNER="${RELEASE_OWNER:-islandbitcoin}"
SKIP_BUILD="${SKIP_BUILD:-}"
DRY_RUN="${DRY_RUN:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

c_blue=$'\033[1;36m'; c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
log()  { printf '%s==>%s %s\n' "$c_blue" "$c_off" "$*"; }
warn() { printf '%swarn:%s %s\n' "$c_yellow" "$c_off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }
# run a mutating command (honors DRY_RUN); reads are called directly.
run()  { if [ -n "$DRY_RUN" ]; then printf '   %s[dry-run]%s %s\n' "$c_dim" "$c_off" "$*"; else "$@"; fi; }

# ── preflight ──────────────────────────────────────────────────────────────────────────
for t in start-cli gh make python3; do
  command -v "$t" >/dev/null 2>&1 || die "missing required tool: $t"
done
[ -n "$DRY_RUN" ] || gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run: gh auth login)"

# package dirs: args, or default to packages/*-startos under the repo root
if [ "$#" -gt 0 ]; then
  PKG_DIRS=("$@")
else
  PKG_DIRS=("$REPO_ROOT"/packages/*-startos)
fi
[ "${#PKG_DIRS[@]}" -gt 0 ] || die "no package dirs (pass dirs, or populate packages/*-startos)"

log "registry: $REGISTRY  |  signing context: $REGISTRY_HOSTNAME${DRY_RUN:+  (DRY RUN)}"

for dir in "${PKG_DIRS[@]}"; do
  [ -d "$dir" ] || { warn "skipping $dir (not a directory)"; continue; }
  dir="$(cd "$dir" && pwd)"
  log "package: $dir"

  # 1. build (unless skipped)
  if [ -z "$SKIP_BUILD" ]; then
    run make -C "$dir"
  fi

  # collect built artifacts
  shopt -s nullglob; s9pks=("$dir"/*.s9pk); shopt -u nullglob
  if [ "${#s9pks[@]}" -eq 0 ]; then
    if [ -n "$DRY_RUN" ]; then
      printf '   %s[dry-run]%s would build %s, then release + publish its *.s9pk\n' "$c_dim" "$c_off" "$dir"
      continue
    fi
    die "no .s9pk produced in $dir (build failed?)"
  fi

  # 2. discover id / version / tag / repo / notes from the first s9pk's manifest
  manifest="$(start-cli s9pk inspect "${s9pks[0]}" manifest)"
  id="$(printf '%s' "$manifest"      | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
  version="$(printf '%s' "$manifest" | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])')"
  notes="$(printf '%s' "$manifest"   | python3 -c 'import json,sys; rn=json.load(sys.stdin).get("releaseNotes"); print((rn.get("en_US") or next(iter(rn.values()),"")) if isinstance(rn,dict) else (rn or ""))')"
  tag="v${version%%:*}"                    # 0.18.0:0 -> v0.18.0
  repo="$RELEASE_OWNER/$(basename "$dir")" # releases live under RELEASE_OWNER (e.g. islandbitcoin/pact-startos)
  [ -n "$notes" ] || notes="$id $version"

  log "  id=$id  version=$version  tag=$tag  repo=$repo  archs=${#s9pks[@]}"

  # 3. ensure a GitHub release with these exact s9pks as assets
  if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    log "  release $tag exists — replacing assets (--clobber)"
  else
    log "  creating release $tag"
    run gh release create "$tag" --repo "$repo" --title "$id ${version%%:*}" --notes "$notes"
  fi
  run gh release upload "$tag" "${s9pks[@]}" --repo "$repo" --clobber

  # 4. index each arch into the registry (local file == the asset we just uploaded)
  for s9pk in "${s9pks[@]}"; do
    base="$(basename "$s9pk")"
    url="https://github.com/$repo/releases/download/$tag/$base"
    log "  publishing $base"
    run start-cli --registry-hostname "$REGISTRY_HOSTNAME" -r "$REGISTRY" \
      registry package add "$s9pk" --url "$url"
  done
done

# 5. verify
log "registry package index:"
run start-cli --registry-hostname "$REGISTRY_HOSTNAME" -r "$REGISTRY" registry package index
log "done."
