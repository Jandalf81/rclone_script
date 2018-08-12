#!/bin/bash


NORMAL="\Zn"
BLACK="\Z0"
RED="\Z1"
GREEN="\Z2"
YELLOW="\Z3"
BLUE="\Z4"
MAGENTA="\Z5"
CYAN="\Z6"
WHITE="\Z7"
BOLD="\Zb"
REVERSE="\Zr"
UNDERLINE="\Zu"


function main_menu ()
{
	local choice
	
	while true
	do
		choice=$(dialog \
			--stdout \
			--ascii-lines \
			--backtitle "RCLONE_SCRIPT menu" \
			--title "main menu" \
			--menu "\nWhat do you want to do?" 25 75 20 \
				1 "Full sync" \
				9 "uninstall"
			)
		
		case "$choice" in
			1) ~/scripts/rclone_script/rclone_script.sh "full"  ;;
			9) ~/scripts/rclone_script/rclone_script-uninstall.sh  ;;
			*) break  ;;
		esac
	done
}

main_menu