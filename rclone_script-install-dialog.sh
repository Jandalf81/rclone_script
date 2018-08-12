#!/bin/bash


# define colors for output
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


# global variables
url="https://raw.githubusercontent.com/Jandalf81/rclone_script"
branch="beta"
remotebasedir = ""

backtitle="RCLONE_SCRIPT installer"


# Welcome dialog
dialog \
	--backtitle "${backtitle}" \
	--title "Welcome" \
	--ascii-lines \
	--colors \
	--no-collapse \
	--cr-wrap \
	--yesno \
		"\nThis script will configure RetroPie so that your savefiles and statefiles are synchronized with a remote destination. Several packages and scripts will be installed, see\n\n	https://github.com/Jandalf81/rclone_script/blob/master/ReadMe.md\n\nfor a rundown.\n\nAre you sure you wish to continue?" \
	28 110 2>&1 > /dev/tty \
    || exit
	

# Warn the user if they are using the BETA branch
function dialogBetaWarning ()
{
	dialog \
		--backtitle "${backtitle}" \
		--title "Beta Warning" \
		--ascii-lines \
		--colors \
		--no-collapse \
		--cr-wrap \
		--yesno \
			"\n${RED}${UNDERLINE}WARNING!${NORMAL}\n\nYou are about to install a beta version!\nAre you ${RED}REALLY${NORMAL} sure you want to continue?" \
	10 50 2>&1 > /dev/tty \
    || exit
}


# Installer
function installer ()
{
	local retval
	
	initSteps
	dialogShowProgress 0
	
# 1a. Testing for RCLONE binary
	updateStep "1a" "in progress" 0
	
	1aTestRCLONE
	if [[ $? -eq 0 ]]
	then
		updateStep "1a" "found" 5
		updateStep "1b" "skipped" 10
	else
		updateStep "1a" "not found" 5
		
# 1b. Getting RCLONE binary
		updateStep "1b" "in progress" 5
		
		1bInstallRCLONE
		if [[ $? -eq 0 ]]
		then
			updateStep "1b" "done" 10
		else
			updateStep "1b" "failed" 5
		fi
	fi
	
# 1c. Testing RCLONE configuration
	updateStep "1c" "in progress" 10
	
	1cTestRCLONEremote
	if [[ $? -eq 0 ]]
	then
		updateStep "1c" "found" 15
		updateStep "1d" "skipped" 20
	else
		updateStep "1c" "not found" 15
		
# 1d. Create RCLONE remote
		updateStep "1d" "in progress" 15
		1dCreateRCLONEremote
		updateStep "1d" "done" 20
	fi
	
# 2a. Testing for PNGVIEW binary
	updateStep "2a" "in progress" 20
	
	2aTestPNGVIEW
	if [[ $? -eq 0 ]]
	then
		updateStep "2a" "found" 25
		updateStep "2b" "skipped" 30
		updateStep "2c" "skipped" 35
	else
		updateStep "2a" "not found" 25

# 2b. Getting PNGVIEW source
		updateStep "2b" "in progress" 25
		
		2bGetPNGVIEWsource
		if [[ $? -eq 0 ]]
		then
			updateStep "2b" "done" 30
			
# 2c. Compiling PNGVIEW
			updateStep "2c" "in progress" 30
			
			2cCompilePNGVIEW
			if [[ $? -eq 0 ]]
			then
				updateStep "2c" "done" 35
			else
				updateStep "2c" "failed" 30
				exit
			fi
		else
			updateStep "2b" "failed" 25
			exit
		fi
	fi
}


