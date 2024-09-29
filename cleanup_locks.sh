#!/bin/bash

# 定义锁定文件目录
LOCK_DIR="/run/lock/lxc"

# 查找并删除超过一定时间（如 1 小时）的锁定文件
find "$LOCK_DIR" -name "*.lock" -type f -mmin +60 -exec rm -f {} \;
