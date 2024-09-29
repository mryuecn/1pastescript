#!/bin/sh

# 更新软件包
apk update && apk upgrade

# 安装基本工具
apk add vim nano curl htop openrc

# 设置时区
apk add tzdata
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone

# 安装并配置 SSH
apk add openssh
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
rc-update add sshd
rc-service sshd start

# 清理未使用的文件
apk cache clean

echo "优化完成！"
