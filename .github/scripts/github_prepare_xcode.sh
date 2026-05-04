#!/usr/bin/env bash

set -euo pipefail
shopt -s extglob

BASE_XCODE_PATH=/Applications/Xcode_26.0.app

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
