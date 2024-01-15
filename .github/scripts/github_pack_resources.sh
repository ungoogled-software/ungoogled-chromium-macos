#!/bin/bash -eux

tar -cf ./ | zstd -vv -11 -T0 -o build_resources.tar.zst

sha256sum ./build_resources.tar.zst | tee ./build_resources_sums.txt

mkdir -p upload_build_resources
mv -vn ./*.zst ./build_resources_sums.txt upload_build_resources/ || true
cp -va ./*.log upload_build_resources/

ls -kahl upload_build_resources/
du -hs upload_build_resources/
