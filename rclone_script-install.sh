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


# global variables
url="https://raw.githubusercontent.com/Jandalf81/rclone_script"
branch="beta"

# configuration variables
remotebasedir=""
shownotifications=""

backtitle="RCLONE_SCRIPT installer"
logfile=~/scripts/rclone_script/rclone_script-install.log


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
		"\nThis script will configure RetroPie so that your savefiles and statefiles will be ${YELLOW}synchronized with a remote destination${NORMAL}. Several packages and scripts will be installed, see\n\n	https://github.com/Jandalf81/rclone_script/blob/master/ReadMe.md\n\nfor a rundown. In short, any time you ${GREEN}start${NORMAL} or ${RED}stop${NORMAL} a ROM the savefiles and savestates for that ROM will be ${GREEN}down-${NORMAL} and ${RED}uploaded${NORMAL} ${GREEN}from${NORMAL} and ${RED}to${NORMAL} a remote destination. To do so, RetroPie will be configured to put all savefiles and statefiles in distinct directories, seperated from the ROMS directories. If you already have some savefiles there, you will need to ${YELLOW}move them manually${NORMAL} after installation.\n\nAre you sure you wish to continue?" \
	20 90 2>&1 > /dev/tty \
    || exit

	
####################
# DIALOG FUNCTIONS #
####################

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

# Show summary dialog
function dialogShowSummary ()
{
	# list all remotes and their type
	remotes=$(rclone listremotes -l)
	
	# get line with RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})

	remoteType="${retval#*:}"
	remoteType=$(echo ${remoteType} | xargs)

	dialog \
		--backtitle "${backtitle}" \
		--title "Summary" \
		--ascii-lines \
		--colors \
		--no-collapse \
		--cr-wrap \
		--yesno \
			"\n${GREEN}All done!${NORMAL}\n\nFrom now on, all your saves and states will be synchronized each time you start or stop a ROM.\n\nAll system will put their saves and states in\n	Local: \"${YELLOW}~/RetroPie/saves/<SYSTEM>${NORMAL}\"\n	Remote: \"${YELLOW}retropie:${remotebasedir}/<SYSTEM>${NORMAL}\" (${remoteType})\nIf you already have some saves in the ROM directories, you need to move them there manually now! Afterward, you should ${red}reboot${NORMAL} your RetroPie. Then, you should start a full sync via\n	${YELLOW}RetroPie / RCLONE_SCRIPT menu / 1 Full sync${NORMAL}\n\nStart\n	${YELLOW}RetroPie / RCLONE_SCRIPT menu / 9 uninstall${NORMAL}\nto revert all changes and remove this script.\n\nTo finish the installer you should reboot your RetroPie now.\n\n${RED}Reboot RetroPie now?${NORMAL}" 25 90
	
	case $? in
		0) sudo shutdown -r now  ;;
	esac
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
	steps[2]="	1a. Test for RCLONE binary			[ waiting...  ]"
	steps[3]="	1b. Get RCLONE binary				[ waiting...  ]"
	steps[4]="	1c. Test RCLONE remote				[ waiting...  ]"
	steps[5]="	1d. Create RCLONE remote			[ waiting...  ]"
	steps[6]="2. PNGVIEW"
	steps[7]="	2a. Test for PNGVIEW binary			[ waiting...  ]"
	steps[8]="	2b. Get PNGVIEW source				[ waiting...  ]"
	steps[9]="	2c. Compile PNGVIEW				[ waiting...  ]"
	steps[10]="3. IMAGEMAGICK"
	steps[11]="	3a. Test for IMAGEMAGICK			[ waiting...  ]"
	steps[12]="	3b. Get IMAGEMAGICK				[ waiting...  ]"
	steps[13]="4. RCLONE_SCRIPT"
	steps[14]="	4a. Get RCLONE_SCRIPT files			[ waiting...  ]"
	steps[15]="	4b. Create RCLONE_SCRIPT menu item		[ waiting...  ]"
	steps[16]="	4c. Configure RCLONE_SCRIPT			[ waiting...  ]"
	steps[17]="5. RUNCOMMAND"
	steps[18]="	5a. Add call to RUNCOMMAND-ONSTART		[ waiting...  ]"
	steps[19]="	5b. Add call to RUNCOMMAND-ONEND		[ waiting...  ]"
	steps[20]="6. Local SAVEFILE directory"
	steps[21]="	6a. Check local base directory			[ waiting...  ]"
	steps[22]="	6b. Check local <SYSTEM> directories		[ waiting...  ]"
	steps[23]="7. Remote SAVEFILE directory"
	steps[24]="	7a. Check remote base directory			[ waiting...  ]"
	steps[25]="	7b. Check remote <SYSTEM> directories		[ waiting...  ]"
	steps[26]="8. Configure RETROARCH"
	steps[27]="	8a. Set local SAVEFILE directories		[ waiting...  ]"
	steps[28]="9. Finalizing"
	steps[29]="	9a. Save configuration				[ waiting...  ]"
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


