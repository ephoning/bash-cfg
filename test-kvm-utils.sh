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
. ./kvm-utils.sh
. ./test-utils.sh

echo "===== _kvmInit ====="
kvmInit test

echo "===== _kvmPut ====="
kvmPut test [ b c ] foobar
kvmPut test [ a b c ] foo
kvmPut test [ d e f ] [ foo bar baz ]
kvmPut test [ x y z ] [ @ a b c ]
kvmPut test [ m n o ] [ @ q b c ]
kvmPut test [ u v w ] [ [ @ a b c ] [ @ d e f ] ]
kvmPut test [ i j k ] [ [ @ a b c ] [ @ d e f ] [ @ x y z ] ]
kvmPut test [ q ] [ [ @ x b c ] [ @ d e f ] [ a b c ] [ @ a b c ] ]

echo "===== _kvmGetBasic ====="
expect "_kvmGetBasic test [ a b c ]"    "foo"
expect "_kvmGetBasic test [ d e f ]"    "[ foo bar baz ]"
expect "_kvmGetBasic test [ x y z ]"    "[ @ a b c ]"
expect "_kvmGetBasic test [ u v w ]"    "[ [ @ a b c ] [ @ d e f ] ]"

kvmPut test [ x a ] foo
kvmPut test [ x b ] bar
kvmPut test [ x c ] baz
kvmPut test [ y a ] foobar
expect "_kvmGetBasic test [ x ? ]"    "[ foo bar baz ]"
expect "_kvmGetBasic test [ ? a ]"    "[ foo foobar ]"
expect "_kvmGetBasic test [ ? b ]"    "bar"

expect "kvmGet test [ x ? ]"    "[ foo bar baz ]"
expect "kvmGet test [ ? a ]"    "[ foo foobar ]"
expect "kvmGet test [ ? b ]"    "bar"


kvmPut test [ v aa x ] foo
kvmPut test [ v bb x ] bar
kvmPut test [ v cc x ] baz
kvmPut test [ w aa x ] foobar

expect "kvmGet test [ v ? ? ]"     "[ foo bar baz ]"
expect "kvmGet test [ ? aa ? ]"    "[ foo foobar ]"
expect "kvmGet test [ ? bb ? ]"    "bar"

echo "===== _kvmGetResortToDefault ====="
expect "_kvmGetResortToDefault test [ a b c ]"    "foo"
expect "_kvmGetResortToDefault test [ x b c ]"    "foobar"
expect "_kvmGetResortToDefault test [ m n o ]"    "[ @ q b c ]"

echo "===== _kvmGetFollowRefs ====="
expect "_kvmGetFollowRefs test [ a b c ]"    "foo"
expect "_kvmGetFollowRefs test [ d e f ]"    "[ foo bar baz ]"
expect "_kvmGetFollowRefs test [ x y z ]"    "foo"
expect "_kvmGetFollowRefs test [ u v w ]"    "[ foo [ foo bar baz ] ]"
expect "_kvmGetFollowRefs test [ i j k ]"    "[ foo [ foo bar baz ] foo ]"

expect "_kvmGetFollowRefs test [ m n o ]"    "foobar"
expect "_kvmGetFollowRefs test [ q ]"        "[ foobar [ foo bar baz ] [ a b c ] foo ]"

echo "===== kvmGet ====="
expect "kvmGet test [ m n o ]"    "foobar"
expect "kvmGet test [ q ]"        "[ foobar [ foo bar baz ] [ a b c ] foo ]"

echo "===== commaSeparate ==="
expect "commaSeparate [ foo bar baz ]" "foo,bar,baz"

testReport
