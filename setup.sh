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
server.setup(){
	echo foo
}

client.setup(){
	echo foo
}

ssh.keygen(){
	echo -n "* Creating ssh key for ${username}..."
	ssh-keygen -N '' -f /home/${username}/.ssh/id_dsa
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error generating the ssh key"; exit 1
	fi
	
	echo -n "* Transferring ssh key for ${username} to ${remote_server}..."
	ssh-copy-id ${remote_server}
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error transferring the ssh key"; exit 1
	fi
	echo -n "* Setting permissions on the ssh key for ${username} on ${remote_server}..."
	ssh ${remote_server} 'chmod 700 .ssh'
	if [ $? -eq 0 ]; then
		echo "done"
	else
		echo; echo "	ERROR: there was an error setting permissions on the ssh key for ${username} on ${remote_server}..."
	fi
}

group.user(){
	echo -n "* Creating group lipsync..."
	grep lipsync /etc/group
	if [ $? -eq 0 ]; then
		echo; echo "	NOTICE: existing group lipsync found, not creating"
	else
		groupadd lipsync
		echo "done"
	fi
	echo -n "* Creating user lipsync..."
	grep lipsync /etc/user
	if [ $? -eq 0 ]; then
		echo; echo "	NOTICE: existing user lipsync found, not creating"
	else
		useradd -g lipsync -d /home/lipsync -m -s /bin/bash lipsync
		echo "done"
	fi
}

build.conffile(){
	echo foo
	#cat >etc/lipsync.conf<<EOF
	
	blah...

	EOF
}

uninstall(){
	echo "* Uninstalling and removing all lipsync files and configs..."
	/etc/init.d/libsyncd stop
	rm -rf /etc/init.d/lipsync*
	rm -rf /etc/lipsync*
	rm -rf /var/log/lipsync*
	rm -rf /usr/share/doc/lipsync*
	echo "done"
}

questions(){
	echo -n " - Are you setting up the server or client implemenatation? (server/client): "
  	read serverorclient

	echo -n " - IP or domainname for the remote or hub server: "
	read remote_server
	
	echo -n " - Lipsync username (user account must exist on local and remote systems): "
    	read username
    
	echo -n " - Full path to lipsync directory: "
	read lipsync_dir
}

deploy(){
	# populate bin
	cp bin/lipsync /bin; chown root:root /bin/lipsync; chmod 755 /bin/lipsync
	# populate init.d
	cp bin/lipsyncd /etc/init.d/; chown root:root /etc/init.d/lipsyncd; chmod 755 /etc/init.d/lipsyncd
	# populate etc
	cp etc/lipsync.conf /etc
	# populate log
	touch /var/log/lipsync.log
	# populate doc
	mkdir /usr/share/doc/lipsync
}
###############################################################################


###############################################################################
###############################################################################
if [ "$serverorclient" != "server" ] && [ "$serverorclient" != "client" ]; then
	echo  "fail"
else
	echo "ok"
fi

if [ "${1}" = "uninstall" ] && [ "${1}" != "remove" ]; then
	echo "* Uninstall option chosen, all lipsync files and config will be purged..."
	uninstall
	exit 0
else
	questions
fi
###############################################################################

exit 0
