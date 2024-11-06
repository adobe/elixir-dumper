defmodule BookReview do
  use Ecto.Schema

  schema "book_reviews" do
    field(:rating, :integer)
    field(:review_text, :string)

    belongs_to(:patron, Patron)
    belongs_to(:book, Book)

    timestamps()
  end
end
