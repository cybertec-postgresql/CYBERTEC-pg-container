#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

PGVER=$(psql -d "$2" -XtAc "SELECT pg_catalog.current_setting('server_version_num')::int/10000")
if [ "$PGVER" -ge 12 ]; then RESET_ARGS="oid, oid, bigint"; fi
if [ "$PGVER" -ge 17 ]; then RESET_ARGS="oid, oid, bigint, boolean"; fi

(
cat - <<SQL
 DO \$\$
 BEGIN
     PERFORM * FROM pg_catalog.pg_authid WHERE rolname = 'admin';
     IF FOUND THEN
         ALTER ROLE admin WITH CREATEDB NOLOGIN NOCREATEROLE NOSUPERUSER NOREPLICATION INHERIT;
     ELSE
         CREATE ROLE admin CREATEDB;
     END IF;
 END;\$\$;

 DO \$\$
 BEGIN
     PERFORM * FROM pg_catalog.pg_authid WHERE rolname = '$1';
     IF FOUND THEN
         ALTER ROLE $1 WITH NOCREATEDB NOLOGIN NOCREATEROLE NOSUPERUSER NOREPLICATION INHERIT;
     ELSE
         CREATE ROLE $1;
    END IF;
 END;\$\$;
SQL

while IFS= read -r db_name; do
    echo "\c ${db_name}"
    # In case if timescaledb binary is missing the first query fails with the error
    # ERROR:  could not access file "$libdir/timescaledb-$OLD_VERSION": No such file or directory
    UPGRADE_TIMESCALEDB=$(echo -e "SELECT NULL;\nSELECT default_version != installed_version FROM pg_catalog.pg_available_extensions WHERE name = 'timescaledb'" | psql -tAX -d "${db_name}" 2> /dev/null | tail -n 1)
    if [ "$UPGRADE_TIMESCALEDB" = "t" ]; then
        echo "ALTER EXTENSION timescaledb UPDATE;"
    fi
    UPGRADE_TIMESCALEDB_TOOLKIT=$(echo -e "SELECT NULL;\nSELECT default_version != installed_version FROM pg_catalog.pg_available_extensions WHERE name = 'timescaledb_toolkit'" | psql -tAX -d "${db_name}" 2> /dev/null | tail -n 1)
    if [ "$UPGRADE_TIMESCALEDB_TOOLKIT" = "t" ]; then
        echo "ALTER EXTENSION timescaledb_toolkit UPDATE;"
    fi
    UPGRADE_POSTGIS=$(echo -e "SELECT COUNT(*) FROM pg_catalog.pg_extension WHERE extname = 'postgis'" | psql -tAX -d "${db_name}" 2> /dev/null | tail -n 1)
    if [ "$UPGRADE_POSTGIS" = "1" ]; then
        # public.postgis_lib_version() is available only if postgis extension is created
        UPGRADE_POSTGIS=$(echo -e "SELECT extversion != public.postgis_lib_version() FROM pg_catalog.pg_extension WHERE extname = 'postgis'" | psql -tAX -d "${db_name}" 2> /dev/null | tail -n 1)
        if [ "$UPGRADE_POSTGIS" = "t" ]; then
            echo "ALTER EXTENSION postgis UPDATE;"
            echo "SELECT public.postgis_extensions_upgrade();"
        fi
    fi
    sed "s/:HUMAN_ROLE/$1/" create_user_functions.sql
    echo "CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA public;
GRANT EXECUTE ON FUNCTION public.pg_stat_statements_reset($RESET_ARGS) TO admin;"

done < <(psql -d "$2" -tAc 'select pg_catalog.quote_ident(datname) from pg_catalog.pg_database where datallowconn')
) | PGOPTIONS="-c synchronous_commit=local" psql -Xd "$2" -f -