#######################
# INSTALLER FUNCTIONS #
#######################


# Installer
function installer ()
{
	initSteps
	dialogShowProgress 0
	
	1RCLONE
	2PNGVIEW
	3IMAGEMAGICK
	4RCLONE_SCRIPT
	5RUNCOMMAND
	6LocalSAVEFILEDirectory
	7RemoteSAVEFILEDirectory
	8ConfigureRETROARCH
	9Finalize
	
	dialogShowSummary
}

function 1RCLONE () 
{
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
			exit
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
}

# Checks if RCLONE is installed
# RETURN
# 	0 > RCLONE is installed
# 	1 > RCLONE is not installed
function 1aTestRCLONE ()
{
	printf "$(date +%FT%T%:z):\t1aTestRCLONE\tSTART\n" >> "${logfile}"
	
	if [ -f /usr/bin/rclone ]
	then
		printf "$(date +%FT%T%:z):\t1aTestRCLONE\tFOUND\n" >> "${logfile}"
		return 0
	else
		printf "$(date +%FT%T%:z):\t1aTestRCLONE\tNOT FOUND\n" >> "${logfile}"
		return 1
	fi
}

# Installs RCLONE by download
# RETURN
#	0 > RCLONE has been installed
#	1 > Error while installing RCLONE
function 1bInstallRCLONE ()
{
	printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tSTART\n" >> "${logfile}"
	
	# TODO get RCLONE for 64bit
	{ # try
		# get binary
		wget -P ~ https://downloads.rclone.org/rclone-current-linux-arm.zip --append-output="${logfile}" &&
		unzip ~/rclone-current-linux-arm.zip -d ~ >> "${logfile}" &&
		
		cd ~/rclone-v* &&

		# move binary
		sudo mv rclone /usr/bin >> "${logfile}" &&
		sudo chown root:root /usr/bin/rclone >> "${logfile}" &&
		sudo chmod 755 /usr/bin/rclone >> "${logfile}" &&
		
		cd ~ &&
		
		# remove temp files
		rm ~/rclone-current-linux-arm.zip >> "${logfile}" &&
		rm -r ~/rclone-v* >> "${logfile}" &&
		
		printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tDONE\n" >> "${logfile}" &&
		
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t1bInstallRCLONE\tERROR\n" >> "${logfile}" &&
		
		# remove temp files
		rm ~/rclone-current-linux-arm.zip >> "${logfile}" &&
		rm -r ~/rclone-v* >> "${logfile}" &&
		
		return 1
	}
}

# Checks if there's a RCLONE remote called RETROPIE
# RETURN
#	0 > remote RETROPIE has been found
#	1 > no remote RETROPIE found
function 1cTestRCLONEremote ()
{
	printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tSTART\n" >> "${logfile}"
	
	local remotes=$(rclone listremotes)
	
	local retval=$(grep -i "^retropie:" <<< ${remotes})
	
	if [ "${retval}" == "retropie:" ]
	then
		printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tFOUND\n" >> "${logfile}"
		return 0
	else
		printf "$(date +%FT%T%:z):\t1cTestRCLONEremote\tNOT FOUND\n" >> "${logfile}"
		return 1
	fi
}

# Tells the user to create a new RCLONE remote called RETROPIE
# RETURN
#	0 > remote RETROPIE has been created (no other OUTPUT possible)
function 1dCreateRCLONEremote ()
{
	printf "$(date +%FT%T%:z):\t1dCreateRCLONEremote\tSTART\n" >> "${logfile}"
	
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
		printf "$(date +%FT%T%:z):\t1dCreateRCLONEremote\tFOUND\n" >> "${logfile}"
		return 0
	fi	
}

