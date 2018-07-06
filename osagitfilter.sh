#!/usr/bin/env bash

# Unofficial Bash Strict Mode <http://redsymbol.net/articles/unofficial-bash-strict-mode/>
set -euo pipefail
IFS=$'\n\t'

SCRIPT_VER=0.6.5
SCRIPT_NAME=$(basename $0 .sh)
CALLED_WITH="$0 $@"
LOG_PATH=~/Library/Logs/Catsdeep/
OSA_GET_LANG_CMD=osagetlang
DEFAULT_OSA_LANG=AppleScript
OSA_LANG=$DEFAULT_OSA_LANG
FORBIDDEN_TEXT="AppleScript Debugger" #colon seperated list
FORBIDDEN=()
DO_LOG=0
FILE=
SCRATCH=

function finish {
	#SCRATCH is initialized to a temp directory only at the moment it's needed
	if [[ $SCRATCH ]]; then
		if [[ $DO_LOG = 0 ]]; then
			rm -Rf "$SCRATCH"
		else #leave the temporary files when in debug or logging mode
			log_line "stopped: $(date '+%Y-%m-%d %H:%M:%S') (temporary files have been left for inspection)"
			#make the log operation "atomic"
			cat $SCRATCH/tmp.log >> $LOG_PATH/$SCRIPT_NAME.log
		fi
	fi
}
trap finish EXIT
################

function usage {
	show_version
	echo
	echo "usage: $SCRIPT_NAME command [options] [FILE]"
	echo
	echo "command (use one):"
	echo "  clean            Translates OSA script to text, to be put into git"
	echo "  smudge           Translates text stored in git to OSA script"
	echo
	echo "arguments  (all optional):"
	echo "  -f, --forbidden  Provide (colon-seperated) forbidden languages. '-' for empty list, defaults to 'AppleScript Debugger'"
	echo "  -l, --log        Write debug info to '$LOG_PATH/$SCRIPT_NAME.log'"
	echo "  -h, -?, --help   Show this help message and exit"
	echo "  -v, --version    Show program's version number and exit"
	echo "  FILE             Filename of current stream; not actually used but comes in handy when debugging"
	echo
	echo "This script translates input from stdin to stdout only. The option '--forbidden' "
	echo "are only used with the 'clean' command."
	if [[ $# > 0 ]]; then
		ERROR 1 "$@"
	fi
	exit 0
}

function show_version {
	echo "$SCRIPT_NAME v$SCRIPT_VER"
}

function log_line {
  if [[ $DO_LOG = 1 ]]; then
    printf "%s\n" "$@">>$SCRATCH/tmp.log
  fi
}

function ERROR {
	ERR_NR=$1
	shift
	>&2 echo "ERROR: $@"
	log_line "ERROR($ERR_NR): $@"
	exit $ERR_NR
}

if [[ $# > 0 ]]; then
	case $1 in
		clean | smudge) CMD=$1;;
		-h | -\? | --help) usage;;
		-v | --version) show_version;exit 0;;
		*) usage "unknown command '$1'";;
	esac
	shift
else
	usage "missing command"
fi
while (( $# > 0 )) ; do
  case $1 in
	-f | --forbidden) [[ $# > 1 ]] || usage "FORBIDDEN argument expected after $1"; FORBIDDEN_TEXT=$2; shift;;
	-l | --log) DO_LOG=1;;
	-h | -\? | --help) usage;;
	-v | --version) show_version;exit 0;;
	-*) usage "Unrecognized switch '$1'";;
	*) FILE=$1;;
  esac
  shift
done
IFS=:
if [[ $FORBIDDEN_TEXT = "-" ]]; then
	FORBIDDEN=()
else
	FORBIDDEN=($FORBIDDEN_TEXT)
fi
IFS=$'\n\t'

[[ $CMD ]] || usage "No command supplied"
[[ -d "$LOG_PATH" ]] || mkdir -p "$LOG_PATH"
SCRATCH=$(mktemp -d -t osagitfilter.tmp)

log_line "---=[ $(show_version) ]=----------------------------------------------"
log_line "started: $(date '+%Y-%m-%d %H:%M:%S')"
log_line "sw_vers: $(sw_vers | tr -d '\t' | tr '\n' ';')"
log_line "call: $CALLED_WITH"
log_line "caller: $(ps -o args= $PPID)" #see: https://stackoverflow.com/a/26985984/56
log_line "scratch: $SCRATCH"
log_line "pwd: $(pwd)"
log_line "command: $CMD"
log_line "filename: '$FILE'"

if [[ $CMD = clean ]]; then

	#Create a temporary file from the stdin, because osadecompile expects a file, and $FILE might not exist on disk
	CLEAN_SCPT_FILE=$SCRATCH/tmp_clean_stdin.scpt
	cat - > $CLEAN_SCPT_FILE

	#determine osa-language of input file
	OSA_LANG=$($OSA_GET_LANG_CMD $CLEAN_SCPT_FILE)
	log_line "OSA lang: $OSA_LANG"

	if [[ $OSA_LANG = "-" ]]; then
		#Not an OSA file, just let it pass through
		cat $CLEAN_SCPT_FILE
	else
		#check if the osa-lang is forbidden
		log_line "forbidden langs: ${FORBIDDEN[@]:-}"
		for BL in "${FORBIDDEN[@]:-}"; do
			if [[ $BL = $OSA_LANG ]]; then
				ERROR 1 "OSA language '$BL' is forbidden by $SCRIPT_NAME"
			fi
		done

		#write header
		if [[ $OSA_LANG = "JavaScript" ]]; then
			comment="//"
		else
			comment="#"
		fi
		echo "$comment@osa-lang:$OSA_LANG"
	
		#decompile to text, and strip tailing whitespace (never newlines, because of $) and finally remove last line if it's empty
		log_line "Starting osadecompile, strip trailing whitespace and remove last line if it's empty (which is added by osacompile)"
		osadecompile $CLEAN_SCPT_FILE | sed -E 's/[[:space:]]*$//' | perl -pe 'chomp if eof'
	fi

elif [[ $CMD = smudge ]]; then

	#Create a temporary file, for "random access" of stdin
	SMUDGE_TXT_FILE=$SCRATCH/tmp_smudge_stdin.txt
	#Read git's input and store it in the temp-file, except the first line when it's a meta-comment
	FIRST_LINE_READ=
	while IFS= read -r line; do
		if [[ -z $FIRST_LINE_READ ]]; then
			FIRST_LINE_READ=YES
			log_line "first line: '$line'"
			if [[ $line =~ ^(#|\/\/)@osa-lang: ]]; then
				OSA_LANG=$(echo $line | sed -E 's/^(#|\/\/)@osa-lang:(.*)$/\2/')
				log_line "osa-lang header: '$OSA_LANG'"
				continue
			fi
		fi
		echo "$line" >> $SMUDGE_TXT_FILE
	done < /dev/stdin
	#when there are characters between last newline and EOF, print these too (basically $line is not a real line in this case)
	if [[ -n "$line" ]]; then
		printf "$line" >> $SMUDGE_TXT_FILE
	fi
	log_line "osa-lang: $OSA_LANG"
	#Create a temporary file, for storing output of osacompile
	SMUDGE_SCPT_FILE=$SCRATCH/tmp_smudge_stdout.scpt
	#Perform the compilation
	log_line "Starting osacompilation"
	cat $SMUDGE_TXT_FILE | osacompile -l "$OSA_LANG" -o $SMUDGE_SCPT_FILE
	#Put the output on the stdout
	cat $SMUDGE_SCPT_FILE

else
	usage "unexpected command (SHOULD NOT HAPPEN)"
fi
