# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :crush,
  ecto_repos: [Crush.Repo]

# Configures the endpoint
config :crush, CrushWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cO0cFuFVaShxKAndeH9miqF++BoBeIykaKBsGEo8TKCKPYYc3ua1eYi61Db+rn83",
  render_errors: [view: CrushWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Crush.PubSub,
  live_view: [signing_salt: "Ey/h8mO3"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

use Mix.Config

config :sasl,
  errlog_type: :error

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
