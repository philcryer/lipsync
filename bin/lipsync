#!/bin/sh -e
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CONF_FILE=/etc/lipsyncd

if [[ -e $CONF_FILE ]]; then
        . $CONF_FILE
fi

# this from http://code.google.com/p/lsyncd/wiki/HowToExecAfter
# execute rsync just like it would have been done directly,
# but save the exit code
IFS=
err=0

#/usr/bin/rsync $@ || err=$?
rsync -r -a -v -e "ssh -l $USER_NAME" --delete $REMOTE_HOST:$LOCAL_DIR $REMOTE_DIR

# this writes source -> destination details to /var/log/lipsyncd.log
eval src=\${$(($# - 1))}
eval dst=\${$#}
echo "$src -> $dst" >> /var/log/lipsyncd.log || true

# returns the exit code of rsync to lsyncd
exit $err
