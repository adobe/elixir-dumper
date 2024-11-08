defmodule Patron do
  @moduledoc false
  use Ecto.Schema

  schema "patrons" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:date_of_birth, :date)
    field(:email_address, :string, redact: true)
    field(:late_fees_balance, :integer)

    has_many(:loans, Loan)
    has_many(:reviews, BookReview)

    timestamps()
  end
end