# Initialize array $STEPS()
# OUTPUT
#	$steps()
function initSteps ()
{
	steps[1]="1. RCLONE"
	steps[2]="	1a. Testing for RCLONE binary			[ waiting...  ]"
	steps[3]="	1b. Getting RCLONE binary			[ waiting...  ]"
	steps[4]="	1c. Testing RCLONE remote			[ waiting...  ]"
	steps[5]="	1d. Create RCLONE remote			[ waiting...  ]"
	steps[6]="2. PNGVIEW"
	steps[7]="	2a. Testing for PNGVIEW binary			[ waiting...  ]"
	steps[8]="	2b. Getting PNGVIEW source			[ waiting...  ]"
	steps[9]="	2c. Compiling PNGVIEW				[ waiting...  ]"
	steps[10]="3. IMAGEMAGICK"
	steps[11]="	3a. Testing for IMAGEMAGICK			[ waiting...  ]"
	steps[12]="	3b. Getting IMAGEMAGICK				[ waiting...  ]"
	steps[13]="4. RCLONE_SCRIPT"
	steps[14]="	4a. Getting RCLONE_SCRIPT			[ waiting...  ]"
	steps[15]="	4b. Creating RCLONE_SCRIPT menu item		[ waiting...  ]"
	steps[16]="	4c. Configure RCLONE_SCRIPT			[ waiting...  ]"
	steps[17]="5. RUNCOMMAND"
	steps[18]="	5a. RUNCOMMAND-ONSTART				[ waiting...  ]"
	steps[19]="	5b. RUNCOMMAND-ONEND				[ waiting...  ]"
	steps[20]="6. Local SAVEFILE directory"
	steps[21]="	6a. Test for local SAVEFILE directory		[ waiting...  ]"
	steps[22]="	6b. Create local SAVEFILE directory		[ waiting...  ]"
	steps[23]="7. Remote SAVEFILE directory"
	steps[24]="	7a. Test for local SAVEFILE directory		[ waiting...  ]"
	steps[25]="	7b. Create local SAVEFILE directory		[ waiting...  ]"
	steps[26]="8. Configure RETROARCH"
	steps[27]="	8a. Setting local SAVEFILE directory		[ waiting...  ]"
	steps[28]="9. Finalizing"
	steps[29]="	9a. Saving configuration			[ waiting...  ]"
}

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
		--title "Installer" \
		--gauge "${progress}" 36 90 0 \
		2>&1 > /dev/tty
		
	sleep 1
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
		"failed")      newStatus="[ ${RED}FAILED${NORMAL}      ]"  ;;
		"skipped")     newStatus="[ ${YELLOW}${BOLD}SKIPPED${NORMAL}     ]"  ;;
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

# Checks if RCLONE is installed
# RETURN
# 	0 > RCLONE is installed
# 	1 > RCLONE is not installed
function 1aTestRCLONE ()
{
	printf "$(date +%FT%T%:z):\t1aTestRCLONE\tSTART\n" >> ./rclone_script-install.log
	
	if [ -f /usr/bin/rclone ]
	then
		printf "$(date +%FT%T%:z):\t1aTestRCLONE\tFOUND\n" >> ./rclone_script-install.log
		return 0
	else
		printf "$(date +%FT%T%:z):\t1aTestRCLONE\tNOT FOUND\n" >> ./rclone_script-install.log
		return 1
	fi
}

# Installs RCLONE
# RETURN
#	0 > RCLONE has been installed
#	1 > Error while installing RCLONE
function 1bInstallRCLONE ()
{
	printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tSTART\n" >> ./rclone_script-install.log
	
	# TODO get RCLONE for 64bit
	{ # try
		# get binary
		wget -P ~ https://downloads.rclone.org/rclone-current-linux-arm.zip --append-output=./rclone_script-install.log &&
		unzip ~/rclone-current-linux-arm.zip -d ~ >> ./rclone_script-install.log &&
		
		cd ~/rclone-v* &&

		# move binary
		sudo mv rclone /usr/bin >> ./rclone_script-install.log &&
		sudo chown root:root /usr/bin/rclone >> ./rclone_script-install.log &&
		sudo chmod 755 /usr/bin/rclone >> ./rclone_script-install.log &&
		
		cd ~ &&
		
		# remove temp files
		rm ~/rclone-current-linux-arm.zip >> ./rclone_script-install.log &&
		rm -r ~/rclone-v* >> ./rclone_script-install.log &&
		
		printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tDONE\n" >> ./rclone_script-install.log
		
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tERROR\n" >> ./rclone_script-install.log
		
		# remove temp files
		rm ~/rclone-current-linux-arm.zip >> ./rclone_script-install.log &&
		rm -r ~/rclone-v* >> ./rclone_script-install.log &&
		
		return 1
	}
}

# Checks if there's a RCLONE remote called RETROPIE
# RETURN
#	0 > remote RETROPIE has been found
#	1 > no remote RETROPIE found
function 1cTestRCLONEremote ()
{
	printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tSTART\n" >> ./rclone_script-install.log
	
	local remotes=$(rclone listremotes)
	
	local retval=$(grep -i "^retropie:" <<< ${remotes})
	
	if [ "${retval}" == "retropie:" ]
	then
		printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tFOUND\n" >> ./rclone_script-install.log
		return 0
	else
		printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tNOT FOUND\n" >> ./rclone_script-install.log
		return 1
	fi
}

