#!/usr/bin/env bash

# This file + terminal output is best viewed with the Menlo-font (because of |≣≡=-) 

function abspath {
	if [[ -d "$1" ]]
	then
		pushd "$1" >/dev/null
		pwd
		popd >/dev/null
	elif [[ -e $1 ]]
	then
		pushd "$(dirname "$1")" >/dev/null
		echo "$(pwd)/$(basename "$1")"
		popd >/dev/null
	else
		echo "$1" does not exist! >&2
		return 127
	fi
}

function lang_test {
	((TEST_NR+=1))
	if (( RUN_TEST != 0 && TEST_NR != RUN_TEST )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	#input arguments
	if [[ ${1:0:1} == ";" ]]; then
		# if first argument starts with ";", then use it completely as command without the ";"
		local CMD="${1:1}"
	else
		# Otherwise, the argument it the file to get the language of
		local CMD="osagetlang $TEST_FILES_DIR/$1"
	fi
	local EXPECTED_LANG=$2
	local EXPECTED_EXIT_CODE=$3
	local TEST_DESCRIPTION=$4
	local HAS_CAPABILITIES=${5:-1}
	#
	local TEST_LOG=$TEST_DIR/$TEST_NR.stderr.log

	echo "|≣≡=- $(printf '%2s' $TEST_NR), running lang-test: $TEST_DESCRIPTION"
	if [[ $HAS_CAPABILITIES != "1" ]]; then
		echo "- Test skipped because of capabilities"
		((TESTS_SKIPPED+=1))
		return
	fi
	if (( LIST_ONLY == 1 )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	echo "---===[ $CMD ]=========---------" > $TEST_LOG
	RESULT=$(bash -c "$CMD" 2>>$TEST_LOG)
	EXIT_CODE=$?
	echo "-=> EXIT_CODE:$EXIT_CODE" >> $TEST_LOG
	if (( $EXIT_CODE != $EXPECTED_EXIT_CODE )); then
		((TESTS_NOK+=1))
		echo "# Test failed, exit code $EXPECTED_EXIT_CODE expected; was $EXIT_CODE (output was '$RESULT')"
		return
	fi
	if (( $EXIT_CODE == 0 )); then
		if [[ $RESULT != $EXPECTED_LANG ]]; then
			((TESTS_NOK+=1))
			echo "# Output '$EXPECTED_LANG' expected, but actually got '$RESULT'"
			return
		fi
	fi
	((TESTS_OK+=1))
}


function filter_test {
	((TEST_NR+=1))
	if (( RUN_TEST != 0 && TEST_NR != RUN_TEST )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	#input arguments
	#local CMD="$1" #Hmm, command substitution...
	local INPUT_FILE="$TEST_FILES_DIR/$2"
	if [[ $3 = "-" ]]; then
		local EXPECTED_FILE=""
	else
		local EXPECTED_FILE="$TEST_FILES_DIR/$3"
	fi
	local EXPECTED_EXIT_CODE="$4"
	local TEST_DESCRIPTION="$5"
	local HAS_CAPABILITIES=${6:-1}
	local NO_DIFF=${7:-0}
	#
	local EXPECTED_FILENAME=$(basename "$EXPECTED_FILE")
	local EXPECTED_EXT="${EXPECTED_FILENAME##*.}"
	local ACTUAL_FILE="$TEST_DIR/$TEST_NR.actual.$EXPECTED_EXT"
	local TEST_LOG=$TEST_DIR/$TEST_NR.stderr.log
	local TEST_CMD="cat $INPUT_FILE | $CMD > $ACTUAL_FILE"
	#
	echo "|≣≡=- $(printf '%2s' $TEST_NR), running filter-test: $TEST_DESCRIPTION"
	if [[ $HAS_CAPABILITIES != "1" && $HAS_CAPABILITIES != "2" ]]; then
		echo "- Test skipped because of capabilities"
		((TESTS_SKIPPED+=1))
		return
	fi
	if (( LIST_ONLY == 1 )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	echo "---===[ cat $INPUT_FILE | $1 > $ACTUAL_FILE }=========---------" > $TEST_LOG
	bash -c "cat $INPUT_FILE | $1 > $ACTUAL_FILE 2>> $TEST_LOG"
	EXIT_CODE=$?
	echo "-=> EXIT_CODE:$EXIT_CODE" >> $TEST_LOG
	if (( $EXIT_CODE != $EXPECTED_EXIT_CODE )); then
		((TESTS_NOK+=1))
		echo "# Test failed, exit code $EXPECTED_EXIT_CODE expected; was $EXIT_CODE"
		return
	fi
	if (( $EXIT_CODE == 0 )); then
		if [[ $EXPECTED_FILE ]]; then
			echo "---===[ diff $EXPECTED_FILE $ACTUAL_FILE ]=========---------" >> $TEST_LOG
			diff $EXPECTED_FILE $ACTUAL_FILE >> $TEST_LOG 2>&1
			EXIT_CODE=$?
			if [[ $NO_DIFF == 1 ]]; then
				echo "- Diff skipped because of reasons (please check manually to be sure)"
				echo "-=> EXIT_CODE:$EXIT_CODE but NO_DIFF specified" >> $TEST_LOG
			else
				echo "-=> EXIT_CODE:$EXIT_CODE" >> $TEST_LOG
				if (( $EXIT_CODE != 0 )); then
					((TESTS_NOK+=1))
					echo "# diff failed, see $TEST_NR.stderr.log"
					if [[ $EXPECTED_EXT != scpt ]]; then #non-binary file
						echo "- COMPARE: opendiff $EXPECTED_FILE $ACTUAL_FILE"
					fi
					return
				fi
			fi
		fi
	fi
	((TESTS_OK+=1))
}

function clean_up {
	if (( TESTS_NOK == 0 )); then
		rm -Rf $TEST_DIR
	else
		echo -n "$TEST_DIR" | pbcopy
		echo "CLEANUP YOURSELF: rm -Rf $TEST_DIR # (test dir copied on to clipboard)"
	fi
}

#testing pre-requisites
if [[ -z $(which osagetlang) || -z $(which osagitfilter) ]]; then
	>&2 echo "Test-subjects 'osagetlang' and/or 'osagitfilter' not found in the PATH."
	>&2 echo "Maybe you should run './setup.sh configure' first?"
	exit 1
fi

#statistics
((TEST_NR=0))
((TESTS_OK=0))
((TESTS_NOK=0))
((TESTS_SKIPPED=0))
#Other
((RUN_TEST=0))
((LIST_ONLY=0))
#
((TEST_ERROR=0))
TEST_DIR="$(mktemp -d -t osagitfilter.test.tmp)"
SCRIPT_DIR="$(abspath $(dirname $0))"
TEST_FILES_DIR="$SCRIPT_DIR/assets"
trap clean_up EXIT INT HUP TERM

if [[ -n `osalang | grep "Debugger"` ]]; then 
	HAS_ASDBG=1
else
	HAS_ASDBG=0
fi
GROUP_RUN=0

while [[ $# -gt 0 ]]; do
	if [[ $1 =~ -?[0-9]+ ]]; then
		if (( $1 == -1 )); then
			((TEST_ERROR=1))
			((RUN_TEST=0))
		elif (( $1 == -2 )); then
			((TEST_ERROR=2))
			((RUN_TEST=0))
		elif (( $1 < 0 )); then
			((RUN_TEST=${1:1}))
		else
			((RUN_TEST=${1}))
		fi
	elif [[ $1 == "-l" || $1 == "--list" ]]; then
		((LIST_ONLY=1))
	elif [[ $1 == "-gr" || $1 == "--group-run" ]]; then
		GROUP_RUN=1
	elif [[ $1 == "-na" || $1 == "--no-asdbg" ]]; then
		HAS_ASDBG=0
	fi
	shift
done

echo "Starting tests... "
echo "	---8<-------------------------------------------------------------------"
echo "	To run one test: '$(basename $0) TEST_NR'"
echo "	To show all tests: '$(basename $0) --list' (or '-l')"
echo "	Force no AppleScript Debugger tests: '$(basename $0) --no-asdbg (or '-na')"
echo "	Use -1 (one) to force failure on lang-tests, -2 for filter-tests"
echo "	Force grouped run: '$(basename $0) --group-run' (or '-gr')"
echo "	---8<-------------------------------------------------------------------"
echo "started: $(date '+%Y-%m-%d %H:%M:%S')"
echo

#--| Determine OSA language tests
lang_test "as.scpt"		"AppleScript"		     0 "Get language of an AppleScript file"
lang_test "asdbg.scpt"	"AppleScript Debugger"   0 "Get language of an AppleScript Debugger file" $HAS_ASDBG
lang_test "js.scpt"		"JavaScript"		     0 "Get language of an JavaScript file"
lang_test "perl.scpt"	"Perl"				   127 "Get language of non-existing file"
cmd=';osagetlang' 
lang_test "$cmd"		""					     1 "Get language without arguments"
lang_test "no-as.scpt"	"-"					     0 "Get language of a non-AppleScript file"
cmd=';cd '$TEST_FILES_DIR'; osagetlang as.scpt' 
lang_test "$cmd"		"AppleScript"		     0 "Get language of an AppleScript file (relative path)"

#--| Instrumentarium to generate a test-error.
if (( TEST_ERROR == 1 )); then
	lang_test "as.scpt"	   "AdobeScript"		  0 "They would like that (test-case designed to fail)"
fi


if (( TESTS_NOK != 0 )); then
	echo "$ Tests for osagetlang failed, no use to continue further tests"
else

	#--| (Wrong) argument tests
	filter_test "osagitfilter"	   "as.scpt"			   "-"			   1 "No arguments"
	filter_test "osagitfilter -h"  "as.scpt"			   "-"			   0 "Show usage screen (--help)"

	CMD_CLEAN="osagitfilter clean --log"
	CMD_CLEAN_2="$CMD_CLEAN | $CMD_CLEAN"
	CMD_CLEAN_ALL="osagitfilter clean --forbidden - --log"									  #Don't deny any OSA language
	CMD_CLEAN_APPLE="osagitfilter clean --forbidden 'JavaScript:AppleScript Debugger' --log"  #Deny Javascript AND AppleScript Debugger
	CMD_SMUDGE="osagitfilter smudge --log"
	CMD_BOTH="osagitfilter clean --log | osagitfilter smudge --log"
	CMD_BOTH_ALL="$CMD_CLEAN_ALL | $CMD_SMUDGE"

	for current_run in	with_logging no_logging; do
		echo "-=≡≣[ Grouped run: $current_run ]≣≡=----------------------------------------------------------"

		#--| Plain AppleScript tests
		filter_test "$CMD_CLEAN"	   "as.scpt"			   "as-hdr.applescript"	   0 "Clean AppleScript"
		filter_test "$CMD_CLEAN_2"	   "as.scpt"			   "as-hdr.applescript"	   0 "Twice clean AppleScript"
		filter_test "$CMD_CLEAN_APPLE" "as.scpt"			   "as-hdr.applescript"	   0 "Deny non-Apple languages: AppleScript"
		filter_test "$CMD_CLEAN"	   "as2.scpt"			   "as2.applescript"	   0 "Clean AppleScript; file not ending with empty line"
		filter_test "$CMD_SMUDGE"	   "as-hdr.applescript"	   "as.scpt"			   0 "Smudge AppleScript"
		filter_test "$CMD_SMUDGE"	   "as.applescript"		   "as.applescript"		   0 "Smudge AppleScript (passthrough, because no header)"
		filter_test "$CMD_SMUDGE"	   "as2.applescript"	   "as2.scpt"			   0 "Smudge AppleScript; file not ending with empty line"
		filter_test "$CMD_BOTH"		   "as.scpt"			   "as.scpt"			   0 "round: Pass through AppleScript"
		filter_test "$CMD_BOTH"		   "as2.scpt"			   "as2.scpt"			   0 "round: Pass through AppleScript; file not ending with empty line"

		#--| Non-AppleScript files test
		#issue 2: doesn't work yet completely
		filter_test "$CMD_CLEAN"	   "no-as.scpt"			   "no-as.scpt"			   0 "Clean AppleScript: Non-AppleScript (ASCII) file"
		filter_test "$CMD_CLEAN"	   "osa-logo.png"		   "osa-logo.png"		   0 "Clean AppleScript: Non-AppleScript (binary) file"
		filter_test "$CMD_CLEAN_2"	   "osa-logo.png"		   "osa-logo.png"		   0 "Twice clean AppleScript: Non-AppleScript (binary) file"

		#--| ScriptDebugger tests
		filter_test "$CMD_CLEAN"	   "asdbg.scpt"			   "asdbg-hdr.applescript" 1 "Default Deny: forbidden Debugging Mode switched on" $HAS_ASDBG
		#--|  ALSO: switched off, because Mojave doesn't allow AppleScript Debugger to be ran from command line or stuff?
		##filter_test "$CMD_CLEAN_ALL"	 "asdbg.scpt"			 "asdbg-hdr.applescript" 0 "Allow Debugging Mode switched on"					$HAS_ASDBG
		filter_test "$CMD_CLEAN_APPLE" "asdbg.scpt"			   "asdbg-hdr.applescript" 1 "Deny non-Apple languages: AppleScript Debugger"	  $HAS_ASDBG
		#--|  This can't be tested completely, because .scpt files always are different, even if they look the same (so no diffing)
		#--|  ALSO: switched off, because Mojave doesn't allow AppleScript Debugger to be ran from command line or stuff?
		##filter_test "$CMD_SMUDGE"		 "asdbg-hdr.applescript" "asdbg.scpt"			 0 "Smudge AppleScript Debugger"						$HAS_ASDBG 1
		##filter_test "$CMD_BOTH_ALL"	 "asdbg.scpt"			 "asdbg.scpt"			 0 "Pass through AppleScript Debugger"					$HAS_ASDBG 1

		#--| JavaScript tests
		filter_test "$CMD_CLEAN"	   "js.scpt"			   "js-hdr.javascript"	   0 "Clean JavaScript"
		filter_test "$CMD_CLEAN_APPLE" "js.scpt"			   "js-hdr.javascript"	   1 "Deny non-Apple languages: JavaScript"
		filter_test "$CMD_SMUDGE"	   "js-hdr.javascript"	   "js.scpt"			   0 "Smudge JavaScript"
		filter_test "$CMD_SMUDGE"	   "js.javascript"		   "js.javascript"		   0 "Smudge JavaScript (passthrough, because no header)"
		filter_test "$CMD_BOTH"		   "js.scpt"			   "js.scpt"			   0 "round: Pass through JavaScript"

		if [[ $GROUP_RUN = 0 ]]; then
			echo "Skipped grouped run"
			break
		fi
		# Remove log-flags from commands
		CMD_CLEAN=${CMD_CLEAN// --log/}
		CMD_CLEAN_ALL=${CMD_CLEAN_ALL// --log/}
		CMD_CLEAN_APPLE=${CMD_CLEAN_APPLE// --log/}
		CMD_SMUDGE=${CMD_SMUDGE// --log/}
		CMD_BOTH=${CMD_BOTH// --log/}
	done

	#--| Instrumentarium to generate a test-error.
	if (( TEST_ERROR == 2 )); then
		filter_test "$CMD_BOTH"		   "js.scpt"			   "as.scpt"			   0 "AppleScript != Javascript (test-case designed to fail)"
	fi

fi

echo
echo "$TEST_NR tests have ran, $TESTS_OK tested OK, $TESTS_NOK tested NOK and $TESTS_SKIPPED have been skipped."
echo "ended: $(date '+%Y-%m-%d %H:%M:%S')"
