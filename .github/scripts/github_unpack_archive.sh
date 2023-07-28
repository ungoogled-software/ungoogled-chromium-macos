#!/bin/bash -eux

# Unpacking script for GitHub Actions

echo "Checking sha256sum of archive:"
sha256sum -c sums.txt

_src_dir="$PWD/build/src"
ls -lrt

mkdir build
echo "Extracting build archive"
tar -C build -xf build_src.tar.zst

rm build_src.tar.zst

sudo df -h
sudo du -hs "$_src_dir"
