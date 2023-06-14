#!/bin/bash
set -e

#WALG_LOG_DEST=/dev/stdout
CWD="$(dirname "$0")"
source "$CWD/common.sh"

VARS=( PGHOST POSTGRES_USER )

ensure_vars_defined "${VARS[@]}"

## see init_test_db.sql
#psql -U ${POSTGRES_USER}  -c "create database test1;"
#psql -U ${POSTGRES_USER} -d test1 -c "CREATE TABLE indexing_table(created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW());"

log "Run SQL insert ($(basename "$0"))"

## There is some troubles with quotes here. So we will run it below as it is.
#CMD="${PREFIX} psql -U "${POSTGRES_USER}" -d "test1" -c "INSERT INTO indexing_table(created_at) VALUES (CURRENT_TIMESTAMP);""
#run_cmd $CMD

${PREFIX} psql -U "${POSTGRES_USER}" -d "test1" -c "INSERT INTO indexing_table(created_at) VALUES (CURRENT_TIMESTAMP);" >> $WALG_LOG_DEST
