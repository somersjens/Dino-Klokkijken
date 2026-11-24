#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
magma_bake_dir=$(mktemp -d /tmp/magma-materials.XXXXXX)
trap 'rm -rf "$magma_bake_dir"' EXIT
swiftc -O -module-cache-path "$magma_bake_dir/cache" Dino/Core/*.swift Dino/DinoGameModel.swift Tools/bake-volcano-materials.swift -o "$magma_bake_dir/bake"
"$magma_bake_dir/bake" "$@"
