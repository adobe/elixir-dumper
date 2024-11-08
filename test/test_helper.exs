Application.put_env(:dumper, DumperTest.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  render_errors: [view: DumperTest.ErrorView],
  check_origin: false,
  pubsub_server: DumperTest.PubSub
)

defmodule DumperTest.ErrorView do
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end

defmodule DumperTest.Router do
  use Phoenix.Router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :fetch_session
  end

  scope "/", ThisWontBeUsed, as: :this_wont_be_used do
    pipe_through :browser

    live_dashboard "/dashboard", additional_pages: [dumper: Dumper.LiveDashboardPage]
  end
end

defmodule DumperTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :dumper

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger_param_key",
    cookie_key: "request_logger_cookie_key"

  plug Plug.Session,
    store: :cookie,
    key: "_live_view_key",
    signing_salt: "/VEDsdfsffMnp5"

  plug DumperTest.Router
end

Supervisor.start_link(
  [
    {Phoenix.PubSub, name: DumperTest.PubSub, adapter: Phoenix.PubSub.PG2},
    DumperTest.Endpoint
  ],
  strategy: :one_for_one
)

##################################################
# DB Setup

Application.put_env(:dumper, Repo, database: "test.db")

_ = Repo.__adapter__().storage_up(Repo.config())
{:ok, _} = Supervisor.start_link([Repo], strategy: :one_for_one)
Ecto.Migrator.run(Repo, "test/support/migrations", :up, all: true)

# Dumper library config

Application.put_env(:dumper, :otp_app, :dumper)
Application.put_env(:dumper, :repo, Repo)

ExUnit.start(exclude: :integration)
