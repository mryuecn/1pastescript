#!/bin/sh

# 更新系统
echo "正在更新系统..."
apk update && apk upgrade

# 安装必要软件
echo "正在安装必要软件..."
apk add nano curl htop vim openntpd

# 配置时区为北京时间
echo "正在设置时区为北京时间..."
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "Asia/Shanghai" > /etc/timezone

# 配置vm.swappiness
echo "正在配置vm.swappiness..."
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p

# 配置SSH
echo "正在配置SSH..."
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config
rc-update add sshd default  # 添加sshd服务到默认运行级别
rc-service sshd start       # 启动sshd服务

# 启用时间同步服务
echo "正在启用时间同步服务..."
rc-update add openntpd default
rc-service openntpd start

# 清理不必要的包
echo "正在清理不必要的包..."
apk cache clean

# 清理终端登录信息
echo "正在清理终端登录信息..."
echo 'clear' >> ~/.profile

# 重启系统
echo "优化完成！系统将重启。"
reboot
