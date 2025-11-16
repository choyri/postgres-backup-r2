#! /bin/bash

set -eu

if [ -z "$SCHEDULE" ]; then
  bash backup.sh
else
  exec go-cron "$SCHEDULE" /bin/bash backup.sh
fi
