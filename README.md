# shrink-backup

_I made this script because I wanted a universal method of backing up my SBC:s into small img files as fast as possible (with rsync), indepentent of what os is in use._

shrink-backup is a very fast utility for backing up your SBC:s into minimal bootable img files for easy restore with autoexpansion at boot.

Supports backing up `root` & `boot` (if existing) partitions. Data from other partitions will be written to `root` if not excluded (exception for [`btrfs`](#btrfs), all existing subvolumes in `/etc/fstab` will be created).  
Please see [`Info`](#info) section.

Autoexpansion tested on **Raspberry Pi** os (bookworm and older), **Armbian**, **Manjaro-arm**, **DietPi** & **ArchLinuxARM** for rpi with `ext4` or [`f2fs`](#f2fs) root partition.  
(Also **experimental** [`btrfs`](#btrfs) functionality, please read further down)  
Full functionality for usage inside [webmin](https://webmin.com/) (including "custom command" button). Thank you to [iliajie](https://github.com/iliajie) for helping out. ❤️

**Latest release:** [shrink-backup.v1.2](https://github.com/UnconnectedBedna/shrink-backup/releases/download/v1.2/shrink-backup.v1.2.tar.gz)  
[**Testing branch:**](https://github.com/UnconnectedBedna/shrink-backup/tree/testing) If you want to use the absolute latest version. There might be bugs.

**Very fast restore thanks to minimal size of img file.**

**Can backup any device as long as filesystem on root is `ext4`** or **[`f2fs`](#f2fs)** (experimental [`btrfs`](#btrfs))  
Default device that will be backed up is determined by scanning what disk-device `root` resides on.  
This means that **if** `boot` is a partition, that partition must be on the **same device and before the `root` partition**.  
The script considers everything on the device before `root` as the bootsector.

Backing up/restoring, to/from: usb-stick `/dev/sdX` with Raspberry pi os has been tested and works. Ie, writing an sd-card img to a usb-stick and vice versa works.

**Ultra-fast incremental backups to existing img files.**

See [wiki](https://github.com/UnconnectedBedna/shrink-backup/wiki) for information about installation methods, usage and examples.  
[Ideas and feedback](https://github.com/UnconnectedBedna/shrink-backup/discussions) is always appreciated, whether it's positive or negative. Please just keep it civil. :)  
If you find a bug or think something is missing in the script, please file a [Bug report or Feature request](https://github.com/UnconnectedBedna/shrink-backup/issues/new/choose)

**To restore a backup, simply "burn" the img file to a device using your favorite method.**

When booting a restored image with autoresize active, **please wait until the the reboot sequence has occurred.** The login prompt _may_ very well become visible before the autoresize function has rebooted.

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
  -e            Disable autoexpansion on root filesystem when image is booted
  -l            Write debug messages to logfile shrink-backup.log located in same directory as script
  -z            Make script zoom at light-speed, only question prompts might slow it down
                  Can be combined with -y for UNSAFE ultra-mega-superduper-speed
  -q --quiet    Do not print rsync copy process
  --no-color    Run script without color formatted text
  --fix         Try to fix the img file if -a fails with a "broken pipe" error
  --loop [img]  Loop img file and exit, works in combination with -l & -z
                  If optional [extra space] is defined, the img file will be extended with the amount before looping
                  NOTE that only the file gets truncated, no partitions
                  Useful if you for example want to manually manage the partitions
  --f2fs        Convert root filesystem on img from ext4 to f2fs
                  Only works on new img file, not in combination with -U
                  Will make backups of fstab & cmdline.txt to: fstab.shrink-backup.bak & cmdline.txt.shrink-backup.bak
                  Then change ext4 to f2fs in both files and add discard to options on root partition in fstab
  --version     Print version and exit
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

> [!NOTE]
> If installed using `curl`, location and name of file is different. Please read [install with curl](https://github.com/UnconnectedBedna/shrink-backup/wiki/Installing#curl---shrink-backup-install-script) for more information.

Use one directory per line in `exclude.txt`.  
`/directory/*` = create directory but exclude content.  
`/directory` = exclude the directory completely.

If `-t` is **NOT** selected the following will be excluded:
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
Use `-l` to write debug info into `shrink-backup.log` file located in the same directory as the script.  
Please provide this file if filing a [Bug report](https://github.com/UnconnectedBedna/shrink-backup/issues/new/choose)

> [!NOTE]
> If installed using `curl`, location and name of file is different. Please read [install with curl](https://github.com/UnconnectedBedna/shrink-backup/wiki/Installing#curl---shrink-backup-install-script) for more information.
<br>

#### `-z` (Zoom speed)
The `-z` "zoom" option simply removes the one second sleep at each info prompt to give the user time to read.  
By using the option, you save 15-25s when running the script.

> [!CAUTION]
> When used in combination with `-y` **warnings will also be bypassed! PLEASE use with care!**  
> The script will for example overwrite files without asking for confirmation!
<br>

#### `--fix` (Broken pipe)
Add `--fix` to your options if a backup fails during `rsync` with a "broken pipe" error. You can also _manually add_ `[extra space]` instead of using `-Ua` to solve this.

**Example:** `sudo shrink-backup -Ua --fix /path/to/backup.img`

The reason it happens is because `rsync` normally deletes files during the backup, not creating a file-list > removing files from img before starting to copy.  
So if you have removed and added new data on the system you backup from, there is a risk `rsync` tries to copy the new data before deleting data from the img, hence completely filling the img.

Using `--fix` configures `rsync` create a file-list and delete data **before** starting to transfer new data. This also means the backup takes a little longer.  
Having a "broken pipe" error during backup has in my experience never broken an img backup after either using `--fix` or adding `[extra space]` while updating the backup with `-U`.
<br>
<br>

#### `--loop` (Loop img file)
Use `--loop` to loop an img file to your `/dev`.  
This functionality works on any linux system, just use the script on any img type file (not limited to `.img` extension files) anywhere available to the computer.

**Example:** `sudo shrink-backup --loop /path/to/backup.img`

If used in combination with `[extra space]` the amount in MiB will be added to the **IMG FILE, NOT any partition.**

**Example:** `sudo shrink-backup --loop /path/to/backup.img 1024`

With this you can for example run: `sudo gparted /dev/loop0` (use correct `loop` it got assigned to) if you have a graphical interface to manually manage the img partitions in a graphical interface with `gparted`.  
You can ofc use any partition manager for this.  
If you added `[extra space]` this will then show up as unpartitioned space at the end of the device where you can create partition(s) and manually copy data to by mounting the new `loop` partition(s) that will become visible in `lsblk`.  
If you do this, don't forget to create or update the img with `-e` (disable autoexpansion) first. Autoexpansion will not work since the space will be occupied by your manually managed partition(s).  
You can still update the img file with `-U` as long as the img `root` partition is big enough to hold the data from the device you backup from, but make sure to [exclude](#-t-excludetxt) your manually managed partition(s) or they will be copied to the img `root` partition.

To remove the loop: `sudo losetup -d /dev/loop0`, (use correct `loop` it got assigned to)  
To remind yourself: `lsblk /dev/loop*` (if you forgot what `loop` it got assigned to)
<br>
<br>

#### `--f2fs` (Convert `ext4` into `f2fs` on img file)
> [!IMPORTANT]
> ONLY use this for **CONVERTING** filesystem into img file, **if you already have `f2fs` on the system you backup from, do not use this option.**

The script will detect what filesystem is used on `root` and act accordingly.  
Only supported with new backups, not when using `-U`.

Autoexpansion at boot is not supported for `f2fs` (there is no way of resizing a mounted `f2fs` filesystem, unlike with `ext4`) so resizing root partition have to be made manually after writing img to sd-card.  
Resize operations (when updating backup with `-U`) is not available for `f2fs` _as of now_.

The script will make backups of `fstab` & `cmdline.txt` into `fstab.shrink-backup.bak` & `cmdline.txt.shrink-backup.bak` on the img.  
It will then change from `ext4` to `f2fs` in `fstab` & `cmdline.txt` and add `discard` to the options on the `root` partition in `fstab`.

Please read information about [`f2fs`](#f2fs) further down.
<br>
<br>

### Info

The script works on any device as long as root filesystem is `ext4`, [`f2fs`](#f2fs) or **experimental** [`btrfs`](#btrfs).  
Since the script uses `lsblk` to crosscheck with `/etc/fstab` to figure out where `root` resides it does not matter what device it is located on.

Even if you forget to disable autoexpansion on a non supported OS, the backup will not fail, it will just skip creating the autoresize script.

> [!IMPORTANT]
> **Rsync WILL cross filesystem boundries, so make sure you [exclude](#-t-excludetxt) external mounts and other partitions unless you want them included in the `root` partition of the img backup.** (separate `/home` for example)

- The script will **ONLY** create `boot` (if exits) and `root` partitions on the img file.
- The script will **ONLY** look at your `root` partition when calculating sizes.

**Not excluding other mounts will copy that data to the img `root` partition, not create more partitions,** so make sure to **_manually add_ `[extra space]`** if you do this.  
Experimental [`btrfs`](#btrfs) is an exception to this, all subvolumes will be created.

See [--loop](#--loop-loop-img-file) for how to manually include more partitions on the img.
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

The easiest way to create a backup is to let the script configure the size.  
To create a backup img using recommended size, use the `-a` option and the path to the img file.

**Example:** `sudo shrink-backup -a /path/to/backup.img`

The script will set the img size by requesting recommended minimum size from `e2fsck` or `du` (`e2fsck` does not work on `f2fs` f.ex).  
This is not the absolute smallest size you can achieve but is the "safest" way to create a "smallest possible" img file.  
If the size of the filesystem you are backing up from does not increase too much, you can most likely keep it updated with the [update function](#image-update) (`-U`) of the script.
<br>
<br>
### Manually configure size

To manually configure size use `[extra space]`  
Space is added on top of `df` reported "used space", not the size of the partition.  
`[extra space]` is in **MiB**, so if you want to add **1G**, add **1024**.

**Example:** `sudo shrink-backup /path/to/backup.img 1024`
<br>
<br>
### Smallest image possible

To get the absolute smallest img file possible, do **NOT** use `-a` option, instead set `[extra space]` to `0`

**Example:** `sudo shrink-backup /path/to/backup.img 0`

This will instruct the script to get the used space from `df` and add 128MiB "*wiggle room*".  
If you are like me, doing a lot of testing, rewriting the sd-card multiple times when experimenting, the extra time it takes each "burn" will add up pretty fast.

**Example:**
```
-rw-r--r-- 1 root root 3.7G Jul 22 21:27 test.img # file created with -a
-rw-r--r-- 1 root root 3.3G Jul 22 22:37 test0.img # file created with 0
```

> [!IMPORTANT]
> Because of how filesystems work, `df` is never a true representation of what will actually fit in a created img file.  
> Each file, no matter the size, will take up one block of the filesystem, so if you have a LOT of very small files (running `docker` f.ex) the "0 added space method" might fail during rsync. Increase the 0 a little bit and retry.
>
> Using this method also means you have VERY little free space on the img file after creation.  
> If the filesystem you back up from increases in size, an update (`-U`) of the img file might fail with lack of space.
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

<hr>

## Image update

To update an existing img file simply use the `-U` option and the path to the img file.

**Example:** `sudo shrink-backup -U /path/to/backup.img`
<br>
<br>
### Autoresizing img when updating

If `-a` is used in combination with `-U`, the script will compare the `root` partition on the img file to the size `resize2fs` recommends as minimum (or `du` calculations depending on filesystem).  

**Example:** `sudo shrink-backup -Ua /path/to/backup.img`

> [!NOTE]
> - The **img file** `root` **partition** needs to be **>=256MB smaller** than `resize2fs` recommended minimum (or `du` calculations) to be **expanded**.
> - The **img file** `root` **partition** needs to be **>=512MB bigger** than `resize2fs` recommended minimum (or `du` calculations) to be **shrunk**.
>
> This is to protect from unnecessary resizing operations most likely not needed.

Using combination `-Ua` on an img that has become overfilled works, if not use [`--fix`](#--fix-broken-pipe) or manually add `[extra space]` and retry.
<br>
<br>
### Manually resizing img when updating

Only expansion is possible with this method.  
If `[extra space]` is used in combination with `-U`, the `root` partition of the img file will be expanded by that amount.  
`[extra space]` is in **MiB**, so if you want to add **1G**, add **1024**.

**Example:** `sudo shrink-backup /path/to/backup.img 1024`

**No checks are being performed to make sure the data you want to back up will actually fit.**  

Resizing operations are not supported with  [`f2fs`](#f2fs).
<br>
<br>
### Order of operations - Image update
1. Loops the img file.
2. Probes the loop of the img file for information about partitions.
3. If `-a` is selected, calculates sizes by comparing `root` used space on system and img file by using `fdisk` & `resize2fs` (or `du` depending on filesystem).
4. Expands filesystem on img file if requested (`-a`) and conditions were met in point 3, or if _manually added_ `[extra space]` is used.
5. Creates temp directory and mounts `root` partition from loop.
6. Checks if `boot` partition exists, if true, checks `fstab` and mounts accordingly from loop.
7. Uses `rsync` to sync filesystems.
8. Shrinks filesystem on img file if requested (`-a`) and conditions were met in point 3.
9. Tries to create autoresize scripts if supported on OS and not disabled with `-e`.
10. Unmounts and removes temp directory and file (file created for `rsync` log output).

<hr>

## f2fs
The script will detect `f2fs` on `root` automatically and act accordingly.

> [!NOTE]
> **Do NOT USE [`--f2fs`](#--f2fs-Convert-ext4-into-f2fs-on-img-file) unless you are converting from a `ext4` filesystem (on your system) into `f2fs` on the img file.**

Autoexpansion at boot is not possible with `f2fs`. User will have to manually expand img to cover entire storage media (f.ex sd-card) before booting a restored img.  
Resizing img `root` partition while updating (`-U`) is not possible with `f2fs` _as of now_. User will have to create a new backup if img runs out of space.  
This is something planned to be implemented further down the line.

<hr>

## btrfs

**ALL testing has been done on Manjaro-arm**

> [!NOTE]
> **THIS IS NOT A CLONE, IT IS A BACKUP OF REQUIRED FILES FOR A BOOTABLE BTRFS SYSTEM!**  
> Deduplication will not follow from the system you backup from to the img.  
> The script does NOT utilize `btrfs send|recieve`

All options in script should work just as on `ext4`. The script will detect `btrfs` and act accordingly.

As of now, top level subvolumes are checked for in `/etc/fstab` and are created (on img creation) and mounted accordingly, mount options should be preserved (if you for example changed compression).  
Updating img and autoresize function has been tested and works on **Manjaro-arm**.

> [!WARNING]
> The script will treat snapshots as nested volumes, so make sure to exclude snapshots if you have any, or directories and **nested volumes** will be created on the img file (not as copy-on-write snapshots).  
> This can be done in `exclude.txt`, wildcards (`*`) works. 
> When creating an img, the initial report window will tell you what volumes will be created. **Make sure these are correct before pressing Y.**

<details>
<summary><i>Fun fact about shrink-backup & btrfs</i></summary>
I used the script to create a backup of my Arch linux (BTW) desktop installation using `btrfs` with grub as bootloader (separate `/home` subvolume included in the image)<br>
Wrote that image to a usb stick, and it booted and autoexpanded without problems.<br>
<br>
<b>I do NOT recommend using shrink-backup as your main backup software for a desktop computer!</b>
<b>Use proper backup software for that.</b>
</details>

<hr>

**Thank you for using shrink-backup** ❤️❤️

*"A backup is not really a backup until it has been restored"*
