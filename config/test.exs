import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ist, ISTWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "kD3BzD5bJ23FY5CLO8yJEDnSyKL9vUlJ74F6XHyE/0/FW5W0ZVHUJT1L97SGVEUW",
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
