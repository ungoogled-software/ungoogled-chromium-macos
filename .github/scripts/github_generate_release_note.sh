#!/bin/bash -eux

_root_dir=$(dirname $(greadlink -f $0))

_chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
_package_revision=$(cat $_root_dir/revision.txt)
_epoch_finish=$(date +%s)

_x64_hash_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_x86-64-macos.dmg.hashes.md"
_arm64_hash_name="ungoogled-chromium_${_chromium_version}-${_ungoogled_revision}.${_package_revision}_arm64-macos.dmg.hashes.md"
_release_tag_version="${_chromium_version}-${_ungoogled_revision}.${_package_revision}__${_epoch_finish}"

touch ./github_release_note.md
printf '## Ungoogled-Chromium %s\n' "$_release_tag_version" | tee -a ./github_release_note.md
printf '\n' | tee -a ./github_release_note.md
cat $_x64_hash_name | tee -a ./github_release_note.md
cat $_arm64_hash_name | tee -a ./github_release_note.md
printf '\n' | tee -a ./github_release_note.md
printf 'See [this GitHub Actions Run](%s) for the [Workflow file](%s/workflow) used as well as the build logs and artifacts\n' "$_gh_run_href" "$_gh_run_href" | tee -a ./github_release_note.md
