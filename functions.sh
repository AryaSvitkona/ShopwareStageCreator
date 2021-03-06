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
        echo "MySQL couldn't be found"
        exit 1
    else
        echo "MySQL path ${mysqlPath}" >> ${logFile}
    fi
}

# returns a human readable timestamp dd-mm-yyyy
function timestamp() {
    date +"%T"
}

# checks installation if config.php file and no .env file exists
# if false, it will stop the processing
function configCheck() {
    if [[ -f "${shopDir}/config.php" ]]; then
        if [[ -f "${shopDir}/.env" ]]; then
            echo "${shopDir}/.env exists - exit here"
            exit 1
        fi
    else
        echo "${shopDir}/config.php doesn't exist -- exit here"
        exit 1
    fi
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
    rsync -av --progress --exclude-from "${scriptPath}/files/rsync-excludes.txt" $shopDir/ ${stageFolder}
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

# check if live database and stage database are not equal
function compareMySQLCredentials () {
    if [ "${Db_Database_Live}" == "${Db_Database_Stage}" ]; then
        echo ${red}Your stage databasename is equal to your live database. Abort command.${reset}
        echo "WARNING: Stage databasename and Live databasename are equal!" >> ${logFile}
        exit 1
    fi
}

# copies dev config file into stage folder and replaces default values
# trough mysql credentials
function createDevConfig() {
    cp -f ${scriptPath}/files/config_dev.php ${shopDir}/stage/config.php

    if [[ -f "${shopDir}/stage/config.php" ]]; then
        sed -i "s/'__HOSTNAME__'/'${Db_Host_Stage}'/g" ${shopDir}/stage/config.php
    	sed -i "s/'__DBNAME__'/'${Db_Database_Stage}'/g" ${shopDir}/stage/config.php
        sed -i "s/'__DBUSERNAME__'/'${Db_Username_Stage}'/g" ${shopDir}/stage/config.php
    	sed -i "s/'__DBPASSWORD__'/'${Db_Password_Stage//&/\\&}'/g" ${shopDir}/stage/config.php
        sed -i "s/'__PORT__'/'${Db_Port_Stage}'/g" ${shopDir}/stage/config.php

    	echo "config.php updated" >> ${logFile}
        echo ${lightGreen}config.php updated${reset}
    else
        echo "Missing config.php in stage" >> ${logFile}
        echo ${red}Missing config.php in stage${reset}
        break
    fi
}

# copies live database into stage database
function copyLiveDbToStage() {
    createLiveDbDump
    checkLiveDatabase
    eraseStageDatabase
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

    echo "Start with DB export" >> ${logFile}
    mysqldump -h ${Db_Host_Live} -u ${Db_Username_Live} -p${Db_Password_Live} ${Db_Database_Live} -P ${Db_Port_Live} > ${shopDir}/mysqlTemp/dump.sql


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

    echo "Start with database import to stage" >> ${logFile}
    ${mysqlPath} -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage} < "${shopDir}/mysqlTemp/dump.sql"


    if [ $? -eq 0 ]; then
        echo "Database imported successfully" >> ${logFile}
    else
        echo "Error while import database to stage" >> ${logFile}
        exit 1
    fi
}

# checks live database dump for triggers

function checkLiveDatabase() {
    timestamp >> $logFile

    if grep -q DEFINER ${shopDir}/mysqlTemp/dump.sql; then
        echo "DEFINER in live database found"
        echo "DEFINER in live database found" >> $logFile
        sed -i 's/DEFINER=`'${Db_Username_Live}'`/DEFINER=`'${Db_Username_Stage}'`/gI' ${shopDir}/mysqlTemp/dump.sql
    else
        echo "no DEFINER found" >> $logFile
    fi
}

