#!/usr/bin/env bash

# pixi-build-rust force-exports RUSTC_WRAPPER="sccache" whenever any SCCACHE*
# variable is visible, which would silently disable kache. Drop them first.
for var in $(compgen -e | grep '^SCCACHE' || true); do
    unset "$var"
done

root="${PIXI_PROJECT_ROOT:-$PWD}"

# Outside .pixi so `pixi build --clean` cannot wipe the cache.
export KACHE_CACHE_DIR="$root/.kache"
# Keep sockets and event logs out of the cache that CI archives.
export KACHE_RUNTIME_DIR="$root/.kache-runtime"
export CARGO_HOME="$root/.cargo"
export KACHE_LOCAL_ONLY=1
