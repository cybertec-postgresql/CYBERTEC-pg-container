#!/bin/bash
# Start the Exporter

EXPORTER_DIR='/postgres_exporter'
QUERIE_FOLDER="$EXPORTER_DIR/queries"
VERSION_SPECIFIC_FOLDER="$EXPORTER_DIR/version_specific/$PGVERSION"
FILES="${QUERIE_FOLDER}/*"
TEMP_QUERY_FILE='/tmp/cpo_queries.yaml'

> $TEMP_QUERY_FILE

for file in $FILES
do
  if [[ -f "$file" ]]; then
    cat "$file" >> "$TEMP_QUERY_FILE"
  else
    echo "Query file $file does not exist (it should).."
    exit 1
  fi
done

# VERSION_FILES="${VERSION_SPECIFIC_FOLDER}/*"
# for version_file in $VERSION_FILES
# do
#   if [[ -f "$version_file" ]]; then
#     cat "$version_file" >> "$TEMP_QUERY_FILE"
#   else
#     echo "Version-specific query file $version_file does not exist for PGVERSION $PGVERSION (it should).."
#     exit 1
#   fi
# done

/bin/postgres_exporter --extend.query-path=/tmp/cpo_queries.yaml #--auto-discover-databases