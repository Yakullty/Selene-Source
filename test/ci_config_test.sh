#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! grep -q "enable-swift-package-manager: false" "$repo_root/pubspec.yaml"; then
  echo "pubspec.yaml must disable Flutter Swift Package Manager for Apple CI builds"
  exit 1
fi

if ! grep -q "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS" "$repo_root/windows/CMakeLists.txt"; then
  echo "windows/CMakeLists.txt must suppress MSVC experimental coroutine deprecation errors"
  exit 1
fi
