defmodule Nameframes.Repo do
  use Ecto.Repo,
    otp_app: :nameframes,
    adapter: Ecto.Adapters.Postgres
end
