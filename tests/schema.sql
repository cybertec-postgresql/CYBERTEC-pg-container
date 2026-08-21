CREATE ROLE pgbouncer WITH PASSWORD 'cpo_defaultPGBouncerPW' LOGIN;
CREATE ROLE app_user WITH PASSWORD 'password' LOGIN;

SELECT $pgbouncer_query$
    CREATE SCHEMA pgbouncer;
    GRANT USAGE ON SCHEMA pgbouncer TO pgbouncer;
    CREATE OR REPLACE FUNCTION pgbouncer.user_lookup(in i_username text, out uname text, out phash text)
    RETURNS record AS $$
    BEGIN
        SELECT rolname, CASE WHEN rolvaliduntil < now() THEN NULL ELSE rolpassword END
        FROM pg_authid
        WHERE rolname=i_username AND rolcanlogin
        INTO uname, phash;
        RETURN;
    END;
    $$ LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = pg_catalog, pg_temp;
    REVOKE ALL ON FUNCTION pgbouncer.user_lookup(text) FROM public, pgbouncer;
    GRANT EXECUTE ON FUNCTION pgbouncer.user_lookup(text) TO pgbouncer;
$pgbouncer_query$ AS create_user_lookup \gset

:create_user_lookup

CREATE DATABASE test_db;
\c test_db

:create_user_lookup

CREATE UNLOGGED TABLE "bAr" ("bUz" INTEGER);
ALTER TABLE "bAr" ALTER COLUMN "bUz" SET STATISTICS 500;
INSERT INTO "bAr" SELECT generate_series(1, 100000);
