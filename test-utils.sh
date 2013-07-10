#!/bin/bash

################################################################################
#
# test utility functions
#
# change log
# ----------
# v1.0         initial version
#
# author: ephoning@gmail.com
#
################################################################################

SUCCEEDED_TEST_COUNT=0
FAILED_TEST_COUNT=0

# expect a certain result
# $1: expression to evaluate
# $2: expected result
#
function expect {
    EXPR="$1"
    EXPECTED_RESULT="$2"
    #set -f  # disable wildcard expansion (i.e., retain '*' in $EXPR)
    RESULT=`$EXPR`
    #set +f  # enable wildcard expansion
    if [[ "$RESULT" == "$EXPECTED_RESULT" ]]; then
	echo "'$EXPR' TEST SUCCEEDED"
	SUCCEEDED_TEST_COUNT=$(($SUCCEEDED_TEST_COUNT + 1))
    else
	echo "'$EXPR' TEST FAILED: EXPECTED: '$EXPECTED_RESULT', BUT GOT: '$RESULT'"
	FAILED_TEST_COUNT=$(($FAILED_TEST_COUNT + 1))
    fi
}

function testReport {
    echo
    echo "----- Test results -----"
    echo "Number of succeeded tests: $SUCCEEDED_TEST_COUNT"
    echo "Number of failed tests:    $FAILED_TEST_COUNT"
}
