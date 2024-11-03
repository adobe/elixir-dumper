defmodule Dumper.LiveDashboardPage do
  @moduledoc false

  alias Phoenix.LiveDashboard.PageBuilder
  use Phoenix.LiveDashboard.PageBuilder, refresher?: false

  import Dumper.ShowTableNames
  import Dumper.ShowTable
  import Dumper.ShowRecord
  import Ecto.Query

  @impl true
  def menu_link(_, _) do
    {:ok, "Dumper"}
  end

  @impl true
  def handle_params(%{"action" => "show_table"} = params, _uri, socket) do
    page = Map.merge(%{"pagenum" => 1, "page_size" => 25}, params)
    module = to_module(params["module"])
    query = Ecto.Queryable.to_query(module)

    query =
      if :inserted_at in module.__schema__(:fields),
        do: order_by(query, desc: :inserted_at, desc: :id),
        else: query

    {:noreply,
     assign(socket,
       action: :show_table,
       module: module,
       records: Dumper.paginate(query, page),
       record: nil,
       associations: nil
     )}
  end

  def handle_params(%{"action" => "show_record"} = params, _uri, socket) do
    repo = Dumper.repo()
    module = to_module(params["module"])
    record = module |> repo.get!(params["id"]) |> repo.preload(module.__schema__(:associations))

    associations =
      Enum.map(module.__schema__(:associations), fn assoc ->
        pagenum = Map.get(params, to_string(assoc), 1)
        page_params = %{"pagenum" => pagenum, "page_size" => 2}
        {assoc, Dumper.paginate(from(u in Ecto.assoc(record, assoc)), page_params)}
      end)

    {:noreply,
     assign(socket,
       action: :show_record,
       module: module,
       record: record,
       records: nil,
       associations: associations
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket,
       action: :show_table_names,
       module: nil,
       records: nil,
       record: nil,
       associations: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="dumper">
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

    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("show_record", %{"module" => module, "id" => record_id}, socket) do
    to =
      PageBuilder.live_dashboard_path(socket, %{
        socket.assigns.page
        | params: %{"action" => "show_record", "module" => module, "id" => record_id}
      })

    {:noreply, push_patch(socket, to: to)}
  end

  def handle_event("to-page", %{"pagenum" => pagenum, "assoc" => assoc}, socket) do
    if assoc do
      to =
        PageBuilder.live_dashboard_path(socket, socket.assigns.page, %{
          String.to_atom(assoc) => pagenum
        })

      {:noreply, push_patch(socket, to: to)}
    else
      to = PageBuilder.live_dashboard_path(socket, socket.assigns.page, pagenum: pagenum)
      {:noreply, push_patch(socket, to: to)}
    end
  end

  def handle_event("select_limit", %{"limit" => limit}, socket) do
    to =
      PageBuilder.live_dashboard_path(socket, socket.assigns.page, pagenum: 1, page_size: limit)

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
end