# wal-g-utils

`wal-g-utils` is a set of bash scripts that is useful to maintain PostgreSQL backups and its restoration.

## Content

| Repository File                                            | Install Path                         | Description                         |
|------------------------------------------------------------|--------------------------------------|-------------------------------------|
| [wal-g-utils/common.sh](wal-g-utils/common.sh)             | /var/lib/wal-g-utils/common.sh       | Common functions and variables      |
| [wal-g-utils/backup-fetch.sh](wal-g-utils/backup-fetch.sh) | /var/lib/wal-g-utils/backup-fetch.sh | Fetch base backup from S3           |
| [wal-g-utils/backup-list.sh](wal-g-utils/backup-list.sh)   | /var/lib/wal-g-utils/backup-list.sh  | List base backups from S3           |
| [wal-g-utils/backup-push.sh](wal-g-utils/backup-push.sh)   | /var/lib/wal-g-utils/backup-push.sh  | Push base backup to S3              |
| [wal-g-utils/wal-fetch.sh](wal-g-utils/wal-fetch.sh)       | /var/lib/wal-g-utils/wal-fetch.sh    | Fetch wal archives from S3          |
| [wal-g-utils/wal-push.sh](wal-g-utils/wal-push.sh)         | /var/lib/wal-g-utils/wal-push.sh     | Push wal archives to S3             |
| [wal-g-utils/recovery.sh](wal-g-utils/recovery.sh)         | /var/lib/wal-g-utils/recovery.sh     | Run PostgreSQL recovery from backup |
| [configs/sudoers](configs/sudoers)                         | /etc/sudoers.d/wal-g                 | Sudoers file to give postgres user permissions to run some utils as root without password |

## Deb package

`.deb` package has all its [content](#content) and needs sudo, postgresql-client and wal-g packages as dependencies.

### Build .deb package

To build package you need to run `make deb`. After successful build you will get `wal-g-utils_$(WALG_UTILS_RELEASE)-1_all.deb` package in the project's root folder.

### Get prebuilt package

You can get already built `walg-gutils` package by [this link](https://github.com/shipilovds/postgresql-walg-docker/releases/download/1.0/wal-g-utils_1.0.0-1_all.deb).

Or you can look for more current versions in [Releases](https://github.com/shipilovds/postgresql-walg-docker/releases) section of this project.

#### Package dependencies

You can get already built `wal-g` package by [this link](https://github.com/shipilovds/wal-g-exporter/releases/download/1.0/wal-g_2.0.1-1_amd64.deb)
