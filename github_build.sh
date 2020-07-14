#!/bin/bash -eux

# Simple partitioned (2 of 3) build script for building Ungoogled-Chromium macOS binaries on GitHub Actions
# Resuming build script for macOS

_root_dir=$(dirname $(greadlink -f $0))
cd build/src

echo $(date +%s) | tee -a "$_root_dir/build_times.log"
echo "::set-output name=status::running"

timeout -k 7m -s SIGTERM 318m ninja -C out/Default chrome chromedriver # TODO check wiggle room for >310m

echo $(date +%s) | tee "$_root_dir/build_finished.log"
echo "::set-output name=status::finished"
