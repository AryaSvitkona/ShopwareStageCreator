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
    cat "${scriptPath}/files/banner.txt"
}

function createLogEntry() {
    date -u >> $logFile
    echo $1 | tee -a $logFile
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
        createLogEntry "Tests successfully passed - all commands available"
    fi
}

# function to test command and writes exception into logfile
function testCommand() {
    if ! [ -x "$(command -v $1)" ]; then
      createLogEntry "Error: $1 is not installed or inaccessible."
    fi
}

# checks shopware installation and its major version (sw5 or sw6)
# output string "SW5" or "SW6" or "unknow"
function shopwareCheck() {
    if [ -f "${shopDir}/shopware.php" ]; then

        if [ -d "${shopDir}/vendor/shopware/shopware" ]; then
            swMajorVersion="SW5"
        else
            swMajorVersion="unknow"
            createLogEntry "${swMajorVersion} instance found"
            exit 1
        fi

    elif [ -d "${shopDir}/vendor/shopware/platform" ]; then
        swMajorVersion="SW6"

    else
        swMajorVersion="unknow"
        createLogEntry "${swMajorVersion} instance found"
        exit 1
    fi

    createLogEntry "${swMajorVersion} instance found"
}

# checks if shopware configuration exists
function configCheck() {
    if [ "${swMajorVersion}" = "SW5" ];then

        if [ -f "${shopDir}/config.php" ]; then
            if [ -f "${shopDir}/.env" ]; then
                createLogEntry "Config.php and .env file found"
                exit 1
            fi
            shopConfigFile="${shopDir}/config.php";

        elif [ -f "${shopDir}/.env" ]; then
            shopConfigFile="${shopDir}/.env";
        else
            createLogEntry "No configuration file found"
            exit 1
        fi
        createLogEntry "Configuration file located at ${shopConfigFile}"
    fi

    if [ "${swMajorVersion}" = "SW6" ];then
        if [ -f "${shopDir}/.env" ]; then
            shopConfigFile="${shopDir}/.env";
            createLogEntry "Configuration file located at ${shopConfigFile}"
        else
            createLogEntry "No configuration file found"
            exit 1
        fi

    fi

}