function 2PNGVIEW ()
{
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

# Checks if PNGVIEW is installed
# RETURN
#	0 > PNGVIEW is installed
#	1 > PNGVIEW is not installed
function 2aTestPNGVIEW ()
{
	printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tSTART\n" >> "${logfile}"
	
	if [ -f /usr/bin/pngview ]
	then
		printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tFOUND\n" >> "${logfile}"
		return 0
	else
		printf "$(date +%FT%T%:z):\t2aTestPNGVIEW\tNOT FOUND\n" >> "${logfile}"
		return 1
	fi
}

# Gets PNGVIEW source
# RETURN
#	0 > source downloaded and unzipped
#	1 > no source downloaded, removed temp files
function 2bGetPNGVIEWsource ()
{
	printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tSTART\n" >> "${logfile}"
	
	{ #try
		wget -P ~ https://github.com/AndrewFromMelbourne/raspidmx/archive/master.zip --append-output="${logfile}" &&
		unzip ~/master.zip -d ~ >> "${logfile}" &&
		
		printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tDONE\n" >> "${logfile}" &&
	
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t2bGetPNGVIEWsource\tERROR\n" >> "${logfile}" &&
		
		rm ~/master.zip >> "${logfile}" &&
		sudo rm -r ~/raspidmx-master >> "${logfile}" &&
	
		return 1
	}
}

# Compiles PNGVIEW source, moves binaries
# RETURN
#	0 > compiled without errors, moved binaries, removed temp files
#	1 > errors while compiling, removed temp files
function 2cCompilePNGVIEW ()
{
	printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tSTART\n" >> "${logfile}"
	
	{ #try
		# compile
		# cd ~/raspidmx-master &&
		make --directory=~/raspidmx-master >> "${logfile}" &&
	
		# move binary files
		sudo mv ~/raspidmx-master/pngview/pngview /usr/bin >> "${logfile}" &&
		sudo mv ~/raspidmx-master/lib/libraspidmx.so.1 /usr/lib >> "${logfile}" &&
		sudo chown root:root /usr/bin/pngview >> "${logfile}" &&
		sudo chmod 755 /usr/bin/pngview >> "${logfile}" &&
		
		# remove temp files
		rm ~/master.zip >> "${logfile}" &&
		sudo rm -r ~/raspidmx-master >> "${logfile}" &&
		
		printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tDONE\n" >> "${logfile}" &&
	
		return 0
	} || { #catch
		printf "$(date +%FT%T%:z):\t2cCompilePNGVIEW\tERROR\n" >> "${logfile}" &&
	
		# remove temp files
		rm ~/master.zip >> "${logfile}" &&
		sudo rm -r ~/raspidmx-master >> "${logfile}" &&
		
		return 1
	}
}

function 3IMAGEMAGICK ()
{
# 3a. Testing for IMAGEMAGICK
	updateStep "3a" "in progress" 35
	
	3aTestIMAGEMAGICK
	if [[ $? -eq 0 ]]
	then
		updateStep "3a" "found" 40
		updateStep "3b" "skipped" 45
	else
		updateStep "3a" "not found" 40
		
# 3b. Getting IMAGEMAGICK
		updateStep "3b" "in progress" 40
		3bInstallIMAGEMAGICK
		if [[ $? -eq 0 ]]
		then
			updateStep "3b" "done" 45
		else
			updateStep "3b" "failed" 40
		fi
	fi
}

# Checks is IMAGEMAGICK is installed
# RETURN
#	0 > IMAGEMAGICK is installed
#	1 > IMAGEMAGICK is not installed
function 3aTestIMAGEMAGICK ()
{
	printf "$(date +%FT%T%:z):\t3aTestIMAGEMAGICK\tSTART\n" >> "${logfile}"
	
	if [ -f /usr/bin/convert ]
	then
		printf "$(date +%FT%T%:z):\t3aTestIMAGEMAGICK\tFOUND\n" >> "${logfile}"
		return 0
	else
		printf "$(date +%FT%T%:z):\t3aTestIMAGEMAGICK\tNOT FOUND\n" >> "${logfile}"
		return 1
	fi
}

# Installs IMAGEMAGICK via APT-GET
# RETURN
#	0 > IMAGEMAGICK has been installed
#	1 > Error while installing IMAGEMAGICK
function 3bInstallIMAGEMAGICK ()
{
	printf "$(date +%FT%T%:z):\t3bInstallIMAGEMAGICK\tSTART\n" >> "${logfile}"
	
	sudo apt-get update >> "${logfile}"
	sudo apt-get --yes install imagemagick >> "${logfile}"
	
	if [[ $? -eq 0 ]]
	then
		printf "$(date +%FT%T%:z):\t3bInstallIMAGEMAGICK\tDONE\n" >> "${logfile}"
		return 0
	else
		printf "$(date +%FT%T%:z):\t3bInstallIMAGEMAGICK\tERROR\n" >> "${logfile}"
		return 1
	fi
}

function 4RCLONE_SCRIPT ()
{
# 4a. Getting RCLONE_SCRIPT
	updateStep "4a" "in progress" 45
	
	4aGetRCLONE_SCRIPT
	if [[ $? -eq 0 ]]
	then
		updateStep "4a" "done" 50
	else
		updateStep "4a" "failed" 45
		exit
	fi

# 4b. Creating RCLONE_SCRIPT menu item
	updateStep "4b" "in progress" 50
	
	4bCreateRCLONE_SCRIPTMenuItem
	if [[ $? -eq 0 ]]
	then
		updateStep "4b" "done" 55
	else
		updateStep "4b" "failed" 50
		exit
	fi

# 4c. Configure RCLONE_SCRIPT
	updateStep "4c" "in progress" 55
	
	4cConfigureRCLONE_SCRIPT
	
	updateStep "4c" "done" 60
}

# Gets RCLONE_SCRIPT
# RETURN
#	0 > downloaded successfully
#	1 > errors while downloading
function 4aGetRCLONE_SCRIPT ()
{
	printf "$(date +%FT%T%:z):\t4aGetRCLONE_SCRIPT\tSTART\n" >> "${logfile}"
	
	# create directory if necessary
	if [ ! -d ~/scripts/rclone_script ]
	then
		mkdir ~/scripts/rclone_script >> "${logfile}"
	fi
	
	{ #try
		# get script files
		wget -N -P ~/scripts/rclone_script ${url}/${branch}/rclone_script.sh --append-output="${logfile}" &&
		wget -N -P ~/scripts/rclone_script ${url}/${branch}/rclone_script-menu.sh --append-output="${logfile}" &&
		wget -N -P ~/scripts/rclone_script ${url}/${branch}/rclone_script-uninstall.sh --append-output="${logfile}" &&
		
		# change mod
		chmod +x ~/scripts/rclone_script/rclone_script.sh >> "${logfile}" &&
		chmod +x ~/scripts/rclone_script/rclone_script-menu.sh >> "${logfile}" &&
		chmod +x ~/scripts/rclone_script/rclone_script-uninstall.sh >> "${logfile}" &&
		
		printf "$(date +%FT%T%:z):\t4aGetRCLONE_SCRIPT\tDONE\n" >> "${logfile}" &&
		
		return 0
	} || { # catch
		printf "$(date +%FT%T%:z):\t4aGetRCLONE_SCRIPT\tERROR\n" >> "${logfile}" &&
		
		return 1
	}
}

# Creates a menu item for RCLONE_SCRIPT in RetroPie menu
# RETURN
#	0 > menu item has been found or created
#	1 > error while creating menu item
function 4bCreateRCLONE_SCRIPTMenuItem ()
{
	printf "$(date +%FT%T%:z):\t4bCreateRCLONE_SCRIPTMenuItem\tSTART\n" >> "${logfile}"
	
	# create redirect script
	printf "#!/bin/bash\n~/scripts/rclone_script/rclone_script-menu.sh" > ~/RetroPie/retropiemenu/rclone_script-redirect.sh
	chmod +x ~/RetroPie/retropiemenu/rclone_script-redirect.sh
	
	# check if menu item exists
	if [[ $(xmlstarlet sel -t -v "count(/gameList/game[path='./rclone_script-redirect.sh'])" ~/.emulationstation/gamelists/retropie/gamelist.xml) -eq 0 ]]
	then
		printf "$(date +%FT%T%:z):\t4bCreateRCLONE_SCRIPTMenuItem\tNOT FOUND\n" >> "${logfile}"
			
		xmlstarlet ed \
			--inplace \
			--subnode "/gameList" --type elem -n game -v ""  \
			--subnode "/gameList/game[last()]" --type elem -n path -v "./rclone_script-redirect.sh" \
			--subnode "/gameList/game[last()]" --type elem -n name -v "RCLONE_SCRIPT menu" \
			--subnode "/gameList/game[last()]" --type elem -n desc -v "Launches a menu allowing you to start a full sync, configure RCLONE_SCRIPT or even uninstall it" \
			~/.emulationstation/gamelists/retropie/gamelist.xml
		
		if [[ $? -eq 0 ]]
		then
			printf "$(date +%FT%T%:z):\t4bCreateRCLONE_SCRIPTMenuItem\tCREATED\n" >> "${logfile}"
			return 0
		else
			printf "$(date +%FT%T%:z):\t4bCreateRCLONE_SCRIPTMenuItem\tERROR\n" >> "${logfile}"
			return 1
		fi
	else
		printf "$(date +%FT%T%:z):\t4bCreateRCLONE_SCRIPTMenuItem\tFOUND\n" >> "${logfile}"
		return 0
	fi
}

# Gets user input to configure RCLONE_SCRIPT
function 4cConfigureRCLONE_SCRIPT ()
{
	printf "$(date +%FT%T%:z):\t4cConfigureRCLONE_SCRIPT\tSTART\n" >> "${logfile}"
	
	remotebasedir=$(dialog \
		--stdout \
		--colors \
		--ascii-lines \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Remote base directory" \
		--inputbox "\nPlease name the directory which will be used as your ${YELLOW}remote base directory${NORMAL}. If necessary, this directory will be created.\n\nExamples:\n* RetroArch\n* mySaves/RetroArch\n\n" 18 40 "RetroArch" 
		)
		
	dialog \
		--stdout \
		--colors \
		--ascii-lines \
		--no-collapse \
		--cr-wrap \
		--backtitle "${backtitle}" \
		--title "Notifications" \
		--yesno "\nDo you wish to see ${YELLOW}notifications${NORMAL} whenever RCLONE_SCRIPT is synchronizing?" 18 40
		
	case $? in
		0) shownotifications="TRUE"  ;;
		1) shownotifications="FALSE"  ;;
		*) shownotifications="FALSE"  ;;
	esac
	
	printf "$(date +%FT%T%:z):\t4cConfigureRCLONE_SCRIPT\tDONE\n" >> "${logfile}"
}

