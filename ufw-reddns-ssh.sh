#!/bin/bash

# 初始化变量
current_time=$(date "+%Y-%m-%d %H:%M:%S")
DOMAIN="自己的域名"
DOMAIN_IP=$(nslookup $DOMAIN | awk '/^Address: / { print $2 }')
LOG_FILE="/var/log/ufw_update.log"
PORT="服务端的SSH端口"

# 从日志文件中提取最后一次记录的IP
if [ -f "$LOG_FILE" ]; then
    LAST_IP=$(grep "DOMAIN-IP:" $LOG_FILE | tail -1 | awk '{print $NF}')
else
    LAST_IP=""
fi

# 更新日志文件
echo "$current_time: 当前DOMAIN-IP: $DOMAIN_IP" >> $LOG_FILE

# 检查IP是否变化或日志文件不存在
if [ "$DOMAIN_IP" != "$LAST_IP" ] || [ -z "$LAST_IP" ]; then
    echo "$current_time: IP地址变化，进行更新" >> $LOG_FILE

    # 更新UFW规则
    # 删除针对该端口的所有规则，避免重复
    ufw status numbered | grep " $PORT " | cut -d "[" -f2 | cut -d "]" -f1 | tac | while read -r line ; do
        yes | ufw delete $line
    done
    # 添加新规则
    ufw allow from $DOMAIN_IP to any port $PORT
    ufw deny $PORT

    echo "$current_time: 更新完成" >> $LOG_FILE
else
    echo "$current_time: IP地址未变化，无需更新" >> $LOG_FILE
fi

# 打印当前防火墙状态
ufw_status=$(ufw status)
echo "$current_time: 当前防火墙状态:" >> $LOG_FILE
echo "$ufw_status" >> $LOG_FILE
echo "===============================" >> $LOG_FILE
