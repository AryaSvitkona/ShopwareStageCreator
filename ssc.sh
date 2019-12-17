#!/bin/bash
#
#  _____ _                    _____                _
# / ____| |                  / ____|              | |
# | (___ | |_ __ _  __ _  ___| |     _ __ ___  __ _| |_ ___  _ __
# \___ \| __/ _` |/ _` |/ _ \ |    | '__/ _ \/ _` | __/ _ \| '__|
# ____) | || (_| | (_| |  __/ |____| | |  __/ (_| | || (_) | |
#|_____/ \__\__,_|\__, |\___|\_____|_|  \___|\__,_|\__\___/|_|
#                 __/ |
#                |___/
#
# Version 1.0
# Author: Stefano Rutishauser
# Description: Creates shop copy of a working Shopware 5.X
# instance into stage subfolder.

#set working directory as variable
scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"
shopDir=$scriptPath/..

if [[ ! -f "${shopDir}/shopware.php" ]]; then
    echo "Package not placed inside Shopware project, shopware.php missing."
    exit
fi

source "${scriptPath}/functions.sh"

banner

COLUMNS=12
echo "======================"
printf 'Choose an action \n'
echo "======================"
options=("Create new stage" "Update existing stage" "Delete existing stage" "Exit")
select opt in "${options[@]}"
do
    case $opt in
        "Create new stage")
            context='create'
            echo ${lightGreen}Choosen \"Create new stage\" ${reset}
            source ${scriptPath}/commands/${context}.sh
            createStage
            break
            ;;
        "Update existing stage")
            context='update'
            echo ${blue}Choosen \"Update existing stage\" ${reset}
            break
            ;;
        "Delete existing stage")
            context='delete'
            echo ${red}Choosen \"Delete existing stage\" ${reset}
            source ${scriptPath}/commands/${context}.sh
            promptDeleteStage
            break
            ;;
        "Exit")
            break
            ;;
        *) echo "invalid option ${REPLY}";;
    esac
done
