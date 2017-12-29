#!/usr/bin/env bash

function usage {
	if [[ $# > 0 ]]; then
		printf "ERROR: %s\n\n" "$1">&2
	fi
	echo "Usage: $SCRIPT_NAME --clean FILE [--blacklist BLACKLIST]   #translates OSA-script to text, BLACKLIST is colon-seperated">&2
	echo "       $SCRIPT_NAME --smudge FILE   #translates text to OSA-script">&2
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
CMD=
FILE=
OSA_LANG=AppleScript #default language
OLD_IFS=
BLACKLIST_TEXT="AppleScript Debugger" #colon seperated list
while (( $# > 0 )) ; do
  case $1 in
	-c | --clean)  [[ $# > 1 ]] || usage "FILE argument expected after $1"; CMD=clean; FILE=$2; shift;;
	-s | --smudge) [[ $# > 1 ]] || usage "FILE argument expected after $1"; CMD=smudge; FILE=$2; shift;;
	-b | --blacklist) [[ $# > 1 ]] || usage "BLACKLIST argument expected after $1"; BLACKLIST_TEXT=$2; shift;;
	-d | --debug) DEBUG=1;;
	-l | --log) DEBUG=2;;
	-h | -\? | --help) usage;;
	*) usage "Unrecognized argument '$1'";;
  esac
  shift
done
debug "---=[ ${SCRIPT_NAME} ]=---"
debug "Started: $(date '+%Y-%m-%d %H:%M:%S')"
# 
IFS=:
BLACKLIST=($BLACKLIST_TEXT)
IFS=' 	
'

[[ $CMD ]] || usage "No command supplied"
[[ -d "$LOG_PATH" ]] || mkdir -p "$LOG_PATH"

for BL in "${BLACKLIST[@]}"; do
	if [[ $BL = $OSA_LANG ]]; then
		ERROR 1 "OSA-language '$BL' (file '$FILE') is blacklisted by $SCRIPT_NAME">&2
	fi
done

debug "Command: $CMD"
debug "PWD: $(pwd)"

if [[ $CMD = clean ]]; then

	[[ -f "$FILE" ]] || usage "File '$FILE' doesn't exist"
	debug "File: $FILE"
	debug "BlackList: ${BLACKLIST[@]}"
	#determine osa language of input file
	OSA_LANG=$($OSA_GET_LANG "$FILE")
	debug "OSA_LANG: $OSA_LANG"
	#write header
	if [[ $OSA_LANG = "JavaScript" ]]; then
		comment="//"
	else
		comment="#"
	fi
	echo "$comment@osa-lang:$OSA_LANG"
	#decompile to text, and strip tailing whitespace (never newlines, because of $)
	osadecompile "$FILE" | sed -E 's/[[:space:]]*$//'

elif [[ $CMD = smudge ]]; then

	#Create a temporary file, for "random access" of stdin
	TMP_TXT_FILE=$(mktemp -t "${SCRIPT_NAME}.temp") || ERROR 1 "'mktemp' failed to create a temporary file (smudge,txt)"
	debug "tmp txt file: $TMP_TXT_FILE"
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
		echo "$line" >> $TMP_TXT_FILE
	done < /dev/stdin
	debug "OSA_LANG: $OSA_LANG"
	#Create a temporary file, for storing output of osacompile
	TMP_SCPT_FILE=$(mktemp -t "${SCRIPT_NAME}.temp") || (rm "$TMP_TXT_FILE"; ERROR 1 "'mktemp' failed to create a temporary file (smudge,scpt)")
	mv "$TMP_SCPT_FILE" "$TMP_SCPT_FILE.scpt" || (rm "$TMP_TXT_FILE" "$TMP_SCPT_FILE"; ERROR 1 "failed to add 'scpt' extension to the temporary file")
	TMP_SCPT_FILE="$TMP_SCPT_FILE.scpt"
	debug "tmp scpt file: $TMP_SCPT_FILE"
	#Perform the compilation
	if ! osacompile -l "$OSA_LANG" -o "$TMP_SCPT_FILE" < "$TMP_TXT_FILE" ; then
		rm "$TMP_TXT_FILE"
		rm "$TMP_SCPT_FILE"
		ERROR 1 "osacompile failed"
	fi
	#Put the output on the stdout and cleanup
	cat "$TMP_SCPT_FILE" && rm -f "$TMP_TXT_FILE" "$TMP_SCPT_FILE"

else
	usage "unexpected command (should not happen)"
fi
