#!/bin/bash -e

TARGET_ROOTFS_DIR=./binary
MOUNTPOINT=./rootfs
ROOTFSIMAGE=ubuntu-$IMAGE_VERSION-rootfs.img

echo Making system image!

# sudo ./post-build.sh $TARGET_ROOTFS_DIR

# Create directories
echo "sudo mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking  \"${ROOTFSIMAGE}\" \"${TARGET_ROOTFS_DIR}\""
sudo mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking  ${ROOTFSIMAGE} ${TARGET_ROOTFS_DIR}/

