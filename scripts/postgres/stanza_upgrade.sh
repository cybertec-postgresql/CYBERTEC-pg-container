# Get current used postgresql version
pg_version=$(psql -t -A -c "SELECT substring(setting FROM '^[0-9]+') FROM pg_settings WHERE name = 'server_version'" 2>/dev/null)
if [[ -z "$pg_version" ]]; then
  echo "ERROR: Database not reachable. Abort Stanza-upgrade attempt"
  exit 1
fi

pg_version=$(psql -t -A -c "SELECT substring(setting FROM '^[0-9]+') FROM pg_settings WHERE name = 'server_version'")

# Get current Stanza version from pgbackrest info
stanza_version=$(pgbackrest info --stanza=db --output=json | jq -r '.[0].db | sort_by(.id) | last | .version')
if [[ -z "$stanza_version" ]]; then
  echo "ERROR: Not able to recieve stanza-version. Abort Stanza-upgrade attempt"
  exit 1
fi

echo "INFO: PG-Version: $pg_version | Stanza-Version: $stanza_version"
# Check if current postgresql versions mapped to current stanza version. If not do a stanza upgrade 
if [ "$pg_version" != "$stanza_version" ]; then
  echo "INFO: Stanza version matches another PostgreSQL version: A Stanza upgrade is required to ensure that pgBackRest can work with the current version of PostgreSQL"
  if pgbackrest stanza-upgrade --stanza=db; then
    echo "INFO: stanza has been successfully updated. New Version: $pg_version"
  else
    echo "ERROR: stanza upgrade failed!"
    exit 1
  fi
else
  echo "INFO: Stanza is up to date. No change required."
fi