function 5RUNCOMMAND ()
{
# 5a. RUNCOMMAND-ONSTART
	updateStep "5a" "in progress" 60
	
	5aRUNCOMMAND-ONSTART
	case $? in
		0) updateStep "5a" "found" 65  ;;
		1) updateStep "5a" "created" 65  ;;
	esac
	
# 5b. RUNCOMMAND-ONEND
	updateStep "5b" "in progress" 65
	
	5aRUNCOMMAND-ONEND
	case $? in
		0) updateStep "5b" "found" 70  ;;
		1) updateStep "5b" "created" 70  ;;
	esac
}

# Checks call of RCLONE_SCRIPT by RUNCOMMAND-ONSTART
# RETURNS
#	0 > call found
#	1 > call created
function 5aRUNCOMMAND-ONSTART ()
{
	printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tSTART\n" >> "${logfile}"
	
	# check if RUNCOMMAND-ONSTART.sh exists
	if [ -f /opt/retropie/configs/all/runcommand-onstart.sh ]
	then
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tFILE FOUND\n" >> "${logfile}"
		
		# check if there's a call to RCLONE_SCRIPT
		if grep -Fq "~/scripts/rclone_script/rclone_script.sh" /opt/retropie/configs/all/runcommand-onstart.sh
		then
			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tCALL FOUND\n" >> "${logfile}"
			
			return 0
		else
			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tCALL NOT FOUND\n" >> "${logfile}"
			
			# add call
			echo "~/scripts/rclone_script/rclone_script.sh \"down\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onstart.sh	

			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tCALL CREATED\n" >> "${logfile}"
			
			return 1
		fi
	else
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tFILE NOT FOUND\n" >> "${logfile}"
	
		echo "#!/bin/bash" > /opt/retropie/configs/all/runcommand-onstart.sh
		echo "~/scripts/rclone_script/rclone_script.sh \"down\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onstart.sh
		
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONSTART\tFILE CREATED\n" >> "${logfile}"
		
		return 1
	fi
}

