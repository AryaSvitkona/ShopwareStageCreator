# Easy way to create a working Shopware 5.X instance into a subfolder

## Description
Creates shop copy of a working Shopware 5.X instance into stage folder (due to licence problems on subdomains). In steps the script will do following tasks:
- creates folder named "stage"
- rsync of files and folders including permissions into "stage" folder
- creates temporary folder for mysqldump
- dumps live database
- import live database into stage Database
- run mysql migrations commands for stage environnement (set maintance mode, update host path, update metarobots snippeds)
- writes new config.php for stage environnement
- clear cache
- send Slack notification into choosen channel (optional)



## Usage
1. clone repository folder into root project directory of your shop (where you can find the shopware.php file, ex. "/var/www/user/shop/ShopwareStageCreator")
2. run script with _bash ssc.sh_
---

## Commands
### pwd
Will provide you the full path to the directory in which the command was called.

```console
stefano@macbook ~$ pwd

/Users/srutishauser
```

### check if file exists
When checking if a file exists, the most commonly used FILE operators are -e and -f. The first one will check whether a file exists regardless of the type, while the second one will return true only if the FILE is a regular file (not a directory or a device)

The most readable option when checking whether a file exist or not is to use the test command in combination with the if statement. Any of the snippets below will check whether the /foor/bar.txt file exists:

```console
FILE=/foo/bar.txt
if test -f "${FILE}"; then
    echo "${FILE} exist"
fi
```

You can pass the -z option to the if command or conditional expression. If the length of STRING is zero, variable is empty.

```console
if [ -z "$var" ]
then
      echo "\$var is empty"
else
      echo "\$var is NOT empty"
fi
```

### read
On Unix-like operating systems, read is a builtin command of the Bash shell. It reads a line of text from standard input and splits it into words. These words can then be used as the input for other commands.

### create selections
To create a selectable "menu" we have to _echo_ first a command so the user knows that he is in charge. After that we provide all possible options, separated by a space as string.
```console
options=("Trendhosting" "Cyon")
```

With the _select_ command it will loop to each option and waits for an input.
```console
select opt in "${options[@]}"
```

Full working code example:
```console
echo 'Select action:'
options=("Create something" "Update something else")
select opt in "${options[@]}"
do
    case $opt in
        "Create something")
            echo "Create something"
            break
            ;;
        "Update something else")
            echo "Update something else"
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
```

### grep
searches string inside File

### awk interpretor
interpretor to manipulate or view textfields

https://askubuntu.com/questions/342842/what-does-this-command-mean-awk-f-print-4

### rsync
On Unix-like operating systems, the rsync command synchronizes files from a source to a destination, on a local machine or over a secure network connection.

https://wiki.ubuntuusers.de/rsync/

```console
rsync -av --progress ../shop/ stage/ --exclude stage/
```

### mysql
On a server which installed mysql services a user can import and manipulate databases via command line.

This command will create a connection to mysql service and is ready to receive commands.
The parameter **-u** will provide the user, **-p** the secret password (whitout space after parameter) and as last the databasename.
```console
mysql -u stefano -psecretpassword databasename
```
https://dev.mysql.com/doc/refman/8.0/en/mysql-commands.html

### mysqldump
On a server which installed mysql services a user can export a database via command line.

This command will create a connection to mysql service and write a .sql dump of the selected database.
The parameter **>** will transfer the content of its database into the specified file.
```console
mysqldump -u stefano -psecretpassword databasename > database_dump.sql
```

### chmod
This command sets the read, write and execute permissions for a file or a directory. In this example the console (as file) will get the execute permissions for owner and group.
```console
chmod chmod 775 bin/console
```
https://wiki.ubuntuusers.de/chmod/

### cURL
The curl command transfers data to or from a network server, using one of the supported protocols (HTTP, HTTPS, FTP, FTPS, SCP, SFTP, TFTP, DICT, TELNET, LDAP or FILE). It is designed to work without user interaction, so it is ideal for use in a shell script.
In this script the curl command will be used to send a json payload over http to a registered webhook of slack.

https://api.slack.com/tutorials/slack-apps-hello-world

https://wiki.ubuntuusers.de/cURL/

### stat
On Unix-like operating systems, the stat command displays the detailed status of a particular file or a file system.
The parameter **-c** is used to format the output in a specific way.
The parameter **%a** is used to show the output in a human readable form.
https://www.computerhope.com/unix/stat.htm

### rm
Dangerous but useful command to remove files or directory including its content. Things that are deleted won't be able to restore (in case you missed the task to create a backup first).

With the parameter **-f** this command will remove every file and directory without asking again. The parameter **-r** stands for _recursive_.
```console
rm -rf stage/
```
https://wiki.ubuntuusers.de/rm/


### printf
Textoutput in an advanced way by passing arguments.
```console
printf "Ich schreibe einen Text mit \e[31m rot \e[0m oder mit \e[32m grün \e[0m \n"
```
http://www.andrewnoske.com/wiki/Bash_-_adding_color
https://www.shellhacks.com/bash-colors/
