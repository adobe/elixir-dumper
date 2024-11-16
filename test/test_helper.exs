##################################################
# Test phoenix web server setup

Supervisor.start_link([DumperTest.Endpoint], strategy: :one_for_one)

##################################################
# DB setup and seeding

_ = Repo.__adapter__().storage_up(Repo.config())
{:ok, _} = Supervisor.start_link([Repo], strategy: :one_for_one)
Ecto.Migrator.run(Repo, "test/support/migrations", :up, all: true)

ExUnit.start(exclude: :integration)
