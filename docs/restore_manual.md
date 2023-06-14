# Manual restoration

> This is a subpage of [main restore doc](docs/restore.md)

Preserving old data can be useful. If desired, move the `$PGDATA` directory (volume source) to a secure location.

### Full Recovery

```
### In the PostgreSQL container:

# Clean old data
rm -rf $PGDATA/*

# Set restore option to full
export WALG_RESTORE=true

# Generate configuration for restoration
envtpl /etc/postgres/postgresql.conf.tpl > $PGDATA/postgresql.conf

# Set working directory to $PGDATA and then retrieve the latest full backup
cd $PGDATA
backup-fetch.sh
```

### PITR

```
### In the PostgreSQL container:

# Clean old data
rm -rf $PGDATA/*

# list available backups and choose the one you need (latest before exact time)
backup-list.sh

# Set the restore option to the chosen time in the format "%Y-%m-%d %H:%m:%S"
export WALG_RESTORE=true

# Generate configuration for restoration
envtpl /etc/postgres/postgresql.conf.tpl > $PGDATA/postgresql.conf

# Set working directory to $PGDATA and then retrieve the chosen full backup
cd $PGDATA
backup-fetch.sh CHOSEN_BACKUP_ARCHIVE
```

### Finalize resoration

```
### In the PostgreSQL container:

# Create a recovery.signal file to signal PostgreSQL to run recovery:
sudo -E -u postgres touch $PGDATA/recovery.signal

# Start PostgreSQL manually
sudo -E -u postgres /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl start

# When everything is finished, stop PostgreSQL
sudo -E -u postgres /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl stop
```

Then, stop the docker-compose and set the following variables:

- `MAINTENANCE=false` - disable maintenance
- `WALG_ENABLED=false` - disable WAL-G to prevent new backup creation and data collision

After verifying that everything is functioning correctly, you can delete old backups from S3, set `WALG_ENABLED=true` again, and restart Docker containers.
