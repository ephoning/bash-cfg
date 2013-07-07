#!/bin/bash

################################################################################
#
# test list utility functions
#
#
# author: ephoning@gmail.com
#
################################################################################

. ./list-utils.sh
. ./test-utils.sh

LIST1="[ a b c ]"
LIST2="[ b c d ]"
LIST3="[ [ x ] y z ]"
LIST4="[ [ [ x ] ] [ y z ] a b c ]" 

echo ===== list =====
expect "list a b c" "$LIST1"
expect "list [ [ x ] ] [ y z ] a b c" "$LIST4"

echo ===== un-list =====
expect "unlist $LIST1" "a b c"
expect "unlist $LIST3" "[ x ] y z"

echo ===== cons =====
expect "cons a $LIST2" "[ a b c d ]"
expect "cons $LIST1 $LIST2" "[ [ a b c ] b c d ]"


echo ===== consEnd =====
expect "consEnd a $LIST2" "[ b c d a ]"

echo ===== concat =====
expect "concat $LIST1 $LIST2" "[ a b c b c d ]"
expect "concat [ ] [ a b c ]" "[ a b c ]"
expect "concat [ a b c ] [ ]" "[ a b c ]"

echo ===== head ====
expect "head $LIST1" a
expect "head $LIST3" "[ x ]"
expect "head $LIST4" "[ [ x ] ]"

echo ===== tail =====
expect "tail $LIST1" "[ b c ]"
expect "tail $LIST4" "[ [ y z ] a b c ]"
expect "tail [ a ]" "[ ]"

echo ===== isList =====
expect "isList $LIST1" true
expect "isList $LIST4" true
expect "isList 42" false

echo ===== isEmptyList =====
expect "isEmptyList [ ]" true
expect "isEmptyList $LIST1" false

echo ===== isMember ====
expect "isMember a $LIST1" true
expect "isMember b $LIST1" true
expect "isMember c $LIST1" true
expect "isMember d $LIST1" false
expect "isMember a $LIST4" true
expect "isMember [ y z ] $LIST4" true

echo ===== pair =====
echo !!! NO TESTS YET !!!

echo ===== nth =====
expect "nth 0 $LIST1" a
expect "nth 0 $LIST3" "[ x ]"

echo ===== length =====
expect "length $LIST1" 3
expect "length $LIST3" 3
expect "length $LIST4" 5

echo ===== last =====
expect "last $LIST1" c
expect "last [ a b [ c ] ]" "[ c ]"


echo ===== removePairByKey=====
echo !!! NO TESTS YET !!!

echo ===== drop ====
expect "drop 0 $LIST1" "$LIST1"
expect "drop 1 $LIST1" "[ b c ]"
expect "drop 2 $LIST1" "[ c ]"

echo ===== dropLast =====
expect "dropLast $LIST1" "[ a b ]"
expect "dropLast $LIST3" "[ [ x ] y ]"

echo ===== reverse =====
expect "reverse [ ]" "[ ]"
expect "reverse [ a ]" "[ a ]"
expect "reverse [ a b c ]" "[ c b a ]"
expect "reverse [ a b [ c ] ]" "[ [ c ] b a ]"

echo ====== isEqLists ====
expect "isEqLists $LIST1 $LIST1" true
expect "isEqLists $LIST1 $LIST2" false
expect "isEqLists $LIST3 $LIST3" true
expect "isEqLists $LIST4 $LIST4" true

echo ===== map =====
expect "map [ list @ ] [ a b c ]" "[ [ a ] [ b ] [ c ] ]"
function double {
    echo "$*$*"
}
expect "map [ double @ ] [ a b c ]" "[ aa bb cc ]"

echo ===== foldLeft =====
# note: '." is seen as "identity" and is discarded
function concatwithdash {
    if [[ "$1" == "." ]]; then
	echo $2
    else
	echo "$1-$2"
    fi
}
expect "foldLeft concatwithdash . [ a b c ]" "a-b-c"

function sum { echo $(($1 + $2)); }
expect "foldLeft sum 0 [ 1 2 3 ]" "6"

echo ===== splitIntoPairs =====
expect "splitIntoPairs [ a b c d e f ]" "[ [ a b ] [ c d ] [ e f ] ]"

testReport
