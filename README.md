bash-cfg
========

Bash-based configuration value storage and retrieval on the basis of Key Value Map (kvm) structured data.

Configuration values are stored using the provided 'key' in *kvmPut* function calls, and retrieved using *kvmGet* function calls.
To use, source kvm-utils.sh in your bash script

Features
--------
* multiple independent k-v map files
* single and "composite" (list / nested list) values
* values can be 'key refererences', which get resolved in turn to arrive at 'final' (non-reference) values
* resort to 'default' value if no value is found for a key by "truncation" of the provided initial key; i.e., try "parent" key (for example, if no value found for key 'a-b-c', try 'b-c', and finally try 'c')
* fetch one or more values using wildcard (?) key part(s)

Storage
-------
Key-value "pairs" are stored in a file named `/tmp/kv-map.<your k-v map name>`
Each key-value pair occupies its own line in this file.
The first word on each line represents the key (consisting of a dash-separated sequence of key parts), the remainder of each line is the associated value


Usage
-----
* reset / clear a particular k-v map store / file:

  `$ kvmInit <k-v- map name>`

* store a key - value pair:

  `$ kvmPut  <k-v map name> [ <key part 1> ... <key part N> ] <value>`

Note: make sure to separate the '[' and ']' list delimiter chars from the values they enclose by at least one space or tab character.

Some examples of valid values:

| Value                 | Type |
| --------------------- | ---- |
| foo                   | string |
| 42                    | number |
| [ fi fa fo ]          | list   |
| [ x y [ alice bob ] ] | nested list
| [ @ a b ]             | reference to another value as stored with key [ a b ]
| [ [ @ a b ] foo [ @ c d ] ] | a 3 element list, 2 of which are key references to other values

Key parts are composed of alphanumeric characters and can also contain '_' and '.' characters

* retrieve a value for a key:

  `$ kvmGet  <k-v- map name> [ <key part 1> ... <key part N> ]`

A single retrieved value for a key is returned as-is. In case of wildcard key specifications, a *kvmGet* can return multiple values. If this is the case, such values are returned as a list.

Usage - Plain
------------------
Assuming:

 `$ kvmPut my-cfg [ x ]         foo`

 `$ kvmPut my-cfg [ a b c ]     [ fi fa fo ]`

Then:

 `$ kvmGet my-cfg [ x ]       ->   foo`

 `$ kvmGet my-cfg [ a b c ]   ->   [ fi fa fo ]`

Usage - References
------------------
Assuming:

 `$ kvmPut my-cfg [ x ]         foo`

 `$ kvmPut my-cfg [ y ]            [ @ x ]`

 `$ kvmPut my-cfg [ a b c ]        [ [ x ] [ @ x ] [ @ y ] ]`

Then:

 `$ kvmGet my-cfg [ y ]       ->   foo`

 `$ kvmGet my-cfg [ a b c ]   ->   [ [ x ] foo foo ]`


Usage - Resort to Defaults
--------------------------
Assuming:

 `$ kvmPut my-cfg [ c ]            foo`

 `$ kvmPut my-cfg [ b c ]          bar`

 `$ kvmPut my-cfg [ a b c ]        foobar`

Then:

 `$ kvmGet my-cfg [ a b c ]   ->   foobar`

 `$ kvmGet my-cfg [ x b c ]   ->   bar`

 `$ kvmGet mu-cfg [ x y c ]   ->   foo`

 `$ kvmGet my-cfg [ x c ]     ->   foo`

Usage - Wildcard Fetch
----------------------
Assuming:

 `$ kvmPut my-cfg [ x a ]        foo`

 `$ kvmPut my-cfg [ x b ]        bar`

 `$ kvmPut my-cfg [ x c ]        baz`

 `$ kvmPut my-cfg [ y a ]        foobar`

Then:

 `$ kvmGet my-cfg [ x ? ]     -> [ foo bar baz ]`

 `$ kvmGet my-cfg [ y ? ]     -> foobar`

 `$ kvmGet my-cfg [ ? a ]     -> [ foo foobar ]`

*Note: we use '?' as wildcard instead of an asterisk to avoid having to disable standard bash wildcard expansion (e.g., per 'set -f') in scripts using 'kvmGet'*

Implementation Details
----------------------
KVM *init*, *put*, and *get* functions reside in file *kvm-utils.sh*. These functions rely heavily on generic list processing functionality as implemented in file *list-utils.sh*: cons, concat, head, tail, length, reverse, map, fold, etc.

Please find unit tests for both these function sets in *test-kvm-utils.sh* and *test-list-utils.sh* respectively. Simple core unit test utility functions can be found in *test-utils.sh*.

Notice that both kvm and list utility functions are strongly recursive in nature. Performance in Bash is not great, but acceptable as it is expected that kvm configuration functionality is used to prime such constructs as bash variables, construct property files, etc. I.e., appropriate for use as part of "just in time" finalization of the configuration of long-running processes.



> Written with [StackEdit](http://benweet.github.io/stackedit/).