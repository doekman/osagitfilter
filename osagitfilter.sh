#!/usr/bin/env bash

SCRIPT_VER=0.3

function finish {
	#SCRATCH is initialized to a temp directory only at the moment it's needed
	if [[ $SCRATCH ]]; then
		if [[ $DEBUG = 0 ]]; then
			rm -Rf "$SCRATCH"
		else
			debug "stopped: $(date '+%Y-%m-%d %H:%M:%S') (temporary files have been left for inspection)"
		fi
	fi
}
trap finish EXIT
################

function usage {
	echo "-=[ $SCRIPT_NAME - v$SCRIPT_VER ]=-"
	echo "usage: $SCRIPT_NAME --clean [--opt-out OPT_OUT] [FILE]  #translates OSA-script to text, OPT_OUT is colon-seperated">&2
	echo "       $SCRIPT_NAME --smudge [FILE]   #translates text to OSA-script">&2
	if [[ $# > 0 ]]; then
		printf "\nERROR: %s\n" "$1">&2
	fi
	exit 1
}

function debug {
	[[ $DEBUG = 1 ]] && printf "DEBUG: %s\n" "$@">&2
	[[ $DEBUG = 2 ]] && printf "%s\n" "$@">>$LOG_PATH/$SCRIPT_NAME.log
}

function ERROR {
	ERR_NR=$1
	shift
	echo "ERROR: $@">&2
	exit $ERR_NR
}

SCRIPT_NAME=$(basename $0 .sh)
LOG_PATH=~/Library/Logs/Catsdeep/
OSA_GET_LANG=osagetlang
DEBUG=0
NO_HEADER=0 #don't prepend osa-lang header for default scripting language (AppleScript)
OSA_LANG=AppleScript #default language
OPT_OUT_TEXT="AppleScript Debugger" #colon seperated list
while (( $# > 0 )) ; do
  case $1 in
	-c | --clean)  CMD=clean;;
	-s | --smudge) CMD=smudge;;
	-o | --opt-out) [[ $# > 1 ]] || usage "OPT_OUT argument expected after $1"; OPT_OUT_TEXT=$2; shift;;
	-d | --debug) DEBUG=1;;
	-l | --log) DEBUG=2;;
	-n | --no-header) NO_HEADER=1;;
	-h | -\? | --help) usage;;
	-v | --version) echo $SCRIPT_VER;exit 0;;
	-*) usage "Unrecognized switch '$1'";;
	*) FILE=$1;;
  esac
  shift
done
IFS=:
OPT_OUT=($OPT_OUT_TEXT)
IFS=' 	
'

[[ $CMD ]] || usage "No command supplied"
[[ -d "$LOG_PATH" ]] || mkdir -p "$LOG_PATH"
SCRATCH=$(mktemp -d -t osagitfilter.tmp)

debug "---=[ $SCRIPT_NAME - v$SCRIPT_VER ]=----------------------------------------------"
debug "started: $(date '+%Y-%m-%d %H:%M:%S')"
debug "command: $CMD"
debug "pwd: $(pwd)"
debug "filename: '$FILE'"
debug "scratch: $SCRATCH"

if [[ $CMD = clean ]]; then

	#Create a temporary file from the stdin, because osadecompile expects a file, and $FILE might not exist on disk
	CLEAN_SCPT_FILE=$SCRATCH/tmp_clean_stdin.scpt
	cat - > $CLEAN_SCPT_FILE

	#determine osa-language of input file
	OSA_LANG=$($OSA_GET_LANG $CLEAN_SCPT_FILE)
	debug "osa-lang: $OSA_LANG"
	debug "opt-out: ${OPT_OUT[@]}"

	#check if the osa-lang is opted out
	for BL in "${OPT_OUT[@]}"; do
		if [[ $BL = $OSA_LANG ]]; then
			ERROR 1 "OSA-language '$BL' is opted out by $SCRIPT_NAME">&2
		fi
	done

	#write header
	if [[ $NO_HEADER = 1 && $OSA_LANG = "AppleScript" ]]; then
		debug "--no-header specified, and osa-lang is AppleScript: writing no header"
	else
		if [[ $OSA_LANG = "JavaScript" ]]; then
			comment="//"
		else
			comment="#"
		fi
		echo "$comment@osa-lang:$OSA_LANG"
	fi
	
	#decompile to text, and strip tailing whitespace (never newlines, because of $)
	osadecompile $CLEAN_SCPT_FILE | sed -E 's/[[:space:]]*$//'

elif [[ $CMD = smudge ]]; then

	#Create a temporary file, for "random access" of stdin
	SMUDGE_TXT_FILE=$SCRATCH/tmp_smudge_stdin.txt
	#Read git's input and store it in the temp-file, except the first line when it's a meta-comment
	FIRST_LINE_READ=
	while IFS= read -r line; do
		if [[ -z $FIRST_LINE_READ ]]; then
			FIRST_LINE_READ=YES
			if [[ $line =~ ^(#|\/\/)@osa-lang: ]]; then
				OSA_LANG=$(echo $line | sed -E 's/^(#|\/\/)@osa-lang:(.*)$/\2/')
				debug "osa-lang header: '$OSA_LANG'"
				continue
			fi
		fi
		echo "$line" >> $SMUDGE_TXT_FILE
	done < /dev/stdin
	debug "osa-lang: $OSA_LANG"
	#Create a temporary file, for storing output of osacompile
	SMUDGE_SCPT_FILE=$SCRATCH/tmp_smudge_stdout.scpt
	#Perform the compilation
	if ! osacompile -l "$OSA_LANG" -o $SMUDGE_SCPT_FILE < $SMUDGE_TXT_FILE ; then
		ERROR 1 "osacompile failed"
	fi
	#Put the output on the stdout
	cat $SMUDGE_SCPT_FILE

else
	usage "unexpected command (should not happen)"
fi
