# shrink-backup

_I made this script because I wanted a universal method of backing up my SBC:s into small img files as fast as possible (with rsync), indepentent of what os is in use._

shrink-backup is a very fast utility for backing up your SBC:s into minimal bootable img files for easy restore with autoexpansion at boot.

Autoexpansion tested on **Raspberry Pi** os (bookworm and older), **Armbian**, **Manjaro-arm**, **DietPi** & **ArchLinuxARM** for rpi with `ext4` or [`f2fs`](#f2fs) root partition.<br>
(Also **experimental** [`btrfs`](#btrfs) functionality, please read further down)<br>
Full support for usage inside [webmin](https://webmin.com/) (including "custom command" button). Thank you to [iliajie](https://github.com/iliajie) for helping out. ❤️

**Latest release:** [shrink-backup.v1.0.0](https://github.com/UnconnectedBedna/shrink-backup/releases/download/v1.0.0/shrink-backup.v1.0.0.tar.gz)<br>
[**Testing branch:**](https://github.com/UnconnectedBedna/shrink-backup/tree/testing) If you want to have the absolute latest version. There might be bugs.

**Very fast restore thanks to minimal size of img file.**

**Can back up any device as long as filesystem on root is `ext4`** or **[`f2fs`](#f2fs)** (experimental [`btrfs`](#btrfs))<br>
Default device that will be backed up is determined by scanning what disk-device `root` resides on.<br>
This means that **if** `boot` is a partition, that partition must be on the **same device as `root`**.

Backing up/restoring, to/from: usb-stick `/dev/sdX` with Raspberry pi os has been tested and works. Ie, writing an sd-card img to a usb-stick and vice versa works.

**Ultra-fast incremental backups to existing img files.** 

See [wiki](https://github.com/UnconnectedBedna/shrink-backup/wiki) for a bit more information about usage.<br>
[Ideas and feedback](https://github.com/UnconnectedBedna/shrink-backup/discussions) is always appreciated, whether it's positive or negative. Please just keep it civil. :)<br>
Or if you find a bug or think something is missing in the script, please file a [Bug report or Feature request](https://github.com/UnconnectedBedna/shrink-backup/issues/new/choose)

**Don't forget to ensure the script is executable.**

**To restore a backup, simply "burn" the img file to a device using your favorite method.**<br>
When booting up a restored image with autoresize active, **please wait until the the reboot sequence has occured.** The login prompt may very well become visible before the autoresize function has rebooted.

<hr>

## Usage
```
shrink-backup -h
Script for creating an .img file and subsequently keeing it updated (-U), autoexpansion is enabled by default
Directory where .img file is created is automatically excluded in backup
########################################################################
Usage: sudo shrink-backup [-Uatyelhz] [--fix] [--loop] [--f2fs] imagefile.img [extra space (MiB)]
  -U            Update existing img file (rsync to existing img)
                  Optional [extra space] extends img root partition
  -a            Autocalculate root size partition, [extra space] is ignored
                  When used in combination with -U:
                  Expand if partition is >=256MiB smaller than autocalculated recommended minimum
                  Shrink if partition is >=512MiB bigger than autocalculated recommended minimum
  -t            Use exclude.txt in same folder as script to set excluded directories
                  One directory per line: "/dir" or "/dir/*" to only exclude contents
  -y            Disable prompts in script (please use this option with care!)
  -e            DISABLE autoexpansion on root filesystem when image is booted
  -l            Write debug messages to logfile shrink-backup.log located in same directory as script
  -z            Make script zoom at light-speed, only question prompts might slow it down
                  Can be combined with -y for UNSAFE ultra-mega-superduper-speed
  --fix         Try to fix the img file if -a fails with a "broken pipe" error
  --loop [img]  Loop img file and exit, works in combination with -l & -z
                  If optional [extra space] is defined, the img file will be extended with the amount before looping
                  NOTE that only the file gets truncated, no partitions
                  Useful if you for example want to manually manage the partitions
  --f2fs        Convert root filesystem on img from ext4 to f2fs
                  Only works on new img file, not in combination with -U
                  Will make backups of fstab & cmdline.txt to: fstab.shrink-backup.bak & cmdline.txt.shrink-backup.bak
                  Then change ext4 to f2fs in both files and add discard to options on root partition in fstab
  -h --help     Show this help snippet
########################################################################
Examples:
sudo shrink-backup -a /path/to/backup.img (create img, resize2fs calcualtes size)
sudo shrink-backup -e -y /path/to/backup.img 1024 (create img, ignore prompts, do not autoexpand, add 1024MiB extra space)
sudo shrink-backup -Utl /path/to/backup.img (update img backup, use exclude.txt and write log to shrink-backup.log)
sudo shrink-backup -U /path/to/backup.img 1024 (update img backup, expand img size/root partition with 1024MiB)
sudo shrink-backup -Ua /path/to/backup.img (update img backup, resize2fs calculates and resizes img file if needed)
sudo shrink-backup -Ua --fix /path/to/backup.img 1024 (update img backup, automatically resizes img file if needed, fix img free space)
sudo shrink-backup -l --loop /path/to/backup.img 1024 (write to log file, expand IMG FILE (not partition) by 1024MiB and loop)
```

#### `-t` (exclude.txt)
The folder where the img file is created will **ALWAYS be excluded in the backup.**<br>
If `-t` option is selected, `exclude.txt` **MUST exist** (but can be empty) within the **directory where the script is located** or the script will exit with an error.

Use one directory per line in `exclude.txt`.<br>
`/directory/*` = create directory but exclude content.<br>
`/directory` = exclude the directory completely.

If `-t` is **NOT** selected the following folders will be excluded:
```
/lost+found
/proc/*
/sys/*
/dev/*
/tmp/*
/run/*
/mnt/*
/media/*
/var/swap
```

#### `-l` (Log file)
Use `-l` to write debug info into `shrink-backup.log` file located in the same directory as the script.<br>
Please provide this file if filing a [Bug report](https://github.com/UnconnectedBedna/shrink-backup/issues/new/choose)
<br>
<br>

#### `-z` (Zoom speed)
The `-z` "zoom" option simply removes the one second sleep at each prompt to give the user time to read.<br>
By using the option, you save 15-25s when running the script.<br>
When used in combination with `-y` **warnings will also be bypassed! PLEASE use with care!**
<br>
<br>

#### `--fix` (Broken pipe)
Add `--fix` to your options if a backup fails during `rsync` with a "broken pipe" error. You can also _manually add_ `[extra space]` instead of using `-a` to solve this.

**Example:** `sudo shrink-backup -Ua --fix /path/to/backup.img`

The reason it happens is because `rsync` normally deletes files during the backup, not creating a file-list > removing files from img before starting to copy.<br>
So if you have removed and added new data on the system you backup from, there is a risk `rsync` tries to copy the new data before deleting data from the img, hence completely filling the img.

Using `--fix` makes `rsync` create a file-list and delete data **before** starting to transfer new data. This also means the backup takes a little longer.<br>
Having a "broken pipe" error during backup has in my experience never broken an img backup after either using `--fix` (can be used in combination with `-a`) or adding `[extra space]` while updating the backup with `-U`.
<br>
<br>

#### `--loop` (Loop img file)
Use `--loop` to loop an img file to your `/dev`.

**Example:** `sudo shrink-backup --loop /path/to/backup.img`

If used in combination with `[extra space]` the amount in MiB will be added to the **IMG FILE** NOT any partition.<br>
With this you can for example run `sudo gparted /dev/loop0` (if you have a graphical interface) to manually manage the img partitions in a graphical interface with `gparted`.<br>
If you added `[extra space]` this will then show up as unpartitioned space at the end of the device.

**Example:** `sudo shrink-backup --loop /path/to/backup.img 1024`

This functionality works on any linux system, just use the script on any img file anywhere available to the computer.

To remove the loop: `sudo losetup -d /dev/loop0`, change `loop0` to the correct `dev` it got looped to.<br>
To remind yourself: `lsblk /dev/loop*` if you forgot the location after using `--mount`
<br>
<br>

#### `--f2fs` (Convert `ext4` into `f2fs` on img file)
ONLY use this for **CONVERTING** filesystem on img file, **if you already have `f2fs` on your root, do not use this option.**<br>
The script will detect what filesystem is used on `root` and act accordingly.<br>
Only supported with new backups, not when using `-U`.

Autoexpansion at boot is not supported for `f2fs` (there is no way of resizing a mounted `f2fs` filesystem, unlike with `ext4`) so resizing root partition have to be made manually after writing img to sd-card.<br>
Resize operations (when updating backup with `-U`) is not available for `f2fs` _as of now_.

The script will make backups of `fstab` & `cmdline.txt` into `fstab.shrink-backup.bak` & `cmdline.txt.shrink-backup.bak` on the img.<br>
It will then change from `ext4` to `f2fs` in `fstab` & `cmdline.txt` and add `discard` to the options on the `root` partition in `fstab`.

Please read information about [`f2fs`](#f2fs) further down.
<br>
<br>

### Info
**Rsync WILL cross filesystem boundries, so make sure you exclude external drives unless you want them included in the backup.**

**Not excluding other partitions will copy the data to the img `root` partition, not create more partitions,** so make sure to **_manually add_ `[extra space]`** if you do this.

The script will **ONLY** look at your `root` partition when calculating sizes.
<br>
<br>

#### Applications used in the script:
- fdisk
- sfdisk
- dd
- parted
- e2fsck
- truncate
- mkfs.ext4
- rsync
- gdisk (sgdisk is needed if the partition table is GPT, the script will inform you)

<hr>

## Image creation

To create a backup img using recomended size, use the `-a` option and the path to the img file.

**Example:** `sudo shrink-backup -a /path/to/backup.img`

Theoretically the script should work on any device as long as root filesystem is `ext4`, [`f2fs`](#f2fs) or **experimental** [`btrfs`](#btrfs).<br>
Since the script uses `lsblk` to crosscheck with `/etc/fstab` to figure out where `root` resides it does not matter what device it is on.

Even if you forget to disable autoexpansion on a non supported OS, the backup will not fail, it will just skip creating the autoresize scripts. :)
<br>
<br>

### Order of operations - Image creation
1. Uses `lsblk` & `/etc/fstab` to figure out the correct disk device to back up.
2. Reads the block sizes of the system's `root` (and `boot` if it exists) partition.
3. Uses `dd` to create the boot part of the system + a few megabytes to include the filesystem on root. (this _can_ be a partition)
4. Uses `df` and/or `resize2fs` (depends on filesystem) to calculate sizes by analyzing the system's `root` partition. (For btrfs: `btrfs filesystem du` + 192MiB is used instead of `resize2fs`)
5. Uses `truncate` to resize img file.
6. Loops the img file.
7. Removes and recreates the `root` partition on the loop of the img file.
8. Creates the `root` filesystem on loop of the img file with the same `UUID` and `LABEL` as the system you are backing up from.
9. Creates a temp directory and mounts img file `root` partition from loop.
10. Checks if `boot` partition exists, if true, checks `fstab` and creates directory on `root` and mounts accordingly from loop.
11. Uses `rsync` to sync filesystems.
12. Tries to create autoresize scripts if supported on OS and not disabled with `-e`.
13. Unmounts and removes temp directory and file (file created for `rsync` log output).

Added space is added on top of `df` reported "used space", not the size of the partition. Added space is in MiB, so if you want to add 1G, add 1024.

The script can be instructed to set the img size by requesting recomended minimum size from `e2fsck` or `du` (`e2fsck` does not work on `f2fs` f.ex) by using the `-a` option.<br>
This is not the absolute smallest size you can achieve but is the "safest" way to create a "smallest possible" img file.<br>
If you do not increase the size of the filesystem you are backing up from too much, you can most likely keep it updated with the update function (`-U`) of the script.

By using `-a` in combination with `-U` the script will resize the img file if needed (not supported on [`f2fs`](#f2fs)).<br>
Please see [`--fix`](#--fix-broken-pipe) and [image update](#image-update) sections for more information.
<br>
<br>

### Smallest image possible

To get the absolute smallest img file possible, do NOT use `-a` option, instead set `[extra space]` to `0`

**Example:** `sudo shrink-backup /path/to/backup.img 0`

This will instruct the script to get the used space from `df` and adding 128MiB "*wiggle room*".<br>
If you are like me, doing a lot of testing, rewriting the sd-card multiple times when experimenting, the extra time it takes each "burn" will add up pretty fast.

**Example:**
```
-rw-r--r-- 1 root root 3.7G Jul 22 21:27 test.img # file created with -a
-rw-r--r-- 1 root root 3.3G Jul 22 22:37 test0.img # file created with 0
```

**Disclaimer!**<br>
Because of how filesystems work, `df` is never a true representation of what will actually fit in a created img file.<br>
Each file, no matter the size, will take up one block of the filesystem, so if you have a LOT of very small files (running `docker` f.ex) the "0 added space method" might fail during rsync. Increase the 0 a little bit and retry.

This also means you have VERY little free space on the img file after creation.<br>
If the filesystem you back up from increases in size, an update (`-U`) of the img file might fail.

By using `-a` in combination with `-U` the script will resize the img file if needed.<br>
Using combination `-Ua` on an img that has become overfilled works, if not add `--fix` and retry.<br>
Please see [`--fix`](#--fix-broken-pipe) and [Image update](#image-update) sections for more information.

<hr>

## Image update

To update an existing img file simply use the `-U` option and the path to the img file.

**Example:** `sudo shrink-backup -U /path/to/backup.img`
<br>
<br>

### Order of operations - Image update
1. Loops the img file.
2. Probes the loop of the img file for information about partitions.
3. If `-a` is selected, calculates sizes by comparing `root` sizes on system and img file by using `fdisk` & `resize2fs` (or `du` depending on filesystem).
4. Expands filesystem on img file if requested and needed or if _manually added_ `[extra space]` is used.
5. Creates temp directory and mounts `root` partition from loop.
6. Checks if `boot` partition exists, if true, checks `fstab` and creates directory on `root` and mounts accordingly from loop.
7. Uses `rsync` to sync filesystems.
8. Shrinks filesystem on img file if `-a` was used and conditions were met in point 3.
9. Tries to create autoresize scripts if supported on OS and not disabled with `-e`.
10. Unmounts and removes temp directory and file (file created for `rsync` log output).
<br>

### Resizing img file when updating
If `-a` is used in combination with `-U`, the script will compare the root partition on the img file to the size `resize2fs` recommends as minimum (or `du` calculations depending on filesystem).

The **img file** `root` **partition** needs to be **>=256MB smaller** than `resize2fs` (or `du` calculations) recommended minimum to be expanded.<br>
The **img file** `root` **partition** needs to be **>=512MB bigger** than `resize2fs` (or `du` calculations) recommended minimum to be shrunk.<br>
This is to protect from unessesary resizing operations most likely not needed.

If _manually added_ `[extra space]` is used in combination with `-U`, the img file's `root` partition will be expanded by that amount. **No checks are being performed to make sure the data you want to back up will actually fit.**<br>
Only expansion is possible with this method.

<hr>

## f2fs
The script will detect `f2fs` on `root` automatically and act accordingly.<br>
**Do NOT USE [`--f2fs`](#--fix-broken-pipe) unless you are converting from a `ext4` filesystem (on your system) into `f2fs` on the img file.**

Autoexpansion at boot is not possible with `f2fs`. User will have to manually expand img to cover entire storage media (f.ex sd-card) when restoring.<br>
Resizing of img `root` partition while updating img (`-U`) is not possible with `f2fs` _as of now_. User will have to create a new backup if img runs out of space.<br>
This is something I am planning to implement further down the line.

<hr>

## btrfs

**ALL testing has been done on Manjaro-arm**<br>
**THIS IS NOT A CLONE, IT IS A BACKUP OF REQUIRED FILES FOR A BOOTABLE BTRFS SYSTEM!**

All options in script should work just as on `ext4`. The script will detect `btrfs` and act accordingly.<br>
The script will treat snapshots as nested volumes, so make sure to exclude snapshots if you have any, or directories and **nested volumes** will be created on the img file (not as copy-on-write snapshots).<br>
This can be done in `exclude.txt`, wildcards (*) _should_ work.<br>
When starting the script, the initial report window will tell you what volumes will be created. **Make sure these are correct before pressing Y**

As of now, top level subvolumes are checked for in `/etc/fstab` and mounted accordingly, mount options should be preseved (for exmaple if you change compression).<br>
Autoresize function works on Manjaro-arm.

<hr>

**Thank you for using my software <3**

*"A backup is not really a backup until it has been restored"*
