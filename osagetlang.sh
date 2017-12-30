#!/usr/bin/env osascript

use AppleScript version "2.4"
use framework "Foundation"
use framework "OSAKit"

on print line_text
	--On some systems, scripting additions contains a definition for NSURL (where XMLLib.osax is included in scripting additions)
	--We need this elsewhere, so scoping like this works.
	using terms from scripting additions
		do shell script "echo " & quoted form of line_text
	end using terms from
end print

on run args
	if (count of args) is not 1 then error "usage: osagetlang.applescript path-to-script-file.scpt" number 1
	set scpt_path to item 1 of args
	set source_nsurl to current application's NSURL's fileURLWithPath:scpt_path
	set the_script to current application's OSAScript's alloc()'s initWithContentsOfURL:source_nsurl |error|:(missing value)
	if the_script is missing value then error "File or contained script is unreachable" number 1
	set osa_lang to the_script's language()'s |name| as text
	print osa_lang
end run
