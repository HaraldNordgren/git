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
HASH3=
HASH4=
HASH5=
HASH6=
HASH7=
HASH8=
HASH9=
HASH10=
HASH11=

test_expect_success 'set up basic repo with 3 files and 3 merge commits' '
     add_line_into_file "hej" hej &&
     git commit --amend --date="Wed Feb 16 14:00 2011 +0100" &&
     HASH1=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hej" hej &&
     git commit --amend --date="Wed Feb 17 14:00 2011 +0100" &&
     HASH2=$(git rev-parse --verify HEAD) &&

     git checkout -b branch1 &&
     add_line_into_file "hej" hej1 &&
     git commit --amend --date="Wed Feb 18 14:00 2011 +0100" &&
     HASH3=$(git rev-parse --verify HEAD) &&

     git checkout master &&
     git checkout -b branch2 &&
     add_line_into_file "hej" hej2 &&
     git commit --amend --date="Wed Feb 19 14:00 2011 +0100" &&
     HASH4=$(git rev-parse --verify HEAD) &&

     git checkout master &&
     git checkout -b branch3 &&
     add_line_into_file "hej" hej3 &&
     git commit --amend --date="Wed Feb 20 14:00 2011 +0100" &&
     HASH5=$(git rev-parse --verify HEAD) &&

     git checkout master &&
     git merge branch1 --no-edit --no-ff &&
     HASH6=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hej" hej &&
     git commit --amend --date="Wed Feb 22 14:00 2011 +0100" &&
     HASH7=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hej" hej &&
     git commit --amend --date="Wed Feb 23 14:00 2011 +0100" &&
     HASH8=$(git rev-parse --verify HEAD) &&

     git merge branch2 --no-edit --no-ff &&
     HASH9=$(git rev-parse --verify HEAD) &&

     git merge branch3 --no-edit --no-ff &&
     HASH10=$(git rev-parse --verify HEAD) &&

     add_line_into_file "hej" hej &&
     git commit --amend --date="Wed Feb 24 14:00 2011 +0100" &&
     HASH11=$(git rev-parse --verify HEAD)
'

test_expect_success 'bisect skip: successful result' '
	git bisect reset &&
	git bisect start HEAD $HASH1 --merges-only &&
	git bisect good &&
	git bisect good &&
	git bisect bad > my_bisect_log.txt &&
	grep "$HASH10 is the first bad merge" my_bisect_log.txt
'

test_done
