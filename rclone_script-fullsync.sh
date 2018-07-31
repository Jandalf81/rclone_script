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


getTypeOfRemote ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line with RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)
}

getTypeOfRemote

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