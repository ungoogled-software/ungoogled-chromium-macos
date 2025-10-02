#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

sudo rm -rf /Applications/Xcode_!(26).app
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
