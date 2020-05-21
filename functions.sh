#!/bin/sh

# colors for notification output
# inspired by https://github.com/shyim/shopware-docker
# for more information visit:
# http://www.andrewnoske.com/wiki/Bash_-_adding_color

esc=$(printf '\033')
reset="${esc}[0m"
yellow="${esc}[33m"
blue="${esc}[34m"
green="${esc}[32m"
lightGreen="${esc}[92m"
red="${esc}[31m"
bold="${esc}[1m"
warn="${esc}[41m${esc}[97m"


# set colors and output banner
function banner() {
    echo "${blue}"
    cat "${scriptPath}/files/banner.txt"
    echo "${reset}"
}

function logEntry() {
    date -u >> $logFile
    echo $1 >> $logFile
}

# runs all nessesary commands and quit if commands not available
function initialTest() {
    echo "${yellow}"
    echo "Tests if all nessesary commands are installed and accessible"
    echo "${reset}"

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

# checks if logfile contains errors and returns to console
    if [ -s ${logFile} ]; then
        cat ${logFile}
        exit 1
    else
        echo "${green}"
        echo "All commands available"
        echo "${reset}"
    fi
}

# function to test command and writes exception into logfile
function testCommand() {
    if ! [ -x "$(command -v $1)" ]; then
      logEntry "Error: $1 is not installed or inaccessible."
    fi
}
