defmodule DumperTest.Router do
  use Phoenix.Router

  import Phoenix.LiveDashboard.Router

  live_dashboard "/dashboard",
    additional_pages: [dumper: {Dumper.LiveDashboardPage, repo: Repo}]
end

defmodule DumperTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :dumper

  plug DumperTest.Router
end