# Checks call of RCLONE_SCRIPT by RUNCOMMAND-ONEND
# RETURNS
#	0 > call found
#	1 > call created
function 5aRUNCOMMAND-ONEND ()
{
	printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tSTART\n" >> "${logfile}"
	
	# check if RUNCOMMAND-ONEND.sh exists
	if [ -f /opt/retropie/configs/all/runcommand-onend.sh ]
	then
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tFILE FOUND\n" >> "${logfile}"
		
		# check if there's a call to RCLONE_SCRIPT
		if grep -Fq "~/scripts/rclone_script/rclone_script.sh" /opt/retropie/configs/all/runcommand-onend.sh
		then
			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tCALL FOUND\n" >> "${logfile}"
			
			return 0
		else
			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tCALL NOT FOUND\n" >> "${logfile}"
			
			# add call
			echo "~/scripts/rclone_script/rclone_script.sh \"up\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onend.sh	

			printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tCALL CREATED\n" >> "${logfile}"
			
			return 1
		fi
	else
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tFILE NOT FOUND\n" >> "${logfile}"
	
		echo "#!/bin/bash" > /opt/retropie/configs/all/runcommand-onend.sh
		echo "~/scripts/rclone_script/rclone_script.sh \"up\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onend.sh
		
		printf "$(date +%FT%T%:z):\t5aRUNCOMMAND-ONEND\tFILE CREATED\n" >> "${logfile}"
		
		return 1
	fi
}

