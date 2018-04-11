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

create_merge_commit()
{
    _branch=$1
    _file=$2

     git checkout -b $_branch &&
     add_line_into_file "hello" $_file &&
     git checkout master &&
     git merge $_branch --no-edit --no-ff
}

HASH1=
HASH2=
HASH3=
HASH4=
HASH5=
HASH6=

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
    HASH2=$(git rev-parse --verify HEAD) &&

    add_line_into_file "hello" hello &&
    add_line_into_file "hello" hello &&
    git merge branch2 --no-edit --no-ff &&
    git merge branch3 --no-edit --no-ff &&
    HASH3=$(git rev-parse --verify HEAD) &&

    add_line_into_file "hello" hello &&
    HASH4=$(git rev-parse --verify HEAD) &&

    create_merge_commit branch4 hello4 &&
    create_merge_commit branch5 hello5 &&
    create_merge_commit branch6 hello6 &&
    create_merge_commit branch7 hello7 &&
    create_merge_commit branch8 hello8 &&
    create_merge_commit branch9 hello9 &&
    create_merge_commit branch10 hello10 &&
    create_merge_commit branch11 hello11 &&
    create_merge_commit branch12 hello12 &&
    create_merge_commit branch13 hello13 &&
    create_merge_commit branch14 hello14 &&
    create_merge_commit branch15 hello15 &&
    create_merge_commit branch16 hello16 &&
    HASH5=$(git rev-parse --verify HEAD) &&

    create_merge_commit branch17 hello17 &&
    create_merge_commit branch18 hello18 &&
    create_merge_commit branch19 hello19 &&
    create_merge_commit branch20 hello20 &&
    HASH6=$(git rev-parse --verify HEAD)
'

test_expect_success 'bisect skip: successful result' '
	test_when_finished git bisect reset &&
	git bisect reset &&
	git bisect start $HASH4 $HASH1 --merges-only &&
	git bisect good &&
	git bisect good &&
	git bisect bad > my_bisect_log.txt &&
	grep "$HASH3 is the first bad merge" my_bisect_log.txt
'

test_expect_success 'bisect skip: successful result' '
	test_when_finished git bisect reset &&
	git bisect reset &&
	git bisect start $HASH6 $HASH2 --merges-only &&
	git bisect good &&
	git bisect good &&
	git bisect bad &&
	git bisect bad > my_bisect_log.txt &&
	grep "$HASH5 is the first bad merge" my_bisect_log.txt
'

test_done
