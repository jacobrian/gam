#This script performs various offboarding tasks when a user leaves the company.
username=$1

#Set log location, pipe all actions to log file.
logloc="/Volumes/GoogleDrive/Team Drives/ITOps Team Drive/Offboarding/google_suite/test_log.log"
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>"$logloc" 2>&1

echo Offboard executed by $(whoami) on $(date) 

# Removing all mobile devices connected
echo "Gathering mobile devices for $username" 
IFS=$'\n'
mobile_devices=($(gam print mobile query $username | grep -v resourceId | awk -F"," '{print $1}'))
unset IFS
	for mobileid in ${mobile_devices[@]}
		do
			gam update mobile $mobileid action account_wipe && echo "Removing $mobileid from $username"
	done 

# Changing user's password to random
echo "Changing "$username"'s' password to something random"
gam update user $username password random 

# Removing all App-Specific account passwords, deleting MFA Recovery Codes,
# deleting all OAuth tokens
echo "Checking and Removing all of "$username"'s Application Specific Passwords, 2SV Recovery Codes, and all OAuth tokens"
gam user $username deprovision 

# Removing user from all Groups
echo "Gathering group information for $username"
amount_of_groups="$(gam info user $username | grep "Groups: (" | sed 's/[^0-9]//g')"
IFS=$'\n'
groups_list=($(gam info user $username | grep -A $amount_of_groups Groups | grep -v Groups | sed 's/^[^<]*<//g' | sed 's/\@.*$//g'))
unset IFS
	for group_name in ${groups_list[@]}
		do
			gam update group $group_name remove user $username && echo "Removed $username from $group_name"
	done 

# Forcing change password on next sign-in and then disabling immediately.
# Speculation that this will sign user out within 5 minutes and not allow
# user to send messages without reauthentication
echo "Setting force change password on next logon and then disabling immediately to expire current session"
gam update user $username changepassword on
sleep 2 && echo "Waiting for 2 seconds"
gam update user $username changepassword off

# Generating new set of MFA recovery codes for the user
echo "Generating new 2SV Recovery Codes for $username"
gam user $username update backupcodes 

# Removing all of user's calendar events
read -r -p "Do you want to Wipe "$username"'s calendar? [Yes/No] " wipe_answer
if [[ $wipe_answer =~ ^([yY][eE][sS]|[yY][eE]|[yY])+$ ]]
	then
		echo "Deleting all of "$username"'s calendar events"
		gam calendar $username wipe 
	else
		echo "Not wiping calendar" 
fi

# Suspending user
echo "Setting $username to suspended" 
gam update user $username suspended on 

# Asks admin if they want to transfer docs to manager, if so, asks for manager's
# google username and then initiate a gdrive file transfer
read -r -p "What is "$username"'s manager's username? " r_manager
read -r -p "Do you want to transfer Google Drive to the manager $r_manager? [Yes/No] " response
if [[ $response =~ ^([yY][eE][sS]|[yY][eE]|[yY])+$ ]]
	then
		echo "Creating transfer to $r_manager"
		gam create datatransfer $username gdrive $r_manager privacy_level shared,private 
	else
		echo "Not transferring GDrive" 
fi


# Asks admin if they want to forward incoming emails to the offboarded user to the manager, if so, asks for manager's google username and then
# prepend s_ to the primary email address, create a group using primary and make manager its owner
read -r -p "Do you want to forward incoming email to the manager $r_manager? [Yes/No] " response
if [[ $response =~ ^([yY][eE][sS]|[yY][eE]|[yY])+$ ]]
        then
                echo "Creating forwarding to $r_manager"
                gam update user $username email s_$username 
                gam delete alias $username 
		sleep 10
                gam create group $username description suspended_user 
								sleep 10
                gam update group $username add owner user $r_manager 
                gam update group $username show_in_group_directory false include_in_global_address_list false allow_web_posting false is_archived false who_can_view_group all_members_can_view 
        else
                echo "Not setting up the forwarding" 
fi


# Printing Log location
echo "Offboard complete for $username."
echo "Log located at $logloc"
