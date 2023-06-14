#!/bin/bash
set -e

WALG_LOG_DEST=/dev/stdout
source "/var/lib/wal-g-utils/common.sh"

log "INFO: Listing Backups ($(basename "$0"))"

VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined "${VARS[@]}"

CMD='/usr/bin/wal-g backup-list'

# run command and get ERRCODE
run_cmd $CMD

if [[ $ERRCODE == 0 ]]; then
  MSG='INFO: Listing Backups Completed'
else
  MSG='ERROR: Listing Backups Failed'
fi

log "$MSG"
exit $ERRCODE
