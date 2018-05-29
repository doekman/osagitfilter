#!/usr/bin/env osascript

use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "OSAKit"

on run args
	if (count of args) is not 1 then error "usage: osagetlang path-to-script-file.scpt" number 1
	set scpt_path to item 1 of args
	set source_nsurl to current application's NSURL's fileURLWithPath:scpt_path
	set the_script to current application's OSAScript's alloc()'s initWithContentsOfURL:source_nsurl |error|:(missing value)
	if the_script is missing value then error "Script cannot be loaded by OSAScript" number 2
	set osa_lang to the_script's language()'s |name| as text
	if osa_lang is "AppleScript" then
		#verify if it's really AppleScript (OSAScript thinks even a JPEG is an AppleScript file)
		set cmd to "file --brief " & quoted form of scpt_path
		set magic_file_type to do shell script cmd
		if magic_file_type is not "AppleScript compiled" then
			error "File is not an OSA script file (magic says: " & magic_file_type & ")" number 3
		end if
	end if
	get osa_lang
end run
