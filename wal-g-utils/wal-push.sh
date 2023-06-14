#!/bin/bash
set -e

source "/var/lib/wal-g-utils/common.sh"

log "INFO: Start WAL Backup($(basename "$0"))"

check_maintenance
check_walg_enabled
check_if_master

# mandatory env vars
VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGDATA )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined "${VARS[@]}"

# define backup command
CMD="$PREFIX /usr/bin/wal-g wal-push $PGDATA/$1"

# run command and get ERRCODE
run_cmd $CMD

if [[ $ERRCODE == 0 ]]; then
  MSG='INFO: WAL Backup Completed'
else
  MSG='ERROR: WAL Backup Failed'
fi

log "$MSG"
exit $ERRCODE
