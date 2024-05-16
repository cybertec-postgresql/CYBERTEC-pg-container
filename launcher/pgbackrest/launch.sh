#!/bin/bash
# Check which Jobs needs to be done

#Define Path
PGBACKREST_PATH=${PGBACKREST_PATH:-'/opt/pgbackrest'}
source "${PGBACKREST_PATH}/bin/shell_lib.sh"

output_info "Start pgBackRest-PreCondition-Check"

if [ "$USE_PGBACKREST" == true ]; then
    output_info "Check if RepoHost-Server needs to start"
    if [ "$REPO_HOST" == true ]; then
        if [[ -n $RESTORE_ENABLE ]] || [[ -n $RESTORE_BASEBACKUP ]]; then
            output_info "pgBackRest: Starting temporary Repo-Host"
            pgbackrest server &
            pid=$!
            trap 'kill $pid' EXIT
        else
            output_info "pgBackRest: Starting Repo-Host"
            /opt/pgbackrest/bin/repo-host/start.sh &
            pgbackrest server
        fi
    else
        output_info "RepoHost-Server not needed. Skip Step"
    fi

    if [ "$USE_PGBACKREST" == true ] && [ "$PGBACKREST_MODE" == "backup" ]; then
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
else
    output_info "pgBackRest not used. Skip Container"
fi
