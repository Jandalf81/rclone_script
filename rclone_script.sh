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
{
	severity=$1
	message=$2
	printf "$(date +%FT%T%:z):\t${severity}:\t${message}\n" >> ${logfile}
}

function debug ()
{
	log "DEBUG" "direction: ${direction}"
	log "DEBUG" "system: ${system}"
	log "DEBUG" "emulator: ${emulator}"
	log "DEBUG" "rom: ${rom}"
	log "DEBUG" "command: ${command}"
	log "DEBUG" "remotebasedir: ${remotebasedir}"
	log "DEBUG" "rompath: ${rompath}"
	log "DEBUG" "romfilename: ${romfilename}"
	log "DEBUG" "romfilebase: ${romfilebase}"
	log "DEBUG" "romfileext: ${romfileext}"
}

function killOtherNotification ()
{
	# get PID of other PNGVIEW process
	otherPID=$(pgrep --full pngview)
	
	if [ "${debug}" = "1" ]; then log "DEBUG" "Other PIDs: ${otherPID}"; fi

	if [ "${otherPID}" != "" ]
	then
		if [ "${debug}" = "1" ]; then log "DEBUG" "Kill other PNGVIEW ${otherPID}"; fi
		
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
	
	# get line wiht RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
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

	log "INFO" "Started ${system}/${romfilename} "
	log "INFO" "Downloading saves and states for ${system}/${romfilename} from ${remoteType}..."
	showNotification "Downloading saves and states from ${remoteType}..."
	
	# test for remote files
	remotefiles=$(rclone lsf retropie:${remotebasedir}/${system} --include "${filter}.*")
	retval=$?
	
	if [ "${retval}" = "0" ]
	then # no error with RCLONE
		
		if [ "${remotefiles}" = "" ]
		then # no remote files found
			log "INFO" "No remote files found"
			showNotification "Downloading saves and states from ${remoteType}... No remote files found"
		else # remote files found
			log "INFO" "Found remote files"
			
			# download saves and states to corresponding ROM
			rclone copy retropie:${remotebasedir}/${system} ~/RetroPie/saves/${system} --include "${filter}.*" --update >> ${logfile}
			retval=$?
			
			if [ "${retval}" = "0" ]
			then
				log "INFO" "Done"
				showNotification "Downloading saves and states from ${remoteType}... Done" "green"
			else
				log "ERROR" "Saves and states could not be downloaded"
				showNotification "Downloading saves and states from ${remoteType}... ERROR" "red" "" "" "" "forced"
			fi
		fi
	else # error with RCLONE
		log "ERROR" "Saves and states could not be downloaded"
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

	log "INFO" "Stopped ${system}/${romfilename} "
	log "INFO" "Uploading saves and states for ${system}/${romfilename} to ${remoteType}..."
	showNotification "Uploading saves and states to ${remoteType}..."

	localfiles=$(find ~/RetroPie/saves/${system} -type f -iname "${filter}.*")
	
	if [ "${localfiles}" = "" ]
	then # no local files found
		log "INFO" "No local saves and states found"
		showNotification "Uploading saves and states to ${remoteType}... No local files found"
	else # local files found
		# upload saves and states to corresponding ROM
		rclone copy ~/RetroPie/saves/${system} retropie:${remotebasedir}/${system} --include "${filter}.*" --update >> ${logfile}
		retval=$?
		
		if [ "${retval}" = "0" ]
		then
			log "INFO" "Done"
			showNotification "Uploading saves and states to ${remoteType}... Done" "green"
		else
			log "ERROR" "saves and states could not be uploaded"
			showNotification "Uploading saves and states to ${remoteType}... ERROR" "red" "" "" "" "forced"
		fi
	fi
}


########
# MAIN #
########

if [ "${debug}" = "1" ]; then debug; fi

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
