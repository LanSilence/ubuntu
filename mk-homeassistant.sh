#!/bin/bash
set -ex

# 1. 环境变量
PYTHON_VERSION=3.13
HASS_VERSION=2025.5.3
FRONTEND_VERSION=20250516.0
MATTER_SERVER_VERSION=7.0.0
AIODISCOVER_VERSION=2.7.0
ROOTFSIMAGE=ubuntu-24.02-rootfs.img
TARGET_ROOTFS_DIR=./rootfs
HASS_SOURCE=../homeassistant-core/core-${HASS_VERSION}
IMG=homeassistant.img
IMG_SIZE=1200M

# 2. 创建 ext4 镜像
if [ ! -f $IMG ]; then
    fallocate -l $IMG_SIZE $IMG
    mkfs.ext4 -L hass-img0 $IMG
fi
trap 'echo "Error occurred, checking dmesg..."; dmesg | grep -i "killed"; exit 1' ERR
# 3. 挂载 rootfs 和 homeassistant 分区
mkdir -p $TARGET_ROOTFS_DIR
sudo mount -t erofs -o loop $ROOTFSIMAGE $TARGET_ROOTFS_DIR/
sudo mount $IMG $TARGET_ROOTFS_DIR/homeassistant

# 4. 拷贝 Home Assistant Core 源码
sudo cp -a $HASS_SOURCE/. $TARGET_ROOTFS_DIR/homeassistant

# 5. 挂载 proc/sys/dev（如有 chroot 脚本可用 ch-mount.sh）
if [ -f ./ch-mount.sh ]; then
    ./ch-mount.sh -m $TARGET_ROOTFS_DIR
fi

# 6. 进入 chroot 构建环境
cat << EOF | sudo chroot $TARGET_ROOTFS_DIR
chown -R haos:haos /homeassistant

cd /homeassistant

# 清理
rm -rf pip-cache tests/ requirements_test*.txt .pylintrc mypy.ini
rm -rf pip-build-env-* homeassistant.egg-info uv-cache build/ dist/
rm -f CLA.md CODE_OF_CONDUCT.md CONTRIBUTING.md codecov.yml .coveragerc Dockerfile*
find . -name "__pycache__" -exec rm -rf {} +
rm -rf /homeassistant/tmp
chown -R haos:haos /homeassistant/*
chown -R haos:haos /homeassistant/.*
EOF

# 7. 卸载
if [ -f ./ch-mount.sh ]; then
    ./ch-mount.sh -u $TARGET_ROOTFS_DIR
fi
sudo umount $TARGET_ROOTFS_DIR/homeassistant
sudo umount $TARGET_ROOTFS_DIR/

echo "Home Assistant OS Core ext4 镜像已构建完成：$IMG"



