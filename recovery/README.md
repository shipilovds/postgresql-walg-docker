# PostgreSQL Restoration with WAL-G

This manual will help you to restore your postgres data in case of serious failure. We can explain all the things with the example of restoration.

We are going to use [docker-compose.yml](../docker-compose.yml) to make test database. All shell actions you meet below will be executed inside the container (postgres_test).

### Test Database

At first you need to make test database:

```
root@a4db1ba6c172:/# sudo -E -u postgres /usr/local/bin/bd-test.sh
```

It will create database and indexing table and run loop with sql command `"INSERT INTO indexing_table(created_at) VALUES (CURRENT_TIMESTAMP);"`. Must work for some time. In the meantime, postgres will save WAL archive every 10 minutes. Stop the loop when you deside to.

### Restoration: Common Part

Now we can stop our container services:

```
root@a4db1ba6c172:/# supervisorctl -u dummy -p dummy stop yacron
root@a4db1ba6c172:/# supervisorctl -u dummy -p dummy stop postgres
```

... and remove all postgres data:
```
root@a4db1ba6c172:/# rm -rf /var/lib/postgresql/data/*
```

### Restoration: Full Recovery

Now we should make our postgresql.conf look like [this](postgresql.conf.full_recovery) and fetch the latest backup into PGDATA:

```
root@a4db1ba6c172:/# vim /etc/postgres/postgresql.conf
root@a4db1ba6c172:/# backup-fetch.sh
```

### Restoration: PITR

On the other hand we might want to restore postgres to a specific time. It means we should engage Point In Time Recovery procedure instead of the Full Recovery. Config for this we can find [here](postgresql.conf.pitr). So let's find the latest backup before our restoration time and get it:
```
root@a4db1ba6c172:/# backup-list.sh
root@a4db1ba6c172:/# vim /etc/postgres/postgresql.conf
root@a4db1ba6c172:/# backup-fetch.sh base_00000001000000000000000C_D_000000010000000000000005
```

### Restoration: Final

At this point we got postgres data from backup archives. But now we should tell Postgres that we run the restoration here and get everything else from WAL archives (postgres will run `wal-fetch` from `restore_command=`):
```
root@a4db1ba6c172:/# sudo -E -u postgres touch /var/lib/postgresql/data/recovery.signal
root@a4db1ba6c172:/# supervisorctl -u dummy -p dummy start postgres
```

Now you can look into container logs to make sure that everything went well.

And then 
```
sudo -E -u postgres psql -U test -d test1 -c "select * from indexing_table;"
```

to make sure that everything is REALLY OK

You can look at example logs for [Full Recovery](docker.log.full_recovery) and [PITR](docker.log.pitr)
