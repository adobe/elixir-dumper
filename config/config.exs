import Config

if Mix.env() == :test do
  # set to :debug to view SQL queries in logs
  config :logger, level: :warning
end
