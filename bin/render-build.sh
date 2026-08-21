#!/usr/bin/env bash
set -o errexit

bundle install
yarn install --frozen-lockfile
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:prepare

if ! bundle exec rails runner 'exit(SolidQueue::Record.connection.data_source_exists?("solid_queue_jobs") ? 0 : 1)'; then
  bundle exec rails db:schema:load:queue
fi
