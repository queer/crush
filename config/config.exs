use Mix.Config

config :crush, CrushWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "q06p4npNdXspi42YkYDdpSHvlBYiyJG5MKeA9nPbM9brPRIuEMQPWDcr41JH8sE4",
  render_errors: [view: CrushWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Crush.PubSub,
  live_view: [signing_salt: "NiUSI7dK"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

gossip_config =
  if System.get_env("GOSSIP_AUTH") do
    [secret: System.get_env("GOSSIP_AUTH")]
  else
    []
  end

gossip_topology =
  [
    fumetsu_gossip: [
      strategy: Cluster.Strategy.Gossip,
      config: gossip_config,
    ]
  ]

# Erlang distribution cookie
cookie =
  if Mix.env() == :prod do
    System.get_env("COOKIE") || raise """
      \n
      ### ERROR ###

      You did not provide a cookie! This is REALLY DANGEROUS. You MUST provide a
      cookie, via the `COOKIE` environment variable, for crush to run!

      ## Why?

      crush enables Erlang distribution by default, to allow for automagic
      cluster formation. However, this means that, without a cookie, anyone can
      connect to your cluster and do all sorts of evil.

      See https://erlang.org/doc/reference_manual/distributed.html#security for
      more info.
      """
  else
    System.get_env("COOKIE") || "a"
  end

config :crush,
  cookie: cookie,
  topology: gossip_topology

import_config "#{Mix.env()}.exs"
