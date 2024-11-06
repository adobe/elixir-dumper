defmodule Book do
  @moduledoc """
  Representation of a Book for demo purposes.

  Markdown is rendered in earmark.
    * ~strike text~
    * **bold text**
  """
  use Ecto.Schema

  schema "books" do
    field(:title, :string)
    field(:published_at, :date)

    belongs_to(:author, Author)
    has_many(:reviews, BookReview)

    timestamps()
  end
end
