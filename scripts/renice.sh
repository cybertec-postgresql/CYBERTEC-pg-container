#!/bin/bash

set -Eeuo pipefail

ppid=$(head -n1 /home/postgres/pgdata/pgroot/data/postmaster.pid)

ps -eo pid,ppid,args \
   | awk "/ $ppid postgres: .* (checkpointer|archiver|startup|walsender|walreceiver) / {print \$1}" \
   | xargs renice -n -20 -p &> /tmp/renice.log
