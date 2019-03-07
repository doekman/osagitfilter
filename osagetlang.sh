#!/usr/bin/env osascript

use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "OSAKit"

on get_absolute_path(path)
	set cmd to "x=" & quoted form of path & ";pushd \"$(dirname \"$x\")\" >/dev/null;echo \"$(pwd)/$(basename \"$x\")\""
	set scpt_path to do shell script cmd
end

on posix_file_exists(path)
	set cmd to "test -f " & (quoted form of path) & "; echo $?"
	return (do shell script cmd) is "0"
end

on run args
	local scpt_path, source_nsurl, the_script, osa_lang

	if (count of args) is not 1 then error "usage: osagetlang path/to/script-file.scpt" number 1
	# Make sure it's an absolute path (since 'read' below gives the following warning on stderr otherwise)
	#    ...CFURLGetFSRef was passed an URL which has no scheme (the URL will not work with other CFURL routines)
	set scpt_path to get_absolute_path(item 1 of args)
	if not posix_file_exists(scpt_path) then
		error "File doesn't exist" number 1
	end if

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
	else
		set osa_lang to the_script's language()'s |name| as text
		if osa_lang is "AppleScript" then
			# double check if it's really AppleScript (OSAScript thinks even a JPEG is an AppleScript file) by checking the header
			# (this was first done with the unix 'file' command, but AppleScript is only recognized by OS X Sierra and later)
			set expected_header to "FasdUAS"
			set bytes_to_read to length of expected_header
			set file_handle to POSIX file scpt_path
			set file_header to read file_handle from 1 to bytes_to_read
			if expected_header ≠ file_header then
				#error "File is not an OSA script file (the first " & bytes_to_read & " characters are '" & file_header & "')" number 3
	            set osa_lang to "-" --Output for non-OSA file
			end if
		end if
	end if
	get osa_lang
end run
