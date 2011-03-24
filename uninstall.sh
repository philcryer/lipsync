#!/bin/bash
echo "	Repairing inconsistent state..." 
	rm ~/.unison/ar* >> /dev/null; ssh -p 666 bob@192.168.1.6 rm ~/.unison/ar* >> /dev/null
	unison lipsync
exit 0
