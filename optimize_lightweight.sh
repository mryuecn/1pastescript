#!/bin/bash

# 更新系统
echo "正在更新系统..."
apt update && apt upgrade -y

# 安装必要软件
echo "正在安装必要软件..."
apt install -y vim nano curl htop ntp

# 配置SSH以允许第三方登录
echo "正在配置SSH..."
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 重新启动SSH服务
systemctl restart sshd

# 优化系统设置
echo "正在优化系统设置..."
echo "vm.swappiness=10" | tee -a /etc/sysctl.conf
sysctl -w vm.swappiness=10

# 设置日志管理
echo "正在配置日志管理..."
echo "/var/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        /usr/lib/newsyslog/rotate
    endscript
}" | tee /etc/logrotate.d/syslog

# 清理不必要的包
echo "正在清理不必要的包..."
apt autoremove -y && apt clean

# 启动和启用NTP服务
echo "正在启用时间同步服务..."
systemctl enable ntp
systemctl start ntp

# 完成
echo "优化完成！系统已准备好运行轻量化程序。"
