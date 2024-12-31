#!/bin/bash -eux

# Simple script for getting ready to build Ungoogled-Chromium macOS binaries on GitHub Actions

_target_cpu="$(/usr/bin/uname -m)"

# Paths for required toolchain binaries
_x86_64_homebrew_path="/usr/local/opt"
_arm64_homebrew_path="/opt/homebrew/opt"
_homebrew_path="$_x86_64_homebrew_path"
if [[ $_target_cpu == "arm64" ]]; then
  _homebrew_path="$_arm64_homebrew_path"
fi
_clangxx_path="$_homebrew_path/llvm/bin"
_ninja_path="$_homebrew_path/ninja/bin"
_python_path="$_homebrew_path/python3/bin"

# Some path variables
_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

shopt -s nocasematch

if [[ $_target_cpu == "arm64" ]]; then
  echo 'target_cpu = "arm64"' >> "$_root_dir/flags.macos.gn"
else
  echo 'target_cpu = "x64"' >> "$_root_dir/flags.macos.gn"
fi

cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.macos.gn" >> "$_src_dir/out/Default/args.gn"

cd "$_src_dir"

_rust_target="x86_64-apple-darwin"
if [[ $_target_cpu == "arm64" ]]; then
  _rust_target="aarch64-apple-darwin"
fi

/usr/bin/arch -$_target_cpu $_python_path/python3 ./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
/usr/bin/arch -$_target_cpu $_python_path/python3 ./tools/rust/build_bindgen.py --rust-target $_rust_target

/usr/bin/arch -$_target_cpu ./out/Default/gn gen out/Default --fail-on-unused-args
