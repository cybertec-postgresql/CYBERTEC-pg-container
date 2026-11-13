#!/bin/bash
set -euo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root_dir=$(cd "${tests_dir}/.." && pwd)
mock_bin="${tests_dir}/mocks"
state_root=$(mktemp -d)
trap 'rm -rf "$state_root"' EXIT

function fail() {
    echo "FAIL: $*" >&2
    if [ -n "${run_output:-}" ]; then
        echo "$run_output" >&2
    fi
    exit 1
}

function assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [ "$expected" != "$actual" ]; then
        fail "${message}: expected ${expected}, got ${actual}"
    fi
}

function state_count() {
    local name="$1"

    if [ -f "${case_state}/${name}" ]; then
        cat "${case_state}/${name}"
    else
        printf '0'
    fi
}

function sleep_count() {
    if [ -f "${case_state}/sleeps" ]; then
        wc -l < "${case_state}/sleeps" | tr -d ' '
    else
        printf '0'
    fi
}

function run_backup() {
    local name="$1"
    case_state="${state_root}/${name}"
    mkdir -p "$case_state"

    set +e
    run_output=$(env \
        PATH="${mock_bin}:${PATH}" \
        MOCK_STATE_DIR="$case_state" \
        MOCK_SCENARIO="${test_scenario:-success}" \
        MOCK_BACKUP_CODES="${test_backup_codes:-0}" \
        MOCK_ROLE_RESULTS="${test_role_results:-f}" \
        SELECTOR="application=spilo,role=master" \
        CONTAINER="${test_container:-postgres}" \
        COMMAND_OPTS="--stanza=db --repo=1 --type=full" \
        PGBACKREST_LOCK_WAIT_SECONDS="${test_lock_wait:-20}" \
        PGBACKREST_LOCK_RETRY_SECONDS="${test_lock_retry:-10}" \
        PGBACKREST_TARGET_WAIT_SECONDS="${test_target_wait:-10}" \
        PGBACKREST_TARGET_RETRY_SECONDS="${test_target_retry:-5}" \
        PGBACKREST_CHECK_PRIMARY="${test_check_primary:-auto}" \
        bash -c 'source "$1"; source "$2"' _ \
            "${root_dir}/scripts/pgbackrest/shell_lib.sh" \
            "${root_dir}/scripts/pgbackrest/backup/start.sh" 2>&1)
    run_status=$?
    set -e
}

function reset_case() {
    unset test_scenario test_backup_codes test_role_results test_container
    unset test_lock_wait test_lock_retry test_target_wait test_target_retry
    unset test_check_primary
}

reset_case
test_backup_codes="50,0"
run_backup lock_then_success
assert_equal 0 "$run_status" "lock contention should recover"
assert_equal 2 "$(state_count backup)" "backup attempt count"
assert_equal 2 "$(state_count role)" "primary check count"
assert_equal 2 "$(state_count get)" "target lookup count"
assert_equal 1 "$(sleep_count)" "lock retry sleep count"

reset_case
test_backup_codes="50"
run_backup lock_exhausted
assert_equal 50 "$run_status" "lock exhaustion should keep exit 50"
assert_equal 3 "$(state_count backup)" "bounded backup attempt count"
assert_equal 2 "$(sleep_count)" "bounded lock sleep count"

reset_case
test_backup_codes="50"
test_lock_wait=0
run_backup lock_retry_disabled
assert_equal 50 "$run_status" "disabled lock retry should keep exit 50"
assert_equal 1 "$(state_count backup)" "disabled retry attempt count"
assert_equal 0 "$(sleep_count)" "disabled retry sleep count"

reset_case
test_backup_codes="25"
run_backup non_lock_failure
assert_equal 25 "$run_status" "non-lock failure should be preserved"
assert_equal 1 "$(state_count backup)" "non-lock failure attempt count"
assert_equal 0 "$(sleep_count)" "non-lock failure sleep count"

reset_case
test_lock_retry=0
run_backup invalid_retry_interval
assert_equal 1 "$run_status" "invalid retry interval should fail validation"
assert_equal 0 "$(state_count backup)" "invalid configuration backup count"

reset_case
test_role_results="t,f"
run_backup role_change
assert_equal 0 "$run_status" "role change should find the new primary"
assert_equal 2 "$(state_count role)" "role change check count"
assert_equal 1 "$(state_count backup)" "role change backup count"
assert_equal 1 "$(sleep_count)" "role change sleep count"

reset_case
test_role_results="error"
run_backup role_error
assert_equal 1 "$run_status" "role query failure should fail the job"
assert_equal 0 "$(state_count backup)" "role query failure backup count"
assert_equal 3 "$(state_count role)" "bounded role query count"
assert_equal 2 "$(sleep_count)" "bounded role query sleep count"

reset_case
test_container="pgbackrest"
run_backup repository_host
assert_equal 0 "$run_status" "repository-host backup should succeed"
assert_equal 0 "$(state_count role)" "repository host must not run psql"
assert_equal 1 "$(state_count backup)" "repository-host backup count"

reset_case
test_scenario="api_error"
run_backup api_error
assert_equal 1 "$run_status" "Kubernetes API failure should fail the job"
assert_equal 0 "$(state_count backup)" "API failure backup count"
assert_equal 3 "$(state_count get)" "bounded API query count"
assert_equal 2 "$(sleep_count)" "bounded API query sleep count"

reset_case
test_scenario="no_target"
run_backup no_target
assert_equal 1 "$run_status" "missing target should fail after timeout"
assert_equal 3 "$(state_count get)" "missing target lookup count"
assert_equal 2 "$(sleep_count)" "missing target sleep count"

echo "pgBackRest backup launcher tests passed"
