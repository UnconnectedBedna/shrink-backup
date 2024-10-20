# shrink-backup install script

This is the curl installer for [shrink-backup](https://github.com/UnconnectedBedna/shrink-backup)  
Special thanks to [framps](https://github.com/framps)

As always, when running scripts directly from the internet, make sure you know the [code](https://github.com/UnconnectedBedna/shrink-backup/blob/install/installer.sh) is safe, **ESPECIALLY** when used in combination with `sudo`.

**Install with:**
```
curl https://raw.githubusercontent.com/UnconnectedBedna/shrink-backup/install/installer.sh | sudo bash
```

To update, rerun the install script with above line.

By using this installer, files for the application will be installed at appropriate locations on your system and make the script executable.  
Note that `exclude.txt` is renamed to `shrink-backup.conf` and placed in `/usr/local/etc`.
```
Script location:       /usr/local/sbin/shrink-backup
Exclude file location: /usr/local/etc/shrink-backup.conf
README location:       /usr/share/doc/shrink-backup/README.md
LICENSE location:      /usr/share/doc/shrink-backup/LICENSE
Log location:          /var/log/shrink-backup.log
```

<hr>

**Thank you for using my software <3**

*"A backup is not really a backup until it has been restored"*
