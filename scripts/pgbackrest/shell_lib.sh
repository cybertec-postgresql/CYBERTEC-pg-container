#!/bin/bash

#Background-Definiton:
INFO="\033[37m"
ERROR="\033[31m"
SUCCESS="\033[32m"
DEFAULT="\033[0m"

function start_debug() {
    if [[ ${DEBUGMODE:-false} == "true" ]]
    then
        output_info "Turning debugging on.."
        export PS4='+(${BASH_SOURCE}:${LINENO})> ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        set -x
    fi
}

function output_info(){
    echo -e "${INFO?}$(date) INFO: ${1?}${DEFAULT}"
}

function output_error(){
    echo -e "${ERROR?}$(date) ERROR: ${1?}${DEFAULT}"
}

function output_success(){
    echo -e "${SUCCESS?}$(date) SUCCESS: ${1?}${DEFAULT}"
}