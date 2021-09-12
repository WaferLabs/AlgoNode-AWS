#!/bin/bash
### BEGIN INIT INFO
# Provides:          node-setup
# Required-Start:    $all
# Required-Stop:     $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: enhanced syslogd
# Description:      
### END INIT INFO

cd /tmp
apt-get update
apt-get install -y git
git clone https://github.com/WaferFinance/AlgoNode-AWS
cd AlgoNode-AWS
bash setup.sh