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
#   ./registry/publish.sh [package-dir ...]              # publish: default packages/*-startos
#   ./registry/publish.sh add-package <name> [--push]    # register a new <name>-startos submodule
#
# Env (defaults):
#   REGISTRY=https://start9.bobodread.com         registry connection URL
#   REGISTRY_HOSTNAME=embassy-5004a3db.local      signing context (must be in registry-hostname)
#   RELEASE_OWNER=islandbitcoin                   GitHub owner (fallback if a dir has no git remote)
#   SKIP_BUILD=                                    set to skip `make` and use existing s9pks
#   FORCE=                                         re-publish a version already in the registry (remove + re-add)
#   DRY_RUN=                                       set to print commands without executing
#
# By default, packages whose version is already in the registry are skipped (so re-running
# only publishes new/bumped versions). Set FORCE=1 to remove+re-add an existing version.
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
FORCE="${FORCE:-}"           # set to re-publish a version that's already in the registry
DRY_RUN="${DRY_RUN:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

c_blue=$'\033[1;36m'; c_yellow=$'\033[1;33m'; c_red=$'\033[1;31m'; c_dim=$'\033[2m'; c_off=$'\033[0m'
log()  { printf '%s==>%s %s\n' "$c_blue" "$c_off" "$*"; }
warn() { printf '%swarn:%s %s\n' "$c_yellow" "$c_off" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }
# run a mutating command (honors DRY_RUN); reads are called directly.
run()  { if [ -n "$DRY_RUN" ]; then printf '   %s[dry-run]%s %s\n' "$c_dim" "$c_off" "$*"; else "$@"; fi; }

# ── subcommand: add-package ─────────────────────────────────────────────────────────────
# Register a new <name>-startos builder as a submodule under packages/. The GitHub repo
# RELEASE_OWNER/<name>-startos must already exist (this clones it).
#   ./registry/publish.sh add-package maple-proxy            # or --package-name maple-proxy
#   ./registry/publish.sh add-package maple-proxy --push     # also push the atoll change
if [ "${1:-}" = "add-package" ]; then
  shift
  name=""; do_push=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --package-name)   name="${2:?--package-name needs a value}"; shift 2 ;;
      --package-name=*) name="${1#*=}"; shift ;;
      --push)           do_push=1; shift ;;
      -*)               die "add-package: unknown flag $1" ;;
      *)                name="$1"; shift ;;
    esac
  done
  [ -n "$name" ] || die "add-package: give a name, e.g. 'add-package maple-proxy' (or --package-name maple-proxy)"
  command -v git >/dev/null 2>&1 || die "missing required tool: git"
  name="${name%-startos}"                      # accept 'maple-proxy' or 'maple-proxy-startos'
  repo="$RELEASE_OWNER/${name}-startos"
  path="packages/${name}-startos"
  [ -e "$REPO_ROOT/$path" ] && die "$path already exists"
  log "add-package: https://github.com/${repo}.git -> $path"
  run git -C "$REPO_ROOT" submodule add "https://github.com/${repo}.git" "$path"
  run git -C "$REPO_ROOT" commit -m "Add ${name}-startos package"
  if [ -n "$do_push" ]; then run git -C "$REPO_ROOT" push
  else log "committed — run 'git push' (or re-run with --push) to publish the change"; fi
  exit 0
fi

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

# Snapshot the current registry index once so we can skip versions already published.
INDEX_JSON="$(start-cli --registry-hostname "$REGISTRY_HOSTNAME" -r "$REGISTRY" registry package index 2>/dev/null || true)"
in_index() { # in_index <id> <version> -> 0 if that version is already in the registry
  printf '%s' "$INDEX_JSON" | python3 -c 'import json,sys
raw = sys.stdin.read(); i = raw.find("{")          # tolerate any leading progress/noise
if i < 0: sys.exit(1)
try: d, _ = json.JSONDecoder().raw_decode(raw[i:])  # parse first JSON value, ignore trailing
except Exception: sys.exit(1)
sys.exit(0 if sys.argv[2] in d.get("packages", {}).get(sys.argv[1], {}).get("versions", {}) else 1)' "$1" "$2"
}
# warn if the index could not be read — skip-detection is then OFF (FORCE still works)
if ! printf '%s' "$INDEX_JSON" | python3 -c 'import json,sys
raw=sys.stdin.read(); i=raw.find("{"); sys.exit(1) if i<0 else json.JSONDecoder().raw_decode(raw[i:])' >/dev/null 2>&1; then
  warn "could not read the registry index — already-published versions will NOT be auto-skipped this run (use FORCE=1 to re-publish existing versions, or check connectivity/auth)"
fi

for dir in "${PKG_DIRS[@]}"; do
  [ -d "$dir" ] || { warn "skipping $dir (not a directory)"; continue; }
  dir="$(cd "$dir" && pwd)"
  log "package: $dir"

  # 0. fast skip: if we can read a single, already-published version from source, don't even build
  if [ -z "$FORCE" ]; then
    src_id="$(grep -oE "id: *'[^']+'" "$dir"/startos/manifest/index.ts 2>/dev/null | head -1 | sed -E "s/.*'([^']+)'.*/\1/")"
    src_vers="$(grep -rhoE "version: *'[^']+'" "$dir"/startos/versions/*.ts 2>/dev/null | sed -E "s/.*'([^']+)'.*/\1/" | sort -u)"
    if [ -n "$src_id" ] && [ "$(printf '%s\n' "$src_vers" | grep -c .)" = "1" ] && in_index "$src_id" "$src_vers"; then
      log "  $src_id@$src_vers already in registry — skipping (FORCE=1 to re-publish)"
      continue
    fi
  fi

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

  # 2b. with FORCE, always remove first (don't trust the snapshot); else skip if already published
  if [ -n "$FORCE" ]; then
    log "  FORCE: removing $id@$version if present, then re-adding"
    run start-cli --registry-hostname "$REGISTRY_HOSTNAME" -r "$REGISTRY" \
      registry package remove "$id" "$version" || true
  elif in_index "$id" "$version"; then
    log "  $id@$version already in registry — skipping publish (FORCE=1 to re-publish)"
    continue
  fi

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