function 6LocalSAVEFILEDirectory ()
{
# 6a. Test for local SAVEFILE directory
	updateStep "6a" "in progress" 70
	
	6aCheckLocalBaseDirectory
	case $? in
		0) updateStep "6a" "found" 75  ;;
		1) updateStep "6a" "created" 75  ;;
	esac

# 6b. Check local <SYSTEM> directories
	updateStep "6b" "in progress" 75
	
	6bCheckLocalSystemDirectories
	case $? in
		0) updateStep "6b" "found" 80  ;;
		1) updateStep "6b" "created" 80  ;;
	esac
}

# Checks if the local base SAVEFILE directory exists
# RETURN
#	0 > directory exists
#	1 > directory has been created
function 6aCheckLocalBaseDirectory ()
{
	printf "$(date +%FT%T%:z):\t6aCheckLocalBaseDirectory\tSTART\n" >> "${logfile}"
	
	# check if local base dir exists
	if [ -d ~/RetroPie/saves ]
	then
		printf "$(date +%FT%T%:z):\t6aCheckLocalBaseDirectory\tFOUND\n" >> "${logfile}"
		
		return 0
	else
		printf "$(date +%FT%T%:z):\t6aCheckLocalBaseDirectory\tNOT FOUND\n" >> "${logfile}"
		
		mkdir ~/RetroPie/saves
		
		printf "$(date +%FT%T%:z):\t6aCheckLocalBaseDirectory\tCREATED\n" >> "${logfile}"
		
		return 1
	fi
}

# Checks if the local system specific directories exists
# RETURN
#	0 > all found
#	1 > created at least one
function 6bCheckLocalSystemDirectories ()
{
	printf "$(date +%FT%T%:z):\t6bCheckLocalSystemDirectories\tSTART\n" >> "${logfile}"
	local retval=0
	
	# for each directory in ROMS directory...
	for directory in ~/RetroPie/roms/*
	do
		system="${directory##*/}"
		
		# check if ROMS directory is a real directory and not a SymLink
		if [ ! -L ~/RetroPie/roms/${system} ]
		then
			# check if same directory exists in SAVES, create if necessary
			if [ -d ~/RetroPie/saves/${system} ] 
			then
				printf "$(date +%FT%T%:z):\t6bCheckLocalSystemDirectories\tFOUND directory ${system}\n" >> "${logfile}"
			else
				mkdir ~/RetroPie/saves/${system}
				printf "$(date +%FT%T%:z):\t6bCheckLocalSystemDirectories\tCREATED directory ${system}\n" >> "${logfile}"
				retval=1
			fi
		else
			# check if same SymLink exists in SAVES, create if necessary
			if [ -L ~/RetroPie/saves/${system} ]
			then
				printf "$(date +%FT%T%:z):\t6bCheckLocalSystemDirectories\tFOUND symlink ${system}\n" >> "${logfile}"
			else
				ln -s $(readlink ~/RetroPie/roms/${system}) ~/RetroPie/saves/${system}
				
				printf "$(date +%FT%T%:z):\t6bCheckLocalSystemDirectories\tCREATED symlink ${system}\n" >> "${logfile}"
				retval=1
			fi
		fi
	done
	
	return ${retval}
}

