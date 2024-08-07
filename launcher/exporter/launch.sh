#!/bin/bash
# Start the Exporter

EXPORTER_DIR='/postgres_exporter'
QUERIE_FOLDER="$EXPORTER_DIR/queries"
FILES="${QUERIE_FOLDER}/*"
touch /tmp/cpo_queries.yaml
for file in $FILES
do
  if [[ -f ${file?} ]]
  then
            cat ${file?} >> /tmp/cpo_queries.yaml
        else
            echo ${FILES}
            echo "Query file ${file?} does not exist (it should).."
            exit 1
        fi
done

/bin/postgres_exporter --extend.query-path=/tmp/cpo_queries.yaml #--auto-discover-databases