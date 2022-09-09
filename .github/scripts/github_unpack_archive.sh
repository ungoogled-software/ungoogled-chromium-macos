#!/bin/bash -eux

# Unpacking script for GitHub Actions

echo "Checking sha256sum of archive:"
sha256sum -c sums.txt

_src_dir="$PWD/build/src"
mkdir -p "$_src_dir"
ls -lrt

# zstd -d --rm ./build_src.sparsebundle.tar.zst
zstd -vv -c -d ./build_src.sparsebundle.tar.zst | tar -x -f -
rm -v ./build_src.sparsebundle.tar.zst

ls -lrt
echo "Mounting build/src folder"
hdiutil attach ./build_src.sparsebundle -mountpoint "$_src_dir" -nobrowse -noverify -noautoopen -noautofsck

sudo df -h
sudo du -hs "$_src_dir"