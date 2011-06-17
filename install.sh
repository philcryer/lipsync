#!/bin/bash
# Distributed under the terms of the BSD License.
# Copyright (c) 2011 Phil Cryer phil.cryer@gmail.com
# Source https://github.com/philcryer/lipsync
 
#clear
stty erase '^?'
echo "lipsync install script"

########################################
# Check users's privileges
########################################
echo -n "* Checking user's privileges..."
if [ "$(id -u)" != "0" ]; then 
	sudo -v >/dev/null 2>&1 || { echo; echo "	ERROR: User $(whoami) is not root, and does not have sudo privileges" ; exit 1; }
else
	echo "ok"
fi

########################################
# Check Linux variant
########################################
echo -n "* Checking Linux variant..."
if [[ $(cat /etc/issue.net | cut -d' ' -f1) == "Debian" ]] || [[ $(cat /etc/issue.net | cut -d' ' -f1) == "Ubuntu" ]];then
	echo "ok"
else
	echo; echo "	ERROR: this installer was written to work with Debian/Ubuntu,"
	echo       "	it could work (tm) with your system - let us know if it does"
fi

########################################
# Check for required software
########################################
echo -n "* Checking for required software..."
type -P ssh &>/dev/null || { echo; echo "	ERROR: lipsync requires ssh-client but it's not installed" >&2; exit 1; }
#type -P ssh-copy-id &>/dev/null || { echo; echo "	ERROR: lipsync requires ssh-copy-id but it's not installed" >&2; exit 1; }
type -P rsync &>/dev/null || { echo; echo "	ERROR: lipsync requires rsync but it's not installed" >&2; exit 1; }
type -P lsyncd &>/dev/null || { echo; echo "	ERROR: lipsync requires lsyncd but it's not installed" >&2; exit 1; }
LSYNCD_VERSION=`lsyncd -version | cut -d' ' -f2 | cut -d'.' -f1`
if [ $LSYNCD_VERSION -lt '2' ]; then
	        echo; echo "    ERROR: lipsync requires lsyncd 2.x or greater, but it's not installed" >&2; exit 1
fi
echo "ok"

########################################
# Define functions
########################################
questions(){
	echo -n "> SERVER: IP or domainname: "
	read remote_server

	echo -n "> SERVER: SSH port: "
	read port
	
	echo -n "> SERVER/CLIENT: username (must exist on both): "
    	read username
    
	echo -n "> CLIENT: directory to be synced: "
	read lipsync_dir_local

	echo -n "> SERVER: remote directory to be synced: "
	read lipsync_dir_remote
}

ssh.keygen(){
  if ssh -i /home/${username}/.ssh/id_dsa -p ${port} -o "KbdInteractiveAuthentication=no" -o "PasswordAuthentication=no" ${username}@${remote_server} echo "hello" > /dev/null
  then
    echo "	ssh key exists here and on server, skipping key generation and transfer steps"
    return
  else
  	if [ -f '/home/${username}/.ssh/id_dsa' ]; then
  		echo "* Existing SSH key found for ${username} backing up..."
  		mv /home/${username}/.ssh/id_dsa /home/${username}/.ssh/id_dsa-OLD
  		if [ $? -eq 0 ]; then
  			echo "done"
  		else
  			echo; echo "	ERROR: there was an error backing up the SSH key"; exit 1
  		fi
  	fi
  
  	echo "* Checking for an SSH key for ${username}..."
  	if [ -f /home/${username}/.ssh/id_dsa ]; then
  		echo "* Existing key found, not creating a new one..."
  	else
  		echo -n "* No existing key found, creating SSH key for ${username}..."
  		ssh-keygen -q -N '' -f /home/${username}/.ssh/id_dsa
  		if [ $? -eq 0 ]; then
  		chown -R $username:$username /home/${username}/.ssh
  			echo "done"
  		else
  			echo; echo "	ERROR: there was an error generating the ssh key"; exit 1
  		fi
  	fi
  	
  	echo "* Transferring ssh key for ${username} to ${remote_server} on port ${port} (login as $username now)..."; 

	if which ssh-copy-id &> /dev/null; then
  		su ${username} -c "ssh-copy-id -i /home/${username}/.ssh/id_dsa.pub '-p ${port} ${username}@${remote_server}'" >> /dev/null
  		if [ $? -eq 0 ]; then
  			X=0	#echo "done"
  		else
  			echo
			echo "	ERROR: there was an error transferring the ssh key"; 
			exit 1 
		fi
	else
  		su ${username} -c "cat /home/${username}/.ssh/id_rsa.pub | ssh $remote_server -p ${port} 'cat - > /home/${username}/.ssh/id_dsa.pub'" >> /dev/null
  		if [ $? -eq 0 ]; then
  			X=0	#echo "done"
  		else
  			echo
			echo "	ERROR: there was an error transferring the ssh key"; 
			exit 1 
		fi
	fi

  	echo -n "* Setting permissions on the ssh key for ${username} on ${remote_server} on port ${port}..."; 
  	su ${username} -c "SSH_AUTH_SOCK=0 ssh ${remote_server} -p ${port} 'chmod 700 .ssh'"
  	if [ $? -eq 0 ]; then
  		echo "done"
  	else
  		echo; echo "	ERROR: there was an error setting permissions on the ssh key for ${username} on ${remote_server} on port ${port}..."; exit 1
  	fi
  fi
}

