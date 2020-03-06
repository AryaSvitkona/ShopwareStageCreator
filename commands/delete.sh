#!/bin/bash

function promptDeleteStage(){

    #check if logfile exists ex. from previous runnings
    logFile="$shopDir/log.txt"

    if  [[ -f "${logFile}" ]]; then
        rm -f ${logFile}
    fi

    #create logfile
    touch ${logFile}
    #set starttime
    timestamp >> ${logFile}
    #set log entry with connected username
    echo "You're connected as ==> " $USER >> ${logFile}

    collectStageCredentials

    deleteInstance=${deleteInstance:-$(promptYesOrNo "Are you sure? This will delete the whole stage instance in ${warn}$shopDir/stage${reset} and clear database ${warn}${Db_Database_Stage}${reset}! (y/N)" 'n')}
    if [ ${deleteInstance} = "n" ]; then
        echo "You've choosen - no" >> ${logFile}
        echo -e "\n${lightGreen}Not touching the stage instance, have fun!${reset}\n"
        exit 0;
    else
        echo "You've choosen - yes" >> ${logFile}
        eraseStageDatabase
        deleteStage
        if [ $? -eq 0 ]; then
            echo -e "\n${lightGreen}Your instance was deleted. Now have a coffee!${reset}\n"
            exit 0
        else
            echo "Error while delete stage" >> ${logFile}
            exit 1
        fi
    fi
}
