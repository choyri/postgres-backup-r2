ARG PG_MAJOR=18

FROM debian:bookworm-slim
ARG PG_MAJOR

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		wget \
        ca-certificates \
        gpg \
        s3cmd \
        tar \
	; \
    mkdir -p /usr/share/postgresql-common/pgdg; \
    wget -O /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
        https://www.postgresql.org/media/keys/ACCC4CF8.asc; \
    . /etc/os-release; \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${VERSION_CODENAME}-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends postgresql-client-${PG_MAJOR}; \
    wget -qO- "https://github.com/ivoronin/go-cron/releases/download/v0.0.5/go-cron_0.0.5_linux_$(dpkg --print-architecture).tar.gz" | tar -xz -C /usr/local/bin; \
    apt-get autoremove -y; \
	rm -rf /var/lib/apt/lists/*

ENV POSTGRES_DATABASE='' \
    POSTGRES_HOST='' \
    POSTGRES_PORT=5432 \
    POSTGRES_USER='' \
    POSTGRES_PASSWORD='' \
    PGDUMP_EXTRA_OPTS='' \
    CLOUDFLARE_R2_ACCESS_KEY_ID='' \
    CLOUDFLARE_R2_SECRET_ACCESS_KEY='' \
    CLOUDFLARE_R2_BUCKET='' \
    CLOUDFLARE_R2_REGION='auto' \
    R2_PREFIX='backups' \
    CLOUDFLARE_R2_ENDPOINT='' \
    SCHEDULE='' \
    PASSPHRASE='' \
    BACKUP_KEEP_DAYS=''

COPY src/ /

ENTRYPOINT ["bash", "run.sh"]
