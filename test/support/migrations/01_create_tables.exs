defmodule Migration.CreateTables do
  use Ecto.Migration

  def change do
    create table(:books) do
      add(:title, :string)
      add(:author_id, :integer)
      add(:published_at, :date)

      timestamps()
    end

    create table(:authors) do
      add(:first_name, :string)
      add(:last_name, :string)
      add(:date_of_birth, :date)

      timestamps()
    end

    create table(:patrons) do
      add(:first_name, :string)
      add(:last_name, :string)
      add(:date_of_birth, :date)
      add(:email_address, :string)
      add(:late_fees_balance, :integer)

      timestamps()
    end

    create table(:loans) do
      add(:patron_id, :integer)
      add(:book_id, :integer)
      add(:borrowed_at, :utc_datetime)
      add(:returned_at, :utc_datetime)
      add(:due_at, :utc_datetime)

      timestamps()
    end

    create table(:book_reviews) do
      add(:patron_id, :integer)
      add(:book_id, :integer)
      add(:rating, :integer)
      add(:review_text, :text)

      timestamps()
    end
  end
end
