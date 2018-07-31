# rclone_script

Setup cloud synchronization for the save files on your RetroPie

## What does this do?

This script will setup different things on your RetroPie in order to automatically sync save files to a cloud service supported by [rclone](https://rclone.org/)

## What will you have to do?

Just install this via
```bash
wget -N -P ~/scripts https://raw.githubusercontent.com/Jandalf81/rclone_script/master/rclone_script-install.sh
chmod 755 ~/scripts/rclone_script-install.sh
~/scripts/rclone_script-install.sh
```
and follow the instructions.

I recommend reading this page completely before actually doing this! Also, I made [this IMGur album](https://imgur.com/a/nOFxP5Y) to show you the installation process and what happens afterwards.

## Again, what does this do?

Let me give you a rundown of the things this script will do:

1. This script will install the _RCLONE_ binary. It will be downloaded directly from their website as the binary installable via _apt-get_ is quite old, sadly. _RCLONE_ actually is what allows us to use a number of different cloud services, see [their website](https://rclone.org/) for a complete list
2. The script will then ask you to define a _remote_. That is the other side used for the synchronization. That remote **has** to be called _retropie_, the script will not continue without it
3. Then, _PNGVIEW_ will be downloaded, compiled and installed. That will be used to show you notifications when up- and downloading save files.
4. _IMAGEMAGICK_ will be installed via _apt-get_, this will be used to actually create images containing the notifications which are shown by _PNGVIEW_
5. The other scripts you see here will now be downloaded. They are used to control _RCLONE_ whenever it needs to sync your save files. Notice that there's also a script to remove all of this from your RetroPie.
6. Some scripts from RetroPie will be changed so they call one of the scripts from step 5 which then calls _RCLONE_... Sounds complicated but you don't have to do anything (for the curious: those are the _RUNCOMMAND-ONSTART_ and _RUNCOMMAND-ONEND_ scripts)
7. Right next to the _roms_ directory, a new directory _saves_ will be created, containing a subdirectory for each system
8. Now, the setup script will ask you to enter a name for the remote base save directory. This is the directory where the save files will be synced to. You can enter any name you like, I recommend calling it _RetroArch_. After naming it, the setup script will create this directory and one subdirectory for each system RetroPie supports at the remote destination (if necessary)
9. Your RetroPie will be configured so each system uses it's own directory for saves. Before, RetroPie looked for these files in the _roms_ directory (which made syncing them without accidentially uploading a ROM - ILLEGALLY - so much more difficult)
10. That's it, setup is complete. If you already have some save files within the _roms_ directory you need to move them to their subdirectory within the _saves_ directory now

## What will RetroPie do after this script is installed?

Whenever you start or stop playing a game, the acompanying save files will be down- or uploaded to the configured remote:

* starting a game will trigger _RCLONE_ to download save files for the game from the remote
* stopping a game will trigger _RCLONE_ to upload save files for the game to the remote

In the RetroPie menu, there will also be a new menu item "_RCLONE_SCRIPT full sync_". Starting this menu item will up- and download newer files to and from the remote, so each side should have the latest save file for each game afterwards. Please note that this will also download save files even if the acompanying ROM is not on your RetroPie.

Of course, all of this only works if your RetroPie has access to the configured cloud service.

## Why do this?

Well, I have two big reasons:
1. I wanted an offsite backup of my save files. I have started _Chrono Trigger_ so many times and always lost the save by tinkering with my RetroPie...
2. I wanted to be able to seamlessly continue playing on another machine. Now I can...
* start the game on RetroPie, play for an hour, save and automatically upload to DropBox
* download the save file to Android via [DropSync](https://play.google.com/store/apps/details?id=com.ttxapps.dropsync&hl=de) and continue playing there via [RetroArch for Android](https://play.google.com/store/apps/details?id=com.retroarch) (don't forget to upload afterwards!)
* continue playing on my PC which is synced automatically cia the DropBox client (which also uploads again automatically)
* then return to RetroPie, which auto-downloads the save when I start the game there

## Are there risks?

Of course! I'm a hobby programer, so this script might have errors I just haven't found yet. I'll do my best to fix them, though.
There are some things which just will not work with any sync, e. g. conflicting file changes. I strongly advice you to only change one side of each synced save file. In other words, don't play _Chrono Trigger_ on you RetroPie and on your PC simultaniously and expect to keep both save slots intact...