#!/usr/bin/env bash

BASE_DIR=$(pwd)
INSTALL_INTO=/usr/local/bin
COMMANDS='osagetlang osagitfilter'
LOG_PATH=~/Library/Logs/Catsdeep/

if [[ $1 = configure ]]; then
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
	if [[ $(which git) ]]; then
		if [[ $2 == "--no-git" ]]; then
			echo "Skipping git config"
		elif [[ $2 == "--git-log" ]]; then
			echo "Configuring git with logging options switched on"
			git config --global filter.osa.clean "osagitfilter clean --log %f" 
			git config --global filter.osa.smudge "osagitfilter smudge --log %f" 
			git config --global filter.osa.required "true"
		else
			echo "Configuring git"
			git config --global filter.osa.clean "osagitfilter clean"
			git config --global filter.osa.smudge "osagitfilter smudge"
			git config --global filter.osa.required "true"
		fi
	else
		echo "git is not found; filter is not configured."
	fi
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
	if [[ $(which git) ]]; then
		echo "Removing git configuration"
		git config --global --remove-section filter.osa
	else
		echo "git is not found; filter is not removed."
	fi
elif [[ $1 = rotate ]]; then
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
	echo "usage: $(basename $0) (configure|reset|rotate) [options]"
	echo
	echo "configure: create symlinks in '$INSTALL_INTO' and add git config ('--no-git' to skip git config, or '--git-log' for logging)"
	echo "    reset: remove those symlinks"
	echo "   rotate: rename any old logs in '$LOG_PATH' to something with a timestamp"
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
