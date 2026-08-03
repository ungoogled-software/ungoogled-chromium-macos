#!/usr/bin/env bash

set -eux

# Build script for local macOS environment

# Some path variables
_root_dir="$(dirname "$(greadlink -f "$0")")"
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"
_cipd="$_src_dir/third_party/depot_tools/cipd"

# Clone to get the Chromium Source
clone=true
while getopts 'd' OPTION; do
  case "$OPTION" in
    d)
      clone=false
      ;;
  esac
done

shift "$(($OPTIND -1))"

_arch=${1:-arm64}

# Add local clang and build tools to PATH
# export PATH="$PATH:$_src_dir/third_party/llvm-build/Release+Asserts/bin"

rm -rf "$_src_dir/out" || true
mkdir -p "$_download_cache"

if $clone; then
  "$_root_dir/retrieve_and_unpack_resource.sh" -g $_arch
else
  "$_root_dir/retrieve_and_unpack_resource.sh" -d -g $_arch
fi

mkdir -p "$_src_dir/out/Default"

# Apply patches and substitutions
python3 "$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
python3 "$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"

python3 "$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"
# Set build flags
cat "$_main_repo/flags.gn" "$_root_dir/flags.macos.gn" > "$_src_dir/out/Default/args.gn"

# Set target_cpu to the corresponding architecture
if [[ $_arch == "arm64" ]]; then
  echo 'target_cpu = "arm64"' >> "$_src_dir/out/Default/args.gn"
else
  echo 'target_cpu = "x64"' >> "$_src_dir/out/Default/args.gn"
fi

mkdir -p "$_src_dir/third_party/llvm-build/Release+Asserts"
mkdir -p "$_src_dir/third_party/rust-toolchain/bin"

"$_root_dir/retrieve_and_unpack_resource.sh" -p $_arch

# Dawn's Tint source generator uses a DEPS-pinned Go toolchain. It is not part
# of the downloadable source archive and must be restored after binary pruning.
case "$(uname -m)" in
  arm64)
    _dawn_go_platform="mac-arm64"
    ;;
  x86_64)
    _dawn_go_platform="mac-amd64"
    ;;
  *)
    echo "Unsupported macOS host architecture: $(uname -m)" >&2
    exit 1
    ;;
esac
printf 'infra/3pp/tools/go/%s version:3@1.25.0\n' "$_dawn_go_platform" |
  "$_cipd" ensure \
    -cache-dir "$_download_cache/cipd" \
    -root "$_src_dir/third_party/dawn/tools/golang/$_dawn_go_platform" \
    -ensure-file -

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./tools/rust/build_bindgen.py --skip-test

./out/Default/gn gen out/Default --fail-on-unused-args

ninja -C out/Default chrome chromedriver

"$_root_dir/sign_and_package_app.sh"
