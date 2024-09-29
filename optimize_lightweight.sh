#!/bin/bash

# 更新系统
echo "正在更新系统..."
apt update && apt upgrade -y

# 安装必要软件
echo "正在安装必要软件..."
apt install -y nano curl htop vim ntp ntpsec

# 配置时区为北京时间
echo "正在设置时区为北京时间..."
timedatectl set-timezone Asia/Shanghai

# 配置vm.swappiness
echo "正在配置vm.swappiness..."
echo "vm.swappiness=10" | tee /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf

# 配置SSH
echo "正在配置SSH..."
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
systemctl restart sshd

# 启用时间同步服务
echo "正在启用时间同步服务..."
systemctl enable ntpsec
systemctl start ntpsec

# 清理不必要的包
echo "正在清理不必要的包..."
apt autoremove -y

# 配置静默启动
echo "DISABLE_SILENT_BOOT=true" >> /etc/default/grub
update-grub

# 清理终端登录信息
echo "正在清理终端登录信息..."
echo 'clear' >> ~/.bashrc

# 重启系统
echo "优化完成！系统将重启。"
reboot
