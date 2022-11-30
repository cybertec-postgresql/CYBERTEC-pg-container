#!/bin/bash
# Check Structure
echo "Initialise pgBackRest ... "
if [ -d "/home/postgres/pgdata/pgbackrest" ]; then
    echo "Skip: Folder structure already exists ... "
else
    mkdir /home/postgres/pgdata/pgbackrest /home/postgres/pgdata/pgbackrest/log
    echo "Folder structure was created"
fi
# Create Stanza and run Init-Backup
pgbackrest stanza-create --stanza=db
pgbackrest backup --type=full --stanza=db --repo=1
echo "Finished: pgBackRest is ready for use"
