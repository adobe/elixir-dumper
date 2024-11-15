defmodule NavHelpers do
  @moduledoc false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint DumperTest.Endpoint

  def navigate_to_dumper_home(view, conn) do
    view |> element("a", "Dumper Home") |> render_click() |> follow_redirect(conn)
  end

  def navigate_to_books_table(conn), do: navigate_to_table(conn, "Book")
  def navigate_to_authors_table(conn), do: navigate_to_table(conn, "Author")

  defp navigate_to_table(conn, schema) do
    {:ok, view, _html} = live(conn, "/dashboard/dumper")
    view |> element("tr", ~r/#{schema}\s*$/) |> render_click() |> follow_redirect(conn)
  end

  def navigate_to_author_100(conn) do
    {:ok, view, _html} = navigate_to_authors_table(conn)
    # open_browser(view)
    view |> element("#dumper td a", "100") |> render_click() |> follow_redirect(conn)
  end

  def navigate_to_book_100(conn) do
    {:ok, view, _html} = navigate_to_books_table(conn)
    change_page_size(view, 1_000)
    view |> element("#dumper td[data-field=\"id\"] a", ~r/100\s*/) |> render_click() |> follow_redirect(conn)
  end

  def change_page_size(view, limit) do
    view |> element("#dumper form", "Showing at most") |> render_change(%{"limit" => limit})
  end

  def next_page(view), do: view |> element("#dumper a", "Next") |> render_click()
  def prev_page(view), do: view |> element("#dumper a", "Prev") |> render_click()

  def results_between(html) do
    rows = html |> Floki.parse_document!() |> Floki.find("tbody tr")

    to_int = fn tr ->
      tr
      |> Floki.find("td")
      |> List.first()
      |> Floki.text()
      |> String.trim()
      |> String.to_integer()
    end

    {rows |> List.first() |> to_int.(), rows |> List.last() |> to_int.()}
  end

  def is_author_page?(view), do: has_element?(view, "h5", "Author")
end
