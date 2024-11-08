defmodule Author do
  @moduledoc false
  use Ecto.Schema

  schema "authors" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:date_of_birth, :date)

    has_many(:books, Book)

    timestamps()
  end
end
