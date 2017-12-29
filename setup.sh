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
else
	echo "Usage: $(basename $0) (install|reset)"
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
