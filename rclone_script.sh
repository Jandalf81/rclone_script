#!/bin/bash

# define colors for output
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)


# include settings file
config=~/scripts/rclone_script/rclone_script.ini
source ${config}
logLevel=2


# parameters
direction="$1"
system="$2"
emulator="$3"
rom="$4"
command="$5"


####################
# HELPER FUNCTIONS #
####################

function log ()
# Prints messages of different severeties to a logfile
# Each message will look something like this:
# <TIMESTAMP>	<SEVERITY>	<CALLING_FUNCTION>	<MESSAGE>
# needs a set variable $logLevel
#	-1 > No logging at all
#	0 > prints ERRORS only
#	1 > prints ERRORS and WARNINGS
#	2 > prints ERRORS, WARNINGS and INFO
#	3 > prints ERRORS, WARNINGS, INFO and DEBUGGING
# needs a set variable $log pointing to a file
# Usage
# log 0 "This is an ERROR Message"
# log 1 "This is a WARNING"
# log 2 "This is just an INFO"
# log 3 "This is a DEBUG message"
{
	severity=$1
	message=$2
	
	if (( ${severity} <= ${logLevel} ))
	then
		case ${severity} in
			0) level="ERROR"  ;;
			1) level="WARNING"  ;;
			2) level="INFO"  ;;
			3) level="DEBUG"  ;;
		esac
		
		printf "$(date +%FT%T%:z):\t${level}\t${0##*/}\t${FUNCNAME[1]}\t${message}\n" >> ${logfile} 
	fi
}

function killOtherNotification ()
{
	# get PID of other PNGVIEW process
	otherPID=$(pgrep --full pngview)
	
	if [ "${debug}" = "1" ]; then log 3 "Other PIDs: ${otherPID}"; fi

	if [ "${otherPID}" != "" ]
	then
		if [ "${debug}" = "1" ]; then log 3 "Kill other PNGVIEW ${otherPID}"; fi
		
		kill ${otherPID}
	fi
}

function showNotification ()
{
	# Quit here, if Notifications are not to be shown and they are not forced
	if [ "${showNotifications}" == "FALSE" ] && [ "$6" != "forced" ]
	then
		return
	fi
	
	message="$1"
	
	if [ "$2" = "" ]
	then
		color="yelloW"
	else
		color="$2"
	fi

	if [ "$3" = "" ]
	then
		timeout="10000"
	else
		timeout="$3"
	fi
	
	if [ "$4" = "" ]
	then
		posx="10"
	else
		posx="$4"
	fi
	
	if [ "$5" = "" ]
	then
		posy="10"
	else
		posy="$5"
	fi
	
	# create PNG using IMAGEMAGICK
	convert -size 1500x32 xc:"rgba(0,0,0,0)" -type truecolormatte -gravity NorthWest \
			-pointsize 32 -font FreeMono -style italic \
			-fill ${color} -draw "text 0,0 '${message}'" \
			PNG32:- > ~/scripts/rclone_script/rclone_script-notification.png
	
	killOtherNotification
	
	# show PNG using PNGVIEW
	nohup pngview -b 0 -l 10000 ~/scripts/rclone_script/rclone_script-notification.png -x ${posx} -y ${posy} -t ${timeout} &>/dev/null &
}

function getROMFileName ()
{
	rompath="${rom%/*}" # directory containing $rom
	romfilename="${rom##*/}" # filename of $rom, including extension
	romfilebase="${romfilename%%.*}" # filename of $rom, excluding extension
	romfileext="${romfilename#*.}" # extension of $rom
}

function prepareFilter ()
{
	filter="${romfilebase//\[/\\[}"
	filter="${filter//\]/\\]}"
}

function getTypeOfRemote ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line with RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
}

function getAvailableConnection ()
# checks if the device is connected to a LAN / WLAN and the Internet
# RETURN
#	0 > device seems to be connected to the Internet
#	1 > device seems to be connected to a LAN / WLAN without internet access
#	2 > device doesn't seem to be connected at all
{
	gatewayIP=$(ip r | grep default | cut -d " " -f 3)	
	if [ "${gatewayIP}" == "" ]
	then 
		log 2 "Gateway could not be detected"
		return 2
	else
		log 2 "Gateway IP: ${gatewayIP}"
	fi
	
	ping -q -w 1 -c 1 ${gatewayIP} > /dev/null
	if [[ $? -eq 0 ]]
	then
		log 2  "Gateway PING successful"
	else
		log 2  "Gateway could not be PINGed"
		return 2
	fi
	
	ping -q -w 1 -c 1 "www.google.com" > /dev/null
	if [[ $? -eq 0 ]]
	then
		log 2  "www.google.com PING successful"
		return 0
	else
		log 2 "www.google.com could not be PINGed"
		return 1
	fi
}


##################
# SYNC FUNCTIONS #
##################

