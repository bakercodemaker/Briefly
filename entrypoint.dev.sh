#!/bin/sh
set -eu

rm -f /app/tmp/pids/server.pid

bundle check || bundle install

if [ -f package.json ]; then
  yarn install --frozen-lockfile
fi

exec "$@"
