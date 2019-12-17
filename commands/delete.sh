#!/bin/bash

function promptDeleteStage(){

  deleteInstance=${deleteInstance:-$(promptYesOrNo "Are you sure? This will delete the whole stage instance in ${warn}$shopDir/stage${reset}! (y/N)" 'n')}
  if [ ${deleteInstance} = "n" ]; then
      echo -e "\n${lightGreen}Not touching the stage instance, have fun!${reset}\n"
      exit 0;
  else
      deleteStage
      if [ $? -eq 0 ]; then
          echo -e "\n${lightGreen}Your instance was deleted. Please drop database on your own and have a coffee after!${reset}\n"
          exit 0
      else
        echo "Error while delete stage" >> ${logFile}
        exit 1
      fi
  fi
}
