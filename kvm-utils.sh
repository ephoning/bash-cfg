#!/bin/bash

################################################################################
#
# key-value map using file storage
#
# change log
# ----------
# v1.0         initial version
#
# author: ephoning@gmail.com
#
################################################################################

. ./list-utils.sh

BASE_KV_MAP_NAME="/tmp/kv-map"

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
    # note: use composed key to allow for easy retrieval via 'grep'
    local KEY=`kvmComposeKey $KEY_PART_LIST`
    local VALUE=`drop 2 $ARG_LIST`
    VALUE=`unlist $VALUE`
    echo "$KEY $VALUE" >> $BASE_KV_MAP_NAME.$KV_MAP_NAME
}

# get a value from the key-value map
# args: <k-v map name> [ <key part 1> ... <key part N> ]
#
function kvmGet {
    #_kvmGetBasic $*      # obsolete; only supports basic value retrieval
    _kvmGetFollowRefs $*  # supports ref following and fall back to defaults
}


# get a value from the key-value map
# args: <k-v map name> [ <key part 1> ... <key part N> ]
#
function _kvmGetBasic {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_PART_LIST=`nth 1 $ARG_LIST`
    # note: use composed key to allow for easy retrieval via 'grep'
    local KEY=`kvmComposeKey $KEY_PART_LIST`
    local LINE=`grep "^$KEY " $BASE_KV_MAP_NAME.$KV_MAP_NAME`
    local LINE_AS_LIST=`list $LINE`
    local VALUE_AS_LIST=`tail $LINE_AS_LIST`
    echo `head $VALUE_AS_LIST`
}

# get a value from the key-value map
# if the value turns out to be a "reference key", then resolve its value in turn
# if no value is found, try "parent" keys instead
#
# note: reference key notation: '[ @ x y z ]'
# (that is: a list of key parts, headed by a reference indicator '@'
#
# usage: kvmGetFollowRefs <kv map name> [ <key part 1> ... <key part N> ]
#
function _kvmGetFollowRefs {
    #local VALUE=`_kvmGetBasic $*` # obsolete; use 'resort to default' instead
    local VALUE=`_kvmGetResortToDefault $*`
    local KV_MAP_NAME=$1
    echo `_kvmGetFollowRefsWithValue $KV_MAP_NAME $VALUE`
}
#
# usage: kvmGetFollowRefsWithValue <kv map name> <value>
#
function _kvmGetFollowRefsWithValue {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local VALUE=`nth 1 $ARG_LIST`
    if [[ `isList $VALUE` == "true" ]]; then
	if [[ `head $VALUE` == "@" ]]; then
	    # resolve reference
	    local KEY_PART_LIST=`tail $VALUE`
	    echo `_kvmGetFollowRefs $KV_MAP_NAME $KEY_PART_LIST`
	else
	    # handle a list of values
	    echo `map [ _kvmGetFollowRefsWithValue $KV_MAP_NAME @ ] $VALUE`
	fi
    else
	# final value
	echo $VALUE
    fi
}

# functions to truncate a list of key parts
# (used upon 'get' misses to try 'gets' with shorter keys; i.e., "parent" keys)
# 
# (if no value found for key 'a-b-c', try 'a-b', then try 'a')
R_TO_L_KEY_TRUNC_FUNC=dropLast
#
# (if no value found for key 'a-b-c', try 'b-c', then try 'c')
L_TO_R_KEY_TRUNC_FUNC=tail

# get a value from the key-value map
# if no value is found for the full key, attempt retrieval
# on shorter keys or "parent" keys.
#
# args: <k-v map name> [ <key part 1> ... <key part N> ]
function _kvmGetResortToDefault {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_PART_LIST=`nth 1 $ARG_LIST`
    _kvmGetTraverseParentKeys $KV_MAP_NAME $L_TO_R_KEY_TRUNC_FUNC $KEY_PART_LIST
}
#
# usage: kvmGetTraverseParentKeys <kv map name> <key truncation func> [ <key part 1> ... <key part N> ]
#
function _kvmGetTraverseParentKeys {
    local ARG_LIST=`list $*`
    local KV_MAP_NAME=`nth 0 $ARG_LIST`
    local KEY_TRUNC_FUNC=`nth 1 $ARG_LIST`
    local KEY_PART_LIST=`nth 2 $ARG_LIST`
    local VALUE=`_kvmGetBasic $KV_MAP_NAME $KEY_PART_LIST`
    if [ -z "$VALUE" ]; then
	local TRUNC_KEY_PART_LIST=`$KEY_TRUNC_FUNC $KEY_PART_LIST`
	if [[ "`isEmptyList $TRUNC_KEY_PART_LIST`" == "true" ]]; then
	    echo ""
	else
	    echo `_kvmGetTraverseParentKeys $KV_MAP_NAME $KEY_TRUNC_FUNC $TRUNC_KEY_PART_LIST`
	fi
    else
	echo $VALUE
    fi
}    

# compose a key from a list of partial key elements
# args: [ <key part 1> ... <key part N> ]
#
# example:
#   kvmComposeKey [ a b c ] -> a-b-c
#
function kvmComposeKey {
    # note: '." is seen as "identity" and is discarded
    function _concatwithdash {
	if [[ "$1" == "." ]]; then
	    echo $2
	else
	    echo "$1-$2"
	fi
    }
    echo `foldLeft _concatwithdash . $*`
}
