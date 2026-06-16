#!/usr/bin/env bash
# Generate docs/packages.json from the LIVE registry, so the marketplace landing page
# always reflects exactly what's published (name, description, categories, icon, install
# urls, and each package's landing link from its marketingUrl).
#
# Run on a machine with the registered key + LAN access (same requirements as publish.sh),
# then commit + push docs/packages.json so GitHub Pages picks it up.
#
#   ./registry/sync-marketplace.sh            # writes docs/packages.json
#   make sync                                 # same, from the parent repo
#
# Env (defaults): REGISTRY, REGISTRY_HOSTNAME  (see publish.sh)

set -euo pipefail

REGISTRY="${REGISTRY:-https://start9.bobodread.com}"
REGISTRY_HOSTNAME="${REGISTRY_HOSTNAME:-embassy-5004a3db.local}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="$REPO_ROOT/docs/packages.json"

command -v start-cli >/dev/null 2>&1 || { echo "missing start-cli" >&2; exit 1; }
command -v python3   >/dev/null 2>&1 || { echo "missing python3" >&2; exit 1; }

# A package <id> is also on Umbrel if the Umbrel store has an atoll-<id> folder.
umbrel_ids=""
for d in "$REPO_ROOT"/umbrel/atoll-store/atoll-*/; do
  [ -d "$d" ] || continue
  b="$(basename "$d")"; umbrel_ids="$umbrel_ids ${b#atoll-}"
done

echo "==> fetching registry index from $REGISTRY (context $REGISTRY_HOSTNAME)"
start-cli --registry-hostname "$REGISTRY_HOSTNAME" -r "$REGISTRY" registry package index \
  | UMBREL_IDS="$umbrel_ids" python3 "$SCRIPT_DIR/index-to-packages.py" "$OUT"
echo "Done. Review docs/packages.json, then commit + push so the marketplace updates."
