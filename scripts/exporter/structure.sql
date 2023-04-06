
# User
CREATE ROLE postgres_exporter with password 'password';
ALTER ROLE postgres_exporter login;

GRANT pg_monitor TO postgres_exporter;
GRANT SELECT ON TABLE pg_authid TO postgres_exporter;

// Structure

CREATE SCHEMA exporter;

ALTER SCHEMA exporter OWNER TO postgres_exporter;

CREATE TABLE exporter.pgbackrestbackupinfo (
    name text NOT NULL,
    data jsonb NOT NULL,
    data_time timestamp with time zone DEFAULT now() NOT NULL
)
WITH (autovacuum_analyze_scale_factor='0', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='8', autovacuum_analyze_threshold='8');

ALTER TABLE exporter.pgbackrestbackupinfo OWNER TO postgres_exporter;

CREATE TABLE exporter.storageUsage (
    name text NOT NULL,
    data jsonb NOT NULL,
    data_time timestamp with time zone DEFAULT now() NOT NULL
)
WITH (autovacuum_analyze_scale_factor='0', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='8', autovacuum_analyze_threshold='8');

ALTER TABLE exporter.storageUsage OWNER TO postgres_exporter;

EXECUTE COPY exporter.storageUsage (config_file, data) FROM program '/home/postgres/pgbackrest/test.sh' ;



CREATE or replace FUNCTION exporter.test() RETURNS boolean AS $$
  my $filename = '/home/postgres/pgbackrest/test.sh';
  if (-e $filename) { 
    system '/home/postgres/pgbackrest/test.sh' and return 1;
  }
  return;
$$ LANGUAGE plperlu;




CREATE OR REPLACE FUNCTION exporter.test() RETURNS SETOF exporter.storageUsage
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $_$
DECLARE
 
BEGIN
-- Get pgBackRest info in JSON format

-- Ensure table is empty 
DELETE FROM exporter.storageUsage;

-- Copy data into the table directory from the pgBackRest into command
COPY exporter.storageUsage (data) FROM '/home/postgres/pgdata/pgbackrest/test.sh' ;


RETURN QUERY SELECT * FROM exporter.storageUsage;

IF NOT FOUND THEN
    RAISE EXCEPTION 'No Data found';
END IF;

END 
$_$;

CREATE FUNCTION exporter.get_pgbackrest_backupdata(p_throttle_minutes integer DEFAULT 10) RETURNS SETOF exporter.pgbackrestbackupinfo
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog', 'pg_temp'
    AS $_$
DECLARE

v_gather_timestamp      timestamptz;
v_throttle              interval;
v_system_identifier     bigint;
 
BEGIN
-- Get pgBackRest info in JSON format

v_throttle := make_interval(mins := p_throttle_minutes);

SELECT COALESCE(max(gather_timestamp), '1970-01-01'::timestamptz) INTO v_gather_timestamp FROM monitor.pgbackrest_info;

IF pg_catalog.pg_is_in_recovery() = 'f' THEN
    IF ((CURRENT_TIMESTAMP - v_gather_timestamp) > v_throttle) THEN

        -- Ensure table is empty 
        DELETE FROM monitor.pgbackrest_info;

        SELECT system_identifier into v_system_identifier FROM pg_control_system();

        -- Copy data into the table directory from the pgBackRest into command
        EXECUTE format( $cmd$ COPY exporter.pgbackrestbackupinfo (config_file, data) FROM program '/opt/crunchy/bin/postgres/pgbackrest_info.sh %s' WITH (format text,DELIMITER '|') $cmd$, v_system_identifier::text );

    END IF;
END IF;

RETURN QUERY SELECT * FROM monitor.pgbackrest_info;

IF NOT FOUND THEN
    RAISE EXCEPTION 'No backups being returned from pgbackrest info command';
END IF;

END 
$_$;