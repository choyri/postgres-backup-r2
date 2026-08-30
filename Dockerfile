ARG PG_MAJOR=18

FROM debian:trixie-slim

ARG PG_MAJOR
ARG TARGETARCH
ARG GO_CRON_VERSION=0.0.5

LABEL org.opencontainers.image.title="postgres-backup-r2" \
      org.opencontainers.image.description="Backup PostgreSQL databases to Cloudflare R2" \
      org.opencontainers.image.source="https://github.com/choyri/postgres-backup-r2" \
      org.opencontainers.image.url="https://github.com/choyri/postgres-backup-r2" \
      org.opencontainers.image.licenses="MIT"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests \
        wget \
        ca-certificates \
        gpg \
        s3cmd \
    ; \
    mkdir -p /usr/share/postgresql-common/pgdg; \
    wget -O /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc; \
    . /etc/os-release; \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends --no-install-suggests postgresql-client-${PG_MAJOR}; \
    \
    # go-cron: verify against the SHA256 published with the release, and unpack
    # only the binary (the tarball also carries LICENSE/README).
    ARCH="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$ARCH" in \
        amd64) GO_CRON_SHA256='564c8291ef18879b300614e179cca3116506191cbc6b8e50448d274b256f2e67' ;; \
        arm64) GO_CRON_SHA256='adc760e969584a391e3d3d93facbc5a198d76981226f2d8c3b3b0217ac9c57d7' ;; \
        *) echo "unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    wget -O /tmp/go-cron.tar.gz \
        "https://github.com/ivoronin/go-cron/releases/download/v${GO_CRON_VERSION}/go-cron_${GO_CRON_VERSION}_linux_${ARCH}.tar.gz"; \
    echo "${GO_CRON_SHA256}  /tmp/go-cron.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/go-cron.tar.gz -C /usr/local/bin go-cron; \
    chmod +x /usr/local/bin/go-cron; \
    rm /tmp/go-cron.tar.gz; \
    \
    apt-get purge -y --auto-remove wget; \
    \
    # s3cmd hard-depends on python3-magic but only uses it to sniff MIME types,
    # and env.sh turns that off. Dropping it takes libmagic's 10 MB database
    # with it; dpkg keeps the dependency recorded as unsatisfied.
    dpkg --purge --force-depends python3-magic libmagic1t64 libmagic-mgc; \
    \
    rm -rf /var/lib/apt/lists/*; \
    \
    groupadd --gid 1000 pgbackup; \
    useradd --uid 1000 --gid 1000 --create-home --home-dir /app --shell /bin/bash pgbackup

# Kept last: a cache miss invalidates every later layer, never an earlier one.
ENV HOME=/app \
    POSTGRES_DATABASE='' \
    POSTGRES_HOST='' \
    POSTGRES_PORT=5432 \
    POSTGRES_USER='' \
    POSTGRES_PASSWORD='' \
    PGDUMP_EXTRA_OPTS='' \
    CLOUDFLARE_R2_ACCESS_KEY_ID='' \
    CLOUDFLARE_R2_SECRET_ACCESS_KEY='' \
    CLOUDFLARE_R2_BUCKET='' \
    R2_PREFIX='backups' \
    CLOUDFLARE_R2_ENDPOINT='' \
    SCHEDULE='' \
    PASSPHRASE='' \
    BACKUP_KEEP_DAYS=''

WORKDIR /app
COPY --chown=pgbackup:pgbackup src/ /app/

USER 1000:1000

ENTRYPOINT ["bash", "run.sh"]
