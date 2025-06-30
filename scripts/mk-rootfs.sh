#!/bin/bash -e
set -e
ROOT_DIR=$(pwd)
SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
TARGET_ROOTFS_DIR="${ROOT_DIR}/binary"
mkdir -p $TARGET_ROOTFS_DIR
fakeroot cp /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
fakeroot cp /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
finish() {
    # ${SCRIPTS_DIR}/ch-mount.sh -u $TARGET_ROOTFS_DIR
    echo -e "error exit"
    exit -1
}

# . scripts/generate-signing-key.sh
# . scripts/rauc.sh

# openssl req -x509 -newkey rsa:4096 -keyout  \
#                 -out "${cert}" -days 3650 -nodes \
#                 -subj "/O=HassOS/CN=HassOS Self-signed Development Certificate"


trap finish ERR
echo -e "\033[47;36m Change root.................... \033[0m"

# ${SCRIPTS_DIR}/ch-mount.sh -m $TARGET_ROOTFS_DIR

cat <<EOF | proot -q qemu-aarch64-static -r $TARGET_ROOTFS_DIR/ -0 -w / -b /dev -b /proc -b /sys /bin/bash


export APT_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get install -fy --allow-downgrades"

export LC_ALL=C.UTF-8

apt-get -y update
apt-get -f -y upgrade
mkdir -p /var/cache/apt/archives/partial
apt install adduser
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
chmod 1777 tmp  

echo "LC_ALL=C.UTF-8" >> /etc/default/locale
apt install -y vim net-tools iproute2 curl wget openssh-server
cd /bin && mv -f systemd-sysusers{,.org} && ln -s echo systemd-sysusers && cd -
apt install -y vim net-tools iproute2 curl wget openssh-server
apt install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
\${APT_INSTALL} python3.13 python3.13-dev  python3.13-venv
python3.13 -m ensurepip
apt install -y udev    #一定要安装udev！！！不然进不去系统，血的教训

\${APT_INSTALL} network-manager systemd-timesyncd wpasupplicant unzip wireless-tools systemd-resolved \
        libturbojpeg0-dev u-boot-tools fdisk jq build-essential isal libusb-1.0-0 usbutils mosquitto 

apt install -y iputils-ping

apt install -y sudo libusb-1.0-0 usbutils mosquitto 
apt install -y kmod
apt install -y apt-utils
mkdir /mnt/{data,overlay,config,boot}

HOST=homeassistant

# Create User
useradd -G sudo -m -s /bin/bash haos
passwd haos <<IEOF
123456
123456
IEOF
passwd root <<IEOF
123456
123456
IEOF

# hostname
echo homeassistant > /etc/hostname

# set localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

systemctl mask wpa_supplicant-wired@
systemctl mask wpa_supplicant-nl80211@
systemctl mask wpa_supplicant@

apt remove -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/
rm -rf /etc/update-motd.d/{10-help-text,60-unminimize}
rm -rf /home/haos/.cache/uv/*

sync

EOF

# ${SCRIPTS_DIR}/ch-mount.sh -u $TARGET_ROOTFS_DIR
