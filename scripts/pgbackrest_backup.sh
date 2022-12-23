#!/bin/bash
# Check Structure
echo "Initialise pgBackRest ... "
if [ -d "/home/postgres/pgdata/pgbackrest/log" ]; then
    echo "Skip: Folder structure already exists ... "
else
    mkdir -p /home/postgres/pgdata/pgbackrest/log
    echo "Created: Folder structure was created"
fi
# Create Stanza and run Init-Backup
pgbackrest stanza-create --stanza=db
pgbackrest backup --type=full --stanza=db --repo=1
echo "Finished: pgBackRest is ready for use"
