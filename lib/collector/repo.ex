defmodule Collector.Repo do
  use Ecto.Repo,
    otp_app: :collector,
    adapter: Ecto.Adapters.Postgres
end
