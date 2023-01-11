#!/bin/bash
# Check which Jobs needs to be done

#Define Path
PGBACKREST_PATH=${PGBACKREST_PATH:-'/opt/pgbackrest'}
source "${PGBACKREST_PATH}/bin/shell_lib.sh"
output_info "Start pgBackRest-PreCondition-Check"


#For Restore with pgBackrest
if [ "$RESTORE_ENABLE" == "true" ]; then
    output_info "pgBackRest: Restore-Job found"
    source "${PGBACKREST_PATH}/bin/restore/start.sh"
    output_success "Restore-Job completed"
else
output_info "Restore not defined - Skip Restore-Step"
    if [ "$RESTORE_BASEBACKUP" == "false" ]; then
        output_info "pgBackRest: Backup-Job found"
        source "${PGBACKREST_PATH}/bin/backup/start.sh"
        output_success "Backup-Job completed"
    else
        output_info "Basebackup not defined - Skip create basebackup"
    fi
fi