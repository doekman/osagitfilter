#!/usr/bin/env bash


function do_test {
	((TEST_NR+=1))
	if (( RUN_TEST != 0 && TEST_NR != RUN_TEST )); then
		((TESTS_SKIPPED+=1))
		return
	fi
	#input arguments
	#local CMD="$1" #Hmm, command substitution...
	local INPUT_FILE="$TEST_FILES_DIR/$2"
	local EXPECTED_FILE="$TEST_FILES_DIR/$3"
	local EXPECTED_EXIT_CODE="$4"
	local TEST_DESCRIPTION="$5"
	#
	local EXPECTED_FILENAME=$(basename "$EXPECTED_FILE")
	local EXPECTED_EXT="${EXPECTED_FILENAME##*.}"
	local ACTUAL_FILE="$TEST_DIR/$TEST_NR.actual.$EXPECTED_EXT"
	local TEST_LOG=$TEST_DIR/$TEST_NR.stderr.log
	local TEST_CMD="cat $INPUT_FILE | $CMD > $ACTUAL_FILE"
	#
	echo "-=≡≣[ Test nr $(printf '%02d' $TEST_NR), running test: $TEST_DESCRIPTION ]≣≡=-"
	echo "-=≡≣[ cat $INPUT_FILE | $1 > $ACTUAL_FILE ]≣≡=-" > $TEST_LOG
	bash -c "cat $INPUT_FILE | $1 > $ACTUAL_FILE 2>> $TEST_LOG"
	EXIT_CODE=$?
	echo "-=> EXIT_CODE:$EXIT_CODE" >> $TEST_LOG
	if (( $EXIT_CODE != $EXPECTED_EXIT_CODE )); then
		((TESTS_NOK+=1))
		echo "# Test failed, exit code $EXPECTED_EXIT_CODE expected; was $EXIT_CODE"
		return
	fi
	if (( $EXIT_CODE == 0 )); then
		echo "-=≡≣[ diff $EXPECTED_FILE $ACTUAL_FILE ]≣≡=-" >> $TEST_LOG
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
	((TESTS_OK+=1))
}

function clean_up {
	if (( TESTS_NOK == 0 )); then
		rm -Rf $TEST_DIR
	else
		echo "CLEANUP YOURSELF: rm -Rf $TEST_DIR"
	fi
}
((TEST_NR=0))
((TESTS_OK=0))
((TESTS_NOK=0))
((TESTS_SKIPPED=0))

TEST_DIR="$(mktemp -d -t osagitfilter.test.tmp)"
TEST_FILES_DIR="test-files"
trap clean_up EXIT INT HUP TERM

if [[ $1 =~ [0-9]+ ]]; then
	((RUN_TEST=$1))
else
	((RUN_TEST=0))
fi

CMD_CLEAN="osagitfilter --clean --log"
CMD_CLEAN_NO="osagitfilter --clean --no-header --log"
CMD_CLEAN_ALL="osagitfilter --clean --forbidden - --log"
CMD_CLEAN_APPLE="osagitfilter --clean --forbidden 'JavaScript:AppleScript Debugger' --log"
CMD_SMUDGE="osagitfilter --smudge --log"
CMD_BOTH="osagitfilter --clean --log | osagitfilter --smudge --log"
echo "Starting tests..."
echo

#--| Plain AppleScript tests
do_test "$CMD_CLEAN"       "as.scpt"               "as-hdr.applescript"    0 "Clean AppleScript"
do_test "$CMD_CLEAN_NO"    "as.scpt"               "as.applescript"        0 "Clean AppleScript (--no-header)"
do_test "$CMD_CLEAN_APPLE" "as.scpt"               "as-hdr.applescript"    0 "Deny non-Apple languages: AppleScript"
do_test "$CMD_SMUDGE"      "as-hdr.applescript"    "as.scpt"               0 "Smudge AppleScript"
do_test "$CMD_SMUDGE"      "as.applescript"        "as.scpt"               0 "Smudge AppleScript (without header)"
do_test "$CMD_BOTH"        "as.scpt"               "as.scpt"               0 "Pass through AppleScript"

#--| ScriptDebugger tests
do_test "$CMD_CLEAN"       "asdbg.scpt"            "asdbg-hdr.applescript" 1 "Default Deny: forbidden Debugging Mode switched on"
do_test "$CMD_CLEAN_ALL"   "asdbg.scpt"            "asdbg-hdr.applescript" 0 "Allow Debugging Mode switched on"
do_test "$CMD_CLEAN_APPLE" "asdbg.scpt"            "asdbg-hdr.applescript" 1 "Deny non-Apple languages: AppleScript Debugger"
#--|  This can't be tested, because on compile-time, a GUID is inserted in the header. This GUID doesn't seem to be related 
#--|  to «event asDBDBid»... So no easy validation for this one.
#--|  Also, when saving with SD, file-size increases big time, so be aware of this when testing.
#do_test "$CMD_SMUDGE"      "asdbg-hdr.applescript" "asdbg.scpt"            0 "Smudge AppleScript Debugger"
#do_test "$CMD_BOTH"        "asdbg.scpt"            "asdbg.scpt"            0 "Pass through AppleScript Debugger"

#--| JavaScript tests
do_test "$CMD_CLEAN"       "js.scpt"               "js-hdr.javascript"     0 "Clean JavaScript"
do_test "$CMD_CLEAN_NO"    "js.scpt"               "js-hdr.javascript"     0 "Clean JavaScript (--no-header)"
do_test "$CMD_CLEAN_APPLE" "js.scpt"               "js-hdr.javascript"     1 "Deny non-Apple languages: JavaScript"
do_test "$CMD_SMUDGE"      "js-hdr.javascript"     "js.scpt"               0 "Smudge JavaScript"
do_test "$CMD_SMUDGE"      "js.javascript"         "js.scpt"               1 "Smudge AppleScript (without header)"
do_test "$CMD_BOTH"        "js.scpt"               "js.scpt"               0 "Pass through JavaScript"


echo
echo "$TEST_NR tests have ran, $TESTS_OK tested OK, $TESTS_NOK tested NOK and $TESTS_SKIPPED have been skipped."
