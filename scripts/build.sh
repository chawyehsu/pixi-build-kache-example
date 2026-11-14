#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/env.sh"

# --clean drops pixi's artifact/workspace cache so cargo actually runs.
# The kache store lives outside .pixi and therefore survives.
pixi build --clean -o dist
