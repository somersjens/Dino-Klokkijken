#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
task_benchmark_dir=$(mktemp -d /tmp/dino-rendering.XXXXXX)
trap 'rm -rf "$task_benchmark_dir"' EXIT
swiftc -O -module-cache-path "$task_benchmark_dir/cache" \
    Dino/Core/DinoAppearance.swift Dino/Core/DinoAvatarMask.swift \
    Tools/DinoRenderingBenchmark.swift -o "$task_benchmark_dir/benchmark"
"$task_benchmark_dir/benchmark"
