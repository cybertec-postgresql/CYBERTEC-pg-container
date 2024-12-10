import argparse
import logging
import os
import subprocess
import sys

from collections import namedtuple
from dateutil.parser import parse

logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

def read_configuration():
    parser = argparse.ArgumentParser(description="Script to clone using pgbackrest. ")
    parser.add_argument('--scope', required=True, help='target cluster name')
    parser.add_argument('--datadir', required=True, help='target cluster postgres data directory')
    parser.add_argument('--recovery-target-time',
                        help='the timestamp up to which recovery will proceed (including time zone)',
                        dest='recovery_target_time_string')
    parser.add_argument('--config-include-path',
                        help='pgbackrest configuration directory')    
    args = parser.parse_args()

    options = namedtuple('Options', 'name datadir recovery_target_time config_include_path')
    if args.recovery_target_time_string:
        recovery_target_time = parse(args.recovery_target_time_string)
        if recovery_target_time.tzinfo is None:
            raise Exception("recovery target time must contain a timezone")
    else:
        recovery_target_time = None

    return options(args.scope, args.datadir, recovery_target_time, args.config_include_path)

def run_clone_from_pgbackrest(options):
    env = os.environ.copy()

    pg_path_argument = "--pg1-path={0}".format(options.datadir)

    pgbackrest_command = ['/usr/bin/pgbackrest', 'restore', '--stanza=db', pg_path_argument]

    if options.config_include_path:
        pgbackrest_command.extend(['--config-include-path=' + options.config_include_path])

    if options.recovery_target_time:
        target_time_argument = "--target={0}".format(options.recovery_target_time)
        pgbackrest_command.extend(['--type=time', target_time_argument])
    
    logger.info("cloning cluster %s using %s", options.name, ' '.join(pgbackrest_command))

    ret = subprocess.call(pgbackrest_command, env=env)
    if ret != 0:
        logger.error("pgbackrest restore exited with exit code {0}".format(ret))
        return ret

    return 0

def main():
    try:
        options = read_configuration()
        run_clone_from_pgbackrest(options)
    except Exception:
        logger.exception("Clone with pgbackrest failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