# cleares cache
function clearCache() {
    timestamp >> $logFile
    if [[ ! $(stat -c '%a' "${shopDir}/stage/bin/console") == "755" ]]; then
        chmod 775 "${shopDir}/stage/bin/console"
    fi

    if [[ -f "${shopDir}/stage/var/cache/clear_cache.sh" ]]; then
        sh "$shopDir/stage/var/cache/clear_cache.sh"
    else
        rm -rf "$shopDir/stage/var/cache/*/"
    fi
}

# runs SQL migrations in stage database
function runMigrations() {
    timestamp >> $logFile
    echo "Run stage migrations" >> $logFile
    ${mysqlPath} -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage} < "${scriptPath}/files/stage-migrations.sql"
}

# provides a quick check up, which http status the stage environnement returns
function afterCheck() {
    #get shop URL
    shopUrl=$(echo "SELECT host FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage})
    basePath=$(echo "SELECT base_path FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage})

    #get http status of stage
    httpstatus=$(curl -Is ${shopUrl}/${basePath} | head -1 | awk '{print $2}')
    echo "HTTP Status: ${httpstatus}" >> $logFile

    if [[ ! $(stat -c '%a' "${shopDir}/stage/") == "755" ]]; then
        chmod 755 "${shopDir}/stage/"
    fi
}

# creates Slack notification into choosen channel (optional)
function slackNotification() {
    shopUrl=$(echo "SELECT host FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage})
    basePath=$(echo "SELECT base_path FROM s_core_shops WHERE id=1" | ${mysqlPath} -s -N -h ${Db_Host_Stage} -u ${Db_Username_Stage} -p${Db_Password_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage})

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

function deleteStage() {
    if [[  -d "${shopDir}/empty" ]]; then
        rm -rf "${shopDir}/empty"
    fi
    mkdir "${shopDir}/empty"
    rsync -av --delete "${shopDir}/empty/" "${shopDir}/stage/"
    rm -rf "${shopDir}/stage/"
}

function collectStageCredentials() {
    if [[ ! -f "${shopDir}/stage/config.php" ]]; then
        echo "Config.php file in stage not found"
        exit
    fi

    Db_Host_Stage=`grep "'host'" $shopDir/stage/config.php | awk -F"'" '{print $4}'`
    Db_Database_Stage=`grep "'dbname'" $shopDir/stage/config.php | awk -F"'" '{print $4}'`
    Db_Username_Stage=`grep "'username'" $shopDir/stage/config.php | awk -F"'" '{print $4}'`
    Db_Password_Stage=`grep "'password'" $shopDir/stage/config.php | awk -F"'" '{print $4}'`
    Db_Port_Stage=`grep "'port'" $shopDir/stage/config.php | awk -F"'" '{print $4}'`
}

function eraseStageDatabase() {
    checkMySQLCredentials ${Db_Host_Stage} ${Db_Username_Stage} ${Db_Password_Stage} ${Db_Database_Stage} ${Db_Port_Stage}

    # get all tables
    TABLES=$($mysqlPath -u ${Db_Username_Stage} -p${Db_Password_Stage} -h ${Db_Host_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage} -e 'show tables' | awk '{ print $1}' | grep -v '^Tables' )

    # make sure tables exits
    if [ "$TABLES" != "" ]
    then
        # erase found tables
        for t in $TABLES
        do
            echo "Deleting $t table from $MDB database..."
            $mysqlPath -u ${Db_Username_Stage} -p${Db_Password_Stage} -h ${Db_Host_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage} -e  "SET FOREIGN_KEY_CHECKS=0; DROP TABLE $t"
        done
        echo "Tables in ${Db_Database_Stage} deleted" >> ${logFile}

        # enable foreign key check
        $mysqlPath -u ${Db_Username_Stage} -p${Db_Password_Stage} -h ${Db_Host_Stage} -D ${Db_Database_Stage} -P ${Db_Port_Stage} -e 'SET FOREIGN_KEY_CHECKS=1;'
    else
        echo "No tables found in ${Db_Database_Stage}!" >> ${logFile}
    fi
}
