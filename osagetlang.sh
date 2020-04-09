#!/usr/bin/env bash
# Unofficial Bash Strict Mode
set -euo pipefail
IFS=$'\n\t'

function show_usage {
	echo "usage: $(basename "$0" .sh) [--options] path/to/script-file.scpt"
	echo "options:"
	echo "  -o, --osa-kit  Determine file-type via OSAKit (default)"
	echo "  -H, --header   Determine file-type via headers (quicker)"
	echo "  -? -h, --help  Show this usage"
	if (( $# > 0 )); then
		echo
		echo "ERROR: $1"
		exit 1
	fi
}

function abs_file_path {
	if [[ -f "$1" ]]; then
		pushd "$(dirname "$1")" >/dev/null
		echo "$(pwd)/$(basename "$1")"
		popd >/dev/null
	else
		echo "File '$1' does not exist!" >&2
		return 127
	fi
}

function osagetlang_via_osakit {
	local script_posix_path="$1"
	osascript - "$script_posix_path" <<'END_OF_APPLESCRIPT'
	use AppleScript version "2.4"
	use scripting additions
	use framework "Foundation"
	use framework "OSAKit"

	on run {scpt_path}
		local source_nsurl, the_script, osa_lang
		# Make sure it's an absolute path (since 'read' below gives the following warning on stderr otherwise)
		#	 ...CFURLGetFSRef was passed an URL which has no scheme (the URL will not work with other CFURL routines)
		set source_nsurl to current application's |NSURL|'s fileURLWithPath:scpt_path
		try
			set the_script to current application's OSAScript's alloc()'s initWithContentsOfURL:source_nsurl |error|:(missing value)
		on error number -10000
			# macOS Mojave, when running in shell context, blocks loading Script Debugger component. Assume it's AppleScript Debugger:
			# see: https://forum.latenightsw.com/t/mojave-changes-make-osadecompile-fail-on-applescript-debugger-files/1854
			# OSAScript also writes an error message to stderr.
			return "AppleScript Debugger"
		end try
		if the_script is missing value then
			return "AppleScript Debugger" # also macOS Mojave, but when ran in GUI context
		end
		return the_script's language()'s |name| as text
	end run
END_OF_APPLESCRIPT
}

function osagetlang_via_header {
	local script_posix_path="$1"
	local max_header_length=16
	local script_content
	script_content=$(head -c "$max_header_length" "$script_posix_path")
	if [[ ${script_content:0:16}   == "FasdUAS 1.101.10" ]]; then
		echo "AppleScript"
	elif [[ ${script_content:0:8}  == "MarY3.00" ]]; then
		echo "AppleScript Debugger"
	elif [[ ${script_content:0:16} == "JsOsaDAS1.001.00" ]]; then
		echo "JavaScript"
	else
		echo "-" #Output for non-OSA files
	fi
}

method=osakit
script_path=
while (( $# > 0 )) ; do
	case "$1" in
		-o | --osa-kit) method=osakit;;
		-H | --header) method=header;;
		"-?" | -h | --help) show_usage; exit 0;;
		*) if (( $# > 1 )); then show_usage "path/to/script-file.scpt argument should be last"; fi; script_path="$1";break;;
	esac
	shift
done

if [[ -z $script_path ]]; then
	show_usage "You should at least provide a path to a script file"
fi

script_path=$(abs_file_path "$script_path")
if [[ $method == osakit ]]; then
	osalang=$(osagetlang_via_osakit "$script_path" 2> /dev/null)
	if [[ "$osalang" == "AppleScript" ]]; then
		# osakit thinks even a JPEG is AppleScript, so check header
		osalang=$(osagetlang_via_header "$script_path")
	fi
else 
	osalang=$(osagetlang_via_header "$script_path")
fi
echo "$osalang"
