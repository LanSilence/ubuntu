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
HASS_SOURCE=${1:-../source/homeassistant-core/core-${HASS_VERSION}}
IMG=homeassistant.img
IMG_SIZE=1200M
HASS_SOURCE_LINK=https://github.com/home-assistant/core/archive/refs/tags/${HASS_VERSION}.tar.gz
HASS_CACHE=cache/homeassistant-core-v${HASS_VERSION}
# wget http://ftp.ubuntu.com/ubuntu/pool/universe/o/opensysusers/opensysusers_0.7.3-5_all.deb -O opensysusers.deb


if [ ! -f $HASS_SOURCE ]; then
  if [ ! -f cache/.hasscore ]; then
      mkdir -p cache/
      wget -O ${HASS_CACHE} ${HASS_SOURCE_LINK} && touch cache/.hasscore
  fi
else
  mkdir -p hass-core
  cp -r $HASS_SOURCE/* hass-core/
fi

if [ ! -d hass-core ] || [ -z "$(ls -A hass-core 2>/dev/null)" ]; then
    mkdir -p hass-core
    tar -xzf ${HASS_CACHE} -C hass-core
    mv hass-core/core-$HASS_VERSION/* ./hass-core
    rm -rf ./hass-core/core-$HASS_VERSION
fi

# 获取最新版本号
if [ ! -f cache/assismgr.deb ];then
ASSISMGER_LATEST_VERSION=$(curl -s https://api.github.com/repos/LanSilence/assismgr/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
wget -O cache/assismgr.deb https://github.com/LanSilence/assismgr/releases/download/${ASSISMGER_LATEST_VERSION}/assismgr_${ASSISMGER_LATEST_VERSION}_arm64.deb
fi

if [ ! -f rootfs.tar.gz ];then
rm -rf homeassistant.img

touch  $IMG
chmod 777 $IMG
mmdebstrap --arch=arm64 \
  --customize-hook='chroot "$1" apt install -y systemd || true ;chroot "$1" mv -f /bin/systemd-sysusers /bin/systemd-sysusers.org&& chroot "$1" ln -s /bin/echo /bin/systemd-sysusers'\
  --customize-hook='chroot "$1" apt install -y network-manager systemd-timesyncd wpasupplicant  wireless-tools systemd-resolved u-boot-tools fdisk jq software-properties-common  openssh-server' \
  --components="main universe multiverse restricted"\
  --include="apt,vim,libubootenv-tool,net-tools,iproute2,curl,wget,unzip,sudo,bash,iputils-ping,libusb-1.0-0,usbutils,mosquitto"\
  --setup-hook="mkdir -p \$1/etc" \
  --customize-hook='cp cache/assismgr.deb "$1"/var/'\
  --customize-hook='chroot "$1" dpkg -i /var/assismgr.deb'\
  --customize-hook='chroot "$1" add-apt-repository -y ppa:deadsnakes/ppa'\
  --customize-hook='chroot "$1" sed -i "/^deb .*Signed-By=/s/ Signed-By=[^ ]*//" /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-noble.sources || true' \
  --customize-hook='chroot "$1" apt update' \
  --customize-hook='chroot "$1"  apt install -y python3.13 python3.13-dev  python3.13-venv'\
  --customize-hook='chroot "$1" apt install -y udev iputils-ping kmod '\
  --customize-hook='chroot "$1" python3.13 -m ensurepip'\
  --essential-hook='chroot "$1" mkdir -p /mnt/data'\
  --essential-hook='chroot "$1" mkdir -p /mnt/overlay'\
  --essential-hook='chroot "$1" mkdir -p /mnt/config'\
  --essential-hook='chroot "$1" mkdir -p /mnt/boot'\
  --essential-hook='chroot "$1" mkdir -p /homeassistant'\
  --customize-hook='chroot "$1" sh -c "echo homeassistant > /etc/hostname"'\
  --customize-hook='chroot "$1" ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime'\
  --customize-hook='chroot "$1" apt install -y rauc || true'\
  --customize-hook='chroot "$1" systemctl mask wpa_supplicant@'\
  --customize-hook='chroot "$1" rm /etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-noble.sources'\
  --customize-hook='cp -r hass-core/* "$1"/homeassistant/'\
  --customize-hook='cp scripts/mmdeb-hass-img.sh "$1"/homeassistant'\
  --customize-hook='chroot "$1" chmod +x /homeassistant/mmdeb-hass-img.sh'\
  --customize-hook='chroot "$1" /homeassistant/mmdeb-hass-img.sh'\
  --customize-hook='cp -rpf rootfs-overlay/* "$1"/'\
  --customize-hook='chroot "$1" chown -R 1000:1000 /homeassistant'\
  --customize-hook='chroot "$1" rm -rf /homeassistant/mmdeb-hass-img.sh'\
  --customize-hook='mkfs.ext4 -b 4096 -L hass-core -d "$1"/homeassistant ./homeassistant.img 307200'\
  --customize-hook='chroot "$1" rm -rf /homeassistant/*'\
  --customize-hook='chroot "$1" apt remove -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu build-essential'\
  --setup-hook='cp rootfs-overlay/etc/shadow "$1"/etc/'\
  --setup-hook='cp rootfs-overlay/etc/passwd "$1"/etc/'\
  --setup-hook='cp rootfs-overlay/etc/group "$1"/etc/'\
  --variant=minbase \
  noble  rootfs.tar.gz http://ports.ubuntu.com/ubuntu-ports 
   # --include="sudo,bash,iproute2,iputils-ping,libusb-1.0-0,usbutils,network-manager,systemd-timesyncd,wpasupplicant,unzip,wireless-tools,systemd-resolved,u-boot-tools,fdisk,jq,software-properties-common,vim,net-tools,iproute2,curl,wget,openssh-server" 

fi
mkdir -p $TARGET_ROOTFS_DIR
tar --exclude='dev/*' -xzf rootfs.tar.gz -C $TARGET_ROOTFS_DIR
cp -rpf rootfs-overlay/* $TARGET_ROOTFS_DIR/
mkdir -p $TARGET_ROOTFS_DIR/lib/firmware/{brcm,aic8800_sdio}
cp -r $ROOT_DIR/linux-firmware/brcm/* $TARGET_ROOTFS_DIR/lib/firmware/brcm/
cp -r $ROOT_DIR/linux-firmware/aic8800_sdio/* $TARGET_ROOTFS_DIR/lib/firmware/aic8800_sdio/
rm rm -rf $TARGET_ROOTFS_DIR/lib/modules/6.12.0-haos+/build
rm -rf $TARGET_ROOTFS_DIR/homeassistant/*
rm -rf $TARGET_ROOTFS_DIR/sbin.usr-is-merged $TARGET_ROOTFS_DIR/bin.usr-is-merged $TARGET_ROOTFS_DIR/lib.usr-is-merged
fakeroot bash -c "
chmod u+s $TARGET_ROOTFS_DIR/usr/bin/sudo
chown -R 1000:1000 $TARGET_ROOTFS_DIR/homeassistant || true
chown -R 1000:1000 $TARGET_ROOTFS_DIR/home/haos || true
chmod u+s $TARGET_ROOTFS_DIR/usr/bin/ping || true
chown 102:104 $TARGET_ROOTFS_DIR/etc/mosquitto/pwfile | true
mkfs.erofs -zlz4hc,12  -Efragments -Ededupe -Eztailpacking ubuntu-24.04-rootfs.img $TARGET_ROOTFS_DIR/
"
