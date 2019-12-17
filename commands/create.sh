#!/bin/bash

function createStage()
{
  #check if logfile exists ex. from previous runnings
  logFile="$shopDir/log.txt"

  if  [[ -f "${logFile}" ]]; then
      rm -f ${logFile}
  fi


  #create logfile
  touch ${logFile}
  #note starttime
  timestamp >> ${logFile}

  #note set log entry with connected username
  echo "You're connected as ==> " $USER >> ${logFile}

  configCheck

  #collect data from live database configuration
  Db_Host_Live=`grep host $shopDir/config.php | awk -F"'" '{print $4}'`
  Db_Database_Live=`grep dbname $shopDir/config.php | awk -F"'" '{print $4}'`
  Db_User_Live=`grep username $shopDir/config.php | awk -F"'" '{print $4}'`
  Db_Password_Live=`grep password $shopDir/config.php | awk -F"'" '{print $4}'`
  Db_Port_Live=`grep port $shopDir/config.php | awk -F"'" '{print $4}'`

  #collect data for stage database environnement
  read -p "Enter your stage database HOST (default: ${Db_Host_Live}): " Db_Host_Stage
  Db_Host_Stage=${Db_Host_Stage:-"${Db_Host_Live}"}

  read -p "Enter your stage database NAME (default: ${Db_Database_Live}): " Db_Database_Stage
  Db_Database_Stage=${Db_Database_Stage:-"${Db_Database_Live}"}

  read -p "Enter your stage database USERNAME (default: ${Db_User_Live}): " Db_Username_Stage
  Db_Username_Stage=${Db_Username_Stage:-"${Db_User_Live}"}

  read -p "Enter your stage database PASSWORD (default: foo): " Db_Password_Stage
  Db_Password_Stage=${Db_Password_Stage:-foo}
  Db_Password_Stage=${Db_Password_Stage//\"/\\\"} # Escapes apostrophes

  read -p "Enter your stage database PORT number (default: 3306): " Db_Port_Stage
  Db_Port_Stage=${Db_Port_Stage:-"3306"}

  checkMySQLCredentials ${Db_Host_Live} ${Db_User_Live} ${Db_Password_Live} ${Db_Database_Live} ${Db_Port_Live}

  checkMySQLCredentials ${Db_Host_Stage} ${Db_Username_Stage} ${Db_Password_Stage} ${Db_Database_Stage} ${Db_Port_Stage}

  shopSync

  createDevConfig

  copyLiveDbToStage

  clearCache

  runMigrations

  afterCheck

  #slackNotification "https://hooks.slack.com/services/abcd/efgh/234567890"

  afterCleanup

  echo "${lightGreen}Stage created successfully, feel free to have a look at the logfile ${reset}"

}
