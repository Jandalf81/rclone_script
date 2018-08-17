# rclone_script

Setup cloud synchronization for the save files on your RetroPie

## What does this do?

This script will setup different things on your RetroPie in order to automatically sync save files to a cloud service supported by [rclone](https://rclone.org/)

## What will you have to do?

Just install this via
```bash
wget -N -P ~/scripts/rclone_script https://raw.githubusercontent.com/Jandalf81/rclone_script/master/rclone_script-install.sh;
chmod 755 ~/scripts/rclone_script/rclone_script-install.sh;
~/scripts/rclone_script/rclone_script-install.sh;
```
and follow the instructions.

I ***strongly*** recommend reading this page completely before actually doing this! You can also look at these Wiki pages to better understand what this script does:

* [Step-by-step guide through the installer](../../wiki/RCLONE_SCRIPT-install)
* [RCLONE_SCRIPT in action](../../wiki/RCLONE_SCRIPT%20in%20action)
* [Guide to the RCLONE_SCRIPT menu](../../wiki/RCLONE_SCRIPT-menu)
* [How to manually move your savefiles](../../wiki/move-Savefiles)
* This also allows you to sync your progress with RetroArch on [Android](../../wiki/sync-and-play-Android) and [Windows](../../sync-and-play-Windows)!

## Again, what does this do?

Let me give you a rundown of the things this script will do:

1. The script will install the _RCLONE_ binary. It will be downloaded directly from their website as the binary installable via _apt-get_ is quite old, sadly. _RCLONE_ actually is what allows us to use a number of different cloud services, see [their website](https://rclone.org/) for a complete list. The script will then ask you to define a _remote_. That is the other side used for the synchronization. That remote **has** to be called _retropie_, the script will not continue without it. Please consult the [RCLONE documentation](https://rclone.org/) on how to configure remotes for different cloud services
2. Then, _PNGVIEW_ will be downloaded, compiled and installed. That will be used to show you notifications when up- and downloading save files.
3. _IMAGEMAGICK_ will be installed via _apt-get_, this will be used to actually create images containing the notifications which are shown by _PNGVIEW_
4. The other scripts you see here will now be downloaded. They are used to control _RCLONE_ whenever it needs to sync your save files. Notice that there's also a script to remove all of this from your RetroPie. A new menu item in the RetroPie menu will be created which let's you control some aspects of RCLONE_SCRIPTS. Then, you'll be asked to enter the desired name of the _remote SAVEFILE base directory_. All your synchronized files will go into this directory.
5. Some scripts from RetroPie will be changed so they call one of the scripts from step 4 which then calls _RCLONE_... Sounds complicated but you don't have to do anything
6. Right next to the _ROMS_ directory, a new directory _SAVES_ will be created, containing a subdirectory for each system. This is where your savefiles will have to be locally now. See [this wiki page](../../wiki/move-Savefiles) on how to move the savefiles there, that will ***not*** be done by the script
7. The setup script will now create the _remote SAVEFILE base directory_ and one subdirectory for each system RetroPie supports at the remote destination (if necessary)
8. Your RetroPie will be configured so each system uses it's own local directory for saves. Before, RetroPie looked for these files in the _ROMS_ directory (which made syncing them without accidentially uploading a ROM - ILLEGALLY - so much more difficult)
9. The settings you entered during installation are then saved for future reference

That's it, setup is complete. If you already have some save files within the _ROMS_ directory you need to move them to their subdirectory within the _SAVES_ directory now. Afterwards, reboot your RetroPie so the new menu item shows up

## What will RetroPie do after this script is installed?

Whenever you start or stop playing a game, the accompanying save files will be down- or uploaded to the configured remote:

* starting a game will trigger _RCLONE_ to download save files for the game from the remote
* stopping a game will trigger _RCLONE_ to upload save files for the game to the remote

Of course, all of this only works if your RetroPie has access to the configured cloud service.

In the RetroPie menu, there will also be a new menu item "_RCLONE_SCRIPT menu_". Starting this menu item will let you...

* start a full sync to up- and download newer files to and from the remote, so each side should have the latest save file for each game afterwards. Please note that this will also download save files even if the accompanying ROM is not on your RetroPie.
* toggle a setting to enable or disable the synchronization when starting or stopping a ROM. With this, you can temporarily disable that process. You'll get a warning, though
* toggle a setting to enable or disable showing a notification for the synchronization process

## Why do this?

Well, I have two big reasons:
1. I wanted an offsite backup of my save files. I have started _Chrono Trigger_ so many times and always lost the save by tinkering with my RetroPie...
2. I wanted to be able to seamlessly continue playing on another machine. Now I can...
   * start the game on RetroPie, play for an hour, save and automatically upload to DropBox
   * download the save file to Android via [DropSync](https://play.google.com/store/apps/details?id=com.ttxapps.dropsync&hl=de) and continue playing there via [RetroArch for Android](https://play.google.com/store/apps/details?id=com.retroarch) (don't forget to upload afterwards!)
   * continue playing on my PC which is synced automatically via the DropBox client (which also uploads again automatically)
   * then return to RetroPie, which auto-downloads the save when I start the game there

## Are there risks?

Of course! I'm a hobby programer, so this script might have errors I just haven't found yet. I'll do my best to fix them, though.
There are some things which just will not work with any sync, e. g. conflicting file changes. I strongly advice you to only change one side of each synced save file. In other words, don't play _Chrono Trigger_ on you RetroPie and on your PC simultaneously and expect to keep both save slots intact...

## This is great! How can I thank you?

First of all: You don't have to. I made this script for myself first of all. I'm happy already if someone else can use it. I only ask you to report any problems or feature requests here.

If you _really_ want to thank me, you could use this [DropBox referral link](https://db.tt/9AcbUWny) to create your account there. This will give us both 500 MiB extra (on top of the default 2 GiB) when you install the DropBox client. That will be enough for a good number of save files... ;-)

## Sources

These are the sites I used as source:
* https://rclone.org/dropbox/
* https://rclone.org/commands/rclone_copy/
* https://rclone.org/filtering/
* https://github.com/RetroPie/RetroPie-Setup/wiki/Runcommand#runcommand-onstart-and-runcommand-onend-scripts
* https://github.com/AndrewFromMelbourne/raspidmx
* https://www.zeroboy.eu/tutorial-gbzbatterymonitor/