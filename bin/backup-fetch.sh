#!/bin/bash
set -e

BACKUP_POINT=${1:-LATEST}
WALG_LOG_DEST=/dev/stdout
CWD="$(dirname "$0")"
source "$CWD/common.sh"

log "INFO: Start Fetching $BACKUP_POINT Backup ($(basename "$0"))"

# mandatory env vars
VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGDATA )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined "${VARS[@]}"

CMD="$PREFIX /usr/local/bin/wal-g backup-fetch $PGDATA $BACKUP_POINT"

# run command and get ERRCODE
run_cmd $CMD

if [[ $ERRCODE == 0 ]]; then
  MSG='INFO: Fetching Backup Completed'
else
  MSG='ERROR: Fetching Backup Failed'
fi

log "$MSG"
exit $ERRCODE
