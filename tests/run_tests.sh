#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# shellcheck disable=SC1091
source ./test_utils.sh

readonly PREFIX="demo-"
readonly UPGRADE_SCRIPT="python3 /scripts/inplace_upgrade.py"
readonly TIMEOUT=300

TESTS_DIR="$(pwd)"
readonly TESTS_DIR
readonly S3_SCENARIO_DIR="${TESTS_DIR}/s3"
readonly TLS_SCENARIO_DIR="${TESTS_DIR}/tls"
readonly TLS_MOUNT_DIRS=('repo-host')
readonly S3_MOUNT_DIRS=()

function remove_mounts() {
    local scenario_dir=$1
    shift
    for mount in "$@"; do
        docker run --rm \
            -v "${scenario_dir}:/host:rw" \
            --user 0:0 \
            "${PG_IMAGE}" \
            sh -c "rm -rf /host/${mount}"
    done
}

function cleanup() {
    stop_containers
    docker ps -q  --filter="name=${PREFIX}" | xargs docker rm -f

    remove_mounts "${TLS_SCENARIO_DIR}" "${TLS_MOUNT_DIRS[@]}"
    remove_mounts "${S3_SCENARIO_DIR}" "${S3_MOUNT_DIRS[@]}"
}

function cleanup_certs() {
    rm -rf "${TLS_SCENARIO_DIR}/certs"
}

function find_leader() {
    local container=$1
    local silent=$2
    declare -r timeout=$TIMEOUT
    local attempts=0

    while true; do
        leader=$(docker_exec "$container" 'patronictl list -f tsv' 2> /dev/null | awk '($4 == "Leader"){print $2}')
        if [[ -n "$leader" ]]; then
            [ -z "$silent" ] && echo "$leader"
            return
        fi
        ((attempts++))
        if [[ $attempts -ge $timeout ]]; then
            docker logs "$container"
            log_error "Leader is not running after $timeout seconds"
        fi
        sleep 1
    done
}

function wait_query() {
    local container=$1
    local query=$2
    local result=$3

    declare -r timeout=$TIMEOUT
    local attempts=0

    while true; do
        ret=$(docker_exec "$container" "psql -U postgres -tAc \"$query\"")
        if [[ "$ret" = "$result" ]]; then
            return 0
        fi
        ((attempts++))
        if [[ $attempts -ge $timeout ]]; then
            log_error "Query \"$query\" didn't return expected result $result after $timeout seconds"
        fi
        sleep 1
    done
}

function wait_all_streaming() {
    local repl_count=${2:-2}
    log_info "Waiting for all replicas to start streaming from the leader ($1)..."
    wait_query "$1" "SELECT COUNT(*) FROM pg_stat_replication WHERE application_name LIKE 'pgcontainer_'" "$repl_count"
}

function wait_zero_lag() {
    local repl_count=${2:-2}
    log_info "Waiting for all replicas to catch up with WAL replay..."
    wait_query "$1" "SELECT COUNT(*) FROM pg_stat_replication WHERE application_name LIKE 'pgcontainer_' AND pg_catalog.pg_wal_lsn_diff(pg_catalog.pg_current_wal_lsn(), COALESCE(replay_lsn, '0/0')) < 16*1024*1024" "$repl_count"
}

function wait_backup() {
    local container=$1
    local dbid=$2

    declare -r timeout=$TIMEOUT
    local attempts=0
    log_info "Waiting for backup on S3..,"

    sleep 1

    docker_exec -i "$1" "psql -U postgres -c CHECKPOINT" > /dev/null 2>&1

    while true; do
        count=$(docker_exec "$container" "pgbackrest info --output=json" | jq -r '.[] | select(.name=="db") | [.backup[] | select(.database.id=='"$dbid"')] | length')

        if [[ "$count" -gt 0 ]]; then
            return
        fi
        ((attempts++))
        if [[ $attempts -ge $timeout ]]; then
            log_error "No backup produced after $timeout seconds"
        fi
        sleep 1
    done
}

function create_schema() {
    docker_exec -i "$1" "psql -U postgres" < schema.sql
    if [[ -n "$EXTRA_EXT" ]]; then
        for ext in "${EXTRA_EXT[@]}"; do
            docker_exec "$1" "psql -U postgres -d test_db -tAc \"CREATE EXTENSION $ext\""
        done
    fi
}

function bootstrap_replica() {
    local scope="$1"
    local name="$2"
    local service="pg1"

    if [[ "$COMPOSE_PROFILE" == "repo-host" ]]; then
        service="pg1-repo"
    fi

    NEW_HOSTNAME="$name" docker-compose run \
        -e SCOPE="$scope" \
        --name "$PREFIX$name" -d \
        "$service"
}

