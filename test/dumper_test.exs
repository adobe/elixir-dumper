defmodule Dumper.DumperTest do
  use Dumper.ConnCase

  import Phoenix.LiveViewTest

  describe "The show all schemas page" do
    test "shows 5 entries in the table", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/dashboard/dumper")
      assert has_element?(view, "tr", "Book")
      assert has_element?(view, "tr", "BookReview")
      assert has_element?(view, "tr", "Loan")
      assert has_element?(view, "tr", "Patron")
      assert has_element?(view, "tr", "Author")
    end
  end

  describe "The Dumper Home header link" do
    test "works from the show table page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_table(conn, "Author")

      {:ok, _view, html} =
        view |> element("a", "Dumper Home") |> render_click() |> follow_redirect(conn)

      assert html =~ "schemas out of 5"
    end

    test "works from the show record page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_author_100(conn)

      {:ok, _view, html} =
        view |> element("a", "Dumper Home") |> render_click() |> follow_redirect(conn)

      assert html =~ "schemas out of 5"
    end
  end

  describe "The show all records in a table page" do
    test "displays sorted records in the table", %{conn: conn} do
      {:ok, _view, html} = navigate_to_table(conn, "Author")
      assert {100, 76} = results_between(html)
    end

    test "respects the page size limit dropdown", %{conn: conn} do
      # There are exactly 100 authors in the DB
      {:ok, view, _html} = navigate_to_table(conn, "Author")

      # Set the limit to 1000, we should see all 100 rows
      assert {100, 1} = view |> change_page_size(1_000) |> results_between()

      # Set the limit back to 25, we should only see 25 rows again
      assert {100, 76} = view |> change_page_size(25) |> results_between()
    end

    test "can navigate to the next and prev pages", %{conn: conn} do
      # There are exactly 100 authors in the DB, so 4 pages of 25
      {:ok, view, _html} = navigate_to_table(conn, "Author")

      # We're at the beginning, so there shouldn't be a Prev link
      refute has_element?(view, "#dumper a", "Prev")

      assert {75, 51} = view |> next_page() |> results_between()
      assert {50, 26} = view |> next_page() |> results_between()
      assert {25, 1} = view |> next_page() |> results_between()

      # We're at the end, so there shouldn't be a Next link
      refute has_element?(view, "#dumper a", "Next")

      # Click the "Prev" link and verify that we go backwards by 25
      assert {50, 26} = view |> prev_page() |> results_between()
    end

    test "Displays the Book schema moduledoc", %{conn: conn} do
      {:ok, view, _html} = navigate_to_table(conn, "Book")
      assert has_element?(view, "summary", "Documentation")
    end
  end

  defp navigate_to_table(conn, schema) do
    {:ok, view, _html} = live(conn, ~p"/dashboard/dumper")
    view |> element("tr", ~r/#{schema}\s*$/) |> render_click() |> follow_redirect(conn)
  end

  defp navigate_to_author_100(conn) do
    {:ok, view, _html} = navigate_to_table(conn, "Author")
    view |> element("#dumper td a", "100") |> render_click() |> follow_redirect(conn)
  end

  defp result_rows(html), do: html |> Floki.parse_document!() |> Floki.find("tbody tr")

  defp change_page_size(view, limit) do
    view |> element("#dumper form", "Showing at most") |> render_change(%{"limit" => limit})
  end

  defp next_page(view), do: view |> element("#dumper a", "Next") |> render_click()
  defp prev_page(view), do: view |> element("#dumper a", "Prev") |> render_click()

  defp results_between(html) do
    rows = result_rows(html)

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

  describe "The Book id 100 show table record page" do
    test "Displays the Book schema moduledoc", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, "summary", "Documentation")
    end

    test "Displays the author and reviews associations", %{conn: conn} do
      {:ok, view, _html} = navigate_to_book_100(conn)
      assert has_element?(view, "summary", "Author")
      assert has_element?(view, "summary", "Reviews")

      # assert there's only 1 author record, as a book only has 1 author
      assert {id, id} =
               view
               |> element("div[data-association=\"author\"]")
               |> render()
               |> results_between()
    end
  end

  defp navigate_to_book_100(conn) do
    {:ok, view, _html} = live(conn, ~p"/dashboard/dumper")

    {:ok, view, _html} =
      view |> element("tr", ~r/Book\s*$/) |> render_click() |> follow_redirect(conn)

    change_page_size(view, 1_000)
    view |> element("#dumper td a", ~r/100\s*/) |> render_click() |> follow_redirect(conn)
  end
end
