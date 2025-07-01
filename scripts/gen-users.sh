#!/bin/bash
# 生成标准 /etc/passwd 和 /etc/group 文件，适用于 rootfs 构建
# 用于替换 proot/chroot 环境下创建用户导致 UID/GID 错误的问题

TARGET_ETC=${1:-"./etc"}

mkdir -p "$TARGET_ETC"


# 创建 home 目录
mkdir -p "$TARGET_ETC/../home/haos"
# 需要 fakeroot/chown 1000:1000 home/haos 打包时属主为 haos

echo "已生成 $TARGET_ETC/passwd 和 $TARGET_ETC/group，可直接替换 rootfs 里的 /etc 文件。"
