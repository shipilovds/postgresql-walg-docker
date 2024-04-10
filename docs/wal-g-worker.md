# wal-g-worker

`wal-g-worker` is a Docker image designed to manage regular PostgreSQL base backups and their retention. Additionally, it provides "backup" metrics.

## Principle of operation

The container operates with the following structure of processes:

| Container Process                                                  | Description                                                   | Schedule                              |
|--------------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------|
| [Yacron](#yacron)                                                  | 0-level process that starts all other processes on schedule   | -                                     |
| `backup-push.sh` from [wal-g-utils](#wal-g-utils)                  | Scheduled task to make base backup                            | "05 */12 * * *" - Every 12h in 05m    |
| `wal-g delete retain  FIND_FULL 15 --use-sentinel-time --confirm`  | Run retention for S3 stored backups (base/wal)                | "0 0 * * *" - Every day at 00:00 UTC  |
| [wal-g-exporter](#wal-g-exporter)                                  | Run wal-g exporter in 'oneshot' mode to generate metrics file | "0 * * * *" - Every hour              |

To interact with PostgreSQL, these processes can use:

- PostgreSQL remote connection
- Unix socket (from the PostgreSQL shared volume)

The type of connection can be set up through [Envirinment Variables](#environment-variables) and your docker volumes.
An example setup for Unix socket can be found [here](docker-compose.yml).

To interact with S3, processes use [Envirinment Variables](#environment-variables)

## Main components

### Yacron

[Yacron](https://github.com/gjcarneiro/yacron) - A modern Cron replacement that is Docker-friendly.
Main process of this container. Runs other processes on schedule.

Config file you can find [here](../configs/yacron.yml).

### WAL-G

[WAL-G](https://github.com/wal-g/wal-g) - Archival and Restoration Tool for databases in the Cloud.

### wal-g-utils

[wal-g-utils](wal-g-utils.md) - A set of bash scripts useful for maintaining PostgreSQL backups and their restoration. It depends on [WAL-G](#wal-g).

### WAL-G Exporter

[wal-g-exporter](https://github.com/shipilovds/wal-g-exporter) - A Prometheus exporter for gathering WAL-G backup metrics for the PostgreSQL database.

## Additional Components

### mc

[mc](https://min.io/docs/minio/linux/reference/minio-mc.html) is a [MinIO](https://min.io/docs/minio/linux/index.html) client that can connect to S3 server and interact with it. It is used here to ensure that the S3 bucket and bucket path for the selected instance exist.

### sudo

sudo is a well-known utility. Notably, this image includes a [sudoers file](configs/sudoers).

### postgresql-client

In case we need something...

## Envirinment Variables

| Variable Name           | Default Value      | Mandatory | Description                                                                                                             |
|-------------------------|--------------------|-----------|-------------------------------------------------------------------------------------------------------------------------|
| AWS_ENDPOINT            |                    | ✅        | Custom endpoint URL for connecting to S3.                                                                               |
| AWS_ACCESS_KEY_ID       |                    | ✅        | A unique identifier associated with an AWS account.                                                                     |
| AWS_SECRET_ACCESS_KEY   |                    | ✅        | Confidential credential for secure access to AWS resources.                                                             |
| AWS_REGION              |                    |           | Needed when you use separate regions.                                                                                   |
| AWS_S3_FORCE_PATH_STYLE |                    |           | To enable path-style addressing when connecting to an S3 service that lack of support for sub-domain style bucket URL   |
| DEFAULT_S3_PREFIX       | s3://wal-g/        |           | Default S3 prefix template.                                                                                             |
| MAINTENANCE             | false              |           | Maintenance mode switcher. When set to `true` - nothing starts in container except limitless `sleep 1`.                 |
| PGHOST                  |                    | ✅        | Name of host (or Unix-domain socket path) to connect to.                                                                |
| PGUSER                  |                    | ✅        | PostgreSQL username.                                                                                                    |
| WALG_ENABLED            | false              |           | WAL-G switcher. WAL-G utility will not work if not set to 'true'.                                                       |
| WALG_S3_PREFIX          |                    | ✅        | Component of the object key that precedes the object's name, resembling a pseudo-directory structure within the bucket. |
| WALG_VALIDATE_S3_PREFIX | true               |           | When set to `true` - validates if `WALG_S3_PREFIX` corresponds to `DEFAULT_S3_PREFIX`. Fails if not.                    |

Other possible environment variables:

- [PostgreSQL](https://www.postgresql.org/docs/current/libpq-envars.html)
- [WAL-G 1](https://github.com/wal-g/wal-g/blob/master/docs/STORAGES.md)/[WAL-G 2](https://github.com/wal-g/wal-g/blob/master/docs/README.md)/[WAL-G 3](https://github.com/wal-g/wal-g/blob/master/docs/PostgreSQL.md)
- [wal-g-exporter](https://github.com/shipilovds/wal-g-exporter/blob/master/README.md#configuration)

## Additional things for testing purposes

Add this to jobs to [yacron config](../configs/yacron.yml)
```yaml
  - name: db-test
    command: /usr/bin/db-test.sh
    schedule: "* * * * *"
    captureStdout: true
    captureStderr: true
```

And mount this config along with [db-test.sh](misc/db-test.sh) into container:

```diff
     volumes:
+      - ./misc/db-test.sh:/usr/bin/db-test.sh
+      - ./configs/yacron.yml:/etc/yacron.yml
```

And add this to postgres container to create test database on start:

```diff
     volumes:
+      - ./misc/init_test_db.sql:/docker-entrypoint-initdb.d/init_test_db.sql
```
