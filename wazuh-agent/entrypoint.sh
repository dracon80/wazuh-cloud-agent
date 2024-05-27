#!/bin/bash

echo $AUTHD_PASS > /var/ossec/etc/authd.pass
chown root:wazuh /var/ossec/etc/authd.pass
chmod 660 /var/ossec/etc/authd.pass

result=$(/var/ossec/bin/wazuh-control start 2>&1)

exit_status=$?

# Check the exit status the agent starting
if [ $exit_status -eq 0 ]; then
    tail -F "/var/ossec/logs/ossec.log"
else
    tail -n 50 "/var/ossec/logs/ossec.log"
    exit 1
fi