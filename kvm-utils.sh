#!/bin/bash

################################################################################
#
# key-value map based put / get using file storage
#
#
# author: ephoning@gmail.com
#
################################################################################

. ./list-utils.sh

BASE_KV_MAP_NAME="/tmp/kv-map"

WILDCARD_REGEX_PATTERN="[[:alnum:]|_|\.]+"

# start with a fresh key-value map file
# args: <k-v map name>
function kvmInit {
    rm -f $BASE_KV_MAP_NAME.$1
}

# put a key-value pair in the key-value map
# args: <k-v map name> [ <key part 1> ... <key-part N> ] <value>
#
# value          :== <singular value> | [ <value> ... <value N> ]
# singular value :== <number> | string | boolean | <reference>
# reference      :== [ @ <key part 1> ... <key part N> ]
#
function kvmPut {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_PART_LIST=`nth 1 $ARG_LIST`
    # note: use composed key to allow for easy retrieval via 'egrep'
    local KEY=`kvmComposeKey $KEY_PART_LIST`
    local VALUE=`drop 2 $ARG_LIST`
    VALUE=`unlist $VALUE`
    echo "$KEY $VALUE" >> $BASE_KV_MAP_NAME.$KV_MAP_NAME
}

# get a value from the key-value map
# args: <k-v map name> [ <key part 1> ... <key part N> ]
#
function kvmGet {
    _kvmGetFollowRefs $*  # supports ref following and fall back to defaults
}


# get value or values (as list) from the key-value map
# args: <k-v map name> [ <key part 1> ... <key part N> ]
#
function _kvmGetBasic {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_PART_LIST=`nth 1 $ARG_LIST`
    # note: use composed key to allow for easy retrieval via 'egrep'
    local KEY=`kvmComposeKey $KEY_PART_LIST`

    #echo "key: $KEY ---"

    local FOUND=`egrep "^$KEY " $BASE_KV_MAP_NAME.$KV_MAP_NAME`
    local FOUND_LIST=`list $FOUND`
    local KV_PAIR_LIST=`splitIntoPairs $FOUND_LIST`
    local VALUES_LIST=`map [ last @ ] $KV_PAIR_LIST`

    #echo "vals list: $VALUES_LIST ---"

    if [[ `length $VALUES_LIST` -eq 0 ]]; then
	echo ""
    elif [[ `length $VALUES_LIST` -eq 1 ]]; then
	echo `head $VALUES_LIST`
    else
	echo $VALUES_LIST
    fi
}

# get value or values (as list) from the key-value map
# if the value turns out to be a "reference key", then resolve its value in turn
# if no value is found, try "parent" keys instead
#
# note: reference key notation: '[ @ x y z ]'
# (that is: a list of key parts, headed by a reference indicator '@'
#
# usage: kvmGetFollowRefs <kv map name> [ <key part 1> ... <key part N> ]
#
function _kvmGetFollowRefs {
    # usage: kvmGetFollowRefsWithValue <kv map name> <value or values>
    function _kvmGetFollowRefsWithValue {
	local ARG_LIST=`list $*`
	local KV_MAP_NAME=`nth 0 $ARG_LIST`
	local VALUE_OR_VALUES=`nth 1 $ARG_LIST`
	if [[ `isList $VALUE_OR_VALUES` == "true" ]]; then
	    if [[ `head $VALUE_OR_VALUES` == "@" ]]; then
		# resolve reference
		local KEY_PART_LIST=`tail $VALUE_OR_VALUES`
		_kvmGetFollowRefs $KV_MAP_NAME $KEY_PART_LIST
	    else
		# handle a list of values
		map [ _kvmGetFollowRefsWithValue $KV_MAP_NAME @ ] $VALUE_OR_VALUES
	    fi
	else
	    # final value
	    echo $VALUE_OR_VALUES
	fi
    }
    local VALUE_OR_VALUES=`_kvmGetResortToDefault $*`
    local KV_MAP_NAME=$1
    _kvmGetFollowRefsWithValue $KV_MAP_NAME $VALUE_OR_VALUES
}

# functions to truncate a list of key parts
# (used upon 'get' misses to try 'gets' with shorter keys; i.e., "parent" keys)
# 
# (if no value found for key 'a-b-c', try 'a-b', then try 'a')
R_TO_L_KEY_TRUNC_FUNC=dropLast
#
# (if no value found for key 'a-b-c', try 'b-c', then try 'c')
L_TO_R_KEY_TRUNC_FUNC=tail


# get a value or values (as list) from the key-value map
# if no value is found for the full key, attempt retrieval
# on shorter keys or "parent" keys.
#
# args: <k-v map name> [ <key part 1> ... <key part N> ]
function _kvmGetResortToDefault {
    # usage: kvmGetTraverseParentKeys <kv map name> <key truncation func> [ <key part 1> ... <key part N> ]
    function _kvmGetTraverseParentKeys {
	local ARG_LIST=`list $*`
	local KV_MAP_NAME=`nth 0 $ARG_LIST`
	local KEY_TRUNC_FUNC=`nth 1 $ARG_LIST`
	local KEY_PART_LIST=`nth 2 $ARG_LIST`
	local VALUE_OR_VALUES=`_kvmGetBasic $KV_MAP_NAME $KEY_PART_LIST`
	if [ -z "$VALUE_OR_VALUES" ]; then
	    local TRUNC_KEY_PART_LIST=`$KEY_TRUNC_FUNC $KEY_PART_LIST`
	    if [[ "`isEmptyList $TRUNC_KEY_PART_LIST`" == "true" ]]; then
		echo ""
	    else
		_kvmGetTraverseParentKeys $KV_MAP_NAME $KEY_TRUNC_FUNC $TRUNC_KEY_PART_LIST
	    fi
	else
	    echo $VALUE_OR_VALUES
	fi
    }    
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_PART_LIST=`nth 1 $ARG_LIST`
    _kvmGetTraverseParentKeys $KV_MAP_NAME $L_TO_R_KEY_TRUNC_FUNC $KEY_PART_LIST
}



# concatenate first 2 args with the provided join string
function _concatWithWildcardAware {
    local FIRST=$1
    local SECOND=$2
    local JOIN=$3
    if [[ "$SECOND" == "*" ]]; then
	SECOND="$WILDCARD_REGEX_PATTERN"
    fi
    if [[ "$FIRST" == "%nil%" ]]; then
	echo $SECOND
    else
	echo "$FIRST$JOIN$SECOND"
    fi
}
function _concatWith {
    local FIRST=$1
    local SECOND=$2
    local JOIN=$3
    if [[ "$FIRST" == "%nil%" ]]; then
	echo $SECOND
    else
	echo "$FIRST$JOIN$SECOND"
    fi
}

# compose a comma separated string from list elements
# example:
#   commaSeparate [ a b c ] -> a,b,c
#
function commaSeparate {
    function _concatWithComma {
	_concatWith $* ,
    }
    foldLeft _concatWithComma %nil% $*
}

# compose a key from a list of partial key elements
# args: [ <key part 1> ... <key part N> ]
#
# examples:
#   kvmComposeKey [ a b c ] -> a-b-c
#   kvmComposeKey [ a * c ] -> a-[[:alnum:]|_|\.]+-c
#
function kvmComposeKey {
    function _concatWithDash {
	_concatWithWildcardAware $* -
    }
    # note: '%nil%' is seen as "identity" and is discarded
    foldLeft _concatWithDash %nil% $*
}
