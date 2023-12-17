# safely-bash
Safely running a public-facing server's bash


## ssh防护
ssh作为bash的重要入口，以默认端口22直接暴露到公网是十分危险的行为。
轻则资料丢失财产损失:broken_heart:，重则沦为肉鸡成为祸害他人的工具:fearful:
因此如何安全地访问云服务器的bash成了一个不大不小的难题:interrobang:。

**修改端口及登录权限**
默认端口22应当优先被更改为非常见端口
同时关闭:x:密码登录，改用密钥:key:登录
```bash
> vim /etc/ssh/sshd_config
Port 非常见端口
PasswordAuthentication no
PubkeyAuthentication yes
```

**开启防防火墙**
一般而言，云平台会提供基础的平台防火墙，再加上主机防火墙，可以抵御一定的入侵攻击


**防火墙限制源端访问**
对于有固定公网IP的用户或企业，主机防火墙限制源端访问即可
firewalld防火墙设置：
```bash
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="客户端IP" port ptocol="tcp" port="SSH端口" accept' --permanent
```
ufw防火墙设置：
```bash
ufw allow from 客户端IP to any port SSH端口
```
iptables防火墙设置：
```bash
iptables -A INPUT -p tcp --dport SSH端口 -s 客户端IP -j ACCEPT
```

**限制动态公网ip访问**
对于无固定公网IP或专线的用户，则需要借助DDNS+bash脚本实现动态限制访问源
原理如下图:point_down:：
![image](https://github.com/aki66938/safely-bash/assets/47413858/fd4b4a25-db10-4859-b53a-b2932b2ae94f)

**首先** 需要购买域名，用免费的也可以。常见的DDNS工具如[阿里云ddns](https://github.com/search?q=ddns+ali&type=repositories)、[腾讯ddns](https://github.com/QiQiWan/DNSPod-DDNS)、[ddns-go](https://github.com/jeessy2/ddns-go)等等
**其次** 编写脚本获取域名指向的动态ip地址（原理和ddns类似，可以说是逆ddns）
```shell
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
```
**最后** 设置crontab定时:clock6:执行获取域名解析地址的ip

完结，撒花:tada:
