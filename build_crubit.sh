#!/usr/bin/env bash

set -eux

# Builds Crubit's cc_bindings_from_rs with the Rust toolchain in the Chromium
# source tree, and installs it to the bin directory of `rust_crubit_root`
# (see flags.macos.gn).

_root_dir="$(dirname "$(greadlink -f "$0")")"
_src_dir="$_root_dir/build/src"
_rust_dir="$_src_dir/third_party/rust-toolchain"
_crubit_root="$_rust_dir/crubit"
_crubit_target_dir="$_src_dir/out/crubit"

# cc_bindings_from_rs dynamically links librustc_driver and libLLVM, which are
# located in rustc/lib of the Rust toolchain (i.e. ../../rustc/lib relative to
# $_crubit_root/bin).
CARGO_HOME="$_crubit_target_dir/cargo_home" \
RUSTC="$_rust_dir/bin/rustc" \
RUSTFLAGS="-Clink-args=-Wl,-rpath,@loader_path/../../rustc/lib" \
  "$_rust_dir/bin/cargo" build --release --locked \
    -p cc_bindings_from_rs --bin cc_bindings_from_rs \
    --manifest-path "$_crubit_root/lib/third_party/crubit/Cargo.toml" \
    --target-dir "$_crubit_target_dir"

mkdir -p "$_crubit_root/bin"
cp "$_crubit_target_dir/release/cc_bindings_from_rs" "$_crubit_root/bin/"

# Make sure the runtime dependencies can be found
"$_crubit_root/bin/cc_bindings_from_rs" --help > /dev/null
