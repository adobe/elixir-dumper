# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

##################################################
# Test phoenix web server setup

Supervisor.start_link([DumperTest.Endpoint], strategy: :one_for_one)

##################################################
# DB setup and seeding

_ = Repo.__adapter__().storage_up(Repo.config())
{:ok, _} = Supervisor.start_link([Repo], strategy: :one_for_one)
Ecto.Migrator.run(Repo, "test/support/migrations", :up, all: true)

ExUnit.start(exclude: :integration)
