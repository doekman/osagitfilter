#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

if [[ $# != 1 ]]; then
	echo "usage: osagetlang path/to/script-file.scpt"
	exit 1
fi

script_file="$1"
if [[ ! -r "$script_file" ]]; then
	echo "Script file doesn't exist or can't be read"
	exit 1
fi

header_length=16
script_content=$(head -c "$header_length" "$1")
if [[ ${script_content:0:16} == "FasdUAS 1.101.10" ]]; then
	echo "AppleScript"
elif [[ ${script_content:0:8} == "MarY3.00" ]]; then
	echo "AppleScript Debugger"
elif [[ ${script_content:0:8} == "JsOsaDAS" ]]; then
	echo "JavaScript"
else
	echo "-" #Output for non-OSA files
fi