build.conf(){
	echo -n "* Creating lipsyncd config..."
	sed etc/lipsyncd_template > etc/lipsyncd \
		-e 's|LSLOCDIR|'$lipsync_dir_local/'|g' \
		-e 's|LSUSER|'$username'|g' \
		-e 's|LSPORT|'$port'|g' \
		-e 's|LSREMSERV|'$remote_server'|g' \
		-e 's|LSREMDIR|'$lipsync_dir_remote'|g'
	echo "done"
}

deploy(){
	echo "* Deploying lipsync..."
	echo -n "	> /usr/local/bin/lipsync..."
	cp bin/lipsync /usr/local/bin; chown root:root /usr/local/bin/lipsync; chmod 755 /usr/local/bin/lipsync
	cp bin/lipsync-notify /usr/local/bin; chown root:root /usr/local/bin/lipsync-notify; chmod 755 /usr/local/bin/lipsync-notify
	echo "done"

	echo -n "	> /usr/local/bin/lipsyncd..."
	if [ -x  /usr/local/bin/lsyncd ]; then
		ln -s /usr/local/bin/lsyncd /usr/local/bin/lipsyncd
	fi
	echo "done"

	echo -n "	> /etc/init.d/lipsyncd..."
	cp etc/init.d/lipsyncd /etc/init.d
	echo "done"

	echo -n "	> Installing cron for user $username..."
	newcronjob="* * * * *  /usr/local/bin/lipsync >/dev/null 2>&1"      #define entry for crontab	
	(crontab -l; echo "$newcronjob") | crontab -u $username -  #list crontab, read entry from crontab, add line from stdin to crontab
	echo "done"

	echo -n "	> /etc/lipsyncd..."
	mv etc/lipsyncd /etc/
	echo "done"

	echo -n "	> /usr/share/doc/lipsyncd..."
	if [ ! -d /usr/share/doc/lipsyncd ]; then
		mkdir /usr/share/doc/lipsyncd
	fi
	cp README* LICENSE uninstall.sh docs/* /usr/share/doc/lipsyncd
	echo "done"

	echo -n "	> /home/$username/.lipsyncd..."
 	if [ ! -d /home/$username/.lipsyncd ]; then
        	mkdir /home/$username/.lipsyncd
		chown $username:$username /home/$username/.lipsyncd
        fi
	echo "done"

	echo -n "	> /home/$username/.lipsyncd/lipsyncd.log..."
	touch /home/$username/.lipsyncd/lipsyncd.log
	chown $username:$username /home/$username/.lipsyncd/lipsyncd.log
	chmod g+w /home/$username/.lipsyncd/lipsyncd.log
	echo "done"

	echo -n "	> checking for $lipsync_dir_local..."
	if [ ! -d $lipsync_dir_local ]; then
		echo; echo -n "	> $lipsync_dir_local not found, creating..."
		mkdir $lipsync_dir_local
		chown $username:$username $lipsync_dir_local
	fi
	echo "done"

	echo "lipsync installed `date`" > /home/$username/.lipsyncd/lipsyncd.log
}

initial_sync(){
	echo -n "* Doing inital sync with server..."
	. /etc/lipsyncd
	su $USER_NAME -c 'rsync -rav --stats --log-file=/home/'$USER_NAME'/.lipsyncd/lipsyncd.log -e "ssh -l '$USER_NAME' -p '$SSH_PORT'" '$REMOTE_HOST':'$LOCAL_DIR' '$REMOTE_DIR''
	echo "Initial sync `date` Completed" > /home/$username/.lipsyncd/lipsyncd.log
}

start(){
	/etc/init.d/lipsyncd start; sleep 2
	if [ -f /home/$username/.lipsyncd/lipsyncd.pid ]; then
#		echo "	NOTICE: lipsyncd is running as pid `cat /home/$username/.lipsyncd/lipsyncd.pid`"
		echo "	NOTICE: lipsyncd is running as pid `pidof lipsyncd`"
		echo "	Check lipsyncd.log for details"
	else
		echo "	NOTICE: lipsyncd failed to start..."
		echo "	Check /home/$username/.lipsyncd/lipsyncd.log for details"
	fi
}

########################################
# Install lipsyncd 
########################################
if [ "${1}" = "uninstall" ]; then
	echo "	ALERT: Uninstall option chosen, all lipsync files and configuration will be purged!"
	echo -n "	ALERT: To continue press enter to continue, otherwise hit ctrl-c now to bail..."
	read continue
	uninstall
	exit 0
else
	questions
	ssh.keygen
	build.conf
	deploy
	initial_sync
fi

########################################
# Start lipsyncd
########################################
echo "lipsync setup complete, starting lipsyncd..."
start

exit 0