function test_pgbouncer_connection() {
    declare -r timeout=$TIMEOUT
    local attempts=0
    sleep 1
    while true; do
        count=$(docker_exec "$1" "PGMAXPROTOCOLVERSION=3.0 PGSSLMODE=require PGPASSWORD=password psql -U app_user -h 'pgbouncer' -p 6432 -d test_db -tAc 'SELECT 123'")
        if [[ "$count" == '123' ]]; then
            return
        fi
        ((attempts++))
        if [[ $attempts -ge $timeout ]]; then
            log_error "PGBouncer connection fails after $timeout seconds"
        fi
        sleep 1
    done

}

function test_exporter_request {
    declare -r timeout=$TIMEOUT
    while true; do
        code=$(docker_exec "$1" "curl -s -w \"%{http_code}\" exporter:9187/metrics -o /dev/null")
        if [[ $code -eq 200 ]]; then
            return
        fi
        log_error "Postgres exporter query fails with code $code"
        sleep 1
    done
}

function check_extensions() {
    spl=$(docker_exec "$1" "psql -U postgres -c 'SHOW shared_preload_libraries'")
    [[ "$spl" =~ 'pg_stat_statements' ]] || log_error 'pg_stat_statements is not in shared_preload_libraries'

    extwlist=$(docker_exec "$1" "psql -U postgres -c 'SHOW extwlist.extensions'")
    [[ "$extwlist" =~ 'pg_stat_statements' ]] || log_error 'pg_stat_statements is not in extwlist.extensions'

    if [[ ! "$PG_IMAGE" =~ -beta([1-9]*)$ ]]; then
        [[ "$extwlist" =~ 'timescaledb' ]] || log_error 'timescaledb is not in extwlist.extensions'
        [[ "$extwlist" =~ 'pg_partman' ]] || log_error 'pg_partman is not in extwlist.extensions'
    fi
}

function test_inplace_upgrade_wrong_version() {
    docker_exec "$1" "PGVERSION=$INIT_VERSION $UPGRADE_SCRIPT 3" 2>&1 | grep 'Upgrade is not required'
}

function test_inplace_upgrade_wrong_capacity() {
    docker_exec "$1" "PGVERSION=$TARGET_VERSION $UPGRADE_SCRIPT 4" 2>&1 | grep 'number of replicas does not match'
}

function test_successful_inplace_upgrade_to_x() {
    docker_exec "$1" "PGVERSION=$2 $UPGRADE_SCRIPT 3"
    check_extensions "$1"
}

function test_spilo() {
    local container=$1

    wait_all_streaming "$container" 1
    create_schema "$container" || exit 1
    wait_zero_lag "$container" 1

    wait_backup "$container" 1

    log_info "Testing pgbouncer connectivity"
    run_test test_pgbouncer_connection "$container"

    log_info "Testing postgres exporter setup"
    run_test test_exporter_request "$container"

    log_info "Testing replica bootstrap"
    extra_replica=$(bootstrap_replica demo pgcontainer3)
    log_info "Started $extra_replica"
    wait_all_streaming "$container" 2
    wait_zero_lag "$container" 2

    log_info "Testing wrong upgrade setups"
    run_test test_inplace_upgrade_wrong_version "$container"
    run_test test_inplace_upgrade_wrong_capacity "$container"

    log_info "Testing in-place major upgrade $INIT_VERSION->$TARGET_VERSION"
    wait_zero_lag "$container"
    run_test test_successful_inplace_upgrade_to_x "$container" "$TARGET_VERSION"
    wait_all_streaming "$container"
    wait_backup "$container" 2
}

# Usage:
#   run_scenario <scenario_name> <compose_profile> <scenario_dir> <mount_dirs...>
function run_scenario() {
    local scenario_name=$1
    COMPOSE_PROFILE=$2
    local scenario_dir=$3
    shift 3
    local -a mount_dirs=("$@")

    log_info "Running scenario: $scenario_name"

    cleanup
    setup_mount_dirs "$scenario_dir" "${mount_dirs[@]}"
    start_containers &

    log_info "Waiting for leader..."
    local leader
    leader="$PREFIX$(find_leader "${PREFIX}pgcontainer1")"

    test_spilo "$leader"
}

function main() {
    local required_vars=(PG_IMAGE PGBOUNCER_IMAGE EXPORTER_IMAGE PGBACKREST_IMAGE INIT_VERSION TARGET_VERSION)
    local v
    for v in "${required_vars[@]}"; do
        if [[ -z "${!v}" ]]; then
            log_error "Missing required environment variable: ${v}"
        fi
    done

    run_scenario "pgBackRest s3" "s3" "${S3_SCENARIO_DIR}" "${S3_MOUNT_DIRS[@]}"

    "${TLS_SCENARIO_DIR}/generate_certs.sh"
    run_scenario "pgBackRest repo-host (TLS)" "repo-host" "${TLS_SCENARIO_DIR}" "${TLS_MOUNT_DIRS[@]}"
}

trap 'cleanup; cleanup_certs' QUIT TERM EXIT

main
