# -----------------------------
# PostgreSQL configuration file
# -----------------------------
datestyle = 'iso, mdy'
default_text_search_config = 'pg_catalog.english'
dynamic_shared_memory_type = posix
hba_file = '/etc/postgres/pg_hba.conf'
lc_messages = 'en_US.utf8'
lc_monetary = 'en_US.utf8'
lc_numeric = 'en_US.utf8'
lc_time = 'en_US.utf8'
listen_addresses = '*'
log_line_prefix = '%m: '
log_timezone = 'UTC'
max_connections = 100
shared_buffers = 128MB
timezone = 'UTC'

# wal settings
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

{{ if eq (.WALG_ENABLED|toString) "true" -}}
# archive mode settings
archive_mode = on
archive_command = '/var/lib/wal-g-utils/wal-push.sh %p'
archive_timeout = 600
{{- end }}

{{ if ne (.WALG_RESTORE|toString) "false" -}}
# these vars are only for restoration:
hot_standby = on
restore_command = '/var/lib/wal-g-utils/wal-fetch.sh "%f" "%p"'
{{- if (.WALG_RESTORE|toString|regexMatch "20[0-9][0-9]-[0-1][0-9]-[0-3][0-9] [0-2][0-9]:[0-6][0-9]:[0-6][0-9]") }}
recovery_target_action = 'promote'
recovery_target_time = '{{ .WALG_RESTORE }}'
{{- else }}
recovery_target_timeline = 'latest'
{{- end }}
{{- end }}
