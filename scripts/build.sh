#!/bin/bash
set -e

ROOT_DIR=$(pwd)
TARGET_ROOTFS_DIR=${ROOT_DIR}/binary/
OVERLAY_DIR=${ROOT_DIR}/rootfs-overlay/

SCRIPTS_DIR=${ROOT_DIR}/scripts
HACODE=${1:-"../source/homeassistant-core/core-2025.5.3"}
export ROOT_DIR
export TARGET_ROOTFS_DIR
export OVERLAY_DIR
if [ ! -f .ubuntuimg ]; then
    echo "Ubuntu image not found, creating..."
    ${SCRIPTS_DIR}/mk-ubuntu.sh && touch .ubuntuimg
else
    echo "Ubuntu image already exists, skipping creation."
fi

if [ ! -f .ubuntuimg ];  then
    echo "############## Ubuntu image build fail exit. #######################"
    exit 1
fi

