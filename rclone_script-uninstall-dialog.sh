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
logfile=~/scripts/rclone_script/rclone_script-uninstall.log


##################
# WELCOME DIALOG #
##################
dialog \
	--stdout \
	--backtitle "${backtitle}" \
	--title "Welcome" \
	--ascii-lines \
	--colors \
	--no-collapse \
	--cr-wrap \
	--yesno \
		"\nThis script will ${RED}uninstall RCLONE_SCRIPT${NORMAL}. If you do this, your savefiles will no longer be synchonized!\n\nAre you sure you wish to continue?" \
	20 90 2>&1 > /dev/tty \
    || exit
	

####################
# DIALOG FUNCTIONS #
####################


# Build progress from array $STEPS()
# INPUT
#	$steps()
# OUTPUT
#	$progress
function buildProgress ()
{
	progress=""
	
	for ((i=0; i<=${#steps[*]}; i++))
	do
		progress="${progress}${steps[i]}\n"
	done
}

# Show Progress dialog
# INPUT
#	1 > Percentage to show in dialog
#	$backtitle
#	$progress
function dialogShowProgress ()
{
	local percent="$1"
	
	buildProgress
	
	clear
	clear
	
	echo "${percent}" | dialog \
		--stdout \
		--colors \
		--ascii-lines \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Uninstaller" \
		--gauge "${progress}" 36 90 0 \
		2>&1 > /dev/tty
		
	sleep 1
}


##################
# STEP FUNCTIONS #
##################

# Initialize array $STEPS()
# OUTPUT
#	$steps()
function initSteps ()
{
	steps[1]="1. RCLONE"
	steps[2]="	1a. Remove RCLONE configuration			[ waiting...  ]"
	steps[3]="	1b. Remove RCLONE binary			[ waiting...  ]"
	steps[4]="2. PNGVIEW"
	steps[5]="	2a. Remove PNGVIEW binary			[ waiting...  ]"
	steps[6]="3. IMAGEMAGICK"
	steps[7]="	3a. Remove IMAGEMAGICK binary			[ waiting...  ]"
	steps[8]="4. RCLONE_SCRIPT"
	steps[9]="	4a. Remove RCLONE_SCRIPT files			[ waiting...  ]"
	steps[10]="	4b. Remove RCLONE_SCRIPT menu item		[ waiting...  ]"
	steps[11]="5. RUNCOMMAND"
	steps[12]="	5a. Remove call from RUNCOMMAND-ONSTART		[ waiting...  ]"
	steps[13]="	5b. Remove call from RUNCOMMAND-ONEND		[ waiting...  ]"
	steps[14]="6. Local SAVEFILE directory"
	steps[15]="	6a. Move savefiles to default			[ waiting...  ]"
	steps[16]="	6b. Remove local SAVEFILE directory		[ waiting...  ]"
	steps[17]="7. Remote SAVEFILE directory"
	steps[18]="	7a. Remove remote SAVEFILE directory		[ waiting...  ]"
	steps[19]="8. Configure RETROARCH"
	steps[20]="	8a. Reset local SAVEFILE directories		[ waiting...  ]"
	steps[21]="9 Finalizing"
	steps[22]="	9a. Remove UNINSTALL script			[ waiting...  ]"
}

# Update item of $STEPS() and show updated progress dialog
# INPUT
#	1 > Number of step to update
#	2 > New status for step
#	3 > Percentage to show in progress dialog
#	$steps()
# OUTPUT
#	$steps()
function updateStep ()
{
	local step="$1"
	local newStatus="$2"
	local percent="$3"
	local oldline
	local newline
	
	# translate and colorize $NEWSTATUS
	case "${newStatus}" in
		"waiting")     newStatus="[ ${NORMAL}WAITING...${NORMAL}  ]"  ;;
		"in progress") newStatus="[ ${NORMAL}IN PROGRESS${NORMAL} ]"  ;;
		"done")        newStatus="[ ${GREEN}DONE${NORMAL}        ]"  ;;
		"found")       newStatus="[ ${GREEN}FOUND${NORMAL}       ]"  ;;
		"not found")   newStatus="[ ${RED}NOT FOUND${NORMAL}   ]"  ;;
		"created")     newStatus="[ ${GREEN}CREATED${NORMAL}     ]"  ;;
		"failed")      newStatus="[ ${RED}FAILED${NORMAL}      ]"  ;;
		"skipped")     newStatus="[ ${YELLOW}SKIPPED${NORMAL}     ]"  ;;
		*)             newStatus="[ ${RED}UNDEFINED${NORMAL}   ]"  ;;
	esac
	
	# search $STEP in $STEPS
	for ((i=0; i<${#steps[*]}; i++))
	do
		if [[ ${steps[i]} =~ .*$step.* ]]
		then
			# update $STEP with $NEWSTATUS
			oldline="${steps[i]}"
			oldline="${oldline%%[*}"
			newline="${oldline}${newStatus}"
			steps[i]="${newline}"
			
			break
		fi
	done
	
	# show progress dialog
	dialogShowProgress ${percent}
}


#########################
# UNINSTALLER FUNCTIONS #
#########################

# Uninstaller
function uninstaller ()
{
	initSteps
	dialogShowProgress 0
	
	1RCLONE
	2PNGVIEW
	3IMAGEMAGICK
	4RCLONE_SCRIPT
	5RUNCOMMAND
	6LocalSAVEFILEDirectory
}

function 1RCLONE ()
{
	printf "$(date +%FT%T%:z):\t1RCLONE\tSTART\n" >> "${logfile}"
	
# 1a. Remove RCLONE configuration
	printf "$(date +%FT%T%:z):\t1aRCLONEconfiguration\tSTART\n" >> "${logfile}"
	updateStep "1a" "in progress" 0
	
	if [ -d ~/.config/rclone ]
	then
		{ #try
			sudo rm -r ~/.config/rclone >> "${logfile}" &&
			printf "$(date +%FT%T%:z):\t1aRCLONEconfiguration\tDONE\n" >> "${logfile}" &&
			updateStep "1a" "done" 8
		} || { #catch
			printf "$(date +%FT%T%:z):\t1aRCLONEconfiguration\tERROR\n" >> "${logfile}" &&
			updateStep "1a" "failed" 0 &&
			exit
		}
	else
		printf "$(date +%FT%T%:z):\t1aRCLONEconfiguration\tNOT FOUND\n" >> "${logfile}"
		updateStep "1a" "not found" 8
	fi
	
# 1b. Remove RCLONE binary
	printf "$(date +%FT%T%:z):\t1bRCLONEbinary\tSTART\n" >> "${logfile}"
	updateStep "1b" "in progress" 8
	
	if [ -f /usr/bin/rclone ]
	then
		{ #try
			sudo rm /usr/bin/rclone >> "${logfile}" &&
			printf "$(date +%FT%T%:z):\t1bRCLONEbinary\tDONE\n" >> "${logfile}" &&
			updateStep "1b" "done" 16
		} || { #catch
			printf "$(date +%FT%T%:z):\t1bRCLONEbinary\tERROR\n" >> "${logfile}" &&
			updateStep "1b" "failed" 8 &&
			exit
		}
	else
		printf "$(date +%FT%T%:z):\t1bRCLONEbinary\tNOT FOUND\n" >> "${logfile}"
		updateStep "1b" "not found" 16
	fi
	
	printf "$(date +%FT%T%:z):\t1RCLONE\tEND\n" >> "${logfile}"
}

function 2PNGVIEW ()
{
	printf "$(date +%FT%T%:z):\t2PNGVIEW\tSTART\n" >> "${logfile}"
	
# 2a. Remove PNGVIEW binary
	printf "$(date +%FT%T%:z):\t2aPNGVIEWbinary\tSTART\n" >> "${logfile}"
	updateStep "2a" "in progress" 16
	
	if [ -f /usr/bin/pngview ]
	then
		{ #try
			sudo rm /usr/bin/pngview >> "${logfile}" &&
			sudo rm /usr/lib/libraspidmx.so.1 >> "${logfile}" &&
			printf "$(date +%FT%T%:z):\t2aPNGVIEWbinary\tDONE\n" >> "${logfile}" &&
			updateStep "2a" "done" 24
		} || { # catch
			printf "$(date +%FT%T%:z):\t2aPNGVIEWbinary\tERROR\n" >> "${logfile}" &&
			updateStep "2a" "failed" 16 &&
			exit
		}
	else
		printf "$(date +%FT%T%:z):\t2aPNGVIEWbinary\tNOT FOUND\n" >> "${logfile}" &&
		updateStep "2a" "not found" 24
	fi
	
	printf "$(date +%FT%T%:z):\t2PNGVIEW\tDONE\n" >> "${logfile}"
}

function 3IMAGEMAGICK ()
{
	printf "$(date +%FT%T%:z):\t3IMAGEMAGICK\tSTART\n" >> "${logfile}"
	
# 3a. Remove IMAGEMAGICK binary
	printf "$(date +%FT%T%:z):\t3aIMAGEMAGICKbinary\tSTART\n" >> "${logfile}"
	updateStep "3a" "in progress" 24
	
	if [ -f /usr/bin/convert ]
	then
		{ # try
			sudo apt-get --yes remove imagemagick* >> "${logfile}" &&
			printf "$(date +%FT%T%:z):\t3aIMAGEMAGICKbinary\tDONE\n" >> "${logfile}" &&
			updateStep "3a" "done" 32
		} || { # catch
			printf "$(date +%FT%T%:z):\t3aIMAGEMAGICKbinary\tERROR\n" >> "${logfile}" &&
			updateStep "3a" "failed" 24 &&
			exit
		}
	else
		printf "$(date +%FT%T%:z):\t3aPIMAGEMAGICKbinary\tNOT FOUND\n" >> "${logfile}"
		updateStep "3a" "not found" 32
	fi
	
	printf "$(date +%FT%T%:z):\t3IMAGEMAGICK\tDONE\n" >> "${logfile}"
}

function 4RCLONE_SCRIPT ()
{
	printf "$(date +%FT%T%:z):\t4RCLONE_SCRIPT\tSTART\n" >> "${logfile}"

# 4a. Remove RCLONE_SCRIPT
	printf "$(date +%FT%T%:z):\t4aRCLONE_SCRIPTfiles\tSTART\n" >> "${logfile}"
	updateStep "4a" "in progress" 32
	
	if [ -f ~/scripts/rclone_script/rclone_script.sh ]
	then
		{ # try
			sudo rm -f ~/scripts/rclone_script/rclone_script-install.* >> "${logfile}" &&
			sudo rm -f ~/scripts/rclone_script/rclone_script.* >> "${logfile}" &&
			printf "$(date +%FT%T%:z):\t4aRCLONE_SCRIPTfiles\tDONE\n" >> "${logfile}" &&
			updateStep "4a" "done" 40
		} || { # catch
			printf "$(date +%FT%T%:z):\t4aRCLONE_SCRIPTfiles\tERROR\n" >> "${logfile}" &&
			updateStep "4a" "failed" 32 &&
			exit
		}
	else
		printf "$(date +%FT%T%:z):\t4aRCLONE_SCRIPTfiles\tNOT FOUND\n" >> "${logfile}"
		updateStep "4a" "not found" 40
	fi
	
# 4b. Remove RCLONE_SCRIPT menu item
	printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItem\tSTART\n" >> "${logfile}"
	updateStep "4b" "in progress" 40
	
	local found=0
		
	if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./rclone_script-menu.sh'])" ~/.emulationstation/gamelists/retropie/gamelist.xml) -ne 0 ]]
	then
		found=$(($found + 1))
		
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItem\tFOUND\n" >> "${logfile}"
		
		xmlstarlet ed \
			--inplace \
			--delete "//game[path='./rclone_script-menu.sh']" \
			~/.emulationstation/gamelists/retropie/gamelist.xml
			
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItem\tREMOVED\n" >> "${logfile}"
	else
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItem\tNOT FOUND\n" >> "${logfile}"
	fi
	
	if [ -f ~/RetroPie/retropiemenu/rclone_script-menu.sh ]
	then
		found=$(($found + 1))
		
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItemScript\tFOUND\n" >> "${logfile}"
		
		sudo rm ~/RetroPie/retropiemenu/rclone_script-menu.sh >> "${logfile}"
		
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItemScript\tREMOVED\n" >> "${logfile}"
	else
		printf "$(date +%FT%T%:z):\t4bRCLONE_SCRIPTMenuItemScript\tNOT FOUND\n" >> "${logfile}"
	fi
	
	case $found in
		0) updateStep "4b" "not found" 48  ;;
		1) updateStep "4b" "done" 48  ;;
		2) updateStep "4b" "done" 48  ;;
	esac
	
	printf "$(date +%FT%T%:z):\t4RCLONE_SCRIPT\tDONE\n" >> "${logfile}"
}

