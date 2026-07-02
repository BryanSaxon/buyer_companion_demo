#!/usr/bin/env bash
set -o errexit

bundle install
bundle exec rails tailwindcss:build
bundle exec rails assets:precompile
bundle exec rails db:migrate
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load:queue
