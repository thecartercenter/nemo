#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

bundle exec rake db:schema:load
bundle exec rake db:seed
bundle exec rake assets:precompile
bundle exec rake db:create_admin

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"