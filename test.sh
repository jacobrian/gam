#!/bin/bash
#Script to remove user from all of their assigned  google groups
username=$1
gam="$HOME/bin/gam/gam"

# Changing user's password to random
echo "Changing "$username"'s' password to something random"

read -r -p "Do you want to transfer Google Drive to the manager? [y/N] " response
if [[ $response =~ ^([yY][eE][sS] |[yY][eE][sS])$ ]]
	then 
		read -r -p "What is "$username"'s manager's username? [Initiates Drive Transfer after immediately after entering manager account name]" r_manager
		#$gam create datatransfer $username gdrive $r_manager privacy_level shared,private | tee -a /tmp/$username.tmp
		echo $r_manager	
fi

echo "Offboard complete for $username. Log available at /tmp/$username.tmp"
