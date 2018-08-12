#!/bin/bash


# define colors for output
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


backtitle="RCLONE_SCRIPT uninstaller"


##################
# WELCOME DIALOG #
##################
dialog \
	--backtitle "${backtitle}" \
	--title "Welcome" \
	--ascii-lines \
	--colors \
	--no-collapse \
	--cr-wrap \
	--yesno \
		"\nThis script will ${RED}uninstall RCLONE_SCRIPT${NORMAL}. If you do this, your savefile will no longer be synchonized!\n\nAre you sure you wish to continue?" \
	20 90 2>&1 > /dev/tty \
    || exit
	

####################
# DIALOG FUNCTIONS #
####################


function selectPartsToRemove ()
{
	local checklist
	
	checklist=$(dialog \
		--backtitle "${backtitle}" \
		--title "Select parts to remove" \
		--ascii-lines \
		--colors \
		--no-collapse \
		--cr-wrap \
		--checklist "Which part(s) do you wish to remove / undo?" 25 90 4 \
			1 "RCLONE binary" on \
			2 "RCLONE configuration" on \
			3 "PNGVIEW binary" on \
			4 "IMAGEMAGICK binary" on \
			5 "RCLONE_SCRIPT" on \
			6 "RUNCOMMAND calls" on \
			7 "Local SAVEFILE directory" on
	)
	
	for item in $checklist
	do
		case "$item" in
			1) removeRCLONEbinary  ;;
			2) removeRCLONEconfiguration  ;;
			3) removePNGVIEW  ;;
			4) removeIMAGEMAGICK  ;;
			5) removeRCLONE_SCRIPT  ;;
			6) removeRUNCOMMANDcalls  ;;
			7) removeLocalSAVEFILEDirectory  ;;
			*) break  ;;
		esac
	done
}