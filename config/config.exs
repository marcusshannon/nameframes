# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :nameframes,
  ecto_repos: [Nameframes.Repo]

# Configures the endpoint
config :nameframes, NameframesWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Ofi+Fg1eTalAE28rm9ZDy/Zvgma7Kw/tmOHVTZh5zt0w+AroXn0xUSlS5VPJG6cA",
  render_errors: [view: NameframesWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Nameframes.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "n+lhHPAKKjvyMWjhQp2skY7ah5IeDrZb"
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
