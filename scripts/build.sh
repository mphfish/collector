#!/usr/bin/env bash
set -e
export DATABASE_URL=postgresql://postgres:postgres@localhost:5432/collector_prod 
export SECRET_KEY_BASE=3U+s03B30y1Da8uOsgzm1hw61gzQxMkAZ5OsfbMCP0GbQuD+Qj7gXj897A2VIEMp 
export MIX_ENV=prod 
export NODE_ENV=production

npm install --prefix ./assets
mix deps.get

APP_NAME="$(grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g')"
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2)"
npm run deploy --prefix ./assets

mix local.hex --force
mix local.rebar --force

mix phx.digest
mix distillery.release

tar -xf "_build/prod/rel/$APP_NAME/releases/$APP_VSN/$APP_NAME.tar.gz" --directory /opt/app/

/opt/app/bin/collector migrate