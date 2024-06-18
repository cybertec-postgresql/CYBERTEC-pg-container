#!/bin/bash
#Script restore a database

#Export and declare needed Variables
export PGDATA="${PGROOT}/data"
declare -r pgdata="${PGDATA}" restore_opts="${RESTORE_COMMAND}" pgroot="${PGROOT}"
export PGHOST='/tmp'
export PATH="${PATH}:/usr/pgsql-${PGVERSION}/bin"

#Check PreConditions
output_info "pgBackRest: Check preconditions"
if [ -f "$pgdata/postmaster.pid" ]; then
    pg_ctl stop --silent --wait --timeout 60 -D $pgdata
    rm -f "$pgdata/postmaster.pid"
    output_info "pgBackRest: postmaster.pid found and deleted"
fi
#if [ -d "$pgroot/data_wal" ]; then
#    rm -rf "$pgroot/data_wal"
#    output_info "pgBackRest: Folder pg_wal found and deleted"
#fi
if [ -d "$pgroot/data_bootstrap" ]; then
    rm -rf "$pgroot/data_bootstrap"
    output_info "pgBackRest: Folder data_bootstrap found and deleted"
fi

if [ -f "${PGROOT}/RESTORE_ID" ]; then
    prev_restore="$(< "$PGROOT/RESTORE_ID")"
    if [ "$prev_restore" = "$RESTORE_ID" ]; then
        output_info "pgBackRest: Found a completion marker for restore \"$RESTORE_ID\", skipping restore"
        exit 0
    else
        output_info "pgBackRest: Cleaning up completion marker for restore \"$prev_restore\""
        rm "$PGROOT/RESTORE_ID"
    fi
fi

# Add Path
POD_INDEX="${HOSTNAME##*-}"
if [ "$POD_INDEX" -eq 0 ]; then
    action=" --target-action=promote"
else
    restore_opts="${restore_opts//--type=[^ ]+/}"
    action=" --type=none"
fi
restore_command="$restore_opts --stanza=db --pg1-path=$pgdata --delta $action"

# Do Restore
output_info "pgBackRest: start restore: Defined options: $restore_command"
bash -xc "pgbackrest restore ${restore_command}" || { output_error "pgBackRest: Restore failed"; exit 1; } #<< /home/postgres/pgdata/pgbackrest/log/restore-pod.log

output_info "Defined Data-DIR: $pgdata"

actual_version="$(< "$pgdata/PG_VERSION")"
output_info "Restored version: $actual_version"
bin_dir="/usr/pgsql-${actual_version}/bin"

if [ "$POD_INDEX" -eq 0 ]; then
    # Check Restore
    until [ "${recovery=}" = 'f' ]; do
        if [ -z "${recovery}" ]; then
            control=$(${bin_dir}/pg_controldata)
            read -r max_conn <<< "${control##*max_connections setting:}"
            read -r max_lock <<< "${control##*max_locks_per_xact setting:}"
            read -r max_ptxn <<< "${control##*max_prepared_xacts setting:}"
            read -r max_work <<< "${control##*max_worker_processes setting:}"
            echo > /tmp/pg_hba.restore.conf 'local all "postgres" peer'
            cat > /tmp/postgres.restore.conf << EOF
archive_command = 'false'
archive_mode = 'on'
hba_file = '/tmp/pg_hba.restore.conf'
max_connections = '${max_conn}'
max_locks_per_transaction = '${max_lock}'
max_prepared_transactions = '${max_ptxn}'
max_worker_processes = '${max_work}'
unix_socket_directories = '/tmp'
EOF
            if [ "$actual_version" -ge 12 ]; then
                read -r max_wals <<< "${control##*max_wal_senders setting:}"

                echo >> /tmp/postgres.restore.conf "max_wal_senders = '${max_wals}'"

            fi
            ${bin_dir}/pg_ctl start --silent --timeout=31536000 --wait --options='--config-file=/tmp/postgres.restore.conf'
        fi

        recovery=$(${bin_dir}/psql -Atc "SELECT CASE
            WHEN NOT pg_catalog.pg_is_in_recovery() THEN false
            WHEN NOT pg_catalog.pg_is_wal_replay_paused() THEN true
            ELSE pg_catalog.pg_wal_replay_resume()::text = ''
            END recovery" && sleep 1) || true
    done

    ${bin_dir}/pg_ctl stop --silent --wait --timeout=31536000
    touch $pgdata/promote_after_restore.signal
else
    output_info "Replica pod, letting Patroni take care of finalizing recovery"
fi


output_info "pgBackRest: Marking PVC restored as \"$RESTORE_ID\""
echo -n "$RESTORE_ID" > "$PGROOT/RESTORE_ID"

output_info "pgBackRest: Restore complete"
output_info "pgBackRest: Create Initial-Sign for Database-Pod"

#echo "$pgdata" >> /home/postgres/pgdata/pgbackrest/test.txt
#echo "$restore_opts" >> /home/postgres/pgdata/pgbackrest/test.txt
