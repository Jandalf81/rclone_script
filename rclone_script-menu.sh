#!/bin/bash


NORMAL="\Zn"
BLACK="\Z0"
RED="\Z1"
GREEN="\Z2"
YELLOW="\Z3\Zb"
BLUE="\Z4"
MAGENTA="\Z5"
CYAN="\Z6"
WHITE="\Z7"
BOLD="\Zb"
REVERSE="\Zr"
UNDERLINE="\Zu"


# include settings file
config=~/scripts/rclone_script/rclone_script.ini
source ${config}

backtitle="RCLONE_SCRIPT menu (https://github.com/Jandalf81/rclone_script)"


####################
# HELPER FUNCTIONS #
####################

function log ()
{
	severity=$1
	message=$2
	printf "$(date +%FT%T%:z):\t${severity}:\t${message}\n" >> ${logfile}
}

function getTypeOfRemote ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line wiht RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
}

function getStatusOfParameters ()
{
	if [ "${syncOnStartStop}" == "TRUE" ]
	then
		statusSyncOnStartStop="${GREEN}ENABLED${NORMAL}"
	else
		statusSyncOnStartStop="${RED}DISABLED${NORMAL}"
	fi
	
	if [ "${showNotifications}" == "TRUE" ]
	then
		statusShowNotifications="${GREEN}ENABLED${NORMAL}"
	else
		statusShowNotifications="${RED}DISABLED${NORMAL}"
	fi
	
	case ${neededConnection} in
		0) statusNeededConnection="Internet access" ;;
		1) statusNeededConnection="LAN / WLAN" ;;
	esac
}

function saveConfig ()
{
	echo "remotebasedir=${remotebasedir}" > ${config}
	echo "showNotifications=${showNotifications}" >> ${config}
	echo "syncOnStartStop=${syncOnStartStop}" >> ${config}
	echo "logfile=~/scripts/rclone_script/rclone_script.log" >> ${config}
	echo "neededConnection=${neededConnection}" >> ${config}
	echo "debug=0" >> ${config}
}


##################
# MENU FUNCTIONS #
##################

# Show the main menu. Return here anytime another dialog is closed
function main_menu ()
{
	local choice="1"
	
	while true
	do
		getStatusOfParameters
	
		choice=$(dialog \
			--stdout \
			--colors \
			--backtitle "${backtitle}" \
			--title "main menu" \
			--default-item "${choice}" \
			--menu "\nWhat do you want to do?" 25 75 20 \
				1 "Full synchronization of all savefiles and statefiles" \
				2 "Toggle \"Synchronize saves on start / stop\" (currently ${statusSyncOnStartStop})" \
				3 "Toggle \"Show notifications on sync\" (currently ${statusShowNotifications})" \
				4 "Set needed Connection (currently \"${statusNeededConnection}\")" \
				"" ""\
				9 "uninstall RCLONE_SCRIPT"
			)
		
		case "$choice" in
			1) doFullSync  ;;
			2) toggleSyncOnStartStop  ;;
			3) toggleShowNotifications  ;;
			4) setNeededConnection ;;
			9) ~/scripts/rclone_script/rclone_script-uninstall.sh  ;;
			*) break  ;;
		esac
	done
}

# Syncs all files in both directions, only transferring newer files
function doFullSync ()
{
	local tmpfile=~/scripts/rclone_script/tmp-sync.txt
	
	getTypeOfRemote
	printf "\nStarted full sync...\n\n" > ${tmpfile}
	log "INFO" "Started full sync..."
	
	# start sync process in background
	{
		# Download newer files from remote to local
		printf "Downloading newer files from retropie:${remotebasedir} (${remoteType}) to ~/RetroPie/saves/...\n"
		rclone copy retropie:${remotebasedir}/ ~/RetroPie/saves/ --update --skip-links --exclude "readme.txt" --verbose 2>&1
		
		# Upload newer files from local to remote
		printf "Uploading newer files from ~/RetroPie/saves/ to retropie:${remotebasedir} (${remoteType})...\n"
		rclone copy ~/RetroPie/saves/ retropie:${remotebasedir}/ --update --skip-links --exclude "readme.txt" --verbose 2>&1
		
		printf "Done\n"
	} >> ${tmpfile} & # capture output of background process
	
	dialog \
			--backtitle "${backtitle}" \
			--title "Doing full sync..." \
			--colors \
			--no-collapse \
			--cr-wrap \
			--tailbox ${tmpfile} 40 120
			
	wait
	
	cat ${tmpfile} >> ${logfile}
	rm ${tmpfile}
	
	log "INFO" "Finished full sync..."
}

function toggleSyncOnStartStop ()
{
	if [ "${syncOnStartStop}" == "TRUE" ]
	then
		syncOnStartStop="FALSE"
	else
		syncOnStartStop="TRUE"
	fi
	
	saveConfig
}

function toggleShowNotifications ()
{
	if [ "${showNotifications}" == "TRUE" ]
	then
		showNotifications="FALSE"
	else
		showNotifications="TRUE"
	fi
	
	saveConfig
}

function setNeededConnection ()
{
	choice=$(dialog \
		--stdout \
		--colors \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Needed connection" \
		--default-item "${neededConnection}" \
		--ok-label "Select" \
		--menu "\nPlease select which type of connection will be needed for your configured remote" 20 50 5 \
			0 "Internet access" \
			1 "LAN / WLAN connection only"
		)
	
	case ${choice} in 
		0) neededConnection=0 ;;
		1) neededConnection=1 ;;
		*) return ;;
	esac
	
	saveConfig
}


########
# MAIN #
########

main_menu