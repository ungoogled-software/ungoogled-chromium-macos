#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

ls -lrt /Applications

# GitHub actions is in flux, and different versions of Xcode exist in different runs.
BASE_XCODE_PATH=/Applications/Xcode_26.app
if [ ! -e "$BASE_XCODE_PATH" ]; then
  BASE_XCODE_PATH=/Applications/Xcode_26.0.app
fi

if [ ! -e "$BASE_XCODE_PATH" ]; then
  echo "Failed to find a suitable version of Xcode"
  exit 1
fi

TARGET_XCODE_VERSION="$(readlink -f "$BASE_XCODE_PATH" | xargs basename | sed 's/Xcode_//' | sed 's/.app//')"

sudo rm -rf /Applications/Xcode_!("$TARGET_XCODE_VERSION").app
if [ ! -e /Applications/Xcode_26.app ]; then
  # try to keep paths consistent between jobs.
  sudo mv "/Applications/Xcode_$TARGET_XCODE_VERSION.app" /Applications/Xcode_26.app
fi

sudo xcode-select --switch /Applications/Xcode_26.app
sudo xcrun simctl delete all

if [ ! -e MetalToolchain.exportedBundle.tar.zst ]; then
  echo "Downloading Metal Toolchain"
  # this also installs the toolchain, so there's no need to separately import it (which would actually fail in this case).
  xcodebuild -downloadComponent MetalToolchain -exportPath metal_toolchain
  ls -lrt metal_toolchain
  mv metal_toolchain/*.exportedBundle MetalToolchain.exportedBundle
  rmdir metal_toolchain
  # cache the bundle for future jobs (the next step will upload it in this case).
  tar -c -f - MetalToolchain.exportedBundle | zstd -vv -11 -T0 -o MetalToolchain.exportedBundle.tar.zst
else
  echo "Extracting Metal Toolchain"
  tar -xf MetalToolchain.exportedBundle.tar.zst
  rm MetalToolchain.exportedBundle.tar.zst
  xcodebuild -importComponent metalToolchain -importPath MetalToolchain.exportedBundle
fi

rm -rf MetalToolchain.exportedBundle
