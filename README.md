# Safely-Bash

A security enhancement toolkit for protecting SSH access to public-facing servers.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

This project provides a comprehensive solution for securing SSH access to public-facing servers, particularly focusing on scenarios with dynamic IP addresses. It combines firewall rules, DDNS (Dynamic DNS), and automated scripts to create a robust security system.

## Features

- Dynamic IP-based access control
- Automated firewall rule updates
- Support for multiple firewall systems (UFW, firewalld, iptables)
- Detailed logging system
- DDNS integration

## Prerequisites

- A registered domain name (free or paid)
- Root access to your server
- One of the supported firewalls (UFW, firewalld, or iptables)
- Basic understanding of Linux system administration

## Security Measures

### 1. SSH Configuration Enhancement

Modify your SSH configuration for better security:

```bash
vim /etc/ssh/sshd_config

# Recommended settings
Port <unusual-port>              # Change from default port 22
PasswordAuthentication no       # Disable password login
PubkeyAuthentication yes       # Enable key-based authentication
```

### 2. Firewall Configuration

#### For Static IP Users

Choose one of the following methods based on your firewall:

**UFW:**
```bash
ufw allow from <client-ip> to any port <ssh-port>
```

**Firewalld:**
```bash
firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="<client-ip>" port protocol="tcp" port="<ssh-port>" accept' --permanent
```

**Iptables:**
```bash
iptables -A INPUT -p tcp --dport <ssh-port> -s <client-ip> -j ACCEPT
```

### 3. Dynamic IP Solution

For users with dynamic IPs, this project provides an automated solution:

1. Set up DDNS for your domain using tools like:
   - [Aliyun DDNS](https://github.com/search?q=ddns+ali&type=repositories)
   - [Tencent DDNS](https://github.com/QiQiWan/DNSPod-DDNS)
   - [ddns-go](https://github.com/jeessy2/ddns-go)

2. Use the provided script (`ufw-reddns-ssh.sh`) to automatically update firewall rules based on your domain's IP.

3. Set up a cron job to run the script periodically.

## Script Usage

1. Edit the script variables:
   - `DOMAIN`: Your domain name
   - `PORT`: Your SSH port
   - `LOG_FILE`: Path to log file (default: /var/log/ufw_update.log)

2. Make the script executable:
```bash
chmod +x ufw-reddns-ssh.sh
```

3. Add to crontab for automatic execution:
```bash
crontab -e
# Add line: */5 * * * * /path/to/ufw-reddns-ssh.sh
```

## Logging

The script maintains detailed logs at `/var/log/ufw_update.log`, including:
- IP address changes
- Firewall rule updates
- Current firewall status
- Timestamps for all operations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
