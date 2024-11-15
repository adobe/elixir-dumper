defmodule Dumper.DumperTest do
  use Dumper.ConnCase, async: true

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
      {:ok, view, _html} = navigate_to_authors_table(conn)
      {:ok, _view, html} = navigate_to_dumper_home(view, conn)
      assert html =~ "schemas out of 5"
    end

    test "works from the show record page", %{conn: conn} do
      {:ok, view, _html} = navigate_to_author_100(conn)
      {:ok, _view, html} = navigate_to_dumper_home(view, conn)
      assert html =~ "schemas out of 5"
    end
  end

  describe "The show all records in a table page" do
    test "displays sorted records in the table", %{conn: conn} do
      {:ok, _view, html} = navigate_to_authors_table(conn)
      assert {100, 76} = results_between(html)
    end

    test "respects the page size limit dropdown", %{conn: conn} do
      # There are exactly 100 authors in the DB
      {:ok, view, _html} = navigate_to_authors_table(conn)

      # Set the limit to 1000, we should see all 100 rows
      assert {100, 1} = view |> change_page_size(1_000) |> results_between()

      # Set the limit back to 25, we should only see 25 rows again
      assert {100, 76} = view |> change_page_size(25) |> results_between()
    end

    test "can navigate to the next and prev pages", %{conn: conn} do
      # There are exactly 100 authors in the DB, so 4 pages of 25
      {:ok, view, _html} = navigate_to_authors_table(conn)

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
      {:ok, view, _html} = navigate_to_books_table(conn)
      assert has_element?(view, "summary", "Documentation")
      assert has_element?(view, "details", "Representation of a Book for demo purposes")
    end
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
end
