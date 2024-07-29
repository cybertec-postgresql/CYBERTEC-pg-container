# Get current used postgresql version
pg_version=$(psql -t -A -c "SELECT substring(setting FROM '^[0-9]+') FROM pg_settings WHERE name = 'server_version'")

# Get current Stanza version from pgbackrest info
stanza_version=$(echo $(pgbackrest info --stanza=db --output=json) | jq -r '.[0].db[0].version')

# Check if current postgresql versions mapped to current stanza version. If not do a stanza upgrade 
if [ "$pg_version" != "$stanza_version" ]; then
  echo "Stanza version matches another PostgreSQL version: A Stanza upgrade is required to ensure that pgBackRest can work with the current version of PostgreSQL"
  pgbackrest stanza-upgrade --stanza=db
else
  echo "Stanza is up to date. No change required."
fi