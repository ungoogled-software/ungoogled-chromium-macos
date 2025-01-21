#!/bin/bash -eux

# Simple partitioned (2 of 3) build script for building Ungoogled-Chromium macOS binaries on GitHub Actions
# Resuming build script for macOS

_target_cpu="${1:-x86_64}"

_x86_64_homebrew_path="/usr/local/opt"
_arm64_homebrew_path="/opt/homebrew/opt"
_homebrew_path="$_x86_64_homebrew_path"
if [[ $_target_cpu == "arm64" ]]; then
  _homebrew_path="$_arm64_homebrew_path"
fi
_clangxx_path="$_homebrew_path/llvm/bin"
_ninja_path="$_homebrew_path/ninja/bin"
_python_path="$_homebrew_path/python3/bin"

_root_dir=$(dirname $(greadlink -f $0))
_src_dir="$_root_dir/build/src"
if [[ -f "$_root_dir/epoch_job_start.txt" ]]; then
  epoch_job_start=$(cat "$_root_dir/epoch_job_start.txt")
  # GitHub's hard time limit is 6 h per job, we want to spare 1 h for steps before and after the build,
  # To get the remaining time for building we subtract 360*60s - 60*60s - (epoch_now - epoch_job_start)
  _remaining_time=$(( 360*60 - 60*60 - $(date +%s) + epoch_job_start ))
fi

cd "$_src_dir"

ln -s "$_src_dir/third_party" "$_src_dir/../third_party"

echo $(date +%s) | tee -a "$_root_dir/build_times_$_target_cpu.log"
echo "status=running" >> $GITHUB_OUTPUT

timeout --preserve-status -k 7m -s SIGTERM ${_remaining_time:-19680}s /usr/bin/arch -$_target_cpu $_ninja_path/ninja -C out/Default chrome chromedriver # 328 m as default $_remaining_time

echo $(date +%s) | tee "$_root_dir/build_finished_$_target_cpu.log"
echo "status=finished" >> $GITHUB_OUTPUT