function 7RemoteSAVEFILEDirectory ()
{
# 7a. Check remote base directory
	updateStep "7a" "in progress" 80
	
	7aCheckRemoteBaseDirectory
	case $? in
		0) updateStep "7a" "found" 85  ;;
		1) updateStep "7a" "created" 85  ;;
		255) updateStep "7a" "failed" 80  ;;
	esac

# 7b. Check remote <system> directories
	updateStep "7b" "in progress" 85
	
	7bCheckRemoteSystemDirectories
	case $? in
		0) updateStep "7b" "found" 90  ;;
		1) updateStep "7b" "created" 90  ;;
		255) updateStep "7b" "failed" 85  ;;
	esac
}

# Checks if the remote base SAVEFILE directory exists
# RETURN
#	0 > directory exists
#	1 > directory has been created
#	255 > error while creating directory
function 7aCheckRemoteBaseDirectory ()
{
	printf "$(date +%FT%T%:z):\t7aCheckRemoteBaseDirectory\tSTART\n" >> "${logfile}"
	
	# list all directories from remote
	remoteDirs=$(rclone lsf --dirs-only -R retropie:)
	
	# for each line...
	while read path
	do
		if [ "${path}" == "${remotebasedir}/" ]
		then
			printf "$(date +%FT%T%:z):\t7aCheckRemoteBaseDirectory\tFOUND\n" >> "${logfile}"
			
			return 0
		fi
	done <<< "${remoteDirs}"
	
	# if there has been no match...
	printf "$(date +%FT%T%:z):\t7aCheckRemoteBaseDirectory\tNOT FOUND\n" >> "${logfile}"
	
	rclone mkdir retropie:"${remotebasedir}" >> "${logfile}"
	
	case $? in
		0) printf "$(date +%FT%T%:z):\t7aCheckRemoteBaseDirectory\tCREATED\n" >> "${logfile}"; return 1  ;;
		*) printf "$(date +%FT%T%:z):\t7aCheckRemoteBaseDirectory\tERROR\n" >> "${logfile}"; return 255  ;;
	esac
}

# Checks if the remote system specific directories exist
# RETURN
#	0 > all found
#	1 > created at least one
#	255 > error while creating directory
function 7bCheckRemoteSystemDirectories ()
{
	printf "$(date +%FT%T%:z):\t7bCheckRemoteSystemDirectories\tSTART\n" >> "${logfile}"
	
	local retval=0
	local output
	
	# list all directories in $REMOTEBASEDIR from remote
	remoteDirs=$(rclone lsf --dirs-only -R retropie:"${remotebasedir}")
	
	# for each directory in ROMS directory...
	for directory in ~/RetroPie/roms/*
	do
		system="${directory##*/}"
		
		# use grep to search $SYSTEM in $DIRECTORIES
		output=$(grep "${system}/" -nx <<< "${remoteDirs}")
		
		if [ "${output}" = "" ]
		then
			# create system dir
			rclone mkdir retropie:"${remotebasedir}/${system}"
			
			if [[ $? -eq 0 ]]
			then
				printf "$(date +%FT%T%:z):\t7bCheckRemoteSystemDirectories\tCREATED ${system}\n" >> "${logfile}"
				
				# put note if local directory is a symlink
				if [ -L ~/RetroPie/saves/${system} ]
				then
					printf "ATTENTION\r\n\r\nThis directory will not be used! This is just a symlink.\r\nPlace your savefiles in\r\n\r\n$(readlink ~/RetroPie/roms/${system})\r\n\r\ninstead." > ~/scripts/rclone_script/readme.txt
					
					rclone copy ~/scripts/rclone_script/readme.txt retropie:"${remotebasedir}/${system}/"
					
					rm ~/scripts/rclone_script/readme.txt
				fi
				
				retval=1
			else
				printf "$(date +%FT%T%:z):\t7bCheckRemoteSystemDirectories\tERROR\n" >> "${logfile}"
				return 255
			fi
		else
			printf "$(date +%FT%T%:z):\t7bCheckRemoteSystemDirectories\tFOUND ${system}\n" >> "${logfile}"
		fi
	done
	
	return ${retval}
}

