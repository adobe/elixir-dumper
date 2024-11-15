defmodule Loan do
  @moduledoc false
  use Ecto.Schema

  schema "loans" do
    field(:borrowed_at, :utc_datetime)
    field(:returned_at, :utc_datetime)
    field(:due_at, :utc_datetime)

    belongs_to(:patron, Patron)
    belongs_to(:book, Book)

    timestamps()
  end
end
