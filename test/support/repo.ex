defmodule Repo do
  use Ecto.Repo, otp_app: :dumper, adapter: Ecto.Adapters.SQLite3
end
