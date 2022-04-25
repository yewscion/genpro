#!/usr/bin/env bash
# localtest.sh
#
# This script runs the current project, passing all arguments to the main
# function inside of exe.scm. The purpose is to test the functionality of the
# program before installing in an easy and repeatable way.

timestamp() {
    date --iso-8601=s | sed 's/^/Timestamp: /'
}


logfile="localtest-$(timestamp).log"

echo "------------------------------------"
echo $(timestamp)
echo "Running Local Test. Good Luck!"
echo "------------------------------------"
echo ""
guile -q -l src/main.scm -e main -s src/exe.scm "$@"
echo ""
echo "------------------------------------"
echo "How'd it go?"
