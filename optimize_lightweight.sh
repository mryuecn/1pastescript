#!/bin/bash

# 更新系统
apt update && apt upgrade -y

# 安装必要软件
apt install -y nano curl htop vim ntp ntpsec

# 设置swappiness
echo "vm.swappiness=10" | tee /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf

# 配置SSH
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd

# 优化日志管理
cat <<EOF >> /etc/logrotate.conf
/var/log/*.log {
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
}
EOF

# 启用时间同步服务
systemctl enable ntpsec

# 禁用静默启动
echo "DISABLE_SILENT_BOOT=true" >> /etc/default/grub
grub2-mkconfig -o /boot/grub/grub.cfg

# 清理不必要的包
apt autoremove -y

# 重启系统
reboot
