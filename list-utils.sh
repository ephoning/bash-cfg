#!/bin/bash

################################################################################
#
# list utility functions
#
# change log
# ----------
# v1.0         initial version
#
# author: ephoning@gmail.com
#
################################################################################

# convert a space-separated set of values into a list
#  example:
#     list a b c -> [ a b c ]
#
function list {
    echo "[" $* "]"
}

# convert a list into a space-separated set of values
#  $*: list
#
#  example:
#     unlist [ a b c ] -> a b c
#
function unlist {
    local LIST=$*
    local LIST_LEN=`length $LIST`
    local RESULT=""
    local i=0
    for (( ; i<$LIST_LEN; i++ ))
    do
	local ITEM=`nth $i $LIST`
	RESULT="$RESULT $ITEM"
    done
    echo $RESULT
}

# cons item to a list
# example:
#  cons foo [ a b c ] -> [ foo a b c ]
#
#  $1: item
#  $*: list
function cons {
    local ARGS=`list $*`
    local ITEM=`nth 0 $ARGS`
    local LIST=`nth 1 $ARGS`
    local UNLIST=`unlist $LIST`
    echo `list $ITEM $UNLIST`
}

# cons item to the end of a list
# example:
#  cons foo [ a b c ] -> [ a b c foo ]
#
#  $1: item
#  $*: list
function consEnd {
    local ARGS=`list $*`
    local ITEM=`nth 0 $ARGS`
    local LIST=`nth 1 $ARGS`
    local UNLIST=`unlist $LIST`
    echo `list $UNLIST $ITEM`
}

# concatenate 2 lists
# example:
#  concat [ foo bar ] [ a b c ] -> [ foo bar a b c ]
#
#  $1: 1st list
#  $2: 2nd list
function concat {
    local ARGS=`list $*`
    local ONE=`nth 0 $ARGS`
    local TWO=`nth 1 $ARGS`
    if [[ "`isEmptyList $ONE`" == "true" ]]; then
	echo $TWO
    else
	local LAST_ELEMENT=`last $ONE`
	local NEW_ONE=`dropLast $ONE`
	local NEW_TWO=`cons $LAST_ELEMENT $TWO`
	echo `concat $NEW_ONE $NEW_TWO`
    fi
}

# get head of list
function head {
    shift
    # collect
    local RESULT="$1"
    if [ "$1" = "[" ]; then
    	shift
        # track sub-list nesting to avoid prematurely signalling list termination
    	local LEVEL=0
    	until [[ "$1" = "]" && $LEVEL = 0 ]]
    	do
    	    RESULT="$RESULT $1"
    	    if [ "$1" = "[" ]; then
    		LEVEL=$(($LEVEL + 1))
    	    fi
    	    if [ "$1" = "]" ]; then
    		LEVEL=$(($LEVEL - 1))
    	    fi
    	    shift
    	done
    	RESULT="$RESULT ]"
    fi
    echo $RESULT
}

