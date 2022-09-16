#!/usr/bin/env bash
# localtest.sh
#
# This script runs the current project, passing all arguments to the main
# function inside of exe.scm. The purpose is to test the functionality of the
# program before installing in an easy and repeatable way.

timestamp() {
    date --iso-8601=s 
}
genprocmd() {
    guile -q -l ../cdr255/genpro.scm -e main -s ../bin/genpro.in "$@"
}

if [ $(basename $PWD) = "sandbox" ]
then
    echo "------------------------------------"
    echo ""
    echo $(timestamp)
    echo ""
    echo "Running Local Test. Good Luck!"
    echo "------------------------------------"
    echo ""
    genprocmd "$@"
    exit
    echo ""
    echo "------------------------------------"
    echo "How'd it go?"
else
    echo "Please run ../localtesh.sh from the /sandbox directory!"
fi
