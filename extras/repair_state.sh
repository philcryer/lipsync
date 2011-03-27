#!/bin/bash
echo "	Repairing inconsistent state..."
	rm ~/.unison/ar* >> /dev/null; ssh LSUSER@LSREMSERV -p LPORT rm ~/.unison/ar* >> /dev/null
	unison lipsync
exit 0
