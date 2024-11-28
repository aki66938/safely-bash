#!/bin/bash

# Initialize variables
current_time=$(date "+%Y-%m-%d %H:%M:%S")
DOMAIN="<your-domain>"
DOMAIN_IP=$(nslookup $DOMAIN | awk '/^Address: / { print $2 }')
LOG_FILE="/var/log/ufw_update.log"
PORT="<ssh-port>"

# Extract the last recorded IP from the log file
if [ -f "$LOG_FILE" ]; then
    LAST_IP=$(grep "DOMAIN-IP:" $LOG_FILE | tail -1 | awk '{print $NF}')
else
    LAST_IP=""
fi

# Update log file
echo "$current_time: Current DOMAIN-IP: $DOMAIN_IP" >> $LOG_FILE

# Check if IP has changed or log file doesn't exist
if [ "$DOMAIN_IP" != "$LAST_IP" ] || [ -z "$LAST_IP" ]; then
    echo "$current_time: IP address changed, updating rules" >> $LOG_FILE

    # Update UFW rules
    # Delete all existing rules for this port to avoid duplicates
    ufw status numbered | grep " $PORT " | cut -d "[" -f2 | cut -d "]" -f1 | tac | while read -r line ; do
        yes | ufw delete $line
    done
    # Add new rule
    ufw allow from $DOMAIN_IP to any port $PORT
    ufw deny $PORT

    echo "$current_time: Update completed" >> $LOG_FILE
else
    echo "$current_time: IP address unchanged, no update needed" >> $LOG_FILE
fi

# Print current firewall status
ufw_status=$(ufw status)
echo "$current_time: Current firewall status:" >> $LOG_FILE
echo "$ufw_status" >> $LOG_FILE
echo "===============================" >> $LOG_FILE