# Tells the user to create a new RCLONE remote called RETROPIE
# RETURN
#	0 > remote RETROPIE has been created (no other OUTPUT possible)
function 1dCreateRCLONEremote ()
{
	printf "$(date +%FT%T%:z):\t1dCreateRCLONEremote\tSTART\n" >> ./rclone_script-install.log
	
	dialog \
		--stdout \
		--colors \
		--ascii-lines \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Installer" \
		--msgbox "\nPlease create a new remote within RCLONE now. Name that remote ${RED}retropie${NORMAL}. Please consult the RCLONE documentation for further information:\n	https://www.rclone.org\n\nOpening RCLONE CONFIG now..." 20 50 \
		2>&1 > /dev/tty
			
	rclone config
	
	1cTestRCLONEremote
	if [[ $? -eq 1 ]]
	then
		dialog \
			--stdout \
			--colors \
			--ascii-lines \
			--no-collapse \
			--cr-wrap \
			--backtitle "${backtitle}" \
			--title "Installer" \
			--msgbox "\nNo remote ${RED}retropie${NORMAL} found.\nPlease try again." 20 50 \
		2>&1 > /dev/tty
			
		1dCreateRCLONEremote
	else
		printf "$(date +%FT%T%:z):\t1dCreateRCLONEremote\tFOUND\n" >> ./rclone_script-install.log
		return 0
	fi	
}

# Checks if PNGVIEW is installed
# RETURN
#	0 > PNGVIEW is installed
#	1 > PNGVIEW is not installed
function 2aTestPNGVIEW ()
{
	printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tSTART\n" >> ./rclone_script-install.log
	
	if [ -f /usr/bin/pngview ]
	then
		printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tFOUND\n" >> ./rclone_script-install.log
		return 0
	else
		printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tNOT FOUND\n" >> ./rclone_script-install.log
		return 1
	fi
}

# Gets PNGVIEW source
# RETURN
#	0 > source downloaded and unzipped
#	1 > no source downloaded, removed temp files
function 2bGetPNGVIEWsource ()
{
	printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tSTART\n" >> ./rclone_script-install.log
	
	{ #try
		wget -P ~ https://github.com/AndrewFromMelbourne/raspidmx/archive/master.zip --append-output=./rclone_script-install.log &&
		unzip ~/master.zip -d ~ >> ./rclone_script-install.log &&
		
		printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tDONE\n" >> ./rclone_script-install.log &&
	
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tERROR\n" >> ./rclone_script-install.log &&
		
		rm ~/master.zip >> ./rclone_script-install.log &&
		sudo rm -r ~/raspidmx-master >> ./rclone_script-install.log &&
	
		return 1
	}
}

# Compiles PNGVIEW source, moves binaries
# RETURN
#	0 > compiled without errors, moved binaries, removed temp files
#	1 > errors while compiling, removed temp files
function 2cCompilePNGVIEW ()
{
	printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tSTART\n" >> ./rclone_script-install.log
	
	{ #try
		# compile
		# cd ~/raspidmx-master &&
		make --directory=~/raspidmx-master >> ./rclone_script-install.log &&
	
		# move binary files
		sudo mv ~/raspidmx-master/pngview/pngview /usr/bin >> ./rclone_script-install.log &&
		sudo mv ~/raspidmx-master/lib/libraspidmx.so.1 /usr/lib >> ./rclone_script-install.log &&
		sudo chown root:root /usr/bin/pngview >> ./rclone_script-install.log &&
		sudo chmod 755 /usr/bin/pngview >> ./rclone_script-install.log &&
		
		# remove temp files
		rm ~/master.zip >> ./rclone_script-install.log &&
		sudo rm -r ~/raspidmx-master >> ./rclone_script-install.log &&
		
		printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tDONE\n" >> ./rclone_script-install.log &&
	
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tERROR\n" >> ./rclone_script-install.log &&
	
		# remove temp files
		rm ~/master.zip >> ./rclone_script-install.log &&
		sudo rm -r ~/raspidmx-master >> ./rclone_script-install.log &&
		
		return 1
	}
}


# main
if [ "${branch}" == "beta" ]
then
	dialogBetaWarning
fi

installer