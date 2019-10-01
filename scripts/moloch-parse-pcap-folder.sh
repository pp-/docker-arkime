#!/bin/bash
# cd /data/pcap/
# Parse all pcaps recursively only if they are a valid tcpdump capture
# find . -exec file {} \; | grep "tcpdump capture" | awk -F: '{print $1}' | xargs -I % /data/moloch/bin/moloch-capture -r %
find /data/pcap/ -name *.pcap* -type f -exec $MOLOCHDIR/bin/moloch-capture -t line1 -c $MOLOCHDIR/etc/config.ini -r '{}' \;
