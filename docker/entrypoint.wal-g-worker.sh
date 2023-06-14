#!/usr/bin/env bash

set -Eeuo pipefail

source "/var/lib/wal-g-utils/common.sh"

log "INFO: Start WAL-G Worker"

maintenance

# mandatory env vars
VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGHOST PGUSER )

# ensure that mandatory env vars are defined or exit script
ensure_vars_defined "${VARS[@]}"

# Check S3 connection and setup
log "INFO: Trying to connect to storage $AWS_ENDPOINT"
mc config host add s3 $AWS_ENDPOINT $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY > /dev/null
log "INFO: Connection with storage has been established"

# Check S3 prefix format:
validate_s3_prefix

# Ensure that storage space has been created
mc mb -p "$(echo $WALG_S3_PREFIX | sed 's|:/||')"
log "INFO: Storage space for host created"
echo

# Run CMD
$@
