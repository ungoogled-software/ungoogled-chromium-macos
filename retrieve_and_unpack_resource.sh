#!/usr/bin/env bash

set -eux

# Script to retrieve and unpack resources to build Chromium macOS

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

while getopts 'gp' OPTION; do
  case "$OPTION" in
    g)
        # Retrieve and unpack general resources
        "$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache"
        "$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" "$_root_dir/downloads.ini" -c "$_download_cache" "$_src_dir"
        ;;
    p)
        rm -rf "$_src_dir/third_party/llvm-build/Release+Asserts/"
        rm -rf "$_src_dir/third_party/rust-toolchain/bin"

        # Retrieve and unpack platform-specific resources
        if [ "$(uname -m)" = "arm64" ]; then
            # For arm64 (Apple Silicon)
            "$_main_repo/utils/downloads.py" retrieve -i "$_root_dir/downloads-arm64.ini" -c "$_download_cache"
            mkdir -p "$_src_dir/third_party/node/mac_arm64/node-darwin-arm64/"
            "$_main_repo/utils/downloads.py" unpack -i "$_root_dir/downloads-arm64.ini" -c "$_download_cache" "$_src_dir"
        else
            # For x86-64 (Intel)
            "$_main_repo/utils/downloads.py" retrieve -i "$_root_dir/downloads-x86-64.ini" -c "$_download_cache"
            mkdir -p "$_src_dir/third_party/node/mac/node-darwin-x64/"
            "$_main_repo/utils/downloads.py" unpack -i "$_root_dir/downloads-x86-64.ini" -c "$_download_cache" "$_src_dir"
        fi

        ## Rust Resource
        _rust_name="x86_64-apple-darwin"
        if [ "$(uname -m)" = "arm64" ]; then
            _rust_name="aarch64-apple-darwin"
        fi

        _rust_dir="$_src_dir/third_party/rust-toolchain"
        _rust_bin_dir="$_rust_dir/bin"
        _rust_flag_file="$_rust_dir/INSTALLED_VERSION"

        _rust_lib_dir="$_rust_dir/rust-std-$_rust_name/lib/rustlib/$_rust_name/lib"
        _rustc_dir="$_rust_dir/rustc"
        _rustc_lib_dir="$_rust_dir/rustc/lib/rustlib/$_rust_name/lib"

        echo "rustc 1.81.0-nightly (f8e566053 2024-06-14)" > "$_rust_flag_file"

        mkdir $_rust_bin_dir
        ln -s "$_rust_dir/rustc/bin/rustc" "$_rust_bin_dir/rustc"
        ln -s "$_rust_dir/cargo/bin/cargo" "$_rust_bin_dir/cargo"
        ln -s "$_rust_lib_dir" "$_rustc_lib_dir"

        _llvm_dir="$_src_dir/third_party/llvm-build/Release+Asserts"
        _llvm_bin_dir="$_llvm_dir/bin"

        ln -s "$_llvm_bin_dir/llvm-install-name-tool" "$_llvm_bin_dir/install_name_tool"
        ;;
    ?)
        echo "Usage: $0 [-g] [-p]"
        exit 1
        ;;
    esac
done

shift "$(($OPTIND -1))"
