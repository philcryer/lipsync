#!/bin/sh -e
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

echo "lipsync uninstall script"
#	rm /home/*/.unison/ar* 
	rm -rf /usr/share/doc/lipsyncd
	rm /etc/init.d/lipsync*
	rm /etc/lipsync*
	rm /usr/local/bin/lipsync
	unlink /usr/local/bin/lipsyncd
	rm /usr/local/bin/lipsync-notify
exit 0


