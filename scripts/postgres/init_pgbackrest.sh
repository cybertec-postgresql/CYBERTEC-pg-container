#!/bin/bash
# Check Structure
if [ -d "/home/postgres/pgdata/pgbackrest/log" ]; then
    echo "Skip: Folder structure already exists ... "
else
    mkdir -p /home/postgres/pgdata/pgbackrest/log
    echo "Created: Folder structure was created"
fi
if [ -d "/home/postgres/pgdata/pgbackrest/spool-path" ]; then
    echo "Skip: Spool-Folder already exists ... "
else
    mkdir -p /home/postgres/pgdata/pgbackrest/spool-path
    echo "Created: Spool-Folder was created"
fi

if [ "$REPO_HOST" == true ]; then
    echo "pgBackRest is running in tls-mode. Skip initialisation on this Container."
else
    echo "Initialise pgBackRest ... "
    # Create Stanza and run Init-Backup
    stanza=$(pgbackrest info --output=json)
    if [ "$stanza" == "[]" ]; then
        pgbackrest stanza-create --stanza=db
        pgbackrest backup --type=full --stanza=db --repo=1
        echo "Finished: pgBackRest is ready for use"
    else
        backupCount=$(pgbackrest info --output=json | jq '.[0].backup'| jq length)
        if [ "$backupCount" == "0" ]; then
            pgbackrest backup --type=full --stanza=db --repo=1
            echo "Finished: pgBackRest is ready for use"
        fi
    fi
fi

# Check if stanza needs an upgrade

# Get current used postgresql version
pg_version=$(psql -V | awk '{print $3}' | cut -d '.' -f 1)

# Get current Stanza version from pgbackrest info
stanza_version=$(echo $(pgbackrest info --stanza=db --output=json) | jq -r '.[0].db[0].version')

# Check if current postgresql versions mapped to current stanza version. If not do a stanza upgrade 
if [ "$pg_version" != "$stanza_version" ]; then
  echo "Stanza version matches another PostgreSQL version: A Stanza upgrade is required to ensure that pgBackRest can work with the current version of PostgreSQL"
  pgbackrest stanza-upgrade --stanza=db
else
  echo "Stanza is up to date. No change required."
fi