function 5RUNCOMMAND ()
{
	printf "$(date +%FT%T%:z):\t5RUNCOMMAND\tSTART\n" >> "${logfile}"
	
# 5a. Remove call from RUNCOMMAND-ONSTART
	printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONSTART\tSTART\n" >> "${logfile}"
	updateStep "5a" "in progress" 48
	
	if [[ $(grep -c "~/scripts/rclone_script/rclone_script.sh" /opt/retropie/configs/all/runcommand-onstart.sh) -gt 0 ]]
	then
	{ #try
		sed -i "/~\/scripts\/rclone_script\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onstart.sh &&
		printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONSTART\tDONE\n" >> "${logfile}" &&
		updateStep "5a" "done" 56
	} || { # catch
		printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONSTART\tERROR\n" >> "${logfile}" &&
		updateStep "5a" "failed" 48
	}
	else
		printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONSTART\tNOT FOUND\n" >> "${logfile}"
		updateStep "5a" "not found" 56
	fi
	
# 5b. Remove call from RUNCOMMAND-ONEND
	printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONEND\tSTART\n" >> "${logfile}"
	updateStep "5b" "in progress" 56
	
	if [[ $(grep -c "~/scripts/rclone_script/rclone_script.sh" /opt/retropie/configs/all/runcommand-onend.sh) -gt 0 ]]
	then
		{ #try
			sed -i "/~\/scripts\/rclone_script\/rclone_script.sh /d" /opt/retropie/configs/all/runcommand-onend.sh &&
			printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONEND\tDONE\n" >> "${logfile}" &&
			updateStep "5b" "done" 64
		} || { # catch
			printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONEND\tERROR\n" >> "${logfile}" &&
			updateStep "5b" "failed" 56
		}
	else
		printf "$(date +%FT%T%:z):\t5RUNCOMMAND-ONEND\tNOT FOUND\n" >> "${logfile}"
		updateStep "5b" "not found" 64
	fi
	
	printf "$(date +%FT%T%:z):\t5RUNCOMMAND\tDONE\n" >> "${logfile}"
}

