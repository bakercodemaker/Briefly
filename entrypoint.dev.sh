#!/bin/sh
set -eu

rm -f /app/tmp/pids/server.pid

bundle check || bundle install
yarn install --frozen-lockfile
bin/rails db:prepare

exec "$@"
