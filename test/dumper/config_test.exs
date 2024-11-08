defmodule Dumper.ConfigTest do
  use Dumper.ConnCase

  import Phoenix.LiveViewTest

  # alias __MODULE__.AllowedFieldsConfig
  # alias __MODULE__.DisplayConfig
  # alias __MODULE__.ExcludedFieldsConfig
  # alias __MODULE__.LinkedIdsConfig
  # alias __MODULE__.RecordLinksConfig

  describe "custom linked ids config" do
    setup do
      Application.put_env(:dumper, :config_module, LinkedIdsConfig)
    end

    test "links work on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      {:ok, view, _html} = view |> element("td[data-field=\"author_id\"] a") |> render_click() |> follow_redirect(conn)
      assert is_author_page(view)
    end

    test "links work on all books page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_books(conn)

      {:ok, view, _html} =
        view
        |> element("tr:first-child td[data-field=\"author_id\"] a")
        |> render_click()
        |> follow_redirect(conn)

      assert is_author_page(view)
    end
  end

  describe "custom display config" do
    setup do
      Application.put_env(:dumper, :config_module, DisplayConfig)
    end

    test "title replaced on book id=100 page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert get_displayed_title_text(view) =~ "MY_UNIQUE_VALUE"
    end

    test "title replaced on all books page", %{conn: conn} do
      {:ok, _view, html} = navigate_to_books(conn)

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
      {:ok, view, _html} = navigate_to_books(conn)
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
      {:ok, view, _html} = navigate_to_books(conn)
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

  defp get_displayed_title_text(view) do
    view |> element("td[data-field=\"title\"]") |> render()
  end

  defp change_page_size(view, limit) do
    view |> element("#dumper form", "Showing at most") |> render_change(%{"limit" => limit})
  end

  defp navigate_to_books(conn) do
    {:ok, view, _html} = live(conn, ~p"/dashboard/dumper")
    view |> element("tr", ~r/Book\s*$/) |> render_click() |> follow_redirect(conn)
  end

  defp navigate_to_book_100(conn) do
    {:ok, view, _html} = navigate_to_books(conn)
    change_page_size(view, 1_000)
    view |> element("#dumper td[data-field=\"id\"] a", ~r/100\s*/) |> render_click() |> follow_redirect(conn)
  end

  defp is_author_page(view) do
    has_element?(view, "h5", "Author")
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
