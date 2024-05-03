#!/bin/bash
# Check which Jobs needs to be done

#Define Path
PGBACKREST_PATH=${PGBACKREST_PATH:-'/opt/pgbackrest'}
source "${PGBACKREST_PATH}/bin/shell_lib.sh"
output_info "Start pgBackRest-PreCondition-Check"

if [ "$MODE" == "pgbackrest" ] && [ "$COMMAND" == "repo-host" ]; then
    output_info "pgBackRest: Start Repo-Host"
    pgbackrest server

elif [ "$MODE" == "pgbackrest" ] && [ "$COMMAND" == "backup" ]; then
    output_info "pgBackRest: Backup-Job found"
    source "${PGBACKREST_PATH}/bin/backup/start.sh"
    output_success "pgBackRest: Backup-Job completed"
else
    #For Restore with pgBackrest
    if [ "$RESTORE_ENABLE" == "true" ]; then
        output_info "pgBackRest: Restore-Job found"
        source "${PGBACKREST_PATH}/bin/restore/start.sh"
        output_success "Restore-Job completed"
    else
    output_info "Restore not defined - Skip Restore-Step"
        if [ "$RESTORE_BASEBACKUP" == "false" ]; then
            output_info "pgBackRest: Backup-Job found"
            export SELECTOR="cluster-name=${SCOPE},spilo-role=master"
            export COMMAND_OPTS="--type=full --stanza=db --repo=1"
            source "${PGBACKREST_PATH}/bin/backup/start.sh"
            output_info "pgBackRest: Update Restore-Configmap"
            configmap="${SCOPE}-pgbackrest-restore"
            kubectl get cm $configmap -o yaml | \
            sed -e 's|restore_basebackup: "false"|restore_basebackup: "true"|' | \
            kubectl apply -f -
            output_success "pgBackRest: Backup-Job completed"
        else
            output_info "Basebackup not defined - Skip create basebackup"
        fi
    fi
fi
