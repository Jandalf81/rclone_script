#!/bin/bash

# define colors for output
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)


# include settings file
source ~/scripts/rclone_script.ini


# parameters
direction="$1"
system="$2"
emulator="$3"
rom="$4"
command="$5"


log ()
{
	severity=$1
	message=$2
	printf "$(date +%FT%T%:z):\t${severity}:\t${message}\n" >> ${logfile}
}

debug ()
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

killOtherNotification ()
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

showNotification ()
{
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
			PNG32:- > ~/scripts/rclone_script-notification.png
	
	killOtherNotification
	
	# show PNG using PNGVIEW
	nohup pngview -b 0 -l 10000 ~/scripts/rclone_script-notification.png -x ${posx} -y ${posy} -t ${timeout} &>/dev/null &
}

getROMFileName ()
{
	rompath="${rom%/*}" # directory containing $rom
	romfilename="${rom##*/}" # filename of $rom, including extension
	romfilebase="${romfilename%%.*}" # filename of $rom, excluding extension
	romfileext="${romfilename#*.}" # extension of $rom
}

prepareFilter ()
{
	filter="${romfilebase//\[/\\[}"
	filter="${filter//\]/\\]}"
}

getTypeOfRemote ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line wiht RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
}

downloadSaves ()
{
	log "INFO" "Started ${romfilename} (${system})"
	log "INFO" "Downloading saves and states from ${remoteType}..."
	showNotification "Downloading saves and states from ${remoteType}..."
	
	# test for remote files
	remotefiles=$(rclone lsf retropie:${remotebasedir}/${system} --include "${filter}.*")
	retval=$?
	
	if [ "${retval}" = "0" ]
	then # no error with RCLONE
		
		if [ "${remotefiles}" = "" ]
		then # no remote files found
			log "INFO" "No remote files found"
			showNotification "Downloading saves and states from ${remoteType}... No remote saves found"
		else # remote files found
			log "INFO" "Found remote files"
			
			# download saves and states to corresponding ROM
			rclone copy retropie:${remotebasedir}/${system} ~/RetroPie/saves/${system} --include "${filter}.*" --update
			retval=$?
			
			if [ "${retval}" = "0" ]
			then
				log "INFO" "Done"
				showNotification "Downloading saves and states from ${remoteType}... Done" "green"
			else
				log "ERROR" "Saves could not be downloaded"
				showNotification "Downloading saves and states from ${remoteType}... ERROR" "red"
			fi
		fi
	else # error with RCLONE
		
		log "ERROR" "Saves could not be downloaded"
		showNotification "Downloading saves and states from ${remoteType}... ERROR" "red"
	fi
}

uploadSaves ()
{
	log "INFO" "Stopped ${romfilename} (${system})"
	log "INFO" "Uploading saves and states to ${remoteType}..."
	showNotification "Uploading saves and states to ${remoteType}..."

	localfiles=$(find ~/RetroPie/saves/${system} -type f -iname "${filter}.*")
	
	if [ "${localfiles}" = "" ]
	then # no local files found
		log "INFO" "No local saves found"
		showNotification "Uploading saves and states to ${remoteType}... No local saves found"
	else # local files found
		# upload saves and states to corresponding ROM
		rclone copy ~/RetroPie/saves/${system} retropie:${remotebasedir}/${system} --include "${filter}.*" --update
		retval=$?
		
		if [ "${retval}" = "0" ]
		then
			log "INFO" "Done"
			showNotification "Uploading saves and states to ${remoteType}... Done" "green"
		else
			log "ERROR" "Saves could not be uploaded"
			showNotification "Uploading saves and states to ${remoteType}... ERROR" "red"
		fi
	fi
}

doFullSync ()
{
	# header
	printf "${UNDERLINE}Full synchronization\n\n"

	# Download newer files from remote to local
	printf "${NORMAL}Downloading newer files from ${YELLOW}${YELLOW}retropie:${remotebasedir} (${remoteType}) ${NORMAL}to ${YELLOW}~/RetroPie/saves/${NORMAL}...\n"
	rclone copy retropie:${remotebasedir}/ ~/RetroPie/saves/ --update --verbose
	printf "${GREEN}Done\n"

	printf "\n"

	# Upload newer files from local to remote
	printf "${NORMAL}Uploading newer files from ${YELLOW}~/RetroPie/saves/${NORMAL} to ${YELLOW}${YELLOW}retropie:${remotebasedir} (${remoteType})${NORMAL} ...\n"
	rclone copy ~/RetroPie/saves/ retropie:${remotebasedir}/ --update --verbose
	printf "${GREEN}Done\n"

	printf "\n"
	printf "${NORMAL}Returning to EmulationStation in ${YELLOW}10 seconds ${NORMAL}...\n"
	read -t 10
}


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

if [ "${direction}" == "full" ]
then
	getTypeOfRemote
	doFullSync
fi
