#!/bin/bash -eux

# Simple script for setting up all toolchain dependencies for building Ungoogled-Chromium on macOS

brew install ninja coreutils --overwrite

# Install httplib2 for Python from PyPI
pip3 install httplib2 --break-system-packages
