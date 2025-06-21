#!/bin/bash
set -e

ROOT_DIR=$(pwd)
TARGET_ROOTFS_DIR=${ROOT_DIR}/binary/
OVERLAY_DIR=${ROOT_DIR}/rootfs-overlay/

SCRIPTS_DIR=${ROOT_DIR}/scripts

export ROOT_DIR
export TARGET_ROOTFS_DIR
export OVERLAY_DIR
$SCRIPTS_DIR/copy-overlay.sh
IMAGE_VERSION=24.02 ./mk-image.sh
