#!/bin/bash -eux
# Simple script for packing Ungoogled-Chromium macOS build artifacts on GitHub Actions

_root_dir=$(dirname $(greadlink -f $0))
_src_dir="$_root_dir/build/src"

if [[ -f "$_root_dir/build_finished.log" ]] ; then
  # For packaging
  _chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
  _ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
  _package_revision=$(cat $_root_dir/revision.txt)

  _file_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_macos.dmg"
  _release_tag_version="${_chromium_version}-${_ungoogled_revision}.${_package_revision}"
  
  cd "$_src_dir"

  xattr -csr out/Default/Chromium.app
  # Using ad-hoc signing
  codesign --force --deep --sign - out/Default/Chromium.app

  chrome/installer/mac/pkg-dmg \
    --sourcefile --source out/Default/Chromium.app \
    --target "$_root_dir/$_file_name" \
    --volname Chromium --symlink /Applications:/Applications \
    --format UDBZ --verbosity 2

  cd "$_root_dir"
  sha256sum ./$_file_name | tee ./sums.txt
  _sha256sum=$(awk '{print $1;exit 0}' ./sums.txt)

  echo "::set-output name=file_name::$_file_name"
  echo "::set-output name=release_tag_version::$_release_tag_version"

  _gh_run_href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  _gh_wf_href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/workflow"

  printf '`sha256sum` for diskimage `%s`: \n\n```\n%s\n```\n\n' "$_file_name" "$_sha256sum" | tee -a ./github_release_text.md
  printf 'See [this GitHub Actions Run](%s) for the [Workflow file](%s) used as well as the build logs and artifacts\n' $_gh_wf_href $_gh_run_href | tee -a ./github_release_text.md
else

  if ! hdiutil detach -verbose "$_src_dir" ; then
    sleep 1; umount "$_src_dir"
    sleep 1; sudo umount "$_src_dir"
    sleep 1; hdiutil detach -verbose "$_src_dir" -force
    sleep 1; sudo hdiutil detach -verbose "$_src_dir" -force
  fi
  sleep 2

  hdiutil compact ./build_src.sparsebundle
  # Needs to be compressed to stay below GitHub's upload limit 5-8GB (?)
  tar -c -f - build_src.sparsebundle/ | zstd -T0 -o build_src.sparsebundle.tar.zst

  sha256sum ./build_src.sparsebundle.tar.zst | tee ./sums.txt
fi

mkdir -p upload_part_build
mv -vn ./*.zst ./*.dmg ./sums.txt upload_part_build/ || true
cp -va ./*.log upload_part_build/

ls -kahl upload_part_build/
du -hs upload_part_build/

mkdir upload_logs
mv -vn ./*.log upload_logs/

ls -kahl upload_logs/
du -hs upload_logs/

echo "ready for upload action"
