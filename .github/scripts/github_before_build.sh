#!/bin/bash -eux

# Simple script for downloading, unpacking, and getting ready to build Ungoogled-Chromium macOS binaries on GitHub Actions

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

mkdir -p "$_src_dir"
hdiutil create -type SPARSEBUNDLE -size 32g -fs APFS -volname build_src -nospotlight -verbose ./build_src.sparsebundle
hdiutil attach ./build_src.sparsebundle -mountpoint "$_src_dir" -nobrowse -noverify -noautoopen -noautofsck
sudo df -h
sudo du -hs "$_src_dir"

# mdutil -i off ./build_src.sparsebundle # does not seem to work on macOS 11
rm -rfv ./build_src.sparsebundle/.{,_.}{fseventsd,Spotlight-V*,Trashes} || true
mkdir -pv ./build_src.sparsebundle/.fseventsd
touch ./build_src.sparsebundle/.fseventsd/no_log ./build_src.sparsebundle/.metadata_never_index ./build_src.sparsebundle/.Trashes

rm -rf "$_src_dir/out" || true
mkdir -p "$_src_dir/out/Default"
mkdir -p "$_download_cache"

"$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache"
"$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache" "$_src_dir"
"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" -c "$_root_dir/build/domsubcache.tar.gz" "$_src_dir"

shopt -s nocasematch
if [[ $GITHUB_REF =~ arm || $(git log --pretty='%s' -1) =~ arm  ]]; then
  echo 'target_cpu = "arm64"' >> "$_root_dir/flags.macos.gn"
  # sudo xcode-select -s "/Applications/Xcode_13.4.app"
fi

cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.macos.gn" >> "$_src_dir/out/Default/args.gn"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args

rm -rvf "$_download_cache" "$_root_dir/build/domsubcache.tar.gz"
