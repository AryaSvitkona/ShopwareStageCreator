#!/bin/sh

function createStage()
{
    logEntry "Start with creating new stage by SSH user: $USER"

    shopwareCheck

    configCheck
    echo ${shopConfigFile}

}
