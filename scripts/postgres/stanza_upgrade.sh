# Ensure PG is ready - Timeout 30s
until psql -c "SELECT 1" >/dev/null 2>&1; do
  echo "Waiting for Postgres..."
  sleep 2
  ((count++))
  if [ $count -gt 15 ]; then echo "Postgres not reachable"; exit 1; fi
done

# Get current used postgresql version
pg_version=$(psql -t -A -c "SELECT substring(setting FROM '^[0-9]+') FROM pg_settings WHERE name = 'server_version'" 2>/dev/null)
if [[ -z "$pg_version" ]]; then
  echo "ERROR: Database not reachable. Abort stanza-upgrade attempt"
  exit 1
fi

pg_version=$(psql -t -A -c "SELECT substring(setting FROM '^[0-9]+') FROM pg_settings WHERE name = 'server_version'")

# Get current stanza version from pgbackrest info
stanza_version=$(pgbackrest info --stanza=db --output=json | jq -r '.[0].db | sort_by(.id) | last | .version')
if [[ -z "$stanza_version" ]]; then
  echo "ERROR: Not able to recieve stanza-version. Abort stanza-upgrade attempt"
  exit 1
fi

echo "INFO: PG-Version: $pg_version | stanza-Version: $stanza_version"
# Check if current postgresql versions mapped to current stanza version. If not do a stanza upgrade 
if [ "$pg_version" != "$stanza_version" ]; then
  echo "INFO: stanza version matches another PostgreSQL version: A stanza upgrade is required to ensure that pgBackRest can work with the current version of PostgreSQL"
  if pgbackrest stanza-upgrade --stanza=db; then
    echo "INFO: stanza has been successfully updated. New Version: $pg_version. Creating a new backup ... "
    pgbackrest backup --stanza=db --type=full --repo=1 > /dev/null 2>&1 &
    BACKUP_PID=$!
    sleep 5s 
    if kill -0 $BACKUP_PID 2>/dev/null; then
      echo "INFO: Backup started successfully."
      disown $BACKUP_PID
      exit 0
    else
      wait $BACKUP_PID
      EXIT_CODE=$?
      if [ $EXIT_CODE -eq 0 ]; then
          exit 0
      else
          echo "ERROR: Backup could not be started successfully!"
          tail -n 10 "$PGHOME/pgdata/pgbackrest/log/db-backup.log"
          exit 1
      fi
    fi
  else
    echo "ERROR: stanza upgrade failed!"
    exit 1
  fi
else
  echo "INFO: stanza is up to date. No change required."
fi

