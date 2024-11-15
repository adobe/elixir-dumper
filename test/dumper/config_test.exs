defmodule Dumper.ConfigTest do
  use Dumper.ConnCase

  describe "custom linked ids config" do
    defmodule LinkedIdsConfig do
      @moduledoc false
      use Dumper.Config

      def ids_to_schema, do: %{book_id: Book, author_id: Author}
    end

    setup do
      Application.put_env(:dumper, :config_module, LinkedIdsConfig)
    end

    test "links work on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      {:ok, view, _html} = view |> element("td[data-field=\"author_id\"] a") |> render_click() |> follow_redirect(conn)
      assert is_author_page?(view)
    end

    test "links work on all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn)

      {:ok, view, _html} =
        view
        |> element("tr:first-child td[data-field=\"author_id\"] a")
        |> render_click()
        |> follow_redirect(conn)

      assert is_author_page?(view)
    end
  end

  describe "custom display config" do
    defmodule DisplayConfig do
      @moduledoc false
      use Dumper.Config

      def display(%{field: :title} = assigns), do: ~H|MY_UNIQUE_VALUE|
    end

    setup do
      Application.put_env(:dumper, :config_module, DisplayConfig)
    end

    test "title replaced on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      title_text = view |> element("td[data-field=\"title\"]") |> render()
      assert title_text =~ "MY_UNIQUE_VALUE"
    end

    test "title replaced on all books page", %{conn: conn} do
      {:ok, _view, html} = navigate_to_books_table(conn)

      html
      |> Floki.parse_fragment!()
      |> Floki.find("td[data-field=\"title\"]")
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

    setup do
      Application.put_env(:dumper, :config_module, AllowedFieldsConfig)
    end

    test "books show only id and title on the book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, "#dumper td[data-field=\"title\"]")
      refute has_element?(view, "#dumper td[data-field=\"author_id\"]")
    end

    test "books show only id and title on the all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn)
      assert has_element?(view, "#dumper td[data-field=\"title\"]")
      refute has_element?(view, "#dumper td[data-field=\"author_id\"]")
    end

    test "unspecified tables are completely hidden by default (strict)", %{conn: conn} do
      defmodule Strict do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: %{Book => [:id, :title]}
      end

      Application.put_env(:dumper, :config_module, Strict)

      # The book_reviews association is normally shown on this page.
      # Test that it is not shown since
      {:ok, view, _html} = navigate_to_book_100(conn)
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))

      defmodule StrictExplicit do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :strict}
      end

      Application.put_env(:dumper, :config_module, StrictExplicit)
      {:ok, view, _html} = navigate_to_book_100(conn)
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))
    end

    test "unspecified tables are shown when :lenient", %{conn: conn} do
      defmodule Lenient do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :lenient}
      end

      Application.put_env(:dumper, :config_module, Lenient)

      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))
    end
  end

  describe "excluded fields config" do
    defmodule ExcludedFieldsConfig do
      @moduledoc false
      use Dumper.Config

      def excluded_fields, do: %{Book => [:title]}
    end

    setup do
      Application.put_env(:dumper, :config_module, ExcludedFieldsConfig)
    end

    test "books show only id and title on the book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      refute has_element?(view, "#dumper td[data-field=\"title\"]")
      assert has_element?(view, "#dumper td[data-field=\"author_id\"]")
    end

    test "books show only id and title on the all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books_table(conn)
      refute has_element?(view, "#dumper td[data-field=\"title\"]")
      assert has_element?(view, "#dumper td[data-field=\"author_id\"]")
    end

    test "excluded is ignored when allowed is specified", %{conn: conn} do
      defmodule ExcludedIgnored do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: %{Book => [:id, :title]}
        def excluded_fields, do: %{Book => [:title, :author_id]}
      end

      Application.put_env(:dumper, :config_module, ExcludedIgnored)
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, "#dumper td[data-field=\"title\"]")
      refute has_element?(view, "#dumper td[data-field=\"author_id\"]")
      # strict by default, so other schemas not specified in allowed_fields hide all fields
      refute has_element?(view, ~s(div[data-association="reviews"] td[data-field="review_text"]))

      defmodule ExcludedIgnoredLenient do
        @moduledoc false
        use Dumper.Config

        def allowed_fields, do: {%{Book => [:id, :title]}, :lenient}
        def excluded_fields, do: %{Book => [:title], BookReview => [:rating]}
      end

      Application.put_env(:dumper, :config_module, ExcludedIgnoredLenient)
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, "#dumper td[data-field=\"title\"]")
      refute has_element?(view, "#dumper td[data-field=\"author_id\"]")
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
      Application.put_env(:dumper, :config_module, RecordLinksConfig)
      {:ok, _view, html} = navigate_to_book_100(conn)
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
      Application.put_env(:dumper, :config_module, AdditionalAssociationsConfig)
      {:ok, _view, html} = navigate_to_book_100(conn)
      assert html =~ "baz"
      assert html =~ "My Unique Association Name"
    end
  end
end
