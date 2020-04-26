defmodule Crush.Repo do
  use Ecto.Repo,
    otp_app: :crush,
    adapter: Ecto.Adapters.Postgres
end
