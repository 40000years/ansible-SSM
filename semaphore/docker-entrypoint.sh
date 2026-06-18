#!/bin/sh
# semaphore/docker-entrypoint.sh
# Fix AWS credentials permissions ที่ mount มาจาก host
# Docker Desktop on Mac จะ map host user → root ใน container

AWS_SRC="/tmp/host-aws"
AWS_DST="/home/semaphore/.aws"

# Copy AWS credentials จาก temp mount (read-only) → home dir (writable)
if [ -d "$AWS_SRC" ]; then
    mkdir -p "$AWS_DST"
    cp -r "$AWS_SRC/." "$AWS_DST/"
    chown -R semaphore:root "$AWS_DST"
    find "$AWS_DST" -type d -exec chmod 700 {} \;
    find "$AWS_DST" -type f -exec chmod 600 {} \;
    echo "[entrypoint] AWS credentials copied: $AWS_DST"
else
    echo "[entrypoint] INFO: No AWS credentials mount (OK if using IAM Role)"
fi

echo "[entrypoint] Starting Semaphore..."
exec /usr/local/bin/server-wrapper "$@"
