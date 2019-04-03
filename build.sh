#!/bin/bash -eux

# Simple build script for macOS

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

# For packaging
_chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
_package_revision=$(cat $_root_dir/revision.txt)

rm -rf "$_src_dir/out" || true
mkdir -p "$_src_dir/out/Default"
mkdir -p "$_download_cache"

"$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache"
"$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache" "$_src_dir"
"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" -c "$_root_dir/build/domsubcache.tar.gz" "$_src_dir"
cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.macos.gn" >> "$_src_dir/out/Default/args.gn"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome chromedriver

chrome/installer/mac/pkg-dmg \
  --sourcefile --source out/Default/Chromium.app \
  --target "$_root_dir/build/ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_macos.dmg" \
  --volname Chromium --symlink /Applications:/Applications \
  --format UDBZ --verbosity 2