function 8ConfigureRETROARCH ()
{
# 8a. Setting local SAVEFILE directory
	updateStep "8a" "in progress" 90
	
	8aSetLocalSAVEFILEDirectory
	
	updateStep "8a" "done" 95
}

# Sets parameters in all system specific configuration files
function 8aSetLocalSAVEFILEDirectory ()
{
	printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tSTART\n" >> "${logfile}"
	
	local retval
	
	# for each directory...
	for directory in /opt/retropie/configs/*
	do
		system="${directory##*/}"
		
		# skip directory ALL
		if [ "${system}" = "all" ]
		then
			continue
		fi
		
		# test if there's a RETROARCH.CFG
		if [ -f "${directory}/retroarch.cfg" ]
		then
			printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tFOUND retroarch.cfg FOR ${system}\n" >> "${logfile}"
			
			# test file for SAVEFILE_DIRECTORY
			retval=$(grep -i "^savefile_directory = " ${directory}/retroarch.cfg)
		
			if [ ! "${retval}" = "" ]
			then
				printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tREPLACED savefile_directory\n" >> "${logfile}"
			
				# replace existing parameter
				sed -i "/^savefile_directory = /c\savefile_directory = \"~/RetroPie/saves/${system}\"" ${directory}/retroarch.cfg
			else
				printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tADDED savefile_directory\n" >> "${logfile}"
				
				# create new parameter above "#include..."
				sed -i "/^#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"/c\savefile_directory = \"~\/RetroPie\/saves\/${system}\"\n#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"" ${directory}/retroarch.cfg
			fi
			
			# test file for SAVESTATE_DIRECTORY
			retval=$(grep -i "^savestate_directory = " ${directory}/retroarch.cfg)
		
			if [ ! "${retval}" = "" ]
			then
				printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tREPLACED savestate_directory\n" >> "${logfile}"
				
				# replace existing parameter
				sed -i "/^savestate_directory = /c\savestate_directory = \"~/RetroPie/saves/${system}\"" ${directory}/retroarch.cfg
			else
				printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tADDED savestate_directory\n" >> "${logfile}"
			
				# create new parameter above "#include..."
				sed -i "/^#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"/c\savestate_directory = \"~\/RetroPie\/saves\/${system}\"\n#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"" ${directory}/retroarch.cfg
			fi
			
		fi
	done
	
	printf "$(date +%FT%T%:z):\t8aSetLocalSAVEFILEDirectory\tDONE\n" >> "${logfile}"
}

function 9Finalize ()
{
# 9a. Saving configuration
	updateStep "9a" "in progress" 95
	
	9aSaveConfiguration
	
	updateStep "9a" "done" 100
}

# Saves the configuration of RCLONE_SCRIPT
function 9aSaveConfiguration ()
{
	printf "$(date +%FT%T%:z):\t9aSaveConfiguration\tSTART\n" >> "${logfile}"
	
	echo "remotebasedir=${remotebasedir}" > ~/scripts/rclone_script/rclone_script.ini
	echo "shownotifications=${shownotifications}" >> ~/scripts/rclone_script/rclone_script.ini
	echo "logfile=~/scripts/rclone_script/rclone_script.log" >> ~/scripts/rclone_script/rclone_script.ini
	echo "debug=0" >> ~/scripts/rclone_script/rclone_script.ini
	
	printf "$(date +%FT%T%:z):\t9aSaveConfiguration\tDONE\n" >> "${logfile}"
}


########
# MAIN #
########


if [ "${branch}" == "beta" ]
then
	dialogBetaWarning
fi

installer