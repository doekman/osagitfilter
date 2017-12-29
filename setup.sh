#!/usr/bin/env bash

BASE_DIR=$(pwd)
INSTALL_INTO=/usr/local/bin
COMMANDS='osagetlang osagitfilter'

if [[ $1 = install ]]; then
	echo "Trying to install the osagitfilter-commands"
	for CMD in $COMMANDS; do
		if [[ -f $INSTALL_INTO/$CMD ]]; then
			echo "- ERROR: the command '$CMD' is already exists in '$INSTALL_INTO'. No install."
		else
			if ln -s $BASE_DIR/$CMD.sh $INSTALL_INTO/$CMD; then
				echo "- '$CMD' installed"
			else
				echo "- ERROR: couldn't create symbolic link ($?)"
			fi
		fi
	done
elif [[ $1 = reset ]]; then
	for CMD in $COMMANDS; do
		if [[ -h $INSTALL_INTO/$CMD ]]; then
			if rm -f $INSTALL_INTO/$CMD; then
				echo "- '$CMD' reset"
			else
				echo "- ERROR: couldn't remove '$CMD' ($?)"
			fi
		else
			echo "- ERROR: the command '$CMD' is not installed in '$INSTALL_INTO' as symbolic link."
		fi
	done
elif [[ $1 = rotate ]]; then
	LOG_PATH=~/Library/Logs/Catsdeep/
	LOG_NAME=osagitfilter
	ROTATE_STAMP=$(date "+%Y-%m-%dT%H-%M-%S")
	if [[ -d $LOG_PATH ]]; then
		echo "Rotating log (if any) in $LOG_PATH:"
		if [[ -f $LOG_PATH/$LOG_NAME.log ]]; then
			echo "- renaming $LOG_NAME.log -> ${ROTATE_STAMP}_$LOG_NAME.log"
			mv $LOG_PATH/$LOG_NAME.log $LOG_PATH/${ROTATE_STAMP}_$LOG_NAME.log
		fi
	else
		echo "Creating log directory, nothing to rotate"
		mkdir -p $LOG_PATH
	fi
	touch $LOG_PATH/$LOG_NAME.log
else
	echo "usage: $(basename $0) (install|reset|rotate)"
	echo
	echo "install: create symlinks in '$INSTALL_INTO'"
	echo "  reset: remove those symlinks"
	echo " rotate: rename any old logs to something with a timestamp"
	echo
	echo "Installation status:"
	for CMD in $COMMANDS; do
		if [[ -h $INSTALL_INTO/$CMD ]]; then
			echo "- '$CMD' is currently installed"
		else
			echo "- '$CMD' is currently NOT installed"
		fi
	done
fi
