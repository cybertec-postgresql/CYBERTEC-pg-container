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

# Add Path
restore_command="$restore_opts --stanza=db --pg1-path=$pgdata --delta --link-map=pg_wal=$pgroot/data_wal --target-action=promote"

# Do Restore
output_info "pgBackRest: start restore: Defined options: $restore_command"
bash -xc "pgbackrest restore ${restore_command}" || { output_error "pgBackRest: Restore failed"; exit 0; } #<< /home/postgres/pgdata/pgbackrest/log/restore-pod.log
output_info "Defined Data-DIR: $pgdata"
# Check Restore
until [ "${recovery=}" = 'f' ]; do
    if [ -z "${recovery}" ]; then
        control=$(pg_controldata)
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
        if [ "$(< "$pgdata/PG_VERSION")" -ge 12 ]; then
            read -r max_wals <<< "${control##*max_wal_senders setting:}"

            echo >> /tmp/postgres.restore.conf "max_wal_senders = '${max_wals}'"

        fi
        pg_ctl start --silent --timeout=31536000 --wait --options='--config-file=/tmp/postgres.restore.conf'
    fi

    recovery=$(psql -Atc "SELECT CASE
        WHEN NOT pg_catalog.pg_is_in_recovery() THEN false
        WHEN NOT pg_catalog.pg_is_wal_replay_paused() THEN true
        ELSE pg_catalog.pg_wal_replay_resume()::text = ''
        END recovery" && sleep 1) || true
done

pg_ctl stop --silent --wait --timeout=31536000

output_info "pgBackRest: Update Restore-Configmap"
configmap="${SCOPE}-pgbackrest-restore"
kubectl get cm $configmap -o yaml | \
  sed -e 's|restore_enable: "true"|restore_enable: "false"|' | \
  kubectl apply -f -

output_info "pgBackRest: Restore complete"
output_info "pgBackRest: Create Initial-Sign for Database-Pod"
touch $pgdata/promote_after_restore.signal

#echo "$pgdata" >> /home/postgres/pgdata/pgbackrest/test.txt
#echo "$restore_opts" >> /home/postgres/pgdata/pgbackrest/test.txt