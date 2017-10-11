#!/bin/bash
#Script to remove user from all of their assigned  google groups
username=$1

gam="$HOME/bin/gam/gam"

read -r -p "Are you sure you want to remove $1 from all mail groups? [y/N] " response
if [[ $response =~ ^([yY][eE][sS] |[yY])$ ]]
	then 
		echo "Gathering group information for $username"
		amount_of_groups="$($gam info user $username | grep "Groups: (" | sed 's/[^0-9]//g')"
	
		IFS=$'\n'	
		groups_list=($($gam info user $username | grep -A $amount_of_groups Groups | grep -v Groups | sed 's/^[^<]*<//g' | sed 's/\@.*$//g'))
		unset IFS
			for group_name in ${groups_list[@]}
				do
					$gam update group $group_name remove user $username && echo "Removed $username from $group_name"
				done | tee /tmp/$username.tmp && echo "Saved log to /tmp/$username.tmp"
fi

