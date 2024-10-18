#!/bin/bash
#
# Simple installer for shrink-backup
# Special thanks to https://github.com/framps
#
# Command to use to install shrink-backup:
#	   curl https://raw.githubusercontent.com/UnconnectedBedna/shrink-backup/install/installer.sh | sudo bash
#

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo 'THIS INSTALLER MUST BE RUN AS ROOT! (WITH SUDO)'
  exit
fi

set -uo pipefail

readonly REPOSITORY="UnconnectedBedna"
readonly BRANCH="main"

readonly PACKAGE_FILE="shrink-backup"
readonly EXCLUDE_FILE="exclude.txt"
readonly LICENSE_FILE="LICENSE"
readonly README_FILE="README.md"
readonly DIR_EXE="/usr/local/sbin"
readonly DIR_ETC="/usr/local/etc"
readonly DIR_DOC="/usr/share/doc/$PACKAGE_FILE"
readonly DOWNLOAD_REPOSITORY="https://raw.githubusercontent.com/$REPOSITORY/$PACKAGE_FILE/$BRANCH"
readonly FILES_2_DOWNLOAD=("$PACKAGE_FILE" "$EXCLUDE_FILE" "$LICENSE_FILE" "$README_FILE")
readonly FILES_2_STORE=("$DIR_EXE" "$DIR_ETC" "$DIR_DOC" "$DIR_DOC")
readonly TMP_DIR=$(mktemp -d)

function cleanup() {
  local exitStatus=$?
  cd $pwd
  rmdir $TMP_DIR &>/dev/null
  if (( $exitStatus > 0 )); then
    echo "Installation of $PACKAGE_FILE failed with rc $exitStatus"
  else
    echo "$PACKAGE_FILE successfully installed"
    echo '---------------------------------------------------------'
    echo 'Script location: /usr/local/sbin/shrink-backup'
    echo 'Exclude file locattion: /usr/local/etc/shrink-backup.conf'
    echo 'README location: /usr/share/doc/shrink-backup/README.md'
    echo 'LICENSE location: /usr/share/doc/shrink-backup/LICENSE'
    echo 'For help: shrink-backup --help'
    echo 'Thank you for using shrink-backup!'
  fi
  exit $exitStatus
}

pwd=$PWD
trap "cleanup" SIGINT SIGTERM EXIT
cd $TMP_DIR

echo "Installing ${PACKAGE_FILE}..."

for (( i=0; i<${#FILES_2_DOWNLOAD[@]}; i++ )); do

  sourceFile="${FILES_2_DOWNLOAD[$i]}"
  targetDir="${FILES_2_STORE[$i]}"

  echo "Downloading $sourceFile from ${DOWNLOAD_REPOSITORY}/${sourceFile}..."
  http_code=$(curl -w "%{http_code}" -L -s ${DOWNLOAD_REPOSITORY}/${sourceFile} -o $sourceFile)

  (( $? )) && { echo "Curl failed"; exit 1; }
  [[ $http_code != 200 ]] && { echo "http request failed with $http_code"; exit 1; }

  echo "Installing $sourceFile into ${targetDir}..."

  # Existing execution bit in github is not reflected by curl
  if [[ "$sourceFile" == "$PACKAGE_FILE" ]]; then
    chmod +x "$sourceFile"
    (( $? )) && { echo "chmod of $sourceFile failed"; exit 1; }
    sed --follow-symlinks -i -E "s/^(INSTALL_METHOD)=.+$/\1=\'curl\'/" "$sourceFile"
    (( $? )) && { echo "sed of $sourceFile failed"; exit 1; }
  # Create LICENSE directory
  elif [[ ! -d "$DIR_DOC" ]] && [[ "$sourceFile" == "$LICENSE_FILE" || "$sourceFile" == "$README_FILE" ]] ; then
    mkdir -p "$DIR_DOC"
    (( $? )) && { echo "mkdir of $DIR_DOC failed"; exit 1; }
  fi
  mv "$sourceFile" "$targetDir"
  (( $? )) && { echo "mv of $sourceFile failed"; exit 1; }

done

# Renaming exclude.txt to shrink-backup.conf since it is now located in /usr/local/etc
echo 'Renaming exclude.txt to shrink-backup.conf...'
if [ -f ${DIR_ETC}/shrink-backup.conf ]; then
  echo 'WARNING!'
  echo "${DIR_ETC}/shrink-backup.conf already exists!"
  while true; do
    read -n 1 -r -p '!! Do you want to overwrite? [y/n] ' input < /dev/tty
    case $input in
      [Yy]) echo -e '\nOverwriting...'; mv "${DIR_ETC}"/"${EXCLUDE_FILE}" "${DIR_ETC}"/shrink-backup.conf; break;;
      [Nn]) echo -e '\nKeeping old file...'; rm "${DIR_ETC}"/"${EXCLUDE_FILE}"; break;;
      *) echo -e "\nERROR! Please enter 'y/Y' or 'n/N'";;
    esac
  done
else
  mv "${DIR_ETC}"/"${EXCLUDE_FILE}" "${DIR_ETC}"/shrink-backup.conf
fi

exit 0
