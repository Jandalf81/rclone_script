#!/bin/bash


# define colors for output
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
UNDERLINE=$(tput smul)


# global variables
url="https://raw.githubusercontent.com/Jandalf81/rclone_script"
branch="master"
remotebasedir = ""


header ()
{
	# clear screen
	clear
	
	printf "${UNDERLINE}Install script for cloud sync via RCLONE\n\n"
}

testRCLONE ()
{
	# testing for RCLONE binary
	printf "${NORMAL}Testing for RCLONE binary... "

	if [ -f /usr/bin/rclone ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		installRCLONE
	fi
}

installRCLONE ()
{
	printf "${NORMAL}Installing RCLONE...\n"
	
	# download current RCLONE
	printf "${NORMAL}   Getting current RCLONE... "
	wget -q -P ~ https://downloads.rclone.org/rclone-current-linux-arm.zip
	printf "${GREEN}Done\n"

	# unzip RCLONE into HOME
	printf "${NORMAL}   Unzipping RCLONE... "
	unzip -q ~/rclone-current-linux-arm.zip -d ~
	printf "${GREEN}Done\n"

	# move RCLONE 
	printf "${NORMAL}   Moving RCLONE to /usr/bin... "
	{ # try
		cd ~/rclone-v* &&

		retval=$(sudo mv rclone /usr/bin 2>&1) &&
		retval=$(sudo chown root:root /usr/bin/rclone 2>&1) &&
		retval=$(sudo chmod 755 /usr/bin/rclone 2>&1) &&

		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		removeRCLONETempFiles
		exit
	}

	cd ~
	removeRCLONETempFiles
}

removeRCLONETempFiles ()
{
	# remove temporary files
	printf "${NORMAL}   Removing temporary files... "
	
	{ #try
		retval=$(rm ~/rclone-current-linux-arm.zip 2>&1) &&
		retval=$(rm ~/rclone-v* -r 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}

testRCLONEconfiguration ()
{
	# test for RCLONEs config file
	printf "${NORMAL}Testing for RETROPIE remote within RCLONE... "
	
	# list all remotes and their type
	remotes=$(rclone listremotes)
	
	# get line wiht RETROPIE remote
	retval=$(grep -i "^retropie:" <<< ${remotes})
		
	if [ "${retval}" = "retropie:" ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		createRCLONEconfiguration
	fi
}

createRCLONEconfiguration ()
{
	printf "${NORMAL}   Please create a new remote within RCLONE now.\n"
	printf "${NORMAL}   Name that remote \"${RED}retropie${NORMAL}\".\n"
	printf "${NORMAL}   Opening RCLONE CONFIG now...\n"
	printf "\n"
	
	rclone config
	
	printf "\n"
	printf "${NORMAL}Continuing installation now\n"
	printf "\n"
	
	testRCLONEconfiguration
}

testPNGVIEW ()
{
	# testing for PNGVIEW binary
	printf "${NORMAL}Testing for PNGVIEW binary... "

	if [ -f /usr/bin/pngview ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		installPNGVIEW
	fi
}

installPNGVIEW ()
{
	printf "${NORMAL}Installing PNGVIEW...\n"
	
	# download PNGVIEW
	printf "${NORMAL}   Getting current PNGVIEW... "
	wget -q -P ~ https://github.com/AndrewFromMelbourne/raspidmx/archive/master.zip
	printf "${GREEN}Done\n"

	# unzip PNGVIEW
	printf "${NORMAL}   Unzipping PNGVIEW... "
	unzip -q ~/master.zip -d ~
	printf "${GREEN}Done\n"
	
	# compile PNGVIEW
	printf "${NORMAL}   Compiling PNGVIEW (may take a while)... "
	cd ~/raspidmx-master
	make > /dev/null
	printf "${GREEN}Done\n"
	
	# move PNGVIEW
	printf "${NORMAL}   Moving PNGVIEW to /usr/bin... "
	{ # try
		retval=$(sudo mv ~/raspidmx-master/pngview/pngview /usr/bin 2>&1) &&
		retval=$(sudo mv ~/raspidmx-master/lib/libraspidmx.so.1 /usr/lib 2>&1) &&
		retval=$(sudo chown root:root /usr/bin/pngview 2>&1) &&
		retval=$(sudo chmod 755 /usr/bin/pngview 2>&1) &&
		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		removePNGVIEWTempFiles
		exit
	}
	
	cd ~
	removePNGVIEWTempFiles
}

removePNGVIEWTempFiles ()
{
	# remove temporary files
	printf "${NORMAL}   Removing temporary files... "
	
	{ #try
		retval=$(rm ~/master.zip 2>&1) &&
		retval=$(sudo rm -r ~/raspidmx-master 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { #catch
		printf "${RED}ERROR: ${retval}\n"
	}
}	

testIMAGEMAGICK ()
{
	# testing for IMAGEMAGICK binary
	printf "${NORMAL}Testing for IMAGEMAGICK binary... "

	if [ -f /usr/bin/convert ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		installIMAGEMAGICK
	fi
}

installIMAGEMAGICK ()
{
	# install IMAGEMAGICK
	printf "${NORMAL}Installing IMAGEMAGICK (may take a while)... "
	
	{ # try
		retval=$(sudo apt-get update 2>&1) &&
		retval=$(sudo apt-get --yes install imagemagick 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		exit
	}
}

installRCLONE_SCRIPT ()
{
	# install RCLONE_SCRIPT
	printf "${NORMAL}Installing RCLONE_SCRIPT...\n"

	# test directory for RCLONE_SCRIPT
	printf "${NORMAL}   Testing directory for RCLONE_SCRIPT... "
	if [ -d ~/scripts ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		printf "{NORMAL}   Creating directory for RCLONE_SCRIPT... "
		mkdir ~/scripts
		printf "${GREEN}Done\n"
	fi	

	# download script
	printf "${NORMAL}   Getting RCLONE_SCRIPT... "

	{ # try
		retval=$(wget -q -N -P ~/scripts ${url}/${branch}/rclone_script.sh 2>&1) &&
		retval=$(sudo chmod 755 ~/scripts/rclone_script.sh 2>&1) &&

		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		exit
	}
	
	# download RCLONE_SCRIPT-FULLSYNC script
	printf "${NORMAL}   Getting RCLONE_SCRIPT-FULLSYNC... "
		
	{ # try
		retval=$(wget -q -N -P ~/RetroPie/retropiemenu ${url}/${branch}/rclone_script-fullsync.sh 2>&1) &&
		retval=$(sudo chmod 755 ~/RetroPie/retropiemenu/rclone_script-fullsync.sh 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		exit
	}
	
	# test for RCLONE_SCRIPT-FULLSYNC menu item
	printf "${NORMAL}   Testing for RCLONE_SCRIPT-FULLSYNC menu item... "
	
	if grep -Fq "<path>./rclone_script-fullsync.sh</path>" ~/.emulationstation/gamelists/retropie/gamelist.xml
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		# create menu item
		printf "${NORMAL}   Creating menu item for RCLONE_SCRIPT-FULLSYNC... "
		menuitem="\t<game>\n"
		
		sed -i "/<\/gameList>/c\\\\t<game>\n\t\t<path>.\/rclone_script-fullsync.sh<\/path>\n\t\t<name>RCLONE_SCRIPT full sync<\/name>\n\t\t<desc>Starts a synchronization of all save files<\/desc>\n\t\t<image></image>\n\t<\/game>\n<\/gameList>" ~/.emulationstation/gamelists/retropie/gamelist.xml
		
		printf "${GREEN}Done\n"

	fi	

	# download uninstall script
	printf "${NORMAL}   Getting UNINSTALL script... "
echo "${url}/${branch}/rclone_script-uninstall.sh"
echo "https://raw.githubusercontent.com/Jandalf81/rclone_script/master/rclone_script-uninstall.sh"
		
	{ # try
		retval=$(wget -q -N -P ~/scripts ${url}/${branch}/rclone_script-uninstall.sh 2>&1) &&
		retval=$(sudo chmod 755 ~/scripts/rclone_script-uninstall.sh 2>&1) &&
		
		printf "${GREEN}Done\n"
	} || { # catch
		printf "${RED}ERROR: ${retval}\n"
		exit
	}
}

testRUNCOMMAND ()
{
	# test RUNCOMMAND-ONSTART
	printf "${NORMAL}Testing for RUNCOMMAND-ONSTART... "
	
	if [ -f /opt/retropie/configs/all/runcommand-onstart.sh ]
	then
		# file exists
		printf "${GREEN}Found\n"
		
		printf "${NORMAL}   Testing RUNCOMMAND-ONSTART for call to RCLONE_SCRIPT... "
		
		# test call to RCLONE from RUNCOMMAND-ONSTART
		if grep -Fq "~/scripts/rclone_script.sh" /opt/retropie/configs/all/runcommand-onstart.sh
		then
			printf "${GREEN}Found\n"
		else
			printf "${YELLOW}Not found\n"
			printf "${NORMAL}   Adding call to RCLONE_SCRIPT... "
			
			echo "~/scripts/rclone_script.sh \"down\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onstart.sh
			
			printf "${GREEN}Done\n"
		fi
	else
		# file does not exist
		printf "${YELLOW}Not found\n"
		printf "${NORMAL}   Creating RUNCOMMAND-ONSTART... "
		
		echo "#!/bin/bash" > /opt/retropie/configs/all/runcommand-onstart.sh
		echo "~/scripts/rclone_script.sh \"down\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onstart.sh
			
		printf "${GREEN}Done\n"
	fi
	
	# test RUNCOMMAND-ONEND
	printf "${NORMAL}Testing for RUNCOMMAND-ONEND... "
	
	if [ -f /opt/retropie/configs/all/runcommand-onend.sh ]
	then
		# file exists
		printf "${GREEN}Found\n"
		
		printf "${NORMAL}   Testing RUNCOMMAND-ONEND for call to RCLONE_SCRIPT... "
		
		# test call to RCLONE from RUNCOMMAND-ONEND
		if grep -Fq "~/scripts/rclone_script.sh" /opt/retropie/configs/all/runcommand-onend.sh
		then
			printf "${GREEN}Found\n"
		else
			printf "${YELLOW}Not found\n"
			printf "${NORMAL}   Adding call to RCLONE_SCRIPT... "
			
			echo "~/scripts/rclone_script.sh \"up\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onend.sh
			
			printf "${GREEN}Done\n"
		fi
	else
		# file does not exist
		printf "${YELLOW}Not found\n"
		printf "${NORMAL}   Creating RUNCOMMAND-ONSTART... "
		
		echo "#!/bin/bash" > /opt/retropie/configs/all/runcommand-onend.sh
		echo "~/scripts/rclone_script.sh \"up\" \"\$1\" \"\$2\" \"\$3\" \"\$4\"" >> /opt/retropie/configs/all/runcommand-onend.sh
			
		printf "${GREEN}Done\n"
	fi
}

testLocalSaveDirectory ()
{
	printf "${NORMAL}Testing local base save directory... "
	
	if [ -d ~/RetroPie/saves ]
	then
		printf "${GREEN}Found\n"
	else
		printf "${YELLOW}Not found\n"
		
		printf "${NORMAL}   Creating local base save directory... "
		mkdir ~/RetroPie/saves
		printf "${GREEN}Done\n"
	fi
	
	printf "${NORMAL}Testing local system specific save directories... "
	
	# for each directory in ROMS directory...
	for directory in ~/RetroPie/roms/*
	do
		system="${directory##*/}"
		
		if [ ! -d ~/RetroPie/saves/${system} ]
		then
			mkdir ~/RetroPie/saves/${system}
		fi
	done
	
	printf "${GREEN}Done\n"
}

testRemoteSaveDirectory ()
{
	read -p "${NORMAL}Please enter name of remote base save directory ([RetroArch]): " remotebasedir
	remotebasedir=${remotebasedir:-RetroArch}

	printf "${NORMAL}Testing remote base save directory (retropie:${remotebasedir})... "
	
	remotebasefound="FALSE"
	
	# list top level directories from remote
	directories=$(rclone lsf retropie:)
	
	# for each line from listing...
	while read directory
	do
		if [ "${directory}" = "${remotebasedir}/" ]
		then
			printf "${GREEN}Found\n"
			remotebasefound="TRUE"
			break
		fi
	done <<< "${directories}"
	
	if [ "$remotebasefound" = "FALSE" ]
	then
		printf "${YELLOW}Not found\n"
		
		printf "${NORMAL}   Creating remote base save directory... "
		rclone mkdir retropie:${remotebasedir}
		printf "${GREEN}Done\n"
	fi
	
	# test and create system specific save directories
	printf "${NORMAL}Testing remote system specific save directories... "
	
	directories=$(rclone lsf retropie:${remotebasedir})
	
	# for each directory in ROMS directory...
	for directory in ~/RetroPie/roms/*
	do
		system="${directory##*/}"
		
		# use grep to search $SYSTEM in $DIRECTORIES
		retval=$(grep "${system}/" -nx <<< "${directories}")
		
		if [ "${retval}" = "" ]
		then
			# create system dir
			rclone mkdir retropie:${remotebasedir}/${system}
		fi
	done
	
	printf "${GREEN}Done\n"
}

setLocalSaveDirectoryPerSystem ()
{
	# set local save directory per system
	printf "${NORMAL}Setting local save directory per system... "
	
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
			# test file for SAVEFILE_DIRECTORY
			retval=$(grep -i "^savefile_directory = " ${directory}/retroarch.cfg)
		
			if [ ! "${retval}" = "" ]
			then
				# replace existing parameter
				sed -i "/^savefile_directory = /c\savefile_directory = \"~/RetroPie/saves/${system}\"" ${directory}/retroarch.cfg
			else
				# create new parameter above "#include..."
				sed -i "/^#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"/c\savefile_directory = \"~\/RetroPie\/saves\/${system}\"\n#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"" ${directory}/retroarch.cfg
			fi
			
			# test file for SAVESTATE_DIRECTORY
			retval=$(grep -i "^savestate_directory = " ${directory}/retroarch.cfg)
		
			if [ ! "${retval}" = "" ]
			then
				# replace existing parameter
				sed -i "/^savestate_directory = /c\savestate_directory = \"~/RetroPie/saves/${system}\"" ${directory}/retroarch.cfg
			else
				# create new parameter above "#include..."
				sed -i "/^#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"/c\savestate_directory = \"~\/RetroPie\/saves\/${system}\"\n#include \"\/opt\/retropie\/configs\/all\/retroarch.cfg\"" ${directory}/retroarch.cfg
			fi
			
		fi
	done
	
	printf "${GREEN}Done\n"
}

saveConfiguration ()
{
	printf "${NORMAL}Saving configuration of RCLONE_SCRIPT... "
	echo "remotebasedir=${remotebasedir}" > ~/scripts/rclone_script.ini
	echo "logfile=~/scripts/rclone_script.log" >> ~/scripts/rclone_script.ini
	echo "debug=0" >> ~/scripts/rclone_script.ini
	printf "${GREEN}Done\n"
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

footer ()
{
	printf "\n"
	printf "${GREEN}All done!\n"
	printf "${NORMAL}From now on, your saves and states will be\n"
	printf "${NORMAL}synchonised each time you start and stop a ROM.\n"
	printf "\n"
	printf "All systems will put their saves and states in\n"
	printf "\tLocal: \"${YELLOW}~/RetroPie/saves/<SYSTEM>${NORMAL}\"\n"
	printf "\tRemote: \"${YELLOW}retropie:${remotebasedir}/<SYSTEM> (${remoteType})${NORMAL}\"\n"
	printf "If you already have some saves in the ROM directories,\n"
	printf "you need to move them there manually!\n"
	printf "After moving your saves you should ${RED}reboot ${NORMAL}your RetroPie.\n"
	printf "\n"
	printf "Then, you should start a full sync via\n"
	printf "${YELLOW}RetroPie / RCLONE_SCRIPT FULL SYNC\n"
	printf "\n"
	printf "${NORMAL}Call \"${RED}~/scripts/rclone_script-uninstall.sh${NORMAL}\" to remove\n"
	printf "all or parts of this script\n"
	printf "\n"
	
	read -p "${NORMAL}Reboot RetroPie now? (y, [n]): " userInput
	userInput=${userInput:-n}
	if [ "${userInput}" = "y" ]; then
		sudo shutdown -r now
	fi
	
}


# main program
header

# test and install RCLONE
testRCLONE

# test and create RCLONE configuration
#~/create_RCLONEconfig.sh # DEBUG
testRCLONEconfiguration

# test and install PNGVIEW
testPNGVIEW

# test and install IMAGEMAGICK
testIMAGEMAGICK

# install RCLONE_SCRIPT
installRCLONE_SCRIPT

# test and create RUNCOMMAND scripts
testRUNCOMMAND

# test and create local and remote save directories
testLocalSaveDirectory
testRemoteSaveDirectory

setLocalSaveDirectoryPerSystem

saveConfiguration

getTypeOfRemote
footer