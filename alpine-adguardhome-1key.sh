#!/bin/sh

# 更新系统
apk update
apk add --no-cache curl

# 设置版本和下载链接
VERSION="0.109.4"  # 请到[官方GitHub仓库](https://github.com/AdguardTeam/AdGuardHome/releases)确认最新版本
ARCH="amd64"        # 根据需要调整架构（arm64, armv7等）
OS="linux"

# 构造下载链接
DOWNLOAD_URL="https://github.com/AdguardTeam/AdGuardHome/releases/download/v${VERSION}/AdGuardHome_linux_${ARCH}.tar.gz"

# 下载并解压
curl -L -o /tmp/adguard.tar.gz "$DOWNLOAD_URL"
tar -C /root -xzf /tmp/adguard.tar.gz

# 进入安装目录（默认解压到root目录，调整为你喜欢的目录）
cd /root/AdGuardHome

# (可选)设置服务为开机启动
# 创建systemd或OpenRC服务，Alpine用OpenRC
cat << EOF > /etc/init.d/adguard
#!/sbin/openrc-run
command="/root/AdGuardHome/AdGuardHome"
command_args="--no-mscs"
pidfile="/run/adguard.pid"
name="adguard"
start_stop_timeout=10
respawn=yes
EOF

chmod +x /etc/init.d/adguard
rc-update add adguard default

# 启动AdGuard Home
/etc/init.d/adguard start

echo "AdGuard Home 安装完成，访问 http://<你的ip>:3000 配置"
