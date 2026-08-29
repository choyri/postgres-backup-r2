#! /bin/bash

set -eu

cd "$(dirname "$0")"

if [ -z "$SCHEDULE" ]; then
  exec bash backup.sh
fi

exec go-cron "$SCHEDULE" /bin/bash backup.sh
