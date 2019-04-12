#!/bin/bash -eux

PLATFORM_ROOT=$(dirname $(greadlink -f ${BASH_SOURCE[0]}))
UNGOOGLED_REPO=$PLATFORM_ROOT/upstream/ungoogled-chromium

_command=$1

$UNGOOGLED_REPO/devutils/update_platform_patches.py $_command $PLATFORM_ROOT/patches
