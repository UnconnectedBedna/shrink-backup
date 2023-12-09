# shrink-backup is a very fast utility for backing up your SBC:s into minimal bootable img files for easy restore with autoexpansion at boot

_I made this script because I wanted a universal method of backing up my SBC:s into small img files as fast as possible (with rsync), indepentent of what os is in use._

Autoexpansion tested on **Raspberry Pi** os (bookworm and older), **Armbian**, **Manjaro-arm** and **ArchLinuxARM** for rpi with **ext4** root partition.<br>
**btrfs** on root partition has been tested on **Manjaro-arm** and is still considered to be beta. Please see btrfs section at the bottom for more info.

**Latest release:** [shrink-backup.v0.9.4](https://github.com/UnconnectedBedna/shrink-backup/releases/download/v0.9.4/shrink-backup.v0.9.4.tar.gz)<br>
[Testing branch](https://github.com/UnconnectedBedna/shrink-backup/tree/testing) if you want to have the absolute latest version. Resizing of existing img file to minimum size and btrfs backups is next on the roadmap and is being developed here.

**Very fast restore thanks to minimal size of img file.**

**Can back up any device as long as root is `ext4`**<br>
`btrfs` is in beta.<br>
Default device that will be backed up is determined by scanning what disk-device `root` resides on.<br>
This means that _if_ `boot` is a partition, that partition must be on the **same device as `root`**.<br>
Backing up/restoring, to/from: usb-stick `/dev/sdX` with Raspberry pi os has been tested and works. Ie, writing an sd-card img to a usb-stick and vice versa works.

**Ultra-fast incremental backups to existing img files.** 

See [wiki](https://github.com/UnconnectedBedna/shrink-backup/wiki) for a bit more information about usage.<br>
[Ideas and feedback](https://github.com/UnconnectedBedna/shrink-backup/discussions) is always appreciated, whether it's positive or negative. Please just keep it civil. :)

**Assure the script is executable.**

**To restore a backup, simply "burn" the img file to a device using your favorite method.**<br>
When booting up a restored image with autoresize active, wait until the the reboot sequence has occured. The login prompt may very well become visible before the autoresize function has rebooted.

## Usage
```
shrink-backup -h
Script for creating an .img file and subsequently keeing it updated (-U), autoexpansion is enabled by default
Directory where .img file is created is automatically excluded in backup
########################################################################
Usage: sudo shrink-backup [-Uatyelh] imagefile.img [extra space (MB)]
  -U         Update the img file (rsync to existing img), [extra space] extends img size/root partition
  -a         Autoresize root partition (extra space is ignored)
                 When used in combination with -U:
                 Expand if img is +256MB smaller resize2fs recommended minimum, shrink if +512MB bigger
  -t         Use exclude.txt in same folder as script to set excluded directories
                 One directory per line: "/dir" or "/dir/*" to only exclude contents
  -y         Disable prompts in script
  -e         DO NOT expand filesystem when image is booted
  -l         Write debug messages in logfile shrink-backup.log in same directory as script
  -h --help  Show this help snippet
########################################################################
Examples:
sudo shrink-backup -a /path/to/backup.img (create img, automatically set size)
sudo shrink-backup -e -y /path/to/backup.img 1024 (create img, ignore prompts, do not autoexpand, add 1024MB extra space)
sudo shrink-backup -Utl /path/to/backup.img (update img backup, use exclude.txt and write log to shrink-backup.log)
sudo shrink-backup -Ua /path/to/backup.img (update img backup, automatically resize img file if needed)
sudo shrink-backup -U /path/to/backup.img 1024 (update img backup, expand img size/root partition with 1024MB)
```

The folder where the img file is created will ALWAYS be excluded in the backup.<br>
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

**Rsync WILL cross filesystem boundries, so make sure you exclude external drives unless you want them included in the backup.**<br>
Not excluding other partitions will copy the data to the img root partition, not create more partitions.

Use `-l` to write debug info into `shrink-backup.log` file located in the same directory as the script.

**Applications used in the script:**
- fdisk
- sfdisk
- parted
- e2fsck
- resize2fs
- dd
- truncate
- mkfs.ext4
- rsync

## Info

Theoretically the script should work on any device as long as root filesystem is `ext4`. But IMHO is best applied on ARM hardware.<br>
`btrfs` is usable but still experimental. Please see section about btrfs below for more information.<br>
Since the script uses `lsblk` to figure out where the root resides it does not matter what device it is on.<br>
Even if you forget to disable autoexpansion on a non supported system, the backup will not fail. :)

### Order of operations - Image creation:
1. Uses `lsblk` to figure out the correct disk device to back up.
2. Reads the block sizes of the partitions.
3. Uses `dd` to create the `boot` part of the system + a few megabytes to include the filesystem on `root`. (this _can_ be a partition)
4. Removes and recreates the `root` partition, the size depends on options used when starting the script.
5. Creates the `root` filesystem with the same `UUID` and `LABEL` as the system you are backing up from. (_MUST_ be `ext4`)
6. Uses `rsync` to sync both partitions. (if more than one)

Added space is added on top of `df` reported "used space", not the size of the partition. Added space is in MB, so if you want to add 1GB, add 1024.

The script can be instructed to set the img size by requesting recomended minimum size from `e2fsck` by using the `-a` option.<br>
This is not the absolute smallest size you can achieve but is the "safest" way to create a "smallest possible" img file.<br>
If you do not increase the size of the filesystem you are backing up from too much, you can most likely keep it updated with the update function (`-U`) of the script.<br>
By using `-a` in combination with `-U` the script will resize the img file if needed. Please see section about image update further down for more information.

### Smallest possible image

To get the absolute smallest img file possible, do NOT use `-a` option and set "extra space" to 0

Example: `sudo shrink-backup /path/to/backup.img 0`

This will instruct the script to get the used space from `df` and adding 128MB "*wiggle room*".<br>
If you are like me, doing a lot of testing, rewriting the sd-card multiple times. The extra time it takes each time will add up pretty fast.

Example:
```
-rw-r--r-- 1 root root 3.7G Jul 22 21:27 test.img # file created with -a
-rw-r--r-- 1 root root 3.3G Jul 22 22:37 test0.img # file created with 0
```

**Disclaimer:**<br>
Because of how filesystems work, `df` is never a true representation of what will actually fit in a created img file.<br>
Each file, no matter the size, will take up one block of the filesystem, so if you have a LOT of very small files (running docker f.ex) the "0 added space method" might fail during rsync. Increase the 0 a little bit and retry.<br>
This also means you have VERY little free space on the img file after creation.<br>
If the filesystem you back up from increases in size, an update (`-U`) of the img file might fail.<br>
By using `-a` in combination with `-U` the script will resize the img file if needed. Please see section about image update below for more information.

### Order of operations - Image update:
1. Probes the img file for information about partitions.
2. Mounts `root` partition with an offset for the loop.
3. Checks if multiple partitions exists. If true, reads `fstab` on img file and mounts `boot` partition accordingly with an offset.
4. Uses `rsync` to sync both partitions. (if more than one)

To update an existing img file simply use the `-U` option and the path to the img file.<br>
Example: `sudo shrink-backup -U /path/to/backup.img`

### Resizing img file when updating<br>
If `-a` is used in combination with `-U`, the script will compare the root partition on the img file to the size `resize2fs` recommends as minimum.<br>
The img file needs to be **+256MB** smaller than `resize2fs` recommended minimum to be expanded.<br>
The img file needs to be **+512MB** bigger than `resize2fs` recommended minimum to be shrunk.<br>
This is to protect from unnecessary resizing operations most likely not needed.

**Disclaimer**<br>
Resizing **always** includes a small risk of corruption, please use with care (ie do not abuse). If you know your system will increase, maybe it's better to just add manual space in the creation? And then when you close in on the limit, use manual method to add more space instead of constantly using `-Ua`.<br>
I have ran a lot of testing of this (on "weak" arm harware like rpi4) and it rarely fails, but it _does_ happen. I also run the backups over lan so that could also be a contributing factor for the failures. Just keep that in mind. :)

If manually added space is used in combination with `-U`, the `root` partition on the img file will be expanded by that amount. No checks are being performed to make sure the data you want to back up will actually fit.<br>
Only expansion is possible with this method.

## btrfs

**This is still in experimental stage so [ideas & feedback](https://github.com/UnconnectedBedna/shrink-backup/discussions) is HIGHLY appreciated!**<br>
The subvolumes are mounted with default compression: `compress=zstd` (default means `zstd:3`)

I am working against Manjaro-arm to create this functionality and the standard install creates root (`/@`) and home (`/@home`) subvolumes (and some nested ones that will also be included), so the script assumes this is the situation on ALL btrfs systems as of now.

The backup img is **NOT a clone**. Snapshots are NOT used to create the backup.<br>
The `UUID` will change on the created img filesystem (btrfs is way more picky than ext4 about this), but in the case of Manjaro (and raspberry pi too for that matter), that does not matter since `PARTUUID` is used in mounting, and that stays the same, but users should be aware.<br>
Subvol id:s are NOT guaranteed to be the same.

Instead of using btrfs send/recieve I opted for rsync, quck and dirty.<br>
Both in creation of a new img and when keeping it updated with `-U`.<br>
My resoning for this is that this script is primarily for creating bootable img files, NOT to create perfectly cloned backups. Speed is also a strong argument here.

The goal in developement of this script is ALWAYS to: as fast as possible create an img file that you can write directly to a sd-card and boot. That goal does NOT mix well with also creating a perfectly cloned backup.<br>
This does mean the script cares MORE about the **file integrity** rather than the **filesystem integrity**. The compression f.ex might be different than on your root filesystem. Subvol id:s might change etc etc.<br>
But the main goal stays the same, the backup must contain ALL REQUESTED FILES, ie a bootable file backup. I do NOT want to be responsible for people loosing their data when using this script, hence this decision. :)

All of this might change in the future though. Not the rsync part (I value speed very high), but the subvol id:s, compression and such is on my mind.<br>
F.ex if more subvols (or less) than root and home is used I want the script to be able to handle that.

**Thank you for using my software <3**

*"A backup is not really a backup until it has been restored"*
