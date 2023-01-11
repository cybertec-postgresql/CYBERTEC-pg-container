#!/bin/bash
#Script backup a database

# call Primary Pod and start basebackup
count=0
while true ; do
    hostName=$(kubectl get pods -l cluster-name=${SCOPE},spilo-role=master -o go-template --template '{{range .items}}{{.metadata.name}} {{ break }}{{end}}')
    if [ -z "$hostName" ]; then
        sleep 5
        output_info "pgBackRest: waiting for primary-Pod"
        ((count++))
        if [ "$count" == 30 ]; then
            output_error "pgBackRest: waiting for primary-Pod - Timeout - Skip Step"
            skip=1
            break
        fi
    else
        break
    fi
done
count=0
if [ "$skip" == 1 ]; then
    output_error "pgBackRest: No primary pod found - prevent deadlock and start database"
else
    output_info "pgBackRest: Detect Primary-Pod $hostName"
    while true ; do
        unset error
        kubectl exec $hostName -c postgres -- /bin/bash -c 'pgbackrest backup --type=full --stanza=db --repo=1' || { output_error "pgBackRest: Create basebackup failed"; error=true; }
        if [ "$error" = true ]; then
            if [ "$count" == 3 ]; then
                output_error "pgBackRest: Basebackup could not be created. Abort init-script";
                exit 0
            else
                ((count++))
                sleep 5
            fi   
        else
            break;
        fi
    done

    output_info "pgBackRest: Update Restore-Configmap"
    configmap="${SCOPE}-pgbackrest-restore"
    kubectl get cm $configmap -o yaml | \
    sed -e 's|restore_basebackup: "false"|restore_basebackup: "true"|' | \
    kubectl apply -f -

    output_info "pgBackRest: Backup complete"
fi

