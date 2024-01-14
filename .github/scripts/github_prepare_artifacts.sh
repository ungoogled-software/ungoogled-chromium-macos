#!/bin/bash -eux
# Simple script for packing Ungoogled-Chromium macOS build artifacts on GitHub Actions

_arch="${1:-x86-64}"
_root_dir=$(dirname $(greadlink -f $0))
_src_dir="$_root_dir/build/src"

if [[ -f "$_root_dir/build_finished_$_arch.log" ]] ; then
  # For packaging
  _chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
  _ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
  _package_revision=$(cat $_root_dir/revision.txt)
  _epoch_finish=$(date +%s)

  _cpu=x86-64; grep -qF arm64 "$_src_dir/out/Default/args.gn" && _cpu=arm64
  _file_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_${_cpu}-macos.dmg"
  _release_tag_version="${_chromium_version}-${_ungoogled_revision}.${_package_revision}_${_cpu}__${_epoch_finish}"
  
  cd "$_src_dir"

  xattr -cs out/Default/Chromium.app
  # Using ad-hoc signing
  codesign --force --deep --sign - out/Default/Chromium.app

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
  echo "release_tag_version=$_release_tag_version" >> $GITHUB_OUTPUT

  _gh_run_href="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
  
  printf '[Hashes](https://en.wikipedia.org/wiki/Cryptographic_hash_function) for the disk image `%s`: \n' "$_file_name" | tee ./github_release_text.md
  printf '\n```\n%s\n```\n' "$_hash_md" | tee -a ./github_release_text.md
  printf 'See [this GitHub Actions Run](%s) for the [Workflow file](%s/workflow) used as well as the build logs and artifacts\n' "$_gh_run_href" "$_gh_run_href" | tee -a ./github_release_text.md

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
