
export WALG_VALIDATE_S3_PREFIX=${WALG_VALIDATE_S3_PREFIX:-'true'}
export WALG_ENABLED=${WALG_ENABLED:-'false'} 
export WALG_RESTORE=${WALG_RESTORE:-'false'}
export WALG_LOG_DEST=${WALG_LOG_DEST:-/dev/stdout}
export MAINTENANCE=${MAINTENANCE:-'false'}
export DEFAULT_S3_PREFIX=${DEFAULT_S3_PREFIX:-'s3://wal-g/'}

USER=$(whoami)
if [[ $USER == postgres ]]; then
    PREFIX=''
else
    PREFIX='sudo -E -u postgres'
fi


log() {
    if [[ $WALG_LOG_DEST == /dev/stdout ]]; then
        echo "$(date '+%Y-%m-%d %T.%3N') $1"
    else
        echo "$(date '+%Y-%m-%d %T.%3N') $1" | sudo tee $WALG_LOG_DEST > /dev/null
    fi
}

ensure_vars_defined() {
  arr=( "$@" )
  for var in "${arr[@]}"; do
    if [[ ! -v "$var" ]]; then
      log "ERROR: ${var} variable is undefined!"
      log 'ERROR: Script Failed'
      exit 1
    fi
  done
}

run_cmd() {
    # run command and get output
    set +e
    CMD_OUTPUT=$($@ 2>&1)
    ERRCODE=$?
    set -e
    # log command output
    IFS=$'\n'
    for line in $CMD_OUTPUT; do
        log "$line"
    done
    unset IFS
}

generate_postgres_conf() {
    envtpl /etc/postgres/postgresql.conf.tpl | sudo tee $PGDATA/postgresql.conf > /dev/null
}

s3_connect() {
    if [[ "$WALG_ENABLED" == "false" ]]; then
            log "INFO: WAL-G is Disabled by 'WALG_ENABLED=false' env"
            return
    fi
    if [[ -z "$WALG_S3_PREFIX" ]] || [[ -z "$AWS_ACCESS_KEY_ID" ]] || [[ -z "$AWS_ENDPOINT" ]] || [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
       log "WARNING: WAL_G is enabled, but variables for S3 connection are undefined. Postgres wal archive will not work."
       echo
    fi
}

maintenance() {
    export MAINTENANCE=${MAINTENANCE:-'false'}
    if [[ $MAINTENANCE == 'true' ]]; then
	log "WARNING: Maintenance mode is enabled. All services have been stopped."
        while true; do sleep 1; done
    fi
}

check_maintenance() {
    if [[ $MAINTENANCE == 'true' ]]; then
        log "ERROR: Maintenance mode is enabled. Can not make any push."
        exit 1
    fi
}

check_walg_enabled() {
    if [[ "$WALG_ENABLED" == "false" ]]; then
          log "INFO: WAL-G is Disabled by 'WALG_ENABLED=false' env. Exiting."
          exit 1
    fi
}

check_if_master() {
    pg_is_in_recovery=$(psql -U ${POSTGRES_USER} -t -c "SELECT pg_is_in_recovery()")
    if [[ $pg_is_in_recovery != " f" ]]; then
        log "ERROR: Curently this instance is not a MASTER! Backup command will not be executed!"
	exit 1
    fi
}

validate_s3_prefix() {
    if [[ "$WALG_S3_PREFIX" != "$DEFAULT_S3_PREFIX"* ]] && [[ "$WALG_VALIDATE_S3_PREFIX" == "true" ]]; then
        log "ERROR: Wrong WALG_S3_PREFIX format or path. Try to set variable value like this: s3://wal-g/your-instance-name/ "
        echo
        exit 1
    fi
}
