#!/bin/bash

echo "=== Checking AWS Cost Monitor Logs ==="
echo "Current time: $(date)"

# Try different log commands
echo ""
echo "1. Trying log show with different syntax:"
/usr/bin/log show --last 3m --style compact 2>/dev/null | grep -i "startup\|bypass\|team cache\|debug\|ecoengineers" | head -10

echo ""
echo "2. Trying to find log files:"
find ~/Library/Logs -name "*AWSCostMonitor*" -o -name "*aws*" 2>/dev/null | head -5

echo ""
echo "3. Checking system log:"
tail -50 /var/log/system.log 2>/dev/null | grep -i "awscostmonitor\|startup\|bypass" | head -5

echo ""
echo "4. Checking if app is writing to stdout/stderr:"
ps aux | grep AWSCostMonitor | grep -v grep

