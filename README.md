# PostgreSQL Docker image

### Image services

This image consists of the following services:
- postgres 12
- yacron
- wal-g
- postgresql_exporter

In the meantime, supervisord is the main service ('CMD' in Dockerfile) that aggregate services under itself.

### Common settings

##### Docker entrypoint and container ENV

There is some scripting with container initialization (including env check). You can see it in [bin/entrypoint.sh](bin/entrypoint.sh) (/usr/local/bin/docker-entrypoint.sh inside the image)

##### Setup supervisord

We use supervisord to run and manage services inside the container. To setup it:

- image file path: `/etc/supervisor/supervisord.conf`
- repo file path: [configs/supervisord.conf](configs/supervisord.conf)
- supervisord documentation is [here](http://supervisord.org/)

For every service in image we setup `[program:x]` section.


### PostgreSQL Setup

##### Postgres default config files:

- `pg_hba.conf`:
  - image file path: `/etc/postgres/pg_hba.conf`
  - repo file path: [configs/pg_hba.conf](configs/pg_hba.conf)
  - documentation you can find [here](https://www.postgresql.org/docs/12/auth-pg-hba-conf.html)

- `postgresql.conf`:
  - image file path: `/etc/postgres/postgresql.conf`
  - repo file path: [configs/postgresql.conf](configs/postgresql.conf)
  - sample config file: [misc/postgresql.conf.sample](misc/postgresql.conf.sample)
  - example config for latest/full recovery: [recovery/postgresql.conf.full_recovery](recovery/postgresql.conf.full_recovery)
  - example config for PITR: [recovery/postgresql.conf.pitr](recovery/postgresql.conf.pitr)
  - documentation you can find [here](https://www.postgresql.org/docs/12/runtime-config.html)

##### Additional settings

- see [Setup supervisord](#markdown-header-setup-supervisord)
- see [Docker entrypoint and container ENV](#markdown-header-docker-entrypoint-and-container-env)
- look [here](https://hub.docker.com/_/postgres) to find info about ENV vars to manage postgres

### Yacron Setup

Yacron is an another one implementation of cron. It is more comfortable to use with docker and to configure (yaml file).

Documentation (and project itself) you can find [here](https://github.com/gjcarneiro/yacron)

### WAL-G Setup

[WAL-G](https://github.com/wal-g/wal-g) is an archival restoration tool for PostgreSQL, MySQL/MariaDB, and MS SQL Server (beta for MongoDB and Redis).

It is important to understand how postgres works and how do we manage to backup it's data. So, you need to understand a difference between such concepts as WAL journal and database. Docs about WAL you can find [here](https://www.postgresql.org/docs/12/wal-intro.html). It is a part of all the data stored in our database (set of transactions, or "delta" in some way of understanding), but just have not written yet and stores like "logs" files. Already written database files - is the other ones. So, we do backup database files first (base backup) and WAL backup after it - to reach "full backup in time" state.

We need to have a storage to store archives in. The best service for it - [MinIO](https://min.io/). Minio client ([mc](https://docs.min.io/docs/minio-client-complete-guide.html)) is already in our docker image.

##### Tools

We place wal-g and mc binaries into `/usr/local/bin/` along with some scripts:
- [bin/common.sh](bin/common.sh) - common vars and functions
- [bin/db-test.sh](bin/db-test.sh) - script for test database creation (for recovery testing)
- [bin/backup-list.sh](bin/backup-list.sh) - script to list backups from storage
- [bin/backup-fetch.sh](bin/backup-fetch.sh) - script to fetch backup from storage into `PGDATA`
- [bin/backup-push.sh](bin/backup-push.sh) - script to push backup archive to storage
- [bin/wal-fetch.sh](bin/wal-fetch.sh) - script to fetch WAL backup from storage
- [bin/wal-push.sh](bin/wal-push.sh) - script to push WAL archive to storage

Most of the scripts originally was taken from [here](https://github.com/patsevanton/wal-g-rpm)

##### ENV Variables

[Here](https://github.com/wal-g/wal-g/blob/master/docs/STORAGES.md) and [there](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) you can find info about Minio connection variables. Several of them is mandatory:

- `WALG_S3_PREFIX`: Minio bucket path
- `AWS_ENDPOINT`: Overrides the default hostname to connect to an S3-compatible service. i.e, http://s3-like-service:9000
- `AWS_ACCESS_KEY_ID`: Specifies an AWS access key associated with an IAM user or role.
- `AWS_SECRET_ACCESS_KEY`: Specifies the secret key associated with the access key. This is essentially the "password" for the access key.

We use WAL-G with our PostgreSQL instace inside the image. So, we need some ENV variables from [here](https://hub.docker.com/_/postgres) and [here](https://www.postgresql.org/docs/12/libpq-envars.html) to connect to postgres. For the most usage scenario it is the next several vars:

- `PGDATA`: Postgres data folder.
- `PGHOST`: Name of host (or Unix-domain socket path) to connect to.
- `POSTGRES_PASSWORD`: Sets the superuser password for PostgreSQL. Needed only by postgres if `PGHOST` is set.
- `POSTGRES_USER`: User with superuser power. Needed only by postgres if `PGHOST` is set.

### PostgreSQL Exporter Setup

Prometheus exporter for PostgreSQL server metrics.

Basic setup: just set ENV `DATA_SOURCE_NAME: "postgresql://_POSTGRES_USER_:_POSTGRES_PASSWORD_@localhost:5432/_POSTGRES_DB_?sslmode=disable"`

Documentation you can find [here](https://github.com/prometheus-community/postgres_exporter).

You can also look at '[Setup supervisord](#markdown-header-setup-supervisord)' to know how to configure and manage this service.

### Archivation and Recovery

##### Archivation
To make regular backups you can create yacron job with [configs/yacrontab.yml](configs/yacrontab.yml):
```yaml
...
jobs:
  - name: backup-push
    command: /usr/local/bin/backup-push.sh
    schedule: "0 1 * * *"
    captureStdout: true
    captureStderr: true
    environment:
      - key: WALG_LOG_DEST
        value: /dev/stdout
...
```

And do not forget about `archive_timeout=NUMBER_OF_SECONDS` in [postgresql.conf](configs/postgresql.conf) to send WAL archive every `NUMBER_OF_SECONDS`.

##### Retention Policy

To make retention policy for backups use command like this (create job for yacron):

`wal-g delete retain FIND_FULL 5 --after $(date --date='-1 month' +"%Y-%m-%dT%T") --confirm` (this one is not working, but will work some day...)

`wal-g delete retain FULL 5 --confirm` (this one works)

Documentation you can find [here](https://github.com/wal-g/wal-g#delete)

To delete outdated WAL archives and backups leftover files from storage:
`wal-g delete garbage [ARCHIVES|BACKUPS]`

##### Recovery

It needs some administration inside the container. You can look at manual [here](recovery/README.md) for better understanding.

### Develop, Build and Deploy

For automatic usage check [`Jenkinsfile`](Jenkinsfile)

##### Requirements

You must have `make`, `docker` and `docker-compose` installed on your system.

##### Build image

`make build` to just build the image

`make push REGISTRY_PASSWORD=yourpassword` to push the image to the registry

You can try to rewrite other variables.

##### Makefile Variables

```
REGISTRY_ADDR       - Docker Registry server name (:server_port)
REGISTRY_USER       - Docker Registry user name
REGISTRY_PASSWORD   - Docker Registry user password
POSTGRES_VERSION    - Original PostgreSQL docker image tag
POSTGRES_IMAGE_NAME - PostgreSQL docker image name
POSTGRES_IMAGE_TAG  - Our PostgreSQL docker image tag
WALG_RELEASE        - WAL-G release version
```

##### Run for tests

`make build` to build the image

then `docker-compose up -d` to run docker container
