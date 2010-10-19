#!/bin/bash
# Name : setup.sh
# Author : Phil Cryer <phil@cryer.us>
# Site : http://github.com/philcryer/lipsync
# Desc : This script sets up lipsync 

clear
stty erase '^?'
echo "lipsync setup script"


###############################################################################
# Check if the user is root, or if they have user has sudo privileges
###############################################################################
echo -n "* Checking that user is root or has sudo access..."
if [ "$(id -u)" != "0" ]; then 
	sudo -v >/dev/null 2>&1 || { echo; echo "	ERROR: User $(whoami) is not root, and does not have sudo privileges" ; exit 1; }
else
	echo "ok"
fi
###############################################################################


###############################################################################
# Checking if this system is either Debian or Ubuntu
###############################################################################
echo -n "* Checking if the installer supports this system..."
if [ `cat /etc/issue.net | cut -d' ' -f1` == "Debian" ] || [ `cat /etc/issue.net | cut -d' ' -f1` == "Ubuntu" ];then
	echo "ok"
else
	echo; echo "	ERROR: this installer currently does not support your system; try a manual install instead"; exit 1
fi
###############################################################################


###############################################################################
# Test if required applications are installed, die if not
###############################################################################
echo -n "* Checking that required software is installed..."
type -P ssh &>/dev/null || { echo; echo "	ERROR: lipsync requires ssh-client but it's not installed" >&2; exit 1; }
type -P ssh-copy-id &>/dev/null || { echo; echo "	ERROR: lipsync requires ssh-copy-id but it's not installed" >&2; exit 1; }
type -P rsync &>/dev/null || { echo; echo "	ERROR: lipsync requires rsync but it's not installed" >&2; exit 1; }
type -P lsyncd &>/dev/null || { echo; echo "	ERROR: lipsync requires lsyncd but it's not installed" >&2; exit 1; }
echo "ok"
###############################################################################


###############################################################################
# Define functions
###############################################################################
questions(){
	echo -n "	- IP or domainname for the remote or hub server: "
	read remote_server

	echo -n "	- Port to run lipsync on (default ssh port is 22, might want to try that first): "
	read port
	
	echo -n "	- Lipsync username (this must presently exist on the local and remote systems): "
    	read username
    
	echo -n "	- Full path to lipsync directory (local directory for user ${username} to be synced): "
	read lipsync_dir
}

ssh.keygen(){
	echo -n "* Creating ssh key for ${username}..."
	ssh-keygen -N '' -f /home/${username}/.ssh/id_dsa
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error generating the ssh key"; exit 1
	fi
	
	echo -n "* Transferring ssh key for ${username} to ${remote_server} (NOTE: you will be prompted to login)..."
	ssh-copy-id ${remote_server}
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error transferring the ssh key"; exit 1
	fi
	echo -n "* Setting permissions on the ssh key for ${username} on ${remote_server} (NOTE: you should not be prompted to login)..."
	ssh ${remote_server} 'chmod 700 .ssh'
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error setting permissions on the ssh key for ${username} on ${remote_server}..."; exit 1
	fi
}

create.group(){
	echo -n "* Creating group lipsync..."
	grep lipsync /etc/group
	if [ $? -eq 0 ]; then
		echo; echo "	NOTICE: existing group lipsync found, not creating"
	else
		groupadd lipsync
		echo "done"
	fi
}

create.user(){
	echo -n "* Creating user lipsync..."
	grep lipsync /etc/passwd
	if [ $? -eq 0 ]; then
		echo; echo "	NOTICE: existing user lipsync found, not creating"
	else
		useradd -g lipsync -s /bin/false lipsync
		echo "done"
	fi
}

build.conf(){
	#cat >etc/lipsync.conf<<EOF
	#EOF
	sleep .1
}

deploy(){
	echo "* Deploying lipsync..."
	echo -n "	> installing /bin/lipsync..."
	cp bin/lipsync /bin; chown root:root /bin/lipsync; chmod 755 /bin/lipsync
	echo "done"
	echo -n "	> installing /etc/init.d/lipsync..."
	cp bin/lipsyncd /etc/init.d/; chown root:root /etc/init.d/lipsyncd; chmod 755 /etc/init.d/lipsyncd
	echo "done"
	echo -n "	> installing /etc/lipsync.xml..."
	cp etc/lipsync.xml /etc
	echo "done"
	echo -n "	> installing docs /var/log/lipsync.log..."
	mkdir /usr/share/doc/lipsync
	cp doc/README /usr/share/doc/lipsync
	echo "done"
	echo -n "	> preparing logfile /var/log/lipsync.log..."
	touch /var/log/lipsync.log
	echo "done"
}

uninstall(){
	echo -n "	NOTICE: stopping lipsync service..."
	#/etc/init.d/lipsyncd stop >> /dev/null 
	echo "done"

	echo -n "	NOTICE: removing lipsync user and group..."
	userdel lipsync
	echo "done"

	echo -n " 	NOTICE: removing lipsync files..."
	rm -rf /etc/init.d/lipsync*
	rm -rf /etc/lipsync*
	rm -rf /var/log/lipsync*
	rm -rf /usr/share/doc/lipsync*
	echo "done"
}
###############################################################################


###############################################################################
# Install or uninstall the lipsync service
###############################################################################
if [ "${1}" = "uninstall" ]; then
	echo "	ALERT: Uninstall option chosen, all lipsync files and configuration will be purged!"
	echo -n "	ALERT: To continue press enter to continue, otherwise hit ctrl-c to bail..."
	read continue
	uninstall
	exit 0
else
	questions
	#ssh.keygen
	create.group
	create.user
	build.conf
	deploy
fi
###############################################################################


###############################################################################
# Startup lipsync and exit
###############################################################################
echo "lipsync setup complete, staring lipsync..."
# /etc/init.d/lipsync
if [ -f /var/run/lipsync.pid ]; then
	echo "	NOTICE: lipsync is running as pid `cat /var/run/lipsync.pid`"
fi
###############################################################################

exit 0
