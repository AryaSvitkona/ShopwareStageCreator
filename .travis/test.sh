#!/bin/sh

function logEntry() {
     date -u >> $logFile
     echo $1 >> $logFile
}

# runs all nessesary commands and quit if commands not available
function initialTest() {

    echo "Test if all nessesary commands are installed and accessible"

    testCommand php
    testCommand mysql
    testCommand mysqldump
    testCommand rsync
    testCommand sed
    testCommand awk
    testCommand grep
    testCommand chmod
    testCommand rm
    testCommand curl
    testCommand dirname
    testCommand mkdir
    testCommand date
}

# function to test command and writes exception into logfile
function testCommand() {
    if ! [ -x "$(command -v $1)" ]; then
      logEntry "Error: $1 is not installed or inaccessible."
    fi
}

initialTest
