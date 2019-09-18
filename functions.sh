# colors for notification output
# inspired by https://github.com/shyim/shopware-docker

esc=$(printf '\033')
reset="${esc}[0m"
blue="${esc}[34m"
green="${esc}[32m"
lightGreen="${esc}[92m"
red="${esc}[31m"
bold="${esc}[1m"
warn="${esc}[41m${esc}[97m"


# set colors and output banner
function banner() {
    echo -n "${blue}"
    cat "${scriptPath}/files/banner.txt"
    echo "${reset}"
}

# returns the path to mysql
function findMySQLPath() {
    mysqlPath=$(which mysql)
    if [[ -z "${mysqlPath}" ]]; then
        echo "MySQL couldn't found"
        exit 1
    else
        echo "MySQL path ${mysqlPath}" >> ${logFile}
    fi
}

# returns a human readable timestamp dd-mm-yyyy
function timestamp() {
  date +"%T"
}

# filesync via rsync between live and stage folders
function shopSync() {
  stageFolder="${shopDir}/stage"
  if [[ ! -d "${stageFolder}" ]]; then
    mkdir -p ${stageFolder}
    echo "Stage folder created" >> ${logFile}
  fi

  timestamp >> ${logFile}
  echo "Datasync processing" >> ${logFile}
  rsync -av --progress --exclude 'stage' $shopDir/ ${stageFolder}
  timestamp >> ${logFile}
  echo "Files synced to stage folder" >> ${logFile}
}

# checks if provided mysql credentials are valid
function checkMySQLCredentials() {
  findMySQLPath

  echo exit | ${mysqlPath} -h $1 -u $2 -p$3 $4 -P$5 2>/dev/null
  if [ "$?" -gt 0 ]; then
    echo "MySQL credentials for $2 is incorrect" >> ${logFile}
    echo ${red}MySQL credentials for $2 is incorrect${reset}
    exit 1
  else
    echo "MySQL credentials for $2 correct." >> ${logFile}
  fi
}

# copies dev config file into stage folder and replaces default values
# trough mysql credentials
function createDevConfig() {
  cp ${scriptPath}/files/config_dev.php ${shopDir}/stage/config_dev.php

  if [[ -f "${shopDir}/stage/config_dev.php" ]]; then
    sed -i 's/'__HOSTNAME__'/'${Db_Host_Stage}'/g' ${shopDir}/stage/config_dev.php
  	sed -i 's/'__DBNAME__'/'${Db_Database_Stage}'/g' ${shopDir}/stage/config_dev.php
    sed -i 's/'__DBUSERNAME__'/'${Db_Username_Stage}'/g' ${shopDir}/stage/config_dev.php
  	sed -i 's/'__DBPASSWORD__'/'${Db_Password_Stage}'/g' ${shopDir}/stage/config_dev.php
    sed -i 's/'__PORT__'/'${Db_Port_Stage}'/g' ${shopDir}/stage/config_dev.php

  	echo "config_dev.php updated" >> ${logFile}
    echo ${lightGreen}config_dev.php updated${reset}
  else
    echo "Missing config_dev.php in stage" >> ${logFile}
    echo ${red}Missing config_dev.php in stage${reset}
    break
  fi
}

# copies live database into stage database
function copyLiveDbToStage() {
  createLiveDbDump
  importLiveDbDumpToStage
}

# creates live database dump
function createLiveDbDump() {
  timestamp >> $logFile
  mysqlTemp="${shopDir}/mysqlTemp"
  if [[ -d "${mysqlTemp}" ]]; then
    rm -rf ${mysqlTemp}
    echo "MySQLTemp folder deleted" >> ${logFile}
  fi

  mkdir -p ${mysqlTemp}
  echo "MySQLTemp folder created" >> ${logFile}

  echo exit | ${mysqlPath} -h $1 -u $2 -p$3 $4 -P$5 2>/dev/null
  echo "Start with DB export" >> ${logFile}
  mysqldump -h ${Db_Host_Live} -u ${Db_User_Live} -p${Db_Password_Live} ${Db_Database_Live} -P ${Db_Port_Live} > ${shopDir}/mysqlTemp/dump.sql


  if [ $? -eq 0 ]; then
    echo "Database dumped successfully" >> ${logFile}
  else
    echo "Error while dump database" >> ${logFile}
    exit 1
  fi
}

# importes live database into stage
function importLiveDbDumpToStage() {
  timestamp >> $logFile
  if [[ ! -d "${mysqlTemp}" ]]; then
    echo "MySQL dump not found" >> ${logFile}
    exit 1
  fi

  mkdir -p ${mysqlTemp}
  echo "MySQLTemp folder created" >> ${logFile}

  echo exit | ${mysqlPath} -h $1 -u $2 -p$3 $4 -P$5 2>/dev/null
  echo "Start with database import to stage" >> ${logFile}
  ${mysqlPath} -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage} < "${shopDir}/mysqlTemp/dump.sql"


  if [ $? -eq 0 ]; then
    echo "Database imported successfully" >> ${logFile}
  else
    echo "Error while import database to stage" >> ${logFile}
    exit 1
  fi
}

# cleares cache
function clearCache() {
  timestamp >> $logFile
  if [[ ! $(stat -c "%a" "${shopDir}/stage/bin/console") == "755" ]]; then
    chmod 775 "${shopDir}/stage/bin/console"
  fi

  sh "$shopDir/stage/var/cache/clear_cache.sh"
}

# runs SQL migrations in stage database
function runMigrations() {
  timestamp >> $logFile
  echo "Run stage migrations" >> $logFile
  ${mysqlPath} -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage} < "${scriptPath}/files/stage-migrations.sql"
}

# provides a quick check up, which http status the stage environnement returns
function afterCheck() {
  #get shop URL
  shopUrl=$(echo "SELECT host FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage})
  basePath=$(echo "SELECT base_path FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage})

  #get http status of stage
  httpstatus=curl -Is ${shopUrl}/${basePath} | head -1 | awk '{print $2}'
  echo "HTTP Status: ${httpstatus}" >> $logFile
}

# creates Slack notification into choosen channel (optional)
function slackNotification() {
  shopUrl=$(echo "SELECT host FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage})
  basePath=$(echo "SELECT base_path FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} ${Db_Database_Stage} -P ${Db_Port_Stage})

  #send slack notification into #infrastructure channel
  curl -X POST -H 'Content-type: application/json' --data '{"text":"Stage environnement created or updated for http://'"${shopUrl}"''"${basePath}"' with user '"${USER}"'"}' ${slackWebHook}

}


function afterCleanup() {
  clearCache
  rm -rf "${shopDir}/mysqlTemp/dump.sql"
}

function printError(){
    >&2 echo -e "$@"
}

# function for prompting yes or no
# copied from shopware installation script https://github.com/shopware/composer-project/blob/master/app/bin/functions.sh
function promptYesOrNo() {
    declare prompt="$1"
    declare default=${2:-""}

    while true
        do
            read -p "$prompt" answer
                case $(echo "$answer" | `which awk` '{print tolower($0)}') in
                    y|yes)
                        echo 'y'
                        break
                        ;;
                    n|no)
                        echo 'n'
                        break
                        ;;
                    *)
                        if [ -z "$answer" ] && [ ! -z "$default" ] ; then
                            echo "$default"
                            break
                        fi
                        printError "Please enter y or n!"
                        ;;
        esac
    done
}
