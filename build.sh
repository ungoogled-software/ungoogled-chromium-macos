#!/usr/bin/env bash

set -eux

# Build script for local macOS environment

# Some path variables
_root_dir="$(dirname "$(greadlink -f "$0")")"
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

# Clone to get the Chromium Source
clone=true
_sdk_path=""
while getopts ':ds:h' OPTION; do
  case "$OPTION" in
    d)
      clone=false
      ;;
    s)
      _sdk_path=$OPTARG
      if [[ ! -d "$_sdk_path" || ! -f "$_sdk_path/SDKSettings.json" ]]; then
        echo "Invalid macOS SDK directory: $_sdk_path" >&2
        exit 1
      fi
      _sdk_path="$(greadlink -f "$_sdk_path")"
      ;;
    h)
      echo "Usage: $0 [-d] [-s SDK_PATH] [arm64|x86_64]"
      echo "  -d             Reuse downloaded source archives"
      echo "  -s SDK_PATH    Use this macOS SDK for Chromium and bindgen (default: automatic)"
      exit 0
      ;;
    *)
      echo "Usage: $0 [-d] [-s SDK_PATH] [arm64|x86_64]" >&2
      exit 1
      ;;
  esac
done

shift "$(($OPTIND -1))"

_arch=${1:-arm64}

if [[ -n "$_sdk_path" ]]; then
  # build_bindgen.py asks xcrun for the SDK; SDKROOT controls that selection.
  export SDKROOT="$_sdk_path"
fi

# Add local clang and build tools to PATH
# export PATH="$PATH:$_src_dir/third_party/llvm-build/Release+Asserts/bin"

rm -rf "$_src_dir/out" || true
mkdir -p "$_download_cache"

if $clone; then
  "$_root_dir/retrieve_and_unpack_resource.py" -g $_arch
else
  "$_root_dir/retrieve_and_unpack_resource.py" -d -g $_arch
fi

mkdir -p "$_src_dir/out/Default"

# Apply patches and substitutions
python3 "$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
python3 "$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"

python3 "$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"
# Set build flags
cat "$_main_repo/flags.gn" "$_root_dir/flags.macos.gn" > "$_src_dir/out/Default/args.gn"

if [[ -n "$_sdk_path" ]]; then
  # Chromium's sdk_inputs action requires its SDK path inside root_build_dir.
  mkdir -p "$_src_dir/out/Default/sdk"
  ln -s "$_sdk_path" "$_src_dir/out/Default/sdk/selected_macos_sdk"
  echo 'mac_sdk_path = "//out/Default/sdk/selected_macos_sdk"' >> "$_src_dir/out/Default/args.gn"
fi

# Set target_cpu to the corresponding architecture
if [[ $_arch == "arm64" ]]; then
  echo 'target_cpu = "arm64"' >> "$_src_dir/out/Default/args.gn"
else
  echo 'target_cpu = "x64"' >> "$_src_dir/out/Default/args.gn"
fi

mkdir -p "$_src_dir/third_party/llvm-build/Release+Asserts"
mkdir -p "$_src_dir/third_party/rust-toolchain/bin"

"$_root_dir/retrieve_and_unpack_resource.py" -p $_arch

cd "$_src_dir"

# Fix ESBuild
_esbuild_version="$(/opt/homebrew/bin/esbuild --version)"
_esbuild_module="$_root_dir/build/esbuild-node/node_modules/esbuild"
if [[ ! -f "$_esbuild_module/package.json" ]] || \
    [[ "$(node -p 'require(process.argv[1]).version' "$_esbuild_module/package.json")" != "$_esbuild_version" ]]; then
  npm install --prefix "$_root_dir/build/esbuild-node" --no-save --package-lock=false --no-bin-links --ignore-scripts --omit=optional --no-audit --no-fund "esbuild@$_esbuild_version"
fi
rm -rf third_party/devtools-frontend/src/node_modules/esbuild
ln -s "$_esbuild_module" third_party/devtools-frontend/src/node_modules/esbuild

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./tools/rust/build_bindgen.py --skip-test

./out/Default/gn gen out/Default --fail-on-unused-args

ninja -C out/Default chrome chromedriver

CHROMIUM_SRC_DIR="$_src_dir" "$_root_dir/sign_and_package_app.sh"
