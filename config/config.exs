# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :collector,
  ecto_repos: [Collector.Repo]

# Configures the endpoint
config :collector, CollectorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "aAa1mCAYDB5v+evNkMW8RIBWvTcSs3Fe7Cd1vd4Z3EKjL9bzbaIE79hy3jCi4uwM",
  render_errors: [view: CollectorWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Collector.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
