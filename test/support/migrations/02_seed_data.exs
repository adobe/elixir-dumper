# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Migration.SeedData do
  @moduledoc false
  use Ecto.Migration

  import Ecto.Query

  def up do
    Enum.each(1..100, fn _ ->
      author =
        Repo.insert!(%Author{
          first_name: Faker.Person.first_name(),
          last_name: Faker.Person.last_name(),
          date_of_birth: Faker.Date.date_of_birth()
        })

      # create books written by author
      Enum.each(1..Enum.random(3..8), fn _ ->
        Repo.insert!(%Book{
          title: 1..4 |> Faker.Lorem.words() |> Enum.join(" "),
          published_at: Faker.Date.between(~D[1800-01-01], Date.utc_today()),
          author_id: author.id
        })
      end)
    end)

    #############################################################################
    ## Patrons, Loans, and BookReviews

    Enum.each(1..1000, fn _ ->
      late_fees = if Enum.random(1..100) > 75, do: Enum.random(1..10) * 10, else: 0

      patron =
        Repo.insert!(%Patron{
          first_name: Faker.Person.first_name(),
          last_name: Faker.Person.last_name(),
          date_of_birth: Faker.Date.date_of_birth(),
          email_address: Faker.Internet.free_email(),
          late_fees_balance: late_fees
        })

      # Loans
      Enum.each(0..4, fn _ ->
        borrowed_at =
          ~D[1970-01-01] |> Faker.Date.between(~D[2023-12-01]) |> DateTime.new!(~T[00:00:00])

        returned_at =
          if Enum.random(1..100) > 92, do: DateTime.add(borrowed_at, Enum.random(3..37), :day)

        loan =
          Repo.insert!(%Loan{
            borrowed_at: borrowed_at,
            returned_at: returned_at,
            due_at: DateTime.add(borrowed_at, 21, :day),
            patron_id: patron.id,
            book_id: random_book_id()
          })

        Repo.insert!(%BookReview{
          rating: Enum.random(1..5),
          review_text: Faker.Lorem.paragraph(),
          patron_id: loan.patron_id,
          book_id: loan.book_id
        })
      end)
    end)
  end

  def down do
    for schema <- [Book, BookReview, Author, Patron, Loan],
        do: Repo.delete_all(schema)
  end

  defp random_book_id do
    x =
      Book
      |> select([:id])
      |> order_by(fragment("RANDOM()"))
      |> limit(1)
      |> Repo.one()

    x.id
  end
end