# get tail of list
function tail {
    # drop opening '['
    shift
    # drop 1st element
    if [ "$1" = "[" ]; then
    	shift
    	local LEVEL=0
    	until [[ "$1" = "]" && $LEVEL = 0 ]]
    	do
    	    if [ "$1" = "[" ]; then
    		LEVEL=$(($LEVEL + 1))
    	    fi
    	    if [ "$1" = "]" ]; then
    		LEVEL=$(($LEVEL - 1))
    	    fi
    	    shift
    	done
    fi
    shift
    echo [ $*
}

# list predicate
# NOTE: needs stronger implementation to deal with malformed "lists"
# examples:
#  isList foo -> false
#  isList [ foo ] -> true
#
function isList {
    if [ "$1" == "[" ]; then
	echo true
    else
	echo false
    fi
}

# empty list predicate
# $*:  list
function isEmptyList {
     if [[ "$1" == "[" && "$2" == "]" ]]; then
	echo true
    else
	echo false
    fi
}

# member predicate
# note: currently only works for non-list list elements (i.e. flat lists)
# examples:
#  member a [ a b c ] -> true
#  member x [ a b c ] -> false
#
function isMember {
    local ARGS=`list $*`
    local ITEM=`nth 0 $ARGS`
    local LIST=`nth 1 $ARGS`
    local LIST_LEN=`length $LIST`
    local i=0
    for (( ; i<$LIST_LEN; i++ ))
    do
	local LIST_ITEM=`nth $i $LIST`
	if [ "$ITEM" == "$LIST_ITEM" ]; then
	    echo true
	    return
	fi
    done
    echo false
}
 
# pair "vars" with "values"
# (note: in lieue of "rich/structured types" we use lists (square bracket terminated value sequences
#        bash supports arrays, but we need support for arbitrary nesting, hence our own list type)
# for input and output)
#
#  example:
#  pair [ [ A B N FOO ] [ a b [ 1 2 3 ] foo ] ] -> [ [ A a ] [ B b ] [ N [ 1 2 3 ] ] [ FOO foo ] ] 
#
function pair {
    local VARS=`nth 0 $*`
    #echo VARS: $VARS
    local VALS=`nth 1 $*`
    #echo VALS: $VALS
    local LEN=`length $VARS`
    local RESULT=""
    local v=0
    for (( ; v<$LEN; v++ ))
    do
	local VAR=`nth $v $VARS`
	local VAL=`nth $v $VALS`
	local PAIR=`list $VAR $VAL`
        RESULT="$RESULT $PAIR"
    done
    list $RESULT
}


# extract nth (0-indexed) element from a list
# (note: it can deal with arbitrarily deeply nested lists)
#  $1: index (0-based)
#  $*: list
#
#  examples:
#     nth 4 [ a b c d e f ] -> e
#     nth 2 [ a b [ c d ] e ] -> [ c d ]
#     nth 3 [ a b c [ foo [ bar barfoo ] ] e ] -> [ foo [ bar barfoo ] ]
#
function nth {
    local IDX=$1
    # drop idx
    shift
    if [ $IDX = 0 ]; then
	echo `head $*`
    else
	IDX=$(($IDX - 1))
	local TAIL=`tail $*`
	echo `nth $IDX $TAIL`
    fi
}

# determine length of list
#  $*: list
#  examples:
#     length [ a b c d e f ] -> 6
#     length [ a b [ c d ] e ] -> 4
#     length [ a b c [ foo [ bar barfoo ] ] e ] -> 5
#
function length {
    if [[ "`isList $*`" == "false" ]]; then
	echo "cannot determine length of non-list: $*"
    elif [[ "`isEmptyList $*`" == "true" ]]; then
	echo 0
    else
	local TAIL=`tail $*`
	echo $((1 + `length $TAIL`))
    fi
}

# get the last element of a list
# $*: list
# examples:
#    last [ a b c ] -> c
#    last [ a b [ c ] ] -> [ c ]
#
function last {
    local LENGTH=`length $*`
    local LAST_IDX=$(($LENGTH - 1))
    echo `nth $LAST_IDX $*`
}

# remove a pair with key matching argument from a list of pairs
# arglist:
#  0: key id
#  rest: pairs list
function removePairByKey {
    local KEY_VAL=`head $*`
    local TAIL=`tail $*`
    local KVPAIRSLIST=`unlist $TAIL`
    local RESULT="[ ]"
    local KVPAIRSLIST_LEN=`length $KVPAIRSLIST`
    local i=0
    for (( ; i<$KVPAIRSLIST_LEN; i++ ))
    do
	local KVPAIR=`nth $i $KVPAIRSLIST`
	local KEY=`head $KVPAIR`
	if [ ! "$KEY" == "$KEY_VAL" ]; then
	    RESULT=`cons $KVPAIR $RESULT`
	fi
    done
    echo $RESULT    
}

# drop first n elements of a list
# argslist:
#  $1: n
#  $*: list
function drop {
    local N=$1
    shift
    local LIST=$*
    for (( i=0; i<$N; i++ ))
    do
	LIST=`tail $LIST`
    done
    echo $LIST
}

# drop last element of a list
# argslist:
# $*: list
function dropLast {
    if [[ "`isEmptyList $*`" == "true" ]]; then
	echo "[ ]"
    else
	local LEN=`length $*`
	if [ $LEN = 1 ]; then
	    echo "[ ]"
	else
	    local HEAD=`head $*`
	    local TAIL=`tail $*`
	    local REST=`dropLast $TAIL`
	    echo `cons $HEAD $REST`
	fi
    fi
}

# reverse a list
# argslist:
# $*: list
# examples:
#    reverse [ a b c ] -> [ c b a ]
function reverse {
    local LIST=$*
    local ACCU="[ ]"
    function _reverse {
	local ARGS="[ $* ]"
	local LIST=`nth 0 $ARGS`
	local ACCU=`nth 1 $ARGS`
	if [[ "`isEmptyList $LIST`" == "true" ]]; then
	    echo $ACCU
	else
	    local ELEMENT=`head $LIST`
	    local NEW_LIST=`tail $LIST`
	    local NEW_ACCU=`cons $ELEMENT $ACCU`
	    echo `_reverse $NEW_LIST $NEW_ACCU`
	fi
    }
    echo `_reverse $LIST $ACCU`
}


# compare 2 lists for equality
# argslist:
# $*: both lists
#
# examples:
#   isEqLists [ 1 2 3 ] [ 1 2 3 ] -> true
#   isEqLists [ 1 2 4 ] [ 1 2 3 ] -> false
function isEqLists {
    local LISTS=`list $*`
    local A=`nth 0 $LISTS`
    local B=`nth 1 $LISTS`

    if [[ `isList $A` == "true" && `isList $B` == "true" ]]; then
	# check for empty lists
	local AE=`isEmptyList $A`
	local BE=`isEmptyList $B`
	if [[ $AE == "true" && $BE == "true" ]]; then
	    echo true
	elif [[ $AE == "true" || $BE == "true" ]]; then
	    echo false
	else
	    # compare heads
	    local HA=`head $A`
	    local HB=`head $B`
	    local HEQ=`isEqLists $HA $HB`
	    if [[ $HEQ == "true" ]]; then
		# compare tails
		local TA=`tail $A`
		local TB=`tail $B`
		echo `isEqLists $TA $TB`
	    else
		echo false
	    fi
	fi
    else
	if [[ `isList $A` == "true" || `isList $B` == "true" ]]; then
	    echo false
	else
	    if [[ $A == $B ]]; then
		echo true
	    else
		echo false
	    fi
	fi
    fi
}




# invoke a cmnd/func on a list of arguments, splicing in an argument at the desired location in
# the cmnd/function string, and collecting the results into a list that is returned to the caller
# the following arg pattern is expected:
#   '[' cmnd/func-name <args list containing zero or more '@' chars.> ']' <list of instances to substitute for '@' args>
#
# examples:
#    map [ touppercase @ ] [ a b c ] -> [ A B C ]
#    map [ list @ ] [ a b c ] -> [ [ a ] [ b ] [ c ] ]
#
function map {
    function _map {
	local PREFUNC_LIST=`nth 0 $*`
	local ARG_LIST=`nth 1 $*`
	local ACCU_LIST=`nth 2 $*`
	
	if [[ "`isEmptyList $ARG_LIST`" == "true" ]]; then
	    echo `reverse $ACCU_LIST`
	else
	    local ARG=`head $ARG_LIST`
	    local REMAINING_ARG_LIST=`tail $ARG_LIST`
	    local PREFUNC=`unlist $PREFUNC_LIST`
	    local FUNC=${PREFUNC//@/$ARG}
	    local RESULT=`$FUNC`
	    local NEW_ACCU_LIST=`cons $RESULT $ACCU_LIST`
	    echo `_map [ $PREFUNC_LIST $REMAINING_ARG_LIST $NEW_ACCU_LIST ]`
	fi
    }
    echo `_map [ $* [ ] ]`
}


# invoke a 2-arg cmd/function on a list of arguments and a base value
# args:
#   $1: function>
#   $2: base value
#   rest: argument list
#
# examples:
#   foldLeft concatwithdash . [ a b c ] -> a-b-c   #(assumes 'concatwithdash' treats '.' as identity value)
#   foldLeft sum 0 [ 1 2 3 ] -> 6                  #(note: '0' is identity value for addition)
#
function foldLeft {
    function _foldLeft {
	local FUNC=`nth 0 $*`
	local RESULT=`nth 1 $*`
	local ARG_LIST=`nth 2 $*`
	
	if [[ "`isEmptyList $ARG_LIST`" == "true" ]]; then
	    echo $RESULT
	else
	    local ARG=`head $ARG_LIST`
	    local REMAINING_ARG_LIST=`tail $ARG_LIST`
	    local NEW_RESULT=`$FUNC $RESULT $ARG`
	    echo `_foldLeft [ $FUNC $NEW_RESULT $REMAINING_ARG_LIST ]`
	fi
    }
    echo `_foldLeft [ $* ]`
}



