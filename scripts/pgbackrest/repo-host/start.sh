#!/bin/bash
# Check Structure
echo "Initialise pgBackRest ... "
if [ -d "/data/pgbackrest/repo1/log" ]; then
    echo "Skip: Folder structure already exists ... "
else
    mkdir -p /data/pgbackrest/repo1/log
    echo "Created: Folder structure was created"
fi

# Create Stanza and run Init-Backup
stanza=$(pgbackrest info --stanza=db --output=json)
db=$(echo $stanza | jq '.[0].db')
archive=$(echo $stanza | jq '.[0].archive')
status=$(echo $stanza | jq '.[0].status.code')
 
if [ "$db" == "[]" ] && [ "$archive" == "[]" ] || [ "$status" == "1" ]; then
    # Check if Primary is ready
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