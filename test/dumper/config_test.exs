# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.ConfigTest do
  use Dumper.ConnCase, async: true

  describe "custom linked ids config" do
    defmodule LinkedIdsConfig do
      @moduledoc false
      use Dumper.Config

      def ids_to_schema, do: %{book_id: Book, author_id: Author}
    end

    test "links work on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn, LinkedIdsConfig)
      assert has_element?(view, ~s(td[data-field="author_id"] a))
    end

    test "links work on all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn, LinkedIdsConfig)
      assert has_element?(view, ~s(tr:first-child td[data-field="author_id"] a))
    end
  end

  describe "custom display config" do
    defmodule DisplayConfig do
      @moduledoc false
      use Dumper.Config

      def display(%{field: :title} = assigns), do: ~H|MY_UNIQUE_VALUE|
    end

    test "title replaced on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn, DisplayConfig)
      title_text = view |> element(~s(td[data-field="title"])) |> render()
      assert title_text =~ "MY_UNIQUE_VALUE"
    end

    test "title replaced on all books page", %{conn: conn} do
      {:ok, _view, html} = navigate_to_books_table(conn, DisplayConfig)

      html
      |> Floki.parse_fragment!()
      |> Floki.find(~s(td[data-field="title"]))
      |> Enum.all?(fn td ->
        assert Floki.text(td) =~ "MY_UNIQUE_VALUE"
      end)
    end
  end

  describe "allowed fields config" do
    defmodule AllowedFieldsConfig do
      @moduledoc false
      use Dumper.Config

      def allowed_fields, do: %{Book => [:id, :title]}
    end

    test "books show only id and title on the book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn, AllowedFieldsConfig)
      assert has_element?(view, ~s(#dumper td[data-field="title"]))
      refute has_element?(view, ~s(#dumper td[data-field="author_id"]))
    end

    test "books show only id and title on the all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn, AllowedFieldsConfig)
      assert has_element?(view, ~s(#dumper td[data-field="title"]))
      refute has_element?(view, ~s(#dumper td[data-field="author_id"]))
    end

    test "unspecified tables are completely hidden by default (strict)", %{conn: conn} do
      defmodule Strict do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: %{Book => [:id, :title]}
      end

      # The book_reviews association is normally shown on this page.
      # Test that it is not shown since
      {:ok, view, _html} = navigate_to_book_100(conn, Strict)
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))

      defmodule StrictExplicit do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :strict}
      end

      {:ok, view, _html} = navigate_to_book_100(conn, StrictExplicit)
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))
    end

    test "unspecified tables are shown when :lenient", %{conn: conn} do
      defmodule Lenient do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :lenient}
      end

      {:ok, view, _html} = navigate_to_book_100(conn, Lenient)
      assert has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))
    end
  end

  describe "excluded fields config" do
    defmodule ExcludedFieldsConfig do
      @moduledoc false
      use Dumper.Config

      def excluded_fields, do: %{Book => [:title]}
    end

    test "books show only id and title on the book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn, ExcludedFieldsConfig)
      refute has_element?(view, ~s(#dumper td[data-field="title"]))
      assert has_element?(view, ~s(#dumper td[data-field="author_id"]))
    end

    test "books show only id and title on the all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn, ExcludedFieldsConfig)
      refute has_element?(view, ~s(#dumper td[data-field="title"]))
      assert has_element?(view, ~s(#dumper td[data-field="author_id"]))
    end

    test "excluded is ignored when allowed is specified", %{conn: conn} do
      defmodule ExcludedIgnored do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: %{Book => [:id, :title]}
        def excluded_fields, do: %{Book => [:title, :author_id]}
      end

      {:ok, view, _html} = navigate_to_book_100(conn, ExcludedIgnored)
      assert has_element?(view, ~s(#dumper td[data-field="title"]))
      refute has_element?(view, ~s(#dumper td[data-field="author_id"]))
      # strict by default, so other schemas not specified in allowed_fields hide all fields
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))

      defmodule ExcludedIgnoredLenient do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :lenient}
        def excluded_fields, do: %{Book => [:title], BookReview => [:rating]}
      end

      {:ok, view, _html} = navigate_to_book_100(conn, ExcludedIgnoredLenient)
      assert has_element?(view, ~s(#dumper td[data-field="title"]))
      refute has_element?(view, ~s(#dumper td[data-field="author_id"]))
      # when lenient, schemas not specified in allowed_fields are allowed
      # so the excluded_fields map is checked
      assert has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="rating"]))
    end
  end

  describe "custom record links config" do
    defmodule RecordLinksConfig do
      @moduledoc false
      use Dumper.Config

      def custom_record_links(%Book{}), do: [{"http://example.com", "example link"}]
    end

    test "displays links on the book id=100 page", %{conn: conn} do
      {:ok, _view, html} = navigate_to_book_100(conn, RecordLinksConfig)
      assert html =~ "example link"
    end
  end

  describe "additional associations config" do
    defmodule AdditionalAssociationsConfig do
      @moduledoc false
      use Dumper.Config

      def additional_associations(%Book{id: 100}) do
        [
          foo: [%{id: 1, baz: "quux"}],
          my_unique_association_name: [%{a: 2, b: 2, c: 2}, %{a: 3, b: 3, c: 3}],
          more_authors: Repo.all(Author),
          empty_association: []
        ]
      end
    end

    test "displays links on the book id=100 page", %{conn: conn} do
      {:ok, _view, html} = navigate_to_book_100(conn, AdditionalAssociationsConfig)
      assert html =~ "baz"
      assert html =~ "My Unique Association Name"
    end
  end

  describe "large tables config" do
    defmodule LargeTablesConfig do
      @moduledoc false
      use Dumper.Config

      def large_tables, do: [Book]
    end

    test "doesn't show page count for large tables", %{conn: conn} do
      {:ok, _view, html} = navigate_to_books_table(conn, LargeTablesConfig)
      refute html =~ "out of"
      assert html =~ "Showing at most"

      {:ok, _view, html} = navigate_to_authors_table(conn, LargeTablesConfig)
      assert html =~ "out of"
      assert html =~ "Showing at most"
    end
  end
end
