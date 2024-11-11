defmodule Dumper.ConfigTest do
  use Dumper.ConnCase, async: true

  describe "custom linked ids config" do
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
  end

  describe "excluded fields config" do
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
  end

  describe "custom record links config" do
    test "displays links on the book id=100 page", %{conn: conn} do
      Application.put_env(:dumper, :config_module, RecordLinksConfig)
      {:ok, _view, html} = navigate_to_book_100(conn)
      assert html =~ "example link"
    end
  end

  describe "additional associations config" do
    test "displays links on the book id=100 page", %{conn: conn} do
      Application.put_env(:dumper, :config_module, AdditionalAssociationsConfig)
      {:ok, _view, html} = navigate_to_book_100(conn)
      assert html =~ "baz"
      assert html =~ "My Unique Association Name"
    end
  end
end

defmodule LinkedIdsConfig do
  @moduledoc false
  use Dumper.Config

  def ids_to_schema, do: %{book_id: Book, author_id: Author}
end

defmodule DisplayConfig do
  @moduledoc false
  use Dumper.Config

  def display(%{field: :title} = assigns), do: ~H|MY_UNIQUE_VALUE|
end

defmodule RecordLinksConfig do
  @moduledoc false
  use Dumper.Config

  def custom_record_links(%Book{}), do: [{"http://example.com", "example link"}]
end

defmodule AllowedFieldsConfig do
  @moduledoc false
  use Dumper.Config

  def allowed_fields, do: %{Book => [:id, :title]}
end

defmodule ExcludedFieldsConfig do
  @moduledoc false
  use Dumper.Config

  def excluded_fields, do: %{Book => [:title]}
end

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
