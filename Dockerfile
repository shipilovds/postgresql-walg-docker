ARG POSTGRES_VERSION
ARG YACRON_RELEASE

# Builder image
FROM golang:buster AS builder
RUN apt update && apt install -y \
    ca-certificates \
    cmake \
    curl \
    git \
    gzip \
    libbrotli-dev \
    libsodium-dev \
    make
ARG WALG_RELEASE
RUN git clone --depth 1 --branch $WALG_RELEASE https://github.com/wal-g/wal-g.git 
WORKDIR /go/wal-g
RUN go get ./...
RUN make deps
RUN make pg_install


# Result image
FROM postgres:$POSTGRES_VERSION
COPY --from=quay.io/prometheuscommunity/postgres-exporter /bin/postgres_exporter /usr/local/bin/postgres_exporter
COPY --from=builder /wal-g /usr/local/bin/wal-g
RUN apt update && apt install -y \
      curl \
      sudo \
      supervisor \
      vim \
    && rm -rf /var/lib/apt/lists/*
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc
RUN curl -L https://github.com/gjcarneiro/yacron/releases/download/$YACRON_RELEASE/yacron-$YACRON_RELEASE-x86_64-unknown-linux-gnu -o /usr/local/bin/yacron
RUN echo "postgres ALL=(ALL) NOPASSWD:SETENV: /usr/bin/tee,/usr/local/bin/*" >> /etc/sudoers
COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
#COPY misc/init_test_db.sql /docker-entrypoint-initdb.d/init_test_db.sql
COPY configs/supervisord.conf /etc/supervisor/supervisord.conf
COPY configs/postgresql.conf /etc/postgres/postgresql.conf
COPY configs/pg_hba.conf /etc/postgres/pg_hba.conf
COPY config/yacrontab.yml /etc/yacrontab.yml
EXPOSE 5432
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

