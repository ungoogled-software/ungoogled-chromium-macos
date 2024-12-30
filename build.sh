#!/usr/bin/env bash

set -eux

# Simple build script for macOS

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

# Clone to get the Chromium Source
clone=true
while getopts 'd' OPTION; do
  case "$OPTION" in
    d)
      clone=false
      ;;
  esac
done

# For packaging
_chromium_version=$(cat "$_root_dir"/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat "$_root_dir"/ungoogled-chromium/revision.txt)
_package_revision=$(cat "$_root_dir"/revision.txt)

# Add local clang and build tools to PATH
# export PATH="$PATH:$_src_dir/third_party/llvm-build/Release+Asserts/bin"

rm -rf "$_src_dir/out" || true
mkdir -p "$_download_cache"

if $clone; then
  "$_root_dir/retrieve_and_unpack_resource.sh" -g "$(uname -m)"
else
  "$_root_dir/retrieve_and_unpack_resource.sh" -d -g
fi

mkdir -p "$_src_dir/out/Default"

"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"
cat "$_main_repo/flags.gn" "$_root_dir/flags.macos.gn" > "$_src_dir/out/Default/args.gn"

mkdir -p "$_src_dir/third_party/llvm-build/Release+Asserts"
mkdir -p "$_src_dir/third_party/rust-toolchain/bin"

"$_root_dir/retrieve_and_unpack_resource.sh" -p "$(uname -m)"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./tools/rust/build_bindgen.py --rust-target "$(uname -m)"

./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome chromedriver

./sign_and_package_app.sh
