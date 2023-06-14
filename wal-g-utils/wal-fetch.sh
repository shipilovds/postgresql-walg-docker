#!/bin/bash
set -e

source "/var/lib/wal-g-utils/common.sh"

log "INFO: Start Fetching WAL Backup ($(basename "$0"))"

VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGDATA )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined $VARS

CMD="$PREFIX /usr/bin/wal-g wal-fetch $1 $2"

# run command and get ERRCODE
run_cmd $CMD

if [[ $ERRCODE == 0 ]]; then
  MSG='INFO: WAL Fetch Completed'
else
  MSG='ERROR: WAL Fetch Failed'
fi

log "$MSG"
exit $ERRCODE
