#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

PGVER=$(psql -d "$2" -XtAc "SELECT pg_catalog.current_setting('server_version_num')::int/10000")
if [ "$PGVER" -ge 12 ]; then RESET_ARGS="oid, oid, bigint"; fi

(echo "DO \$\$
BEGIN
    PERFORM * FROM pg_catalog.pg_authid WHERE rolname = 'admin';
    IF FOUND THEN
        ALTER ROLE admin WITH CREATEDB NOLOGIN NOCREATEROLE NOSUPERUSER NOREPLICATION INHERIT;
    ELSE
        CREATE ROLE admin CREATEDB;
    END IF;

    PERFORM * FROM pg_catalog.pg_authid WHERE rolname = 'cron_admin';
    IF FOUND THEN
        ALTER ROLE cron_admin WITH NOCREATEDB NOLOGIN NOCREATEROLE NOSUPERUSER NOREPLICATION INHERIT;
    ELSE
        CREATE ROLE cron_admin;
    END IF;
END;\$\$;

GRANT cron_admin TO admin;

DO \$\$
BEGIN
    PERFORM * FROM pg_catalog.pg_authid WHERE rolname = '$1';
    IF FOUND THEN
        ALTER ROLE $1 WITH NOCREATEDB NOLOGIN NOCREATEROLE NOSUPERUSER NOREPLICATION INHERIT;
    ELSE
        CREATE ROLE $1;
    END IF;
END;\$\$;

CREATE TABLE IF NOT EXISTS public.postgres_log (
    log_time timestamp(3) with time zone,
    user_name text,
    database_name text,
    process_id integer,
    connection_from text,
    session_id text NOT NULL,
    session_line_num bigint NOT NULL,
    command_tag text,
    session_start_time timestamp with time zone,
    virtual_transaction_id text,
    transaction_id bigint,
    error_severity text,
    sql_state_code text,
    message text,
    detail text,
    hint text,
    internal_query text,
    internal_query_pos integer,
    context text,
    query text,
    query_pos integer,
    location text,
    application_name text,
    CONSTRAINT postgres_log_check CHECK (false) NO INHERIT
);
GRANT SELECT ON public.postgres_log TO admin;"
if [ "$PGVER" -ge 13 ]; then
    echo "ALTER TABLE public.postgres_log ADD COLUMN IF NOT EXISTS backend_type text;"
fi
if [ "$PGVER" -ge 14 ]; then
    echo "ALTER TABLE public.postgres_log ADD COLUMN IF NOT EXISTS leader_pid integer;"
    echo "ALTER TABLE public.postgres_log ADD COLUMN IF NOT EXISTS query_id bigint;"
fi

# Sunday could be 0 or 7 depending on the format, we just create both
for i in $(seq 0 7); do
    echo "CREATE FOREIGN TABLE IF NOT EXISTS public.postgres_log_$i () INHERITS (public.postgres_log) SERVER pglog
    OPTIONS (filename '../pg_log/postgresql-$i.csv', format 'csv', header 'false');
GRANT SELECT ON public.postgres_log_$i TO admin;

CREATE OR REPLACE VIEW public.failed_authentication_$i WITH (security_barrier) AS
SELECT *
  FROM public.postgres_log_$i
 WHERE command_tag = 'authentication'
   AND error_severity = 'FATAL';
ALTER VIEW public.failed_authentication_$i OWNER TO postgres;
GRANT SELECT ON TABLE public.failed_authentication_$i TO robot_zmon;
"
done

cat _zmon_schema.dump

while IFS= read -r db_name; do
    echo "\c ${db_name}"
    # In case if timescaledb binary is missing the first query fails with the error
    # ERROR:  could not access file "$libdir/timescaledb-$OLD_VERSION": No such file or directory
    UPGRADE_TIMESCALEDB=$(echo -e "SELECT NULL;\nSELECT default_version != installed_version FROM pg_catalog.pg_available_extensions WHERE name = 'timescaledb'" | psql -tAX -d "${db_name}" 2> /dev/null | tail -n 1)
    if [ "$UPGRADE_TIMESCALEDB" = "t" ]; then
        echo "ALTER EXTENSION timescaledb UPDATE;"
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
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache SCHEMA public;
CREATE EXTENSION IF NOT EXISTS set_user SCHEMA public;
ALTER EXTENSION set_user UPDATE;
GRANT EXECUTE ON FUNCTION public.set_user(text) TO admin;
GRANT EXECUTE ON FUNCTION public.pg_stat_statements_reset($RESET_ARGS) TO admin;"
    if [ "$PGVER" -lt 10 ]; then
        echo "GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_xlog() TO admin;"
    else
        echo "GRANT EXECUTE ON FUNCTION pg_catalog.pg_switch_wal() TO admin;"
    fi
    if [ "$ENABLE_PG_MON" = "true" ] && [ "$PGVER" -ge 11 ]; then echo "CREATE EXTENSION IF NOT EXISTS pg_mon SCHEMA public;"; fi
    cat metric_helpers.sql

# CPO-Monitoring
echo "GRANT pg_monitor TO cpo_exporter;
GRANT SELECT ON TABLE pg_authid TO cpo_exporter;";

# Structure

echo "CREATE SCHEMA IF NOT EXISTS exporter;
ALTER SCHEMA exporter OWNER TO cpo_exporter;
CREATE EXTENSION IF NOT EXISTS pgnodemx SCHEMA exporter;
ALTER EXTENSION pgnodemx UPDATE;

CREATE TABLE exporter.pgbackrestbackupinfo (
    name text NOT NULL,
    data jsonb NOT NULL,
    data_time timestamp with time zone DEFAULT now() NOT NULL
)
WITH (autovacuum_analyze_scale_factor='0', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='2', autovacuum_analyze_threshold='2');
ALTER TABLE exporter.pgbackrestbackupinfo OWNER TO cpo_exporter;";

done < <(psql -d "$2" -tAc 'select pg_catalog.quote_ident(datname) from pg_catalog.pg_database where datallowconn')
) | PGOPTIONS="-c synchronous_commit=local" psql -Xd "$2"

