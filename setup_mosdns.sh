#!/bin/sh

# 创建 /etc/mosdns 工作目录
mkdir -p /etc/mosdns && cd /etc/mosdns

# 下载 mosdns
wget https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip
unzip mosdns-linux-amd64.zip

# 创建相关规则目录
mkdir -p /etc/mosdns/rule
curl -o /etc/mosdns/rule/direct-list.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/direct-list.txt
curl -o /etc/mosdns/rule/apple-cn.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/apple-cn.txt
curl -o /etc/mosdns/rule/google-cn.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/google-cn.txt
curl -o /etc/mosdns/rule/proxy-list.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/proxy-list.txt
curl -o /etc/mosdns/rule/gfw.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/gfw.txt
curl -o /etc/mosdns/rule/CN-ip-cidr.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/CN-ip-cidr.txt
touch /etc/mosdns/rule/force-nocn.txt
touch /etc/mosdns/rule/hosts.txt
touch /etc/mosdns/rule/fake-ip-cidr.txt
touch /etc/mosdns/rule/force-cn.txt

# 创建 mosdns 启动脚本
cat << 'EOF' > /etc/init.d/mosdns
#!/sbin/openrc-run

command="/etc/mosdns/mosdns"
command_args="-config /etc/mosdns/config.yaml"
pidfile="/run/mosdns.pid"

depend() {
    need net
}

start_pre() {
    checkpath --directory --mode 0755 /run/mosdns
}

start() {
    ebegin "Starting mosdns"
    start-stop-daemon --start --make-pidfile --pidfile $pidfile --background --exec $command -- $command_args
    eend $?
}

stop() {
    ebegin "Stopping mosdns"
    start-stop-daemon --stop --pidfile $pidfile
    eend $?
}
EOF

# 赋予启动脚本可执行权限
chmod +x /etc/init.d/mosdns

# 将脚本添加到默认运行级别
rc-update add mosdns default

# 启动 mosdns 服务
rc-service mosdns start

echo "mosdns 安装及配置完成，服务已启动。"
