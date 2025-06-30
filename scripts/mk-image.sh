#!/bin/bash -e
ROOT_DIR=$(pwd)
TARGET_ROOTFS_DIR=${ROOT_DIR}/binary
IMAGE_VERSION=${IMAGE_VERSION:-24.04}
ROOTFSIMAGE=ubuntu-$IMAGE_VERSION-rootfs.img

echo Making system image!

# sudo ./post-build.sh $TARGET_ROOTFS_DIR

# Create directories
echo "fakeroot mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking  \"${ROOTFSIMAGE}\" \"${TARGET_ROOTFS_DIR}\""
fakeroot mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking  ${ROOTFSIMAGE} ${TARGET_ROOTFS_DIR}/

