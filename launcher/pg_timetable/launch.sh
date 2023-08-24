#!/bin/bash
# Start pg_timetable

cd pg_timetable && ./pg_timetable --dbname=${PGTT_PGDATABASE} --clientname=${PGTT_CLIENTNAME} --user=${PGTT_PGUSER} --password=${PGTT_PGPASSWORD}
