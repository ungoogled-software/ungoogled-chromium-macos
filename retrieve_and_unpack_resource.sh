#!/usr/bin/env bash 

set -eux

# Script to retrieve and unpack resources to build Chromium macOS

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

# Retrieve and unpack general resources

"$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache"
"$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache" "$_src_dir"

# Retrieve and unpack architecture-specific resources
if [ "$(uname -m)" = "arm64" ]; then
    # For arm64 (Apple Silicon)
    "$_main_repo/utils/downloads.py" retrieve -i "$_root_dir/downloads-arm64.ini" -c "$_download_cache"
    "$_main_repo/utils/downloads.py" unpack -i "$_root_dir/downloads-arm64.ini" -c "$_download_cache" "$_src_dir"
else
    # For x86-64 (Intel)
    "$_main_repo/utils/downloads.py" retrieve -i "$_root_dir/downloads-x86-64.ini" -c "$_download_cache"
    "$_main_repo/utils/downloads.py" unpack -i "$_root_dir/downloads-x86-64.ini" -c "$_download_cache" "$_src_dir"
fi
