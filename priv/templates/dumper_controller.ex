# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule <%= @web_module %>.DumperController do
  use <%= @web_module %>, :controller

  import Ecto.Query
  alias <%= @app_module %>.Repo

  def home(conn, _) do
    {:ok, modules} = :application.get_key(<%= @application %>, :modules)
    render(conn, :home, modules: Enum.filter(modules, &is_ecto_schema?/1))
  end

  def resource(conn, %{"id" => id, "resource" => resource}) do
    # This handles routes like /foo?id=1234, which is used by the "Find by ID" form on index pages.
    conn |> redirect(to: ~p"/dumper/#{resource}/#{id}") |> halt()
  end

  def resource(conn, %{"resource" => resource} = params) do
    cond do
      # index
      module = to_module(resource, :index) ->
        page = Map.merge(%{"page" => 1, "page_size" => 25}, params)
        query = Ecto.Queryable.to_query(module)
        query = if :inserted_at in module.__schema__(:fields), do: order_by(query, desc: :inserted_at), else: query
        render(conn, :index, module: module, records: paginate(query, page))

      # show
      module = to_module(resource, :show) ->
        [id] = Enum.take(resource, -1)
        record = module |> Repo.get!(id) |> Repo.preload(module.__schema__(:associations))
        render(conn, :show, module: module, fields: module.__schema__(:fields), record: record)

      :else ->
        conn |> Plug.Conn.put_status(404) |> Plug.Conn.halt()
    end
  end

  defp to_module(resource, action) do
    resource = if action == :show, do: Enum.drop(resource, -1), else: resource
    module = resource |> Enum.map(&Macro.camelize/1) |> Module.safe_concat()
    if is_ecto_schema?(module), do: module
  rescue
    # Module.safe_concat will raise if the resource string doesn't map to an existing atom
    ArgumentError -> nil
  end

  defp is_ecto_schema?(module) do
    # true iff it 1. is a module 2. has a __schema__ function 3. is not an Embedded Schema
    match?({:module, _}, Code.ensure_loaded(module)) &&
      {:__schema__, 1} in module.__info__(:functions) &&
      module.__schema__(:source) != nil
  end

  defp paginate(query, %{"page" => page, "page_size" => page_size}) do
    page = if is_binary(page), do: String.to_integer(page), else: page
    page = max(1, page)

    page_size = if is_binary(page_size), do: String.to_integer(page_size), else: page_size
    page_size = max(1, page_size)

    entries =
      query
      |> limit(^page_size)
      |> offset(^(page_size * (page - 1)))
      |> Repo.all()

    total_pages = ceil(Repo.aggregate(query, :count) / page_size)

    %{
      entries: entries,
      has_prev?: page > 1,
      has_next?: page < total_pages,
      page: page,
      page_size: page_size
    }
  end
end
