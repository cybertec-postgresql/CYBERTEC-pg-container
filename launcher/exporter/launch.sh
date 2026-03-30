#!/bin/bash

EXPORTER_DIR='/postgres_exporter'
TEMP_QUERY_FILE='/tmp/cpo_queries.yaml'
CONFIG_FILE='/tmp/cpo_exporter_configuration.yaml'

# query folder definition
QUERY_DIRS=(
  "$EXPORTER_DIR/queries"
  "$EXPORTER_DIR/version_specific/$PGVERSION"
  "$EXPORTER_DIR/custom_queries"
)

# create files for config and queries
> "$TEMP_QUERY_FILE"
echo "{}" > "$CONFIG_FILE"

for dir in "${QUERY_DIRS[@]}"; do
  if [ -d "$dir" ] && [ "$(ls -A "$dir" 2>/dev/null)" ]; then
    for file in "$dir"/*; do
      if [[ -f "$file" ]]; then
        cat "$file" >> "$TEMP_QUERY_FILE"
        echo "" >> "$TEMP_QUERY_FILE"
      fi
    done
  fi
done

# Check if query file is empty
if [ ! -s "$TEMP_QUERY_FILE" ]; then
  echo "INFO: queries.yaml is empty"
fi

echo "Start postgres_exporter..."
/bin/postgres_exporter \
  --config.file="$CONFIG_FILE" \
  --extend.query-path="$TEMP_QUERY_FILE"
