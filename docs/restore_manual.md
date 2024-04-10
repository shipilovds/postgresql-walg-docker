# Manual restoration

> This is a subpage of [main restore doc](restore.md)

Preserving old data can be useful. If desired, move the `$PGDATA` directory (volume source) to a secure location.

### Full Recovery

```
### In the PostgreSQL container:

# Ensure that PGDATA exists
mkdir -p /var/lib/postgresql/data
chown postgres:root /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Clean old data
rm -rf $PGDATA/*

# Set restore option to full
export WALG_RESTORE=true

# Set working directory to $PGDATA and then retrieve the latest full backup
cd $PGDATA
/var/lib/wal-g-utils/backup-fetch.sh

# Generate configuration for restoration
envtpl /etc/postgres/postgresql.conf.tpl > $PGDATA/postgresql.conf
```

### PITR

```
### In the PostgreSQL container:

# Ensure that PGDATA exists
mkdir -p /var/lib/postgresql/data
chown postgres:root /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Clean old data
rm -rf $PGDATA/*

# list available backups and choose the one you need (latest before exact time)
/var/lib/wal-g-utils/backup-list.sh

# Set the restore option to the chosen time in the format "%Y-%m-%d %H:%m:%S"
export WALG_RESTORE="2020-02-11 19:33:00"

# Set working directory to $PGDATA and then retrieve the chosen full backup
cd $PGDATA
/var/lib/wal-g-utils/backup-fetch.sh CHOSEN_BACKUP_ARCHIVE

# Generate configuration for restoration
envtpl /etc/postgres/postgresql.conf.tpl > $PGDATA/postgresql.conf
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

rm $PGDATA/recovery.signal
```

Then, stop the docker-compose and set the following variables:

- `MAINTENANCE=false` - disable maintenance
- `WALG_ENABLED=false` - disable WAL-G to prevent new backup creation and data collision

After verifying that everything is functioning correctly, you can delete old backups from S3, set `WALG_ENABLED=true` again, and restart Docker containers.
