#!/bin/bash -eux
# Simple script for packing Ungoogled-Chromium macOS build artifacts on GitHub Actions

_target_cpu="${1:-x86_64}"

_root_dir="$(dirname "$(greadlink -f "$0")")"
_src_dir="$_root_dir/build/src"

# If build finished successfully
if [[ -f "$_root_dir/build_finished_$_target_cpu.log" ]] ; then
  # For packaging
  _chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
  _ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
  _package_revision=$(cat $_root_dir/revision.txt)

  _file_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_${_target_cpu}-macos.dmg"
  _hash_name="${_file_name}.hashes.md"

  cd "$_src_dir"

  xattr -cs out/Default/Chromium.app

  # Prepar the certificate for app signing
  echo $MACOS_CERTIFICATE | base64 --decode > "$TMPDIR/certificate.p12"

  security create-keychain -p "$MACOS_CI_KEYCHAIN_PWD" build.keychain
  security default-keychain -s build.keychain
  security unlock-keychain -p "$MACOS_CI_KEYCHAIN_PWD" build.keychain
  security import "$TMPDIR/certificate.p12" -k build.keychain -P "$MACOS_CERTIFICATE_PWD" -T /usr/bin/codesign
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$MACOS_CI_KEYCHAIN_PWD" build.keychain

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
  ditto -c -k --keepParent "out/Default/Chromium.app" "$TMPDIR/notarize.zip"

  # Notarize the app
  xcrun notarytool submit "$TMPDIR/notarize.zip" --wait \
    --apple-id "$PROD_MACOS_NOTARIZATION_APPLE_ID" \
    --team-id "$PROD_MACOS_NOTARIZATION_TEAM_ID" \
    --password "$PROD_MACOS_NOTARIZATION_PWD"
  xcrun stapler staple "out/Default/Chromium.app"

  # Package the app
  chrome/installer/mac/pkg-dmg \
    --sourcefile --source out/Default/Chromium.app \
    --target "$_root_dir/$_file_name" \
    --volname Chromium --symlink /Applications:/Applications \
    --format UDBZ --verbosity 2

  cd "$_root_dir"
  echo -e "md5: \nsha1: \nsha256: " | tee ./hash_types.txt
  { md5sum "$_file_name" ; sha1sum "$_file_name" ; sha256sum "$_file_name" ; } | tee ./sums.txt

  _hash_md=$(paste ./hash_types.txt ./sums.txt | awk '{print $1 " " $2}')

  echo "file_name=$_file_name" >> $GITHUB_OUTPUT

  _gh_run_href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

  printf '[Hashes](https://en.wikipedia.org/wiki/Cryptographic_hash_function) for the disk image `%s`: \n' "$_file_name" | tee -a ./${_hash_name}
  printf '\n```\n%s\n```\n' "$_hash_md" | tee -a ./${_hash_name}

  # Use separate folder for build product, so that it can be used as individual asset in case the release action fails
  mkdir -p release_asset
  mv -vn ./*.dmg release_asset/ || true

  ls -kahl release_asset/
  du -hs release_asset/
fi

gsync --file-system "$_src_dir"

# Needs to be compressed to stay below GitHub's upload limit 2 GB (?!) 2020-11-24; used to be  5-8GB (?)
tar -C build -c -f - src | zstd -vv -11 -T0 -o build_src.tar.zst

sha256sum ./build_src.tar.zst | tee ./sums.txt

mkdir -p upload_part_build
mv -vn ./*.zst ./sums.txt upload_part_build/ || true
cp -va ./*.log upload_part_build/

ls -kahl upload_part_build/
du -hs upload_part_build/

mkdir upload_logs
mv -vn ./*.log upload_logs/

ls -kahl upload_logs/
du -hs upload_logs/

echo "ready for upload action"
