# PostgreSQL

The current image is based on the [Official PostgreSQL Docker Image](https://github.com/docker-library/postgres),
but it incorporates some [changes](docker/Dockerfile.postgres) to enable WAL-G wal backup.

## Additional Components

### WAL-G

[WAL-G](https://github.com/wal-g/wal-g) - An Archival and Restoration Tool for databases in the Cloud.

### wal-g-utils

[wal-g-utils](wal-g-utils.md) - A set of bash scripts useful for maintaining PostgreSQL backups and restoration. It relies on [WAL-G](#wal-g).

### sudo

sudo is a well-known utility. Notably, this image includes a [sudoers file](configs/sudoers).

### envtpl

[envtpl](https://github.com/subfuzion/envtpl) renders Go templates on the command line using environment variables.

## Functionality

### Updated Entry Point

Enhancements:

- S3 connection variables check
- [Maintenance mode](#maintenance-mode) switcher
- [PostgreSQL configuration generator](#main-config-generator)

> you can always compare with [original](https://github.com/docker-library/postgres/blob/master/16/bookworm/docker-entrypoint.sh)

### Main Config Generation

During the execution of the [entrypoint script](docker/entrypoint.postgres.sh), the [postgresql.conf.tpl](configs/postgresql.conf.tpl) template file is utilized to generate `$PGDATA/postgresql.conf`

Two variables are required:

- `WALG_ENABLED`
- `WALG_RESTORE`

### WAL Backup Push

A set of settings from the generated postgresql.conf.

If `WALG_ENABLED=true`, the generator will add `archive_mode = on` and `archive_command = '/var/lib/wal-g-utils/wal-push.sh %p'` to enable wal backup through [PostgreSQL Continuous Archiving](https://www.postgresql.org/docs/current/continuous-archiving.html)

> For setting up *Base Backup*, an additional container with [WAL-G Worker](wal-g-worker.md) is needed.

### Maintenance Mode

Useful in cases when maintenance on your database is necessary. Initiates an endless `sleep 1` on the entrypoint level before any other operations. Activated on container start with `MAINTENANCE=true` in the environment.

### Restore from backup

Refer to the [special doc page](restore.md) for details.

## Envirinment Variables

| Variable Name           | Default Value      | Description                                                                                                             |
|-------------------------|--------------------|-------------------------------------------------------------------------------------------------------------------------|
| AWS_ENDPOINT            |                    | Custom endpoint URL for connecting to S3.                                                                               |
| AWS_ACCESS_KEY_ID       |                    | A unique identifier associated with an AWS account.                                                                     |
| AWS_SECRET_ACCESS_KEY   |                    | Confidential credential for secure access to AWS resources.                                                             |
| AWS_REGION              |                    | Necessary when using separate regions.                                                                                  |
| AWS_S3_FORCE_PATH_STYLE |                    | Enables path-style addressing when connecting to an S3 service that lacks support for sub-domain style bucket URL.      |
| DEFAULT_S3_PREFIX       | s3://wal-g/        | Default S3 prefix template.                                                                                             |
| MAINTENANCE             | false              | Maintenance mode switcher. When set to `true`, nothing starts in the container except limitless `sleep 1`.              |
| PGHOST                  |                    | Name of host (or Unix-domain socket path) to connect to.                                                                |
| PGUSER                  |                    | PostgreSQL username for connection.                                                                                     |
| POSTGRES_PASSWORD       |                    | *Required* This environment variable sets the superuser password for PostgreSQL.                                        |
| POSTGRES_USER           | postgres           | This variable will create the specified user with superuser power and a database with the same name.                    |
| POSTGRES_DB             | postgres           | Defines a different name for the default database that is created when the image is first started.                      |
| WALG_ENABLED            | false              | WAL-G switcher. WAL-G utility will not work if not set to 'true'.                                                       |
| WALG_S3_PREFIX          |                    | Component of the object key that precedes the object's name, resembling a pseudo-directory structure within the bucket. |
| WALG_VALIDATE_S3_PREFIX | true               | When set to `true`, validates if `WALG_S3_PREFIX` corresponds to `DEFAULT_S3_PREFIX`. Fails if not.                     |
| WALG_ARCHIVE_TIMEOUT    | 600                | PostgresQL `archive_timeout` option in `postgresql.conf`. Timeout in second to archive complited WAL segments.          |

Other possible environment variables:

- [PostgreSQL Envs](https://www.postgresql.org/docs/current/libpq-envars.html) and [PostgreSQL Docker Envs](https://github.com/docker-library/docs/blob/master/postgres/README.md#environment-variables)
- [WAL-G 1](https://github.com/wal-g/wal-g/blob/master/docs/STORAGES.md)/[WAL-G 2](https://github.com/wal-g/wal-g/blob/master/docs/README.md)/[WAL-G 3](https://github.com/wal-g/wal-g/blob/master/docs/PostgreSQL.md)
