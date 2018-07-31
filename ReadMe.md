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

In order to do all this, the following changes will be made:

* Installation of the RCLONE binary. The script downloads from the RCLONE website directly as the binary installable via _apt-get_ is quite old, sadly.
* Installation of the PNGVIEW binary. This will be downloaded in source form and compiled on your Pi. This binary will be 