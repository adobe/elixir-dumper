# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.ShowTableNames do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder

  def show_table_names(assigns) do
    ~H"""
    <div class="pt-3">
      <PageBuilder.live_table
        id="dumper-index"
        dom_id="dumper-index"
        page={@page}
        title="Schemas"
        row_fetcher={fetch_rows(@otp_app)}
        row_attrs={&row_attrs/1}
        rows_name="schemas"
      >
        <:col field={:name} sortable={:desc} />
      </PageBuilder.live_table>
    </div>
    """
  end

  defp fetch_rows(otp_app) do
    fn params, _node ->
      %{search: search, sort_by: _sort_by, sort_dir: sort_dir, limit: limit} = params
      search = String.downcase(search || "")

      {:ok, modules} = :application.get_key(otp_app, :modules)

      modules =
        modules
        |> Enum.filter(&is_ecto_schema?/1)
        |> Enum.map(fn module -> %{name: module |> Module.split() |> Enum.join(".")} end)

      # apply search
      modules = Enum.filter(modules, fn %{name: name} -> String.downcase(name) =~ search end)

      # sort
      modules = Enum.sort(modules, sort_dir)

      {Enum.take(modules, limit), Enum.count(modules)}
    end
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
