defmodule NavHelpers do
  @moduledoc false
  use Phoenix.VerifiedRoutes,
    endpoint: DumperTest.Endpoint,
    router: DumperTest.Router

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint DumperTest.Endpoint

  defp add_config_to_path(path, config) do
    if URI.new!(path).query == nil,
      do: path <> "?config_module=#{config}",
      else: path <> "&config_module=#{config}"
  end

  defp href(href_element) do
    [href] = href_element |> render() |> Floki.parse_fragment!() |> Floki.attribute("href")
    href
  end

  def navigate_to_dumper_home(view, conn, config \\ Dumper.Config) do
    path = view |> element("a", "Dumper Home") |> href()
    live(conn, add_config_to_path(path, config))
  end

  def navigate_to_books_table(conn, config \\ Dumper.Config), do: navigate_to_table(conn, "Book", config)
  def navigate_to_authors_table(conn, config \\ Dumper.Config), do: navigate_to_table(conn, "Author", config)

  defp navigate_to_table(conn, schema, config) do
    path = ~p"/dashboard/dumper?action=show_table&module=#{schema}"
    live(conn, add_config_to_path(path, config))
  end

  def navigate_to_author_100(conn, config \\ Dumper.Config) do
    {:ok, view, _html} = navigate_to_authors_table(conn, config)
    change_page_size(view, 1_000)
    book_100_path = view |> element(~s(#dumper td[data-field="id"] a), ~r/100\s*/) |> href()
    live(conn, add_config_to_path(book_100_path, config))
  end

  def navigate_to_book_100(conn, config \\ Dumper.Config) do
    {:ok, view, _html} = navigate_to_books_table(conn, config)
    change_page_size(view, 1_000)
    book_100_path = view |> element(~s(#dumper td[data-field="id"] a), ~r/100\s*/) |> href()
    live(conn, add_config_to_path(book_100_path, config))
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
