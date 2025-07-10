#!/bin/bash -eux

# Simple script for downloading and unpacking required resources to build Ungoogled-Chromium macOS binaries on GitHub Actions

_target_cpu="$1"

_root_dir="$(dirname "$(greadlink -f "$0")")"
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

mkdir -p "$_src_dir"
sudo df -h
sudo du -hs "$_src_dir"

rm -rf "$_src_dir/out" || true
mkdir -p "$_download_cache"

"$_root_dir/retrieve_and_unpack_resource.sh" -d -g "$_target_cpu"

mkdir -p "$_src_dir/out/Default"

python3 "$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
python3 "$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
python3 "$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"

mkdir -p "$_src_dir/third_party/llvm-build/Release+Asserts"
mkdir -p "$_src_dir/third_party/rust-toolchain/bin"

"$_root_dir/retrieve_and_unpack_resource.sh" -d -p "$_target_cpu"

rm -rvf "$_download_cache"
