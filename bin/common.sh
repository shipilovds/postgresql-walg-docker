
if [[ -z "$WALG_LOG_DEST" ]]; then
  WALG_LOG_DEST=/proc/1/fd/1
fi

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
