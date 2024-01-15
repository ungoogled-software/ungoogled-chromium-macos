#!/bin/bash -eux

# Unpacking script for GitHub Actions

echo "Checking sha256sum of archive:"
sha256sum -c build_resources_sums.txt

ls -lrt

echo "Extracting build archive"
tar -xf build_resources.tar.zst

rm build_resources.tar.zst
