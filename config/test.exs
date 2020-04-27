use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :crush, Crush.Repo,
  username: "postgres",
  password: "postgres",
  database: "crush_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :crush, CrushWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :riak_core,
  ring_state_dir: 'ring_data_dir_test',
  platform_data_dir: 'data_test',
  handoff_port: 8989,
  web_port: 8999,
  handoff_ip: '127.0.0.1',
  schema_dirs: ['priv']


config :lager,
  handlers: [
    lager_console_backend: [level: :error]
  ]
