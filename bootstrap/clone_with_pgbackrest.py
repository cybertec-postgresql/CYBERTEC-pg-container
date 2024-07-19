import argparse
import csv
import logging
import os
import re
import shlex
import subprocess
import sys

from collections import namedtuple

logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

def read_configuration():
    parser = argparse.ArgumentParser(description="Script to clone using pgbackrest. ")
    parser.add_argument('--scope', required=True, help='target cluster name')
    parser.add_argument('--datadir', required=True, help='target cluster postgres data directory')
    parser.add_argument('--dry-run', action='store_true', help='find a matching backup and build the wal-e '
                        'command to fetch that backup without running it')
    args = parser.parse_args()

    options = namedtuple('Options', 'name datadir dry_run')
    return options(args.scope, args.datadir, args.dry_run)

def run_clone_from_pgbackrest(options):
    env = os.environ.copy()

    pg_path_argument = "--pg1-path={0}".format(options.datadir)
    pgbackrest_command = ['/usr/bin/pgbackrest', '--stanza=db', 'restore', pg_path_argument]
    
    logger.info("cloning cluster %s using %s", options.name, ' '.join(pgbackrest_command))

    if not options.dry_run:
        ret = subprocess.call(pgbackrest_command, env=env)
        if ret != 0:
            raise Exception("pgbackrest restore exited with exit code {0}".format(ret))

    return 0

def main():
    options = read_configuration()
    try:
        run_clone_from_pgbackrest(options)
    except Exception:
        logger.exception("Clone with pgbackrest failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())