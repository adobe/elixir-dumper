defmodule Dumper.ShowTableNames do
  use Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder

  def show_table_names(assigns) do
    ~H"""
    <PageBuilder.live_table
      id="dumper-index"
      dom_id="dumper-index"
      page={@page}
      title="Schemas"
      row_fetcher={&fetch_all_tables/2}
      row_attrs={&row_attrs/1}
      rows_name="schemas"
    >
      <:col field={:name} sortable={:desc} />
    </PageBuilder.live_table>
    """
  end

  defp fetch_all_tables(params, _node) do
    %{search: search, sort_by: _sort_by, sort_dir: sort_dir, limit: limit} = params
    search = (search || "") |> String.downcase()

    {:ok, modules} = :application.get_key(:library, :modules)

    modules =
      modules
      |> Enum.filter(&is_ecto_schema?/1)
      |> Enum.map(fn module -> %{name: module |> Module.split() |> Enum.join(".")} end)

    # apply search
    modules = modules |> Enum.filter(fn %{name: name} -> String.downcase(name) =~ search end)

    # sort
    modules = modules |> Enum.sort(sort_dir)

    {Enum.take(modules, limit), Enum.count(modules)}
  end

  defp row_attrs(%{name: module}) do
    [
      {"phx-click", "show_table"},
      {"phx-value-module", module},
      {"phx-page-loading", true}
    ]
  end

  defp is_ecto_schema?(module) do
    # true iff it 1. is a module 2. has a __schema__ function 3. is not an Embedded Schema
    match?({:module, _}, Code.ensure_loaded(module)) &&
      {:__schema__, 1} in module.__info__(:functions) &&
      module.__schema__(:source) != nil
  end
end