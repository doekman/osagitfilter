#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

function abspath {
	if [[ -d "$1" ]]; then
		pushd "$1" >/dev/null
		pwd
		popd >/dev/null
	elif [[ -e $1 ]]; then
		pushd "$(dirname "$1")" >/dev/null
		echo "$(pwd)/$(basename "$1")"
		popd >/dev/null
	else
		echo "$1" does not exist! >&2
		return 127
	fi
}

function root_check {
	if [[ $EUID -ne 0 ]]; then
		>&2 echo "Please run script with 'sudo $(basename "$0") $*', exiting..."
		exit 1
	fi
}

function os_check {
	VERSION=$(sw_vers | grep "ProductVersion" | sed -E 's/[^.0-9]+//g')
	#From "10.11.12" (sw_vers) get "11"
	#From "12.0.1" (sw_vers) get "12"
	MAJOR=$(echo "$VERSION" | awk -F . '{ if ($1 >= 11) print $1; else print $2; }')
	MIN_MAJOR_VER=10
	MIN_OS_NAME=Yosemite
	if [[ $MAJOR -lt $MIN_MAJOR_VER ]]; then
		>&2 echo "osagitfilter needs at least macOS 10.$MIN_MAJOR_VER ($MIN_OS_NAME) but you have macOS ${VERSION}, exiting..."
		exit 1
	elif [[ -n $1 ]]; then
		if [[ $VERBOSE == 1 ]]; then
			echo "osagitfilter needs at least macOS 10.$MIN_MAJOR_VER.* ($MIN_OS_NAME) but you have macOS ${VERSION}, so that's OK..."
		fi
	fi
}

SCRIPT_NAME=$0
BASE_DIR=$(dirname "$(abspath "$0")")
INSTALL_INTO=/usr/local/bin
COMMANDS=$'osagetlang\tosagitfilter'
LOG_PATH=~/Library/Logs/Catsdeep/
VERBOSE=0
GIT_OPTION=""
C=unknown

while [[ $# -gt 0 ]]; do
	case $1 in
		configure | reset | rotate | create_local_bin) C=$1;;
		-v | --verbose) VERBOSE=1;;
		--no-git | --git-log) GIT_OPTION=$1;;
		*) echo "Unknown command/option '$1'";;
	esac
	shift;
done

if [[ $C = configure ]]; then
	echo "Trying to install the osagitfilter-commands"
	os_check $VERBOSE
	if [[ ! -d $INSTALL_INTO ]]; then
		echo "! ERROR: the folder $INSTALL_INTO doesn't exist on your system."
		echo
		echo "Create it with: sudo ${SCRIPT_NAME} create_local_bin"
		exit 1
	fi
	for CMD in $COMMANDS; do
		if [[ -f $INSTALL_INTO/$CMD ]]; then
			echo "- WARNING: the command '$CMD' is already exists in '$INSTALL_INTO'."
		else
			if ln -s "$BASE_DIR/$CMD.sh" "$INSTALL_INTO/$CMD"; then
				echo "- '$CMD' installed"
			else
				echo "- ERROR: couldn't create symbolic link ($?)"
			fi
		fi
	done
	if [[ $(which git) ]]; then
		if [[ $GIT_OPTION == "--no-git" ]]; then
			echo "Skipping git config"
		elif [[ $GIT_OPTION == "--git-log" ]]; then
			echo "Configuring git with logging options switched on"
			git config --global filter.osa.clean "$INSTALL_INTO/osagitfilter clean --log %f" 
			git config --global filter.osa.smudge "$INSTALL_INTO/osagitfilter smudge --log %f" 
			git config --global filter.osa.required "true"
		else
			echo "Configuring git"
			git config --global filter.osa.clean "$INSTALL_INTO/osagitfilter clean %f"
			git config --global filter.osa.smudge "$INSTALL_INTO/osagitfilter smudge %f"
			git config --global filter.osa.required "true"
		fi
	else
		echo "git is not found; filter is not configured."
	fi
elif [[ $C = reset ]]; then
	for CMD in $COMMANDS; do
		if [[ -h $INSTALL_INTO/$CMD ]]; then
			if rm -f "$INSTALL_INTO/$CMD"; then
				echo "- '$CMD' reset"
			else
				echo "- ERROR: couldn't remove '$CMD' ($?)"
			fi
		else
			echo "- WARNING: the command '$CMD' is not installed in '$INSTALL_INTO' as symbolic link."
		fi
	done
	if [[ $(which git) ]]; then
		echo "Removing git configuration"
		git config --global --remove-section filter.osa || echo "- WARNING: git exitted with code $?"
	else
		echo "WARNING: git is not found; filter is not removed."
	fi
elif [[ $C = rotate ]]; then
	LOG_NAME=osagitfilter
	ROTATE_STAMP=$(date "+%Y-%m-%dT%H-%M-%S")
	if [[ -d $LOG_PATH ]]; then
		echo "Rotating log (if any) in $LOG_PATH:"
		if [[ -f $LOG_PATH/$LOG_NAME.log ]]; then
			echo "- renaming $LOG_NAME.log -> ${ROTATE_STAMP}_$LOG_NAME.log"
			mv $LOG_PATH/$LOG_NAME.log "$LOG_PATH/${ROTATE_STAMP}_$LOG_NAME.log"
		fi
	else
		echo "Creating log directory, nothing to rotate"
		mkdir -p $LOG_PATH
	fi
	touch $LOG_PATH/$LOG_NAME.log
elif [[ $C = create_local_bin ]]; then
	root_check "$@"
	if [[ ! -d $INSTALL_INTO ]]; then
		echo "Creating $INSTALL_INTO"
		mkdir $INSTALL_INTO
	fi
	if [[ $(stat -f '%u' $INSTALL_INTO) != $(id -u "${SUDO_USER}") ]]; then
		echo "Change ownership to ${SUDO_USER}:admin"
		chown -R "${SUDO_USER}:admin" $INSTALL_INTO
	fi
	if [[ ":$PATH:" == *":$INSTALL_INTO:"* ]]; then
		echo "The folder $INSTALL_INTO is created successfully."
		echo "Next you can run: $SCRIPT_NAME configure"
	else
		echo "You should add $INSTALL_INTO to your PATH variable. This should be the case on every macOS install."
		echo "You should solve this yourself."
		exit 1
	fi
else
	echo "usage: $SCRIPT_NAME (configure|reset|rotate) [options] [-v|--verbose]"
	echo
	echo "configure: create symlinks in '$INSTALL_INTO' and add git config ('--no-git' to skip git config, or '--git-log' for logging)"
	echo "    reset: remove those symlinks and reset git configuration"
	echo "   rotate: rename any old logs in '$LOG_PATH' to something with a timestamp"
	#hidden option: when needed, this is suggested by command 'configure'
	#echo "create_local_bin: must be run with 'sudo'. Makes sure $INSTALL_INTO is created correctly."
	echo
	echo "Installation status:"
	for CMD in $COMMANDS; do
		if [[ -h $INSTALL_INTO/$CMD ]]; then
			echo "- '$CMD' is currently installed"
		else
			echo "- '$CMD' is currently NOT installed"
		fi
	done
	echo
	if [[ $VERBOSE == 1 ]]; then
		echo "script location: $BASE_DIR"
		echo "   install into: $INSTALL_INTO"
		echo "       log path: $LOG_PATH"
		echo
	fi
	os_check $VERBOSE
fi
