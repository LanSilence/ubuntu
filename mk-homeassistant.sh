#!/bin/bash -e
set -e
TARGET_ROOTFS_DIR=./rootfs

ROOTFSIMAGE=ubuntu-$IMAGE_VERSION-rootfs.img
HASS_SOURCE=${1:-"../homeassistant-core/core-2025.5.3"}
finish() {
    if mountpoint -q "${TARGET_ROOTFS_DIR}/proc"; then
        ./ch-mount.sh -u $TARGET_ROOTFS_DIR
    fi
    if mountpoint -q "${TARGET_ROOTFS_DIR}/homeassistant"; then
        sudo umount "${TARGET_ROOTFS_DIR}/homeassistant"
    fi
    if mountpoint -q "${TARGET_ROOTFS_DIR}"; then
        sudo umount "${TARGET_ROOTFS_DIR}/"
    fi
    echo -e "error exit"
    exit -1
}
trap finish ERR

echo Making home assistant image!

if [ ! -f homeassistant.img ]; then
    fallocate -l 800M homeassistant.img
    mkfs.ext4 -L hass-img0 homeassistant.img
fi
sudo mount -t erofs  -o loop ${ROOTFSIMAGE} ${TARGET_ROOTFS_DIR}/
sudo mount homeassistant.img ${TARGET_ROOTFS_DIR}/homeassistant
sudo cp -rpf ${HASS_SOURCE}/* ${TARGET_ROOTFS_DIR}/homeassistant
./ch-mount.sh -m ${TARGET_ROOTFS_DIR}

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/
cd /homeassistant
python3.13 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install --cache-dir /homeassistant/pip-cache  -r requirements.txt -c homeassistant/package_constraints.txt
rm -rf /homeassistant/pip-cache
rm -rf tests/                   # 测试代码[2](@ref)
rm -f requirements_test*.txt    # 测试依赖文件[2](@ref)
rm -f .pylintrc                 # lint配置
rm -f mypy.ini                  # 类型检查配置

# 构建/缓存文件
rm -rf pip-build-env-*          # pip临时构建环境[1](@ref)
rm -rf homeassistant.egg-info   # 安装元数据[1](@ref)
rm -rf uv-cache                 # UV工具缓存[5](@ref)
rm -rf build/ dist/             # 构建产物目录

# 文档/协作文件
rm -f CLA.md CODE_OF_CONDUCT.md CONTRIBUTING.md
rm -f codecov.yml .coveragerc   # 覆盖率配置
rm -f Dockerfile*               # 容器配置（除非需要容器化）
find . -name "__pycache__" -exec rm -rf {} +
EOF

./ch-mount.sh -u $TARGET_ROOTFS_DIR
sudo umount ${TARGET_ROOTFS_DIR}/homeassistant
sudo umount  ${TARGET_ROOTFS_DIR}/
# sudo ./post-build.sh $TARGET_ROOTFS_DIR

# Create directories



