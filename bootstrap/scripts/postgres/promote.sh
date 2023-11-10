#!/bin/bash
#Promote a Database after a restore
while true ; do
    sleep 5
    if [ -f "${PGDATA}/postmaster.pid" ]; then
    sleep 5
        break
    fi
done

source "/scripts/postgres/shell_lib.sh"
output_info "pgBackRest: Promote Database because of earlier pgBackRest-Restore."
pg_ctl promote -D ${PGDATA}
rm -f "${PGDATA}/promote_after_restore.signal"