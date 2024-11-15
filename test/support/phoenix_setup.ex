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
