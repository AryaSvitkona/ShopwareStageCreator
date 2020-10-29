#!/bin/sh

function createStage()
{
    createLogEntry "Creating new stage with SSH user: $USER"

    shopwareCheck

    configCheck

}
