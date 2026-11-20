#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$repo_root/apps/native/DerivedData"

xcodebuild -quiet \
  -project "$repo_root/apps/native/EchoPaw.xcodeproj" \
  -scheme EchoPaw \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$build_dir" \
  build

open "$build_dir/Build/Products/Debug/EchoPaw.app"
