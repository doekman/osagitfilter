#!/usr/bin/env bash


function lang_test {
	((TEST_NR+=1))
	if (( RUN_TEST != 0 && TEST_NR != RUN_TEST )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	#input arguments
	local CMD="osagetlang $TEST_FILES_DIR/$1"
	local EXPECTED_LANG=$2
	local EXPECTED_EXIT_CODE=$3
	local TEST_DESCRIPTION=$4
	#
	local TEST_LOG=$TEST_DIR/$TEST_NR.stderr.log

	echo "|≣≡=- $(printf '%2s' $TEST_NR), running lang-test: $TEST_DESCRIPTION"
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
	#
	local EXPECTED_FILENAME=$(basename "$EXPECTED_FILE")
	local EXPECTED_EXT="${EXPECTED_FILENAME##*.}"
	local ACTUAL_FILE="$TEST_DIR/$TEST_NR.actual.$EXPECTED_EXT"
	local TEST_LOG=$TEST_DIR/$TEST_NR.stderr.log
	local TEST_CMD="cat $INPUT_FILE | $CMD > $ACTUAL_FILE"
	#
	echo "|≣≡=- $(printf '%2s' $TEST_NR), running filter-test: $TEST_DESCRIPTION"
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
	>&2 echo "Maybe you should run './setup.sh install' first?"
	exit 1
fi

#statistics
((TEST_NR=0))
((TESTS_OK=0))
((TESTS_NOK=0))
((TESTS_SKIPPED=0))
#
((TEST_ERROR=0))
TEST_DIR="$(mktemp -d -t osagitfilter.test.tmp)"
TEST_FILES_DIR="test-files"
trap clean_up EXIT INT HUP TERM

if [[ $1 =~ -?[0-9]+ ]]; then
	if (( $1 == -1 )); then
		((TEST_ERROR=1))
		((RUN_TEST=0))
	elif (( $1 <= -2 )); then
		((TEST_ERROR=2))
		((RUN_TEST=0))
	else
		((RUN_TEST=$1))
	fi
else
	((RUN_TEST=0))
fi

echo "Starting tests... (to run one test: '$(basename $0) TEST_NR'; use -1 to force failure on lang-tests, -2 for filter-tests)"
echo

#--| Determine OSA language tests
lang_test "as.scpt"    "AppleScript"          0 "Get language of an AppleScript file"
lang_test "asdbg.scpt" "AppleScript Debugger" 0 "Get language of an AppleScript Debugger file"
lang_test "js.scpt"    "JavaScript"           0 "Get language of an JavaScript file"
lang_test "perl.scpt"  "Perl"                 1 "Get language of non-existing file"
lang_test ""           ""                     1 "Get language without arguments"

#--| Instrumentarium to generate a test-error.
if (( TEST_ERROR == 1 )); then
	lang_test "as.scpt"    "AdobeScript"          0 "They would like that (test-case designed to fail)"
fi


if (( TESTS_NOK != 0 )); then
	echo "$ Tests for osagetlang failed, no use to continue further tests"
else

	#--| (Wrong) argument tests
	filter_test "osagitfilter"     "as.scpt"               "-"             1 "No arguments"
	filter_test "osagitfilter -h"  "as.scpt"               "-"             0 "Show usage screen (--help)"

	CMD_CLEAN="osagitfilter clean --log"
	CMD_CLEAN_NO="osagitfilter clean --no-header --log"
	CMD_CLEAN_ALL="osagitfilter clean --forbidden - --log"
	CMD_CLEAN_APPLE="osagitfilter clean --forbidden 'JavaScript:AppleScript Debugger' --log"
	CMD_SMUDGE="osagitfilter smudge --log"
	CMD_BOTH="osagitfilter clean --log | osagitfilter smudge --log"

	#--| Plain AppleScript tests
	filter_test "$CMD_CLEAN"       "as.scpt"               "as-hdr.applescript"    0 "Clean AppleScript"
	filter_test "$CMD_CLEAN_NO"    "as.scpt"               "as.applescript"        0 "Clean AppleScript (--no-header)"
	filter_test "$CMD_CLEAN_APPLE" "as.scpt"               "as-hdr.applescript"    0 "Deny non-Apple languages: AppleScript"
	filter_test "$CMD_SMUDGE"      "as-hdr.applescript"    "as.scpt"               0 "Smudge AppleScript"
	filter_test "$CMD_SMUDGE"      "as.applescript"        "as.scpt"               0 "Smudge AppleScript (without header)"
	filter_test "$CMD_BOTH"        "as.scpt"               "as.scpt"               0 "Pass through AppleScript"
	#Known issue
	#filter_test "$CMD_BOTH"        "as2.scpt"              "as2.scpt"              0 "Pass through AppleScript; file not ending with empty line"

	#--| ScriptDebugger tests
	filter_test "$CMD_CLEAN"       "asdbg.scpt"            "asdbg-hdr.applescript" 1 "Default Deny: forbidden Debugging Mode switched on"
	filter_test "$CMD_CLEAN_ALL"   "asdbg.scpt"            "asdbg-hdr.applescript" 0 "Allow Debugging Mode switched on"
	filter_test "$CMD_CLEAN_APPLE" "asdbg.scpt"            "asdbg-hdr.applescript" 1 "Deny non-Apple languages: AppleScript Debugger"
	#--|  This can't be tested, because on compile-time, a GUID is inserted in the header. This GUID doesn't seem to be related 
	#--|  to «event asDBDBid»... So no easy validation for this one.
	#--|  Also, when saving with SD, file-size increases big time, so be aware of this when testing.
	#filter_test "$CMD_SMUDGE"      "asdbg-hdr.applescript" "asdbg.scpt"            0 "Smudge AppleScript Debugger"
	#filter_test "$CMD_BOTH"        "asdbg.scpt"            "asdbg.scpt"            0 "Pass through AppleScript Debugger"

	#--| JavaScript tests
	filter_test "$CMD_CLEAN"       "js.scpt"               "js-hdr.javascript"     0 "Clean JavaScript"
	filter_test "$CMD_CLEAN_NO"    "js.scpt"               "js-hdr.javascript"     0 "Clean JavaScript (--no-header)"
	filter_test "$CMD_CLEAN_APPLE" "js.scpt"               "js-hdr.javascript"     1 "Deny non-Apple languages: JavaScript"
	filter_test "$CMD_SMUDGE"      "js-hdr.javascript"     "js.scpt"               0 "Smudge JavaScript"
	filter_test "$CMD_SMUDGE"      "js.javascript"         "js.scpt"               1 "Smudge AppleScript (without header)"
	filter_test "$CMD_BOTH"        "js.scpt"               "js.scpt"               0 "Pass through JavaScript"

	#--| Instrumentarium to generate a test-error.
	if (( TEST_ERROR == 2 )); then
		filter_test "$CMD_BOTH"        "js.scpt"               "as.scpt"               0 "AppleScript != Javascript (test-case designed to fail)"
	fi

fi

echo
echo "$TEST_NR tests have ran, $TESTS_OK tested OK, $TESTS_NOK tested NOK and $TESTS_SKIPPED have been skipped."
