#!/usr/bin/env bash

set -eux

# Simple build script for macOS

_root_dir=$(dirname $(greadlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

# For packaging
_chromium_version=$(cat "$_root_dir"/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat "$_root_dir"/ungoogled-chromium/revision.txt)
_package_revision=$(cat "$_root_dir"/revision.txt)

# Add local clang and build tools to PATH
# export PATH="$PATH:$_src_dir/third_party/llvm-build/Release+Asserts/bin"

rm -rf "$_src_dir/out" || true
mkdir -p "$_src_dir/out/Default"
mkdir -p "$_download_cache"

"$_root_dir/retrieve_and_unpack_resource.sh" -g

"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list" --keep-contingent-paths
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" "$_src_dir"
cat "$_main_repo/flags.gn" "$_root_dir/flags.macos.gn" > "$_src_dir/out/Default/args.gn"

"$_root_dir/retrieve_and_unpack_resource.sh" -p

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./tools/rust/build_bindgen.py

./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome chromedriver

chrome/installer/mac/pkg-dmg \
  --sourcefile --source out/Default/Chromium.app \
  --target "$_root_dir/build/ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_macos.dmg" \
  --volname Chromium --symlink /Applications:/Applications \
  --format UDBZ --verbosity 2

# Fix issue where macOS requests permission for incoming network connections
# See https://github.com/ungoogled-software/ungoogled-chromium-macos/issues/17
xattr -cs out/Default/Chromium.app

# Sign the binary
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier chrome_crashpad_handler --options=restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/chrome_crashpad_handler
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper.app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper.renderer --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-renderer-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Renderer\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-gpu-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(GPU\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.helper.plugin --options restrict,kill,runtime --entitlements $_root_dir/entitlements/helper-plugin-entitlements.plist out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Plugin\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.framework.AlertNotificationService --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/Chromium\ Helper\ \(Alerts\).app
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier app_mode_loader --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/app_mode_loader
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier web_app_shortcut_copier --options restrict,library,runtime,kill out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Helpers/web_app_shortcut_copier
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libEGL out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libEGL.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libGLESv2 out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libGLESv2.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier libvk_swiftshader out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework/Libraries/libvk_swiftshader.dylib
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium.framework out/Default/Chromium.app/Contents/Frameworks/Chromium\ Framework.framework
codesign --sign "$MACOS_CERTIFICATE_NAME" --force --timestamp --identifier io.ungoogled-software.ungoogled-chromium --options restrict,library,runtime,kill --entitlements $_root_dir/entitlements/app-entitlements.plist --requirements '=designated => identifier "io.ungoogled-software.ungoogled-chromium" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */' out/Default/Chromium.app

# Verify the binary signature
codesign --verify --deep --verbose=4 out/Default/Chromium.app

# Pepare app notarization
ditto -c -k --keepParent "out/Default/Chromium.app" "notarize.zip"

# Notarize the app
xcrun notarytool store-credentials "notarytool-profile" --apple-id "$PROD_MACOS_NOTARIZATION_APPLE_ID" --team-id "$PROD_MACOS_NOTARIZATION_TEAM_ID" --password "$PROD_MACOS_NOTARIZATION_PWD"
xcrun notarytool submit "notarize.zip" --keychain-profile "notarytool-profile" --wait
xcrun stapler staple "out/Default/Chromium.app"

# If you do not have an Apple Developer account to notarize the app, or you do not want to notarize the app
# comment the lines above and uncomment the following line to use ad-hoc signing

# Using ad-hoc signing
# codesign --force --deep --sign - out/Default/Chromium.app
