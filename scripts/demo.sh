#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

echo "==> cold build (populates the kache store)"
pixi build --clean -o dist

echo
echo "==> cold build stats"
kache stats --last-build --full

# kache aggregates events per build root, so the cold and warm builds share a
# session. Clear the runtime dir (not the store) to get a clean warm report.
rm -rf "$KACHE_RUNTIME_DIR"

echo
echo "==> warm build (same sources; kache should serve the compilations)"
pixi build --clean -o dist

echo
echo "==> warm build stats"
kache stats --last-build --full
