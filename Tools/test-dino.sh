#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
task_test_dir=$(mktemp -d /tmp/dino-tests.XXXXXX)
trap 'rm -rf "$task_test_dir"' EXIT
swiftc -module-cache-path "$task_test_dir/cache" Dino/Core/*.swift Dino/DinoGameModel.swift Tests/DinoCoreTests.swift Tests/DinoSocialTests.swift -o "$task_test_dir/tests"
"$task_test_dir/tests"
