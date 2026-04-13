#!/bin/bash
# Check Structure
if [ -d "/home/postgres/pgdata/pgbackrest/log" ]; then
    echo "INFO: Folder structure already exists ... "
else
    mkdir -p /home/postgres/pgdata/pgbackrest/log
    echo "INFO: Folder structure was created"
fi
if [ -d "/home/postgres/pgdata/pgbackrest/spool-path" ]; then
    echo "INFO: Spool-Folder already exists ... "
else
    mkdir -p /home/postgres/pgdata/pgbackrest/spool-path
    echo "INFO: Spool-Folder was created"
fi

if [ "$REPO_HOST" == true ]; then
    echo "INFO: gBackRest is running in tls-mode. Skip initialisation on this Container."
else
    echo "INFO: Checking pgBackRest status..."
    info_json=$(pgbackrest info --output=json 2>/dev/null)
    exit_code=$?

    stanza_exists=$(echo "$info_json" | jq -r '.[] | select(.name=="db") | .name' 2>/dev/null)

    if [ $exit_code -ne 0 ] || [ -z "$stanza_exists" ]; then
        echo "INFO: Stanza not found or repo not reachable."
        
        if [ "$info_json" == "[]" ] || [ -z "$info_json" ]; then
            echo "INFO: Initialise pgBackRest stanza..."
            pgbackrest stanza-create --stanza=db
            echo "INFO: Creating initial full backup..."
            pgbackrest backup --type=full --stanza=db --repo=1
        else
            echo "ERROR: pgBackRest status could not be determined.Reason: Exit Code $exit_code / JSON: ${info_json:-empty}"
        fi
    else
        echo "INFO: Stanza exists. Checking for backups..."
        backupCount=$(echo "$info_json" | jq -r '.[] | select(.name=="db") | .backup | length' 2>/dev/null)
        
        if [ "${backupCount:-0}" -eq 0 ]; then
            echo "WARN: No backups found. Creating initial full backup..."
            pgbackrest backup --type=full --stanza=db --repo=1
        else
            echo "INFO: pgBackrest already ready. Skipping ... "
        fi
    fi
fi

# Check if stanza needs an upgrade
if [ -f "/scripts/postgres/stanza_upgrade.sh" ]; then
    source /scripts/postgres/stanza_upgrade.sh
fi
