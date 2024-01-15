#!/bin/bash -eux

_chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
_package_revision=$(cat $_root_dir/revision.txt)
_epoch_finish=$(date +%s)

_x64_file_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_x86-64-macos.dmg"
_arm64_file_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_arm64-macos.dmg"
_release_tag_version="${_chromium_version}-${_ungoogled_revision}.${_package_revision}__${_epoch_finish}"
_release_name="Ungoogled-Chromium macOS ${_release_tag_version}"

echo "x64_file_name=$_x64_file_name" >> $GITHUB_OUTPUT
echo "arm64_file_name=$_arm64_file_name" >> $GITHUB_OUTPUT
echo "release_tag_version=$_release_tag_version" >> $GITHUB_OUTPUT
echo "release_name=$_release_name" >> $GITHUB_OUTPUT
