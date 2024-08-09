#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    sed -e "s/^pgbouncer:x:[^:]*:[^:]*:/pgbouncer:x:$(id -u):$(id -g):/" /etc/passwd > "$RW_DIR/tmp/passwd"
    cat "$RW_DIR/tmp/passwd" > /etc/passwd
    rm "$RW_DIR/tmp/passwd"
fi

set -ex

if [ "$PGUSER" = "postgres" ]; then
    echo "WARNING: pgbouncer will connect with a superuser privileges!"
    echo "You need to fix this as soon as possible."
fi

mkdir -p /tmp/pgbouncer/certs

if [ -z "${CONNECTION_POOLER_CLIENT_TLS_CRT}" ]; then
    openssl req -nodes -new -x509 -subj /CN=spilo.dummy.org \
        -keyout /tmp/pgbouncer/certs/pgbouncer.key \
        -out /tmp/pgbouncer/certs/pgbouncer.crt
        # -keyout /etc/ssl/certs/pgbouncer.key \
        # -out /etc/ssl/certs/pgbouncer.crt
else
    ln -s ${CONNECTION_POOLER_CLIENT_TLS_CRT} /tmp/pgbouncer/certs/pgbouncer.crt
    ln -s ${CONNECTION_POOLER_CLIENT_TLS_KEY} /tmp/pgbouncer/certs/pgbouncer.key
    if [ ! -z "${CONNECTION_POOLER_CLIENT_CA_FILE}" ]; then
        ln -s ${CONNECTION_POOLER_CLIENT_CA_FILE} /tmp/pgbouncer/certs/ca.crt
    fi
    # ln -s ${CONNECTION_POOLER_CLIENT_TLS_CRT} /etc/ssl/certs/pgbouncer.crt
    # ln -s ${CONNECTION_POOLER_CLIENT_TLS_KEY} /etc/ssl/certs/pgbouncer.key
    # if [ ! -z "${CONNECTION_POOLER_CLIENT_CA_FILE}" ]; then
    #     ln -s ${CONNECTION_POOLER_CLIENT_CA_FILE} /etc/ssl/certs/ca.crt
    # fi
fi

if [ "$ADDITIONAL_PGBOUNCER_CONFIG" ]; then
    bouncerConfigPath="$ADDITIONAL_PGBOUNCER_CONFIG"
else
    envsubst < /etc/pgbouncer/pgbouncer.ini.tmpl > /tmp/pgbouncer/pgbouncer.ini
    envsubst < /etc/pgbouncer/auth_file.txt.tmpl > /tmp/pgbouncer/auth_file.txt
    bouncerConfigPath="/tmp/pgbouncer/pgbouncer.ini"
fi

./bin/pgbouncer $bouncerConfigPath
