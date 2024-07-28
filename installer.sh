#!/bin/bash
#
# Simple installer for shrink-backup
#
# Command to use to install shrink-backup:
#	   curl https://raw.githubusercontent.com/UnconnectedBedna/shrink-backup/master/install | sudo bash
#

set -uo pipefail

# Has to be updatedwhen PR is accepted
readonly REPOSITORY="framps" # UnconnectedBedna
readonly BRANCH="install" # testing

readonly PACKAGE_FILE="shrink-backup"
readonly LICENSE_FILE="LICENSE"
readonly README_FILE="README.md"
readonly DIR_DOC="/usr/share/doc/$PACKAGE_FILE"
readonly DIR_EXE="/usr/local/sbin"
readonly DIR_ETC="/usr/local/etc"
readonly DOWNLOAD_REPOSITORY="https://raw.githubusercontent.com/$REPOSITORY/$PACKAGE_FILE/$BRANCH"
readonly FILES_2_DOWNLOAD=("$PACKAGE_FILE" "${PACKAGE_FILE}.conf" "$LICENSE_FILE" "$README_FILE")
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
	fi
	exit $exitStatus
}

pwd=$PWD
trap "cleanup" SIGINT SIGTERM EXIT
cd $TMP_DIR

echo "Installing $PACKAGE_FILE ..."

for (( i=0; i<${#FILES_2_DOWNLOAD[@]}; i++ )); do

	sourceFile="${FILES_2_DOWNLOAD[$i]}"
	targetDir="${FILES_2_STORE[$i]}"

	echo -n "Downloading $sourceFile from $DOWNLOAD_REPOSITORY/$sourceFile ... "
	http_code=$(curl -w "%{http_code}" -L -s $DOWNLOAD_REPOSITORY/$sourceFile -o $sourceFile)

	(( $? )) && { echo "Curl failed"; exit 1; }
	[[ $http_code != 200 ]] && { echo "http request failed with $http_code"; exit 1; }
	echo "done"

	echo -n "Installing $sourceFile into $targetDir ... "
	sudo chown root:root "${sourceFile}"
	(( $? )) && { echo "chown of $sourceFile failed"; exit 1; }

	sudo chmod 755 "${sourceFile}"
	(( $? )) && { echo "chmod of $sourceFile failed"; exit 1; }

	if [[ "$sourceFile" == "$PACKAGE_FILE" ]]; then # existing executable bit in github is not reflected by curl
		sudo chmod +x "$sourceFile"
		(( $? )) && { echo "chmod of $sourceFile failed"; exit 1; }
		sed --follow-symlinks -i -E "s/^(INSTALL_METHOD)=.+$/\1=\'curl\'/" "$sourceFile"
		(( $? )) && { echo "sed of $sourceFile failed"; exit 1; }
	elif [[ ! -d "$DIR_DOC" ]] && [[ "$sourceFile" == "$LICENSE_FILE" || "$sourceFile" == "$README_FILE" ]] ; then # create LICENSE directory
		sudo mkdir -p "$DIR_DOC"
		(( $? )) && { echo "mkdir of $DIR_DOC failed"; exit 1; }
		sudo chown root:root "${DIR_DOC}/.."
		(( $? )) && { echo "chown of ${DIR_SOC}/.. failed"; exit 1; }
	fi
	sudo mv "${sourceFile}" "${targetDir}"
	(( $? )) && { echo "mv of $sourceFile failed"; exit 1; }
	echo "done"

done

exit 0
