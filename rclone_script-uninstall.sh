#!/bin/bash

# define colors for output
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)

header ()
{
	# clear screen
	clear
	
	printf "${UNDERLINE}Uninstall cloud sync via RCLONE\n"
	printf "\n"
	printf "${NORMAL}Please select the options you'd like to remove from this system.\n"
	printf "Please note that this script also allows you to ${RED}delete your saves${NORMAL}.\n"
	printf "\n"
	printf "To ${GREEN}keep your saves${NORMAL}, ${RED}do not remove ${NORMAL}the ${YELLOW}local base save directory${NORMAL}\n"
	printf "and the ${YELLOW}core overrides ${NORMAL}pointing to these directories!\n"
	printf "\n"
}

removeRCLONE ()
{
	# remove RCLONE binary
	printf "${NORMAL}   Removing RCLONE binary... "
	
	{ #try
		retval=$(sudo rm /usr/bin/rclone 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removeRCLONEconfiguration ()
{
	# remove RCLONE configuration
	printf "${NORMAL}   Removing RCLONE configuration... "
	
	{ #try
		retval=$(rclone config delete retropie 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removePNGVIEW ()
{
	# remove PNGVIEW binary
	printf "${NORMAL}   Removing PNGVIEW binary... "
	
	{ #try
		retval=$(sudo rm /usr/bin/pngview 2>&1) &&
		retval=$(sudo rm /usr/lib/libraspidmx.so.1 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removeIMAGEMAGICK ()
{
	# remove IMAGEMAGICK
	printf "${NORMAL}   Removing IMAGEMAGICK... "
	
	{ #try
		retval=$(sudo apt-get --yes remove imagemagick* 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removeRUNCOMMAND ()
{
	# remove RUNCOMMAND scripts
	printf "${NORMAL}   Removing RUNCOMMAND calls to RCLONE_SCRIPT... "
	
	{ #try
		retval=$(sed -i "/^~\/scripts\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onstart.sh 2>&1) &&
		retval=$(sed -i "/^~\/scripts\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onend.sh 2>&1) &&
	
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removeRCLONE_SCRIPT ()
{
	# remove RCLONE_SCRIPT
	printf "${NORMAL}   Removing RCLONE_SCRIPT... "
	
	{ #try
		#don't acutally do this while it's being made
		retval=$(rm -d ~/scripts/rclone_script.sh 2>&1) &&
		retval=$(rm -d ~/scripts/rclone_script.ini 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

removeRCLONE_SCRIPT-FULLSYNC ()
{
	# TODO
}

removeLocalSaveDirectory ()
{
	# TODO: Issue #4: Move save files to default directories
	
	# remove base save directory
	printf "${NORMAL}   Removing local base save directory... "
	
	{ #try
		retval=$(rm -r ~/RetroPie/saves 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

resetSavefileDirectories ()
{
	# TODO: Issue #4: Reset savefile directories in CFG to default
}

# main program
header

read -p "${NORMAL}Remove RCLONE configuration? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	removeRCLONEconfiguration
fi

read -p "${NORMAL}Remove RCLONE binary? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	removeRCLONE
fi

read -p "${NORMAL}Remove PNGVIEW binary? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	removePNGVIEW
fi

read -p "${NORMAL}Remove IMAGEMAGICK? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	removeIMAGEMAGICK
fi

read -p "${NORMAL}Remove RUNCOMMAND calls to RCLONE_SCRIPT? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	printf "   ${RED}ATTENTION!${NORMAL} By removing these calls your saves will no longer be\n"
	printf "   synchronized. Your progress in games will be available on this machine only!\n"
	
	read -p "   ${NORMAL}Really proceed? ([y], n): " userInput
	userInput=${userInput:-y}
	if [ "${userInput}" = "y" ]; then
		removeRUNCOMMAND
	fi
fi

read -p "${NORMAL}Remove RCLONE_SCRIPT? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	printf "   ${RED}ATTENTION!${NORMAL} By removing RCLONE_SCRIPT your saves will no longer be\n"
	printf "   synchronized. Your progress in games will be available on this machine only!\n"
	
	read -p "   ${NORMAL}Really proceed? ([y], n): " userInput
	userInput=${userInput:-y}
	if [ "${userInput}" = "y" ]; then
		removeRCLONE_SCRIPT
	fi
fi

read -p "${NORMAL}Remove local base save directory? ([y], n): " userInput
userInput=${userInput:-y}
if [ "${userInput}" = "y" ]; then
	printf "   ${RED}ATTENTION!${NORMAL} This directory contains your saves.\n"
	printf "   By removing this directory you ${RED}WILL LOSE ${NORMAL}all saves!\n"
	
	read -p "   ${NORMAL}Really proceed? ([y], n): " userInput
	userInput=${userInput:-y}
	if [ "${userInput}" = "y" ]; then
		removeLocalSaveDirectory
	fi
fi