#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

sudo rm -rf /Applications/Xcode_!(26).app
sudo xcode-select --switch /Applications/Xcode_26.app
sudo xcrun simctl delete all
xcodebuild -downloadComponent MetalToolchain
