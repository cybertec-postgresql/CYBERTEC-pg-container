#!/bin/bash
# Run a pgBackRest backup on the current target Pod.

pgbackrest_lock_wait_seconds="${PGBACKREST_LOCK_WAIT_SECONDS:-600}"
pgbackrest_lock_retry_seconds="${PGBACKREST_LOCK_RETRY_SECONDS:-10}"
pgbackrest_target_wait_seconds="${PGBACKREST_TARGET_WAIT_SECONDS:-150}"
pgbackrest_target_retry_seconds="${PGBACKREST_TARGET_RETRY_SECONDS:-5}"
pgbackrest_check_primary="${PGBACKREST_CHECK_PRIMARY:-auto}"

function pgbackrest_require_non_negative_integer() {
    local name="$1"
    local value="$2"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        output_error "pgBackRest: ${name} must be a non-negative integer"
        return 1
    fi
}

function pgbackrest_require_positive_integer() {
    local name="$1"
    local value="$2"

    if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
        output_error "pgBackRest: ${name} must be greater than zero"
        return 1
    fi
}

function pgbackrest_wait_for_target() {
    local waited=0
    local lookup_status
    local role
    local role_status
    local sleep_seconds

    while true; do
        pgbackrest_target_pod=$(kubectl get pods -l "$SELECTOR" -o go-template --template '{{range .items}}{{.metadata.name}}{{break}}{{end}}')
        lookup_status=$?

        if [ "$lookup_status" -ne 0 ]; then
            output_error "pgBackRest: unable to query the target Pod"
        elif [ -n "$pgbackrest_target_pod" ]; then
            if [ "$pgbackrest_check_primary" != "true" ]; then
                return 0
            fi

            role=$(kubectl exec "$pgbackrest_target_pod" -c "$CONTAINER" -- /bin/bash -c \
                'psql -XAtq -U "${PGUSER_SUPERUSER:-postgres}" -d postgres -c "SELECT pg_is_in_recovery()"')
            role_status=$?

            if [ "$role_status" -ne 0 ]; then
                output_error "pgBackRest: unable to verify the PostgreSQL role on ${pgbackrest_target_pod}"
            else
                case "$role" in
                    f)
                        return 0
                        ;;
                    t)
                        output_info "pgBackRest: ${pgbackrest_target_pod} is no longer primary, waiting for a new target"
                        ;;
                    *)
                        output_error "pgBackRest: unexpected PostgreSQL role returned by ${pgbackrest_target_pod}"
                        ;;
                esac
            fi
        else
            output_info "pgBackRest: waiting for a target Pod"
        fi

        if [ "$waited" -ge "$pgbackrest_target_wait_seconds" ]; then
            output_error "pgBackRest: no valid target Pod found before timeout"
            return 1
        fi

        sleep_seconds="$pgbackrest_target_retry_seconds"
        if [ $((waited + sleep_seconds)) -gt "$pgbackrest_target_wait_seconds" ]; then
            sleep_seconds=$((pgbackrest_target_wait_seconds - waited))
        fi
        sleep "$sleep_seconds"
        waited=$((waited + sleep_seconds))
    done
}

for pgbackrest_required_variable in SELECTOR CONTAINER COMMAND_OPTS; do
    if [ -z "${!pgbackrest_required_variable:-}" ]; then
        output_error "pgBackRest: ${pgbackrest_required_variable} is required"
        exit 1
    fi
done

pgbackrest_require_non_negative_integer "PGBACKREST_LOCK_WAIT_SECONDS" "$pgbackrest_lock_wait_seconds" || exit 1
pgbackrest_require_positive_integer "PGBACKREST_LOCK_RETRY_SECONDS" "$pgbackrest_lock_retry_seconds" || exit 1
pgbackrest_require_non_negative_integer "PGBACKREST_TARGET_WAIT_SECONDS" "$pgbackrest_target_wait_seconds" || exit 1
pgbackrest_require_positive_integer "PGBACKREST_TARGET_RETRY_SECONDS" "$pgbackrest_target_retry_seconds" || exit 1

case "$pgbackrest_check_primary" in
    auto)
        if [ "$CONTAINER" = "postgres" ]; then
            pgbackrest_check_primary=true
        else
            pgbackrest_check_primary=false
        fi
        ;;
    true|false)
        ;;
    *)
        output_error "pgBackRest: PGBACKREST_CHECK_PRIMARY must be auto, true or false"
        exit 1
        ;;
esac

pgbackrest_lock_waited=0
pgbackrest_attempt=0

while true; do
    pgbackrest_wait_for_target
    pgbackrest_target_status=$?
    if [ "$pgbackrest_target_status" -ne 0 ]; then
        exit 1
    fi

    pgbackrest_attempt=$((pgbackrest_attempt + 1))
    output_info "pgBackRest: starting backup attempt ${pgbackrest_attempt} on ${pgbackrest_target_pod}"

    kubectl exec "$pgbackrest_target_pod" -c "$CONTAINER" -- /bin/bash -c "pgbackrest backup ${COMMAND_OPTS}"
    pgbackrest_backup_status=$?

    if [ "$pgbackrest_backup_status" -eq 0 ]; then
        output_success "pgBackRest: backup complete"
        break
    fi

    if [ "$pgbackrest_backup_status" -ne 50 ]; then
        output_error "pgBackRest: backup failed with exit code ${pgbackrest_backup_status}"
        exit "$pgbackrest_backup_status"
    fi

    if [ "$pgbackrest_lock_waited" -ge "$pgbackrest_lock_wait_seconds" ]; then
        output_error "pgBackRest: lock wait exhausted after ${pgbackrest_lock_waited} seconds"
        exit 50
    fi

    pgbackrest_retry_sleep="$pgbackrest_lock_retry_seconds"
    if [ $((pgbackrest_lock_waited + pgbackrest_retry_sleep)) -gt "$pgbackrest_lock_wait_seconds" ]; then
        pgbackrest_retry_sleep=$((pgbackrest_lock_wait_seconds - pgbackrest_lock_waited))
    fi

    output_info "pgBackRest: repository lock is busy, retrying in ${pgbackrest_retry_sleep} seconds"
    sleep "$pgbackrest_retry_sleep"
    pgbackrest_lock_waited=$((pgbackrest_lock_waited + pgbackrest_retry_sleep))
done
