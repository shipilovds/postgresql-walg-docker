#!/bin/bash
set -e

CWD="$(dirname "$0")"
source "$CWD/common.sh"

log "INFO: Start Backup ($(basename "$0"))"

# mandatory env vars
VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGDATA POSTGRES_PASSWORD )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined "${VARS[@]}"

# check if optional env vars are defined or set default values
if [[ -z "$POSTGRES_USER" ]]; then
  POSTGRES_USER='postgres'
fi

if [[ -z "$POSTGRES_DB" ]]; then
  POSTGRES_DB='postgres'
fi

if [[ -z "$WALG_BACKUP_ARGS" ]]; then
  WALG_BACKUP_ARGS="--pguser $POSTGRES_USER --pgpassword $POSTGRES_PASSWORD --pgdatabase $POSTGRES_DB"
fi

# define backup command
CMD="$PREFIX /usr/local/bin/wal-g backup-push $WALG_BACKUP_ARGS $PGDATA"

# run command and get ERRCODE
run_cmd $CMD

if [[ $ERRCODE == 0 ]]; then
  MSG='INFO: Backup Completed'
else
  MSG='ERROR: Backup Failed'
fi

log "$MSG"
exit $ERRCODE
