#!/bin/bash
# Check which Jobs needs to be done

#Define Path
PGBACKREST_PATH=${PGBACKREST_PATH:-'/opt/pgbackrest'}
source "${PGBACKREST_PATH}/bin/shell_lib.sh"

output_info "Start pgBackRest-PreCondition-Check"

if [[ "$USE_PGBACKREST" == true ]]; then
    case $MODE in
        repo)
            output_info "pgBackRest: Starting Repo-Host"
            "${PGBACKREST_PATH}/bin/repo-host/start.sh" &
            pgbackrest server
            ;;
        restore)
            output_info "pgBackRest: Restore-Job found"
            if [ "$RESTORE_ENABLE" != "true" ]; then
                output_info "pgBackRest: restore not requested, skipping."
                exit 0
            fi

            source "${PGBACKREST_PATH}/bin/restore/start.sh"
            output_success "Restore-Job completed"
            ;;
        backup)
            output_info "pgBackRest: Backup-Job found"
            source "${PGBACKREST_PATH}/bin/backup/start.sh"
            output_success "pgBackRest: Backup-Job completed"
            ;;
        *)
            output_error "Unknown MODE: $MODE"
            exit 1
    esac
else
    output_info "pgBackRest not used. Skip Container"
fi
