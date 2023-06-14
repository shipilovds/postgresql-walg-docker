#!/usr/bin/env bash

set -Eeo pipefail

source "/var/lib/wal-g-utils/common.sh"

log "INFO: Start PostgresQL Database Recovery"

VARS=( WALG_S3_PREFIX AWS_ACCESS_KEY_ID AWS_ENDPOINT AWS_SECRET_ACCESS_KEY PGDATA )

ensure_vars_defined "${VARS[@]}"

dialog --yesno "This is PostgresQL restoration script that uses wal-g to fetch data from backup.\nChoose 'Yes' to continue or 'No' to exit now...\nWizard will close if you choose 'Cancel' in any dialog." 10 80

recovery_type=$(dialog --stdout --menu "Choose type of recovery" 10 60 3 "FULL" "Full Recovery (Latest State)" "PITR" "Point In Time Recovery (Select Date/Time)")
# default backup - latest
backup_name=LATEST

export WALG_RESTORE=true

if [[ $recovery_type == PITR ]]; then
    orig_log=$(/var/lib/wal-g-utils/backup-list.sh | sed '1,2d; $d' | tr -s ' ')
    
    options=''
    
    while IFS='\n' read -r line; do
        options+=$(echo "$line" | cut -d ' ' -f 3)
        options+=' '
        options+=$(echo "$line" | cut -d ' ' -f 4)
        options+=' '
    
    done < <( echo "$orig_log")
    
    backup_name=$( dialog --stdout --menu "Choose one:" 30 90 10 $options )
    
    cur_date=$(date +"%d %m %Y")
    date=$(dialog --stdout --date-format "%Y-%m-%d" --calendar "Select date" 5 50 $cur_date)
    
    cur_time=$(date +"%H %m %S")
    time=$(dialog --stdout --time-format "%H:%m:%S" --timebox "Choose time" 5 1 $cur_time)

    export WALG_RESTORE="$date $time"
fi

clear

log "INFO: Cleaning PGDATA..."
rm -rf $PGDATA/*
cd $PGDATA

log "INFO: Fetching Backup from $WALG_S3_PREFIX"
$PREFIX /var/lib/wal-g-utils/backup-fetch.sh $backup_name
if [[ $? == 0 ]]; then
  log 'INFO: Backup Fetch Completed'
else
  log 'ERROR: Backup Fetch Failed. Exiting...'
  exit 1
fi

$PREFIX touch recovery.signal

log "INFO: Recovery signal created"
generate_postgres_conf
log "INFO: PostgresQL Recovery config generated"
log "INFO: Ready to start recovery process"
log ""
log "INFO: To run recovery:"
log "INFO:       # sudo -E -u postgres /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl start"
log "INFO: To stop server:"
log "INFO:       # sudo -E -u postgres /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl stop"
log ""
log "INFO: If everyting went well - do not forget to check that $PGDATA/recovery.signal is absent!"
log ""
log "INFO: Then you must stop docker-compose and set variables:"
log "INFO:     MAINTENANCE=false"
log "INFO:     WALG_ENABLED=false"
log "INFO: After new start, when you make sure that everything is fine - you can set WALG_ENABLED=true again and restart"