function downloadSaves ()
{
	if [ "${syncOnStartStop}" == "FALSE" ]
	then
		showNotification "!!! Synchronization is currently disabled !!!" "red" "" "" "" "forced"
		return
	fi

	log 2 "Started ${system}/${romfilename} "
	log 2 "Downloading saves and states for ${system}/${romfilename} from ${remoteType}..."
	showNotification "Downloading saves and states from ${remoteType}..."
	
	getAvailableConnection
	availableConnection=$?
	if [[ ${availableConnection} -gt ${neededConnection} ]]
	then 
		log 0 "Needed Connection not available. Needed ${neededConnection}, available ${availableConnection}"
		
		case ${neededConnection} in
			0) showNotification "Downloading saves and states from ${remoteType}... No Internet connection available" "red" "" "" "" "forced" ;;
			1) showNotification "Downloading saves and states from ${remoteType}... No LAN / WLAN connection available" "red" "" "" "" "forced" ;;
		esac
		
		return
	fi
	
	# test for remote files
	remotefiles=$(rclone lsf retropie:${remotebasedir}/${system} --include "${filter}.*")
	retval=$?
	
	if [ "${retval}" = "0" ]
	then # no error with RCLONE
		
		if [ "${remotefiles}" = "" ]
		then # no remote files found
			log 2 "No remote files found"
			showNotification "Downloading saves and states from ${remoteType}... No remote files found"
		else # remote files found
			log 2 "Found remote files"
			
			# download saves and states to corresponding ROM
			rclone copy retropie:${remotebasedir}/${system} ~/RetroPie/saves/${system} --include "${filter}.*" --update >> ${logfile}
			retval=$?
			
			if [ "${retval}" = "0" ]
			then
				log 2 "Done"
				showNotification "Downloading saves and states from ${remoteType}... Done" "green"
			else
				log 2 "Saves and states could not be downloaded"
				showNotification "Downloading saves and states from ${remoteType}... ERROR" "red" "" "" "" "forced"
			fi
		fi
	else # error with RCLONE
		log 0 "Saves and states could not be downloaded"
		showNotification "Downloading saves and states from ${remoteType}... ERROR" "red" "" "" "" "forced"
	fi
}

function uploadSaves ()
{
	if [ "${syncOnStartStop}" == "FALSE" ]
	then
		showNotification "!!! Synchronization is currently disabled !!!" "red" "" "" "" "forced"
		return
	fi

	log 2 "Stopped ${system}/${romfilename} "
	log 2 "Uploading saves and states for ${system}/${romfilename} to ${remoteType}..."
	showNotification "Uploading saves and states to ${remoteType}..."
	
	getAvailableConnection
	availableConnection=$?
	if [[ ${availableConnection} -gt ${neededConnection} ]]
	then 
		log 0 "Needed Connection not available. Needed ${neededConnection}, available ${availableConnection}"
		
		case ${neededConnection} in
			0) showNotification "Uploading saves and states to ${remoteType}... No Internet connection available" "red" "" "" "" "forced" ;;
			1) showNotification "Uploading saves and states to ${remoteType}... No LAN / WLAN connection available" "red" "" "" "" "forced" ;;
		esac
		
		return
	fi

	localfiles=$(find ~/RetroPie/saves/${system} -type f -iname "${filter}.*")
	
	if [ "${localfiles}" = "" ]
	then # no local files found
		log 2 "No local saves and states found"
		showNotification "Uploading saves and states to ${remoteType}... No local files found"
	else # local files found
		# upload saves and states to corresponding ROM
		rclone copy ~/RetroPie/saves/${system} retropie:${remotebasedir}/${system} --include "${filter}.*" --update >> ${logfile}
		retval=$?
		
		if [ "${retval}" = "0" ]
		then
			log 2 "Done"
			showNotification "Uploading saves and states to ${remoteType}... Done" "green"
		else
			log 2 "saves and states could not be uploaded"
			showNotification "Uploading saves and states to ${remoteType}... ERROR" "red" "" "" "" "forced"
		fi
	fi
}


function deleteFileFromRemote ()
# deletes a file from the remote
# INPUT
#	$1 > relative filepath incl. name and extension to the local savepath
# RETURN
#	0 > file deteted successfully
#	1 > connection not available
#	2 > file could not be deleted
{
	fileToDelete="$1"
	log 2 "File to delete: retropie:${remotebasedir}/${fileToDelete}"
	
	getAvailableConnection
	availableConnection=$?
	if [[ ${availableConnection} -gt ${neededConnection} ]]
	then 
		log 0 "Needed Connection not available. Needed ${neededConnection}, available ${availableConnection}"
		return 1
	fi
	
	rclone delete "retropie:${remotebasedir}/${fileToDelete}" 2>&1 >> ${logfile}
	if [[ $? -eq 0 ]]
	then
		log 2 "File deleted successfully"
		return 0
	else
		log 0 "File could not be deleted. Error Code $?"
		return 1
	fi
}

########
# MAIN #
########

#if [ "${debug}" = "1" ]; then debug; fi
log 3 "direction: ${direction}"
log 3 "system: ${system}"
log 3 "emulator: ${emulator}"
log 3 "rom: ${rom}"
log 3 "command: ${command}"
log 3 "remotebasedir: ${remotebasedir}"
log 3 "rompath: ${rompath}"
log 3 "romfilename: ${romfilename}"
log 3 "romfilebase: ${romfilebase}"
log 3 "romfileext: ${romfileext}"

if [ "${direction}" == "up" ] && [ "${system}" != "kodi" ]
then
	getROMFileName
	prepareFilter
	getTypeOfRemote
	uploadSaves
fi

if [ "${direction}" == "down" ] && [ "${system}" != "kodi" ]
then
	getROMFileName
	prepareFilter
	getTypeOfRemote
	downloadSaves
fi

if [ "${direction}" == "delete" ]
then
	deleteFileFromRemote "${2}"
fi
