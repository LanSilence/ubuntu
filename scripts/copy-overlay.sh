#!/bin/bash

set -e

mkdir -p $TARGET_ROOTFS_DIR/lib/firmware/{brcm,aic8800_sdio}
cp -r $ROOT_DIR/linux-firmware/brcm/* $TARGET_ROOTFS_DIR/lib/firmware/brcm/
cp -r $ROOT_DIR/linux-firmware/aic8800_sdio/* $TARGET_ROOTFS_DIR/lib/firmware/aic8800_sdio/
cp -rpf $OVERLAY_DIR/* $TARGET_ROOTFS_DIR/
cat <<EOF | proot -q qemu-aarch64-static -r $TARGET_ROOTFS_DIR/ -0 -w / -b /dev -b /proc -b /sys /bin/bash
mkdir /homeassistant
systemctl enable homeassistant 
systemctl enable hassos-overlay
systemctl enable hassos-image
systemctl enable home-haos.mount
systemctl enable hassos-persists.service
systemctl enable NetworkManager 
systemctl enable systemd-timesyncd
systemctl enable mnt-boot.mount
systemctl enable raucdb-update
rm -rf /lib/modules/6.12.0-haos+/build
rm -rf sbin.usr-is-merged bin.usr-is-merged lib.usr-is-merged
rm /root/.bash_history
chown mosquitto:mosquitto /etc/mosquitto/pwfile
history -c
apt remove -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
sudo apt autoremove -y
apt-get clean
rm rf /var/lib/apt/lists/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/
rm -rf /etc/update-motd.d/{10-help-text,60-unminimize}
rm -rf /home/haos/.cache/uv/*-
EOF

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

# cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

# # Fixup owners
# if [ "$ID" -ne 0 ]; then
#     find / -user $ID -exec chown -h 0:0 {} \;
# fi
# for u in \$(ls /home/); do
#     chown -h -R \$u:\$u /home/\$u
# done
# EOF