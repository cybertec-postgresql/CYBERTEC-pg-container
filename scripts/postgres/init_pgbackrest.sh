#!/bin/bash
# Check Structure
echo "Initialise pgBackRest ... "
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