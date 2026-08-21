#!/bin/bash

if ! docker info &> /dev/null; then
    if podman info &> /dev/null; then
        alias docker=podman
        alias xargs='xargs '  # allows '| xargs docker'
        shopt -s expand_aliases
    else
        echo "docker/podman: command not found"
        exit 1
    fi
fi

set -a

if [[ -t 2 ]]; then
    readonly RED="\033[1;31m"
    readonly RESET="\033[0m"
    readonly GREEN="\033[0;32m"
else
    readonly RED=""
    readonly RESET=""
    readonly GREEN=""
fi

function log_info() {
    echo -e "${GREEN}$*${RESET}"
}

function log_error() {
    echo -e "${RED}$*${RESET}"
    exit 1
}

COMPOSE_PROFILE=""

function docker_compose() {
    if [[ -n "$COMPOSE_PROFILE" ]]; then
        docker-compose --profile "$COMPOSE_PROFILE" "$@"
    else
        docker-compose "$@"
    fi
}

function setup_mount_dirs() {
    local scenario_dir=$1
    shift
    local -a dirs=("$@")
    local d
    for d in "${dirs[@]}"; do
        mkdir -p "${scenario_dir}/${d}"
        chmod 777 "${scenario_dir}/${d}"
    done
}

function start_containers() {
    docker_compose up -d
}

function stop_containers() {
    docker_compose rm -fs
}

function rm_container() {
    docker rm -f "$1"
}

function docker_exec() {
    declare -r cmd=${*: -1:1}
    docker exec "${@:1:$(($#-1))}"  bash -c  "$cmd"
}

function run_test() {
    "$@" || log_error "Test case $1 FAILED"
    echo -e "Test case $1 ${GREEN}PASSED${RESET}"
}
