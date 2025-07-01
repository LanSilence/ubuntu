#!/bin/bash
set -e
rm -rf binary

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
HASS_SOURCE=${1:-../source/homeassistant-core/core-${HASS_VERSION}}
IMG=homeassistant.img
IMG_SIZE=1200M

# wget http://ftp.ubuntu.com/ubuntu/pool/universe/o/opensysusers/opensysusers_0.7.3-5_all.deb -O opensysusers.deb

rm -rf homeassistant.img

touch  $IMG
chmod 777 $IMG

mmdebstrap --arch=arm64 \
  --essential-hook="mkdir -p \$1/etc"\
  --essential-hook='chroot "$1" mkdir -p /mnt/data'\
  --essential-hook='chroot "$1" mkdir -p /mnt/overlay'\
  --essential-hook='chroot "$1" mkdir -p /mnt/config'\
  --essential-hook='chroot "$1" mkdir -p /mnt/boot'\
  --essential-hook='chroot "$1" mkdir -p /homeassistant'\
  --customize-hook='chroot "$1" sh -c "echo homeassistant > /etc/hostname"'\
  --customize-hook='cp -r hass-core/* "$1"/homeassistant/'\
  --customize-hook='cp scripts/mmdeb-hass-img.sh "$1"/homeassistant'\
  --customize-hook='chroot "$1" chmod +x /homeassistant/mmdeb-hass-img.sh'\
  --customize-hook='cp -rpf rootfs-overlay/* "$1"/'\
  --customize-hook='chroot "$1" chown -R 1000:1000 /homeassistant'\
  --customize-hook='mkfs.ext4 -b 4096 -L hass-core -d "$1"/homeassistant ./homeassistant.img 307200'\
  --customize-hook='chroot "$1" rm -rf /homeassistant/*'\
  --customize-hook='chroot "$1" apt remove -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu build-essential'\
  --setup-hook='cp /home/lan/homeassistant/haos-core/ubuntu/rootfs-overlay/etc/shadow "$1"/etc/'\
  --setup-hook='cp /home/lan/homeassistant/haos-core/ubuntu/rootfs-overlay/etc/passwd "$1"/etc/'\
  --setup-hook='cp /home/lan/homeassistant/haos-core/ubuntu/rootfs-overlay/etc/group "$1"/etc/'\
  --variant=minbase \
  noble  rootfs.tar.gz http://ports.ubuntu.com/ubuntu-ports 
   # --include="sudo,bash,iproute2,iputils-ping,libusb-1.0-0,usbutils,network-manager,systemd-timesyncd,wpasupplicant,unzip,wireless-tools,systemd-resolved,u-boot-tools,fdisk,jq,software-properties-common,vim,net-tools,iproute2,curl,wget,openssh-server" 

mkdir binary
tar --exclude='dev/*' -xzf rootfs.tar.gz -C binary

fakeroot mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking ubuntu-24.04-rootfs.img binary/