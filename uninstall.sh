#!/bin/sh -e
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

if [ -e $CONF_FILE ]; then
	. $CONF_FILE
fi

echo "lipsync uninstall script"
	rm -rf /usr/share/doc/lipsyncd
	rm /etc/init.d/lipsync*
	rm /etc/lipsync*
	rm /usr/local/bin/lipsync
	unlink /usr/local/bin/lipsyncd
	rm /usr/local/bin/lipsync-notify
	crontab -u $username -l | awk '$0!~/lipsync/ { print $0 }' > newcronjob
	crontab -u $username newcronjob; rm newcronjob
exit 0


