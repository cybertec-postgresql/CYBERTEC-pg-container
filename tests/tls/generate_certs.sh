#!/usr/bin/env bash
set -euo pipefail

CERTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
mkdir -p "${CERTS_DIR}/ca" \
         "${CERTS_DIR}/server" \
         "${CERTS_DIR}/client"

cd "${CERTS_DIR}"

openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout ca/ca.key -out ca/ca.crt \
    -subj "/CN=cybertectest CA"

openssl req -newkey rsa:2048 -nodes \
    -keyout server/server.key -out server/server.crt \
    -subj "/CN=pgbackrest" \
    -addext "subjectAltName=DNS:pgbackrest,DNS:pgcontainer1,DNS:pgcontainer2,DNS:localhost"
openssl x509 -req -in server/server.crt \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial -days 3650 \
    -copy_extensions copyall \
    -out server/server.crt

openssl req -newkey rsa:2048 -nodes \
    -keyout client/client.key -out client/client.crt \
    -subj "/CN=postgres" \
    -addext "subjectAltName=DNS:pgcontainer1,DNS:pgcontainer2"
openssl x509 -req -in client/client.crt \
    -CA ca/ca.crt -CAkey ca/ca.key -CAcreateserial -days 3650 \
    -copy_extensions copyall \
    -out client/client.crt

docker run --rm \
    -v "${CERTS_DIR}:/certs:rw" \
    --user 0:0 \
    "${PG_IMAGE}" \
    sh -c '
        chown 26:26 /certs/ca/ca.key /certs/server/server.key /certs/client/client.key && \
        chmod 600 /certs/ca/ca.key /certs/server/server.key /certs/client/client.key && \
        chmod 644 /certs/ca/ca.crt /certs/server/server.crt /certs/client/client.crt
    '
