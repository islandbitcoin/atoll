#!/usr/bin/env bash
# Publish built .s9pk packages to the Start9 Marketplace registry.
#
# Usage: ./registry/publish.sh <registry-host> <package-dir> [package-dir ...]
#
# STATUS: placeholder. The registry at start9.bobodread.com (running on Zion) is not
# finished yet, and the exact publish command for StartOS v0.4.0 still needs to be
# confirmed. Until then this script discovers the artifacts and prints the intended
# command rather than guessing and running something wrong.
#
# When the registry is ready, replace the echo below with the real publish call
# (likely a `start-cli` invocation against $REGISTRY) and drop the exit.

set -euo pipefail

REGISTRY="${1:?registry host required}"
shift

echo "Target registry: $REGISTRY"
found=0
for pkg in "$@"; do
  for s9pk in "$pkg"/*.s9pk; do
    [ -e "$s9pk" ] || continue
    found=1
    echo "  would publish: $s9pk"
  done
done

if [ "$found" -eq 0 ]; then
  echo "No .s9pk artifacts found. Run 'make build' first." >&2
  exit 1
fi

echo
echo "NOTE: publishing is not wired up yet — see registry/README.md." >&2
exit 1
