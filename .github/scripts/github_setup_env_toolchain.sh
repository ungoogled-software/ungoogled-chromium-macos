#!/bin/bash -eux

# Simple script for setting up all toolchain dependencies and environment variables for building Ungoogled-Chromium on macOS

_arch="$(/usr/bin/uname -m)"

# Install Homebrew for x86_64 (arm64 installation is not needed as it comes pre-installed on GitHub Action Runners)
if [[ $_arch == "x86_64" ]]; then
  /usr/bin/arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies from Homebrew
if [[ $_arch == "x86_64" ]]; then
  # Install expat as a workaround for a bug in the Python 3.13 formula.
  # See https://github.com/Homebrew/homebrew-core/issues/206778.
  /usr/bin/arch -x86_64 /usr/local/bin/brew install expat
  /usr/bin/arch -x86_64 /usr/local/bin/brew install python3 llvm ninja coreutils readline xz zlib binutils node --overwrite
else
  /usr/bin/arch -arm64 /opt/homebrew/bin/brew install python3 llvm ninja coreutils readline xz zlib binutils node --overwrite
fi

# Paths for required toolchain binaries
_x86_64_homebrew_path="/usr/local/opt"
_arm64_homebrew_path="/opt/homebrew/opt"
_homebrew_path="$_x86_64_homebrew_path"
if [[ $_arch == "arm64" ]]; then
  _homebrew_path="$_arm64_homebrew_path"
fi
_clangxx_path="$_homebrew_path/llvm/bin"
_ninja_path="$_homebrew_path/ninja/bin"
_python_path="$_homebrew_path/python3/bin"

# Install httplib2 for Python from PyPI
/usr/bin/arch -$_arch $_python_path/pip3 install httplib2 --break-system-packages

# Set environment variables
export PATH="$_clangxx_path:$_ninja_path:$_python_path:$PATH"
export CXX="$_clangxx_path/clang++"
export NINJA="$_ninja_path/ninja"
export LDFLAGS="-L$_homebrew_path/llvm/lib"
export CPPFLAGS="-I$_homebrew_path/llvm/include"

# Setup GitHub Actions environment variables
echo "$_clangxx_path" >> $GITHUB_PATH
echo "$_ninja_path" >> $GITHUB_PATH
echo "$_python_path" >> $GITHUB_PATH
echo "CXX=$_clangxx_path/clang++" >> $GITHUB_ENV
echo "NINJA=$_ninja_path/ninja" >> $GITHUB_ENV
echo "LDFLAGS=-L$_homebrew_path/llvm/lib" >> $GITHUB_ENV
echo "CPPFLAGS=-I$_homebrew_path/llvm/include" >> $GITHUB_ENV
