#!/bin/bash

set -e

sudo mkdir -p $TARGET_ROOTFS_DIR/lib/firmware/{brcm,aic8800_sdio}
sudo cp -r $ROOT_DIR/linux-firmware/brcm/* $TARGET_ROOTFS_DIR/lib/firmware/brcm/
sudo cp -r $ROOT_DIR/linux-firmware/aic8800_sdio/* $TARGET_ROOTFS_DIR/lib/firmware/aic8800_sdio/
sudo cp -rpf $OVERLAY_DIR/* $TARGET_ROOTFS_DIR/
cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/
mkdir /homeassistant
systemctl enable homeassistant 
systemctl enable hassos-overlay
systemctl enable hassos-image
systemctl enable home-haos.mount
systemctl enable hassos-persists.service
rm -rf /lib/modules/6.12.0-haos+/build
rm -rf sbin.usr-is-merged bin.usr-is-merged lib.usr-is-merged
rm /root/.bash_history
chown mosquitto:mosquitto /etc/mosquitto/pwfile
history -c
EOF

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

# Fixup owners
if [ "$ID" -ne 0 ]; then
    find / -user $ID -exec chown -h 0:0 {} \;
fi
for u in \$(ls /home/); do
    chown -h -R \$u:\$u /home/\$u
done
EOF