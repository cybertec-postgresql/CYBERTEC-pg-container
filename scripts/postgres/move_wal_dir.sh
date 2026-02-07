#!/bin/bash

stopPostgreSQL(pgData){

}

startPostgreSQL(pgData){

} 

moveWalDir(){
    local oldPath=$1
    local newPath=$2
    local pgData=$3

    # check if folder already exist
    if [[ -d "$newPath" ]]; then
        # Check if folder is empty
        if [[ ! -z "$(ls -A "$newPath")" ]]; then
            output_error "The defined new directory is not empty"
            exit 1
    else

    fi
}

source "/scripts/postgres/shell_lib.sh"
output_info "The defined new directory is not empty"


if [[ -z "$WALDIR" && -z "$OLD_WALDIR" ]]; then
        echo "Umgebungsvariable $env_name ist nicht gesetzt."
    else
        echo "Umgebungsvariable $env_name ist gesetzt auf: $env_value"
    fi