function 6LocalSAVEFILEDirectory ()
{
	printf "$(date +%FT%T%:z):\t6LocalSAVEFILEDirectory\tSTART\n" >> "${logfile}"
	
# 6a. Move savefiles to default
	printf "$(date +%FT%T%:z):\t6a moveFilesToDefault\tSTART\n" >> "${logfile}"
	updateStep "6a" "in progress" 64
	
#counter=1
#while [ $counter -le 10000 ]
#do
#	echo "." > ~/RetroPie/saves/gba/datei_${counter}.srm
#	((counter++))
#done

	# start copy task in background, pipe numbered output into COPY.TXT and to LOGFILE
	$(cp -v -r ~/RetroPie/saves/* ~/RetroPie/roms | cat -n | tee copy.txt | cat >> "${logfile}") &
	
	# show content of COPY.TXT
	dialog \
		--backtitle "${backtitle}" \
		--title "Move savefiles to default" \
		--ascii-lines \
		--colors \
		--no-collapse \
		--cr-wrap \
		--tailbox copy.txt 40 120
		
	wait
	
	rm copy.txt
	
#rm ~/RetroPie/saves/gba/datei*
#rm ~/RetroPie/roms/gba/datei*

	updateStep "6a" "done" 72
	
# 6b. Remove local SAVEFILE directory
}


########
# MAIN #
########

uninstaller