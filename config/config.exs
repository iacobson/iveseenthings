# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :surface, :components, [
  {Surface.Components.Form.ErrorTag, default_translator: {ISTWeb.ErrorHelpers, :translate_error}}
]

config :iveseenthings,
  namespace: IST

# Configures the endpoint
config :iveseenthings, ISTWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ISTWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: IST.PubSub,
  live_view: [signing_salt: "CHRziMgO"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Game

# the max number of players allowed in the game at once (bots or humans)
config :iveseenthings, :player_count, 100
config :iveseenthings, :fps_limit, 200

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.

import_config "#{config_env()}.exs"
