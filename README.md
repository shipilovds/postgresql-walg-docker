# PostgreSQL + WAL-G

Integration of PostgreSQL with WAL-G in Docker. It is simple. It just works.

This project consists of two main images:

- [Modified PostgreSQL image](https://ghcr.io/shipilovds/postgres-walg)
- [Custom WAL-G image](https://ghcr.io/shipilovds/wal-g-worker)

You can find the targeted documentation in the following README subpages:

- [docs/postgres.md](docs/postgres.md)
- [docs/wal-g-worker.md](docs/wal-g-worker.md)

To see an example of usage, you can look into [docker-compose.yml](docker-compose.yml)

> It is possible to use this work without docker - look [here](docs/wal-g-utils.md#deb-package)
