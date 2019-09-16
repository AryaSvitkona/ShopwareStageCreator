#!/bin/bash

function deleteStage(){

  deleteInstance=${deleteInstance:-$(promptYesOrNo "Are you sure? This will delete the whole stage instance in ${warn}$shopDir/stage${reset}! (y/N)" 'n')}
  if [ ${deleteInstance} = "n" ]; then
      echo -e "\n${lightGreen}Not touching the stage instance, have fun!${reset}\n"
      exit 0;
  else
      echo -e "\n${lightGreen}Your instance was deleted, have a coffee!${reset}\n"
      exit 0;
  fi
}
