# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Migration.CreateTables do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:books) do
      add :title, :string
      add :author_id, :integer
      add :published_at, :date

      timestamps()
    end

    create table(:authors) do
      add :first_name, :string
      add :last_name, :string
      add :date_of_birth, :date

      timestamps()
    end

    create table(:patrons) do
      add :first_name, :string
      add :last_name, :string
      add :date_of_birth, :date
      add :email_address, :string
      add :late_fees_balance, :integer

      timestamps()
    end

    create table(:loans) do
      add :patron_id, :integer
      add :book_id, :integer
      add :borrowed_at, :utc_datetime
      add :returned_at, :utc_datetime
      add :due_at, :utc_datetime

      timestamps()
    end

    create table(:book_reviews) do
      add :patron_id, :integer
      add :book_id, :integer
      add :rating, :integer
      add :review_text, :text

      timestamps()
    end
  end
end
