# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.LiveDashboardPage do
  @moduledoc false

  use Phoenix.LiveDashboard.PageBuilder, refresher?: false

  import Dumper.ShowRecord
  import Dumper.ShowTable
  import Dumper.ShowTableNames
  import Ecto.Query

  alias Phoenix.LiveDashboard.PageBuilder

  @assoc_page_size 5

  @impl true
  def menu_link(_, _), do: {:ok, "Dumper"}

  @impl true
  def init(term), do: {:ok, Map.new(term)}

  @impl true
  def mount(params, %{repo: _} = session, socket) do
    # config module via params is a hack to enable testing
    # it will not override a config module defined in the router options
    config_module = Map.get(params, "config_module", Dumper.Config)
    config_module = if is_binary(config_module), do: String.to_existing_atom(config_module), else: config_module
    session = Map.put_new(session, :config_module, config_module)
    session = Map.put_new(session, :otp_app, session.repo.config()[:otp_app])

    dumper_home = PageBuilder.live_dashboard_path(socket, %{socket.assigns.page | params: %{}})
    {:ok, socket |> assign(session) |> assign(dumper_home: dumper_home)}
  end

  defp clear_assigns(socket) do
    assign(socket,
      action: nil,
      module: nil,
      records: nil,
      record: nil,
      associations: nil,
      additional_associations: nil
    )
  end

  @impl true
  def handle_params(%{"action" => "show_table"} = params, _uri, socket) do
    page = Map.merge(%{"pagenum" => 1, "page_size" => 25}, params)
    module = to_module(params["module"])
    fields = module.__schema__(:fields)

    query = Ecto.Queryable.to_query(module)
    query = if :inserted_at in fields, do: order_by(query, desc: :inserted_at), else: query
    query = if :id in fields, do: order_by(query, desc: :id), else: query

    {:noreply,
     socket
     |> clear_assigns()
     |> assign(
       action: :show_table,
       module: module,
       records: Dumper.paginate(query, page, socket.assigns.repo)
     )}
  end

  def handle_params(%{"action" => "show_record"} = params, _uri, socket) do
    repo = socket.assigns.repo
    module = to_module(params["module"])
    record = module |> repo.get!(params["id"]) |> repo.preload(module.__schema__(:associations))

    associations =
      Enum.map(module.__schema__(:associations), fn assoc ->
        pagenum = Map.get(params, to_string(assoc), 1)
        page_params = %{"pagenum" => pagenum, "page_size" => @assoc_page_size}
        {assoc, Dumper.paginate(from(u in Ecto.assoc(record, assoc)), page_params, socket.assigns.repo)}
      end)

    {:noreply,
     socket
     |> clear_assigns()
     |> assign(
       action: :show_record,
       module: module,
       record: record,
       associations: associations,
       additional_associations: Dumper.additional_associations(record, socket.assigns.config_module)
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> clear_assigns() |> assign(action: :show_table_names)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="dumper">
      <div><.link navigate={@dumper_home}>Dumper Home</.link></div>
      <.show_table_names :if={@action == :show_table_names} {assigns} />
      <.show_table :if={@action == :show_table} {assigns} />
      <.show_record :if={@action == :show_record} {assigns} />
    </div>
    """
  end

  @impl true
  def handle_event("show_table", %{"module" => module}, socket) do
    to =
      PageBuilder.live_dashboard_path(socket, %{
        socket.assigns.page
        | params: %{"action" => "show_table", "module" => module}
      })

    {:noreply, push_navigate(socket, to: to)}
  end

  def handle_event("show_record", %{"module" => module, "id" => record_id}, socket) do
    to = record_path(module, record_id, socket)
    {:noreply, push_navigate(socket, to: to)}
  end

  def handle_event("to-page", %{"pagenum" => pagenum} = params, socket) do
    param = if params["assoc"], do: String.to_atom(params["assoc"]), else: :pagenum
    to = PageBuilder.live_dashboard_path(socket, socket.assigns.page, %{param => pagenum})
    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("select_limit", %{"limit" => limit}, socket) do
    to =
      PageBuilder.live_dashboard_path(socket, socket.assigns.page, pagenum: 1, page_size: limit)

    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("id-search", %{"search" => search}, socket) do
    to = record_path(socket.assigns.module, search, socket)
    {:noreply, push_patch(socket, to: to)}
  end

  defp to_module(nil), do: nil

  defp to_module(module_param) do
    module = module_param |> String.split(".") |> Module.safe_concat()
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

  defp record_path(module, record_id, socket) do
    PageBuilder.live_dashboard_path(socket, %{
      socket.assigns.page
      | params: %{"action" => "show_record", "module" => module, "id" => record_id}
    })
  end
end
