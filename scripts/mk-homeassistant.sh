#!/bin/bash
set -e

# 1. 环境变量
PYTHON_VERSION=3.13
HASS_VERSION=2025.5.3
FRONTEND_VERSION=20250516.0
MATTER_SERVER_VERSION=7.0.0
AIODISCOVER_VERSION=2.7.0
ROOTFSIMAGE=ubuntu-24.04-rootfs.img
ROOT_DIR=$(pwd)
TARGET_ROOTFS_DIR=${ROOT_DIR}/binary
SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
HASS_SOURCE=${1:-../homeassistant-core/core-${HASS_VERSION}}
IMG=homeassistant.img
IMG_SIZE=1200M

# 2. 创建 ext4 镜像
if [ ! -f $IMG ]; then
    fallocate -l $IMG_SIZE $IMG
    mkfs.ext4 -L hass-core $IMG
fi

# 3. 挂载 rootfs 和 homeassistant 分区
# mkdir -p $TARGET_ROOTFS_DIR
# sudo mount -t erofs -o loop $ROOTFSIMAGE $TARGET_ROOTFS_DIR/
sudo mount $IMG $TARGET_ROOTFS_DIR/homeassistant

# 4. 拷贝 Home Assistant Core 源码
sudo cp -a $HASS_SOURCE/. $TARGET_ROOTFS_DIR/homeassistant

# 5. 挂载 proc/sys/dev（如有 chroot 脚本可用 ch-mount.sh）
if [ -f ${SCRIPTS_DIR}/ch-mount.sh ]; then
    ${SCRIPTS_DIR}/ch-mount.sh -m $TARGET_ROOTFS_DIR
fi

# 6. 进入 chroot 构建环境
cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/
apt update
mkdir -p /var/cache/apt/archives/partial
apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu python3-dev build-essential

chown -R haos:haos /homeassistant
su haos
mkdir -p /home/haos/uv-cache
cd /homeassistant

python${PYTHON_VERSION} -m venv venv
source venv/bin/activate
export UV_LINK_MODE=copy
export TMPDIR=/home/haos/tmp
export PIP_NO_CACHE_DIR=1
export UV_CONCURRENT_DOWNLOADS=1
mkdir -p ${TMPDIR}
export UV_CACHE_DIR=/home/haos/uv-cache
pip3 install uv==0.7.1
pip install --upgrade pip
pip install -r requirements.txt -c homeassistant/package_constraints.txt

# 安装前端、matter-server、aiodiscover
/homeassistant/venv/bin/uv pip install home-assistant-frontend==${FRONTEND_VERSION} --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install python-matter-server==${MATTER_SERVER_VERSION} --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install aiodiscover==${AIODISCOVER_VERSION} --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet aiodhcpwatcher==1.1.1 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet av==13.1.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
/homeassistant/venv/bin/uv pip install --quiet PyNaCl==1.5.0 --index-strategy unsafe-first-match --upgrade --constraint /homeassistant/homeassistant/package_constraints.txt
# 下载并解压 translations（本地构建无需下载，官方包已自带translations）
# if [ -f script/translations.py ]; then
#     python3 -m script.translations download
# fi

# 可选：预编译前端资源
if [ -f script/frontend.py ]; then
    python3 -m script.frontend
fi

# 清理
rm -rf pip-cache tests/ requirements_test*.txt .pylintrc mypy.ini
rm -rf pip-build-env-* homeassistant.egg-info uv-cache build/ dist/
rm -f CLA.md CODE_OF_CONDUCT.md CONTRIBUTING.md codecov.yml .coveragerc Dockerfile*
find . -name "__pycache__" -exec rm -rf {} +
rm -rf /home/haos/tmp ${UV_CACHE_DIR}
exit
EOF

# 7. 卸载
if [ -f ${SCRIPTS_DIR}/ch-mount.sh ]; then
    ${SCRIPTS_DIR}/ch-mount.sh -u $TARGET_ROOTFS_DIR
fi
sudo umount $TARGET_ROOTFS_DIR/homeassistant

echo "Home Assistant OS Core ext4 镜像已构建完成：$IMG"



