import Config

if Mix.env() == :test do
  config :dumper, DumperTest.Endpoint,
    url: [host: "localhost", port: 4000],
    secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
    live_view: [signing_salt: "hMegieSe"],
    check_origin: false

  config :dumper, Repo, database: "test.db"

  config :logger, level: :warning
end
