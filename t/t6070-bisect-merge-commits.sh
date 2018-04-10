#!/bin/sh
#
# Copyright (c) 2018 Harald Nordgren
#
test_description='Tests git bisect merge commit functionality'

exec </dev/null

. ./test-lib.sh

add_line_into_file()
{
    _line=$1
    _file=$2

    if [ -f "$_file" ]; then
        echo "$_line" >> $_file || return $?
        MSG="Add <$_line> into <$_file>."
    else
        echo "$_line" > $_file || return $?
        git add $_file || return $?
        MSG="Create file <$_file> with <$_line> inside."
    fi

    test_tick
    git commit --quiet -m "$MSG" $_file
}

HASH1=
HASH2=

test_expect_success 'set up basic repo with 3 files and 3 merge commits' '
     add_line_into_file "hello" hello &&
     HASH1=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hello" hello &&

     git checkout -b branch1 &&
     add_line_into_file "hello" hello1 &&

     git checkout master &&
     git checkout -b branch2 &&
     add_line_into_file "hello" hello2 &&

     git checkout master &&
     git checkout -b branch3 &&
     add_line_into_file "hello" hello3 &&

     git checkout master &&
     git merge branch1 --no-edit --no-ff &&

     add_line_into_file "hello" hello &&

     add_line_into_file "hello" hello &&

     git merge branch2 --no-edit --no-ff &&

     git merge branch3 --no-edit --no-ff &&
     HASH2=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hello" hello
'

test_expect_success 'bisect skip: successful result' '
	test_when_finished git bisect reset &&
	git bisect reset &&
	git bisect start HEAD $HASH1 --merges-only &&
	git bisect good &&
	git bisect good &&
	git bisect bad > my_bisect_log.txt &&
	grep "$HASH2 is the first bad merge" my_bisect_log.txt
'

test_done
