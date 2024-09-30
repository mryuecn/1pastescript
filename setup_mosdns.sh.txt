#!/bin/sh

# 更新系统
echo "正在更新系统..."
apk update && apk upgrade

# 安装必要软件
echo "正在安装必要软件..."
apk add nano curl htop vim openntpd openssh

# 创建 /etc/mosdns 工作目录
mkdir -p /etc/mosdns && cd /etc/mosdns
# 下载 MosDNS
wget https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip
unzip mosdns-linux-amd64.zip

# 创建相关集合
mkdir -p /etc/mosdns/rule
curl -o /etc/mosdns/rule/direct-list.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/direct-list.txt && \
curl -o /etc/mosdns/rule/apple-cn.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/apple-cn.txt && \
curl -o /etc/mosdns/rule/google-cn.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/google-cn.txt && \
curl -o /etc/mosdns/rule/proxy-list.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/proxy-list.txt && \
curl -o /etc/mosdns/rule/gfw.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/gfw.txt && \
curl -o /etc/mosdns/rule/CN-ip-cidr.txt https://raw.githubusercontent.com/IrineSistiana/mosdns/release/CN-ip-cidr.txt && \
touch /etc/mosdns/rule/force-nocn.txt && \
touch /etc/mosdns/rule/hosts.txt && \
touch /etc/mosdns/rule/fake-ip-cidr.txt && \
touch /etc/mosdns/rule/force-cn.txt

# 配置 /etc/mosdns/config.yaml
cat << EOF > /etc/mosdns/config.yaml
log:
  level: error # debug
  production: true

api:
  http: "0.0.0.0:9080"

include: []

plugins:
  - tag: "geosite-cn"
    type: domain_set
    args:
      files:
        - "./rule/direct-list.txt"
        - "./rule/apple-cn.txt"
        - "./rule/google-cn.txt"

  - tag: "geosite-nocn"
    type: domain_set
    args:
      files:
        - "./rule/proxy-list.txt"
        - "./rule/gfw.txt"

  - tag: "geoip-cn"
    type: ip_set
    args:
      files: "./rule/CN-ip-cidr.txt"

  - tag: "fake-ip-clash"
    type: ip_set
    args:
      files: "./rule/fake-ip-cidr.txt"

  - tag: "force-cn"
    type: domain_set
    args:
      files:
        - "./rule/force-cn.txt"

  - tag: "force-nocn"
    type: domain_set
    args:
      files:
        - "./rule/force-nocn.txt"

  - tag: "hosts"
    type: hosts
    args:
      files:
        - "./rule/hosts.txt"

  - tag: "cache"
    type: "cache"
    args:
      size: 1024
      lazy_cache_ttl: 0
      dump_file: ./cache.dump
      dump_interval: 600

  - tag: forward_local
    type: forward
    args:
      concurrent: 2
      upstreams:
        - addr: "https://dns.alidns.com/dns-query"
        - addr: "tls://dns.alidns.com"

  - tag: forward_remote
    type: forward
    args:
      concurrent: 2
      upstreams:
        - addr: 127.0.0.1:1053

  - tag: "primary_forward"
    type: sequence
    args:
      - exec: $forward_local
      - exec: ttl 60-3600
      - matches:
          - "!resp_ip $geoip-cn"
          - "has_resp"
        exec: drop_resp

  - tag: "secondary_forward"
    type: sequence
    args:
      - exec: prefer_ipv4
      - exec: $forward_remote
      - matches:
          - rcode 2
        exec: $forward_local
      - exec: ttl 300-3600

  - tag: "final_forward"
    type: fallback
    args:
      primary: primary_forward
      secondary: secondary_forward
      threshold: 150
      always_standby: true

  - tag: "main_sequence"
    type: sequence
    args:
      - exec: $hosts
      - exec: query_summary hosts
      - matches: has_wanted_ans
        exec: accept
      - exec: $cache
      - exec: query_summary cache
      - matches: has_wanted_ans
        exec: accept
      - exec: query_summary qtype65
      - matches:
          - qtype 65
        exec: reject 0
      - matches:
          - qname $geosite-cn
        exec: $forward_local
      - exec: query_summary geosite-cn
      - matches: has_wanted_ans
        exec: accept
      - matches:
          - qname $force-cn
        exec: $forward_local
      - exec: query_summary force-cn
      - matches: has_wanted_ans
        exec: accept
      - matches:
          - qname $geosite-nocn
        exec: $forward_remote
      - exec: query_summary geosite-nocn
      - matches: has_wanted_ans
        exec: accept
      - matches:
          - qname $force-nocn
        exec: $forward_remote
      - exec: query_summary force-nocn
      - matches: has_wanted_ans
        exec: accept
      - exec: $final_forward

  - tag: "udp_server"
    type: "udp_server"
    args:
      entry: main_sequence
      listen: 0.0.0.0:5233

  - tag: "tcp_server"
    type: "tcp_server"
    args:
      entry: main_sequence
      listen: 0.0.0.0:5233
EOF

# 创建 MosDNS 系统服务
cat << EOF > /etc/systemd/system/mosdns.service
[Unit]
Description=MosDNS Service
After=network.target

[Service]
ExecStart=/etc/mosdns/mosdns
WorkingDirectory=/etc/mosdns
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 启动 MosDNS 服务并设置开机自启动
systemctl daemon-reload
systemctl start mosdns.service
systemctl enable mosdns.service

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
