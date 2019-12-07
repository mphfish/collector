#!/usr/bin/env bash
set -e

APP_NAME="$(grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g')"
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2)"
npm run deploy --prefix ./assets

mix local.hex --force
mix local.rebar --force

mix phx.digest
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/collector_prod SECRET_KEY_BASE=3U+s03B30y1Da8uOsgzm1hw61gzQxMkAZ5OsfbMCP0GbQuD+Qj7gXj897A2VIEMp MIX_ENV=prod mix distillery.release

mkdir -p /opt/app
sudo chown -R pi:pi /opt/app

tar -xf "_build/prod/rel/$APP_NAME/releases/$APP_VSN/$APP_NAME.tar.gz" --directory /opt/app/

sudo chown -R pi:pi /opt/app
/opt/app/bin/collector migrate
systemctl restart collector.service