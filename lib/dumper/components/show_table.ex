defmodule Dumper.ShowTable do
  use Phoenix.Component

  import Dumper
  import Phoenix.HTML.Form

  def show_table(assigns) do
    ~H"""
    <div class="pt-3">
      <h5 class="mb-0"><%= module_name(@module) %></h5>
      <.docs module={@module} />
    </div>

    <form phx-change="select_limit" class="form-inline">
      <div class="form-row align-items-center">
        <%= if @records.page_size do %>
          <div class="col-auto">Showing at most</div>
          <div class="col-auto">
            <div class="input-group input-group-sm">
              <select name="limit" class="custom-select" id="limit-select">
                <%= options_for_select([25, 50, 100, 500, 1000, 5000], @records.page_size) %>
              </select>
            </div>
          </div>
          <div class="col-auto">out of <%= @records.total_entries %></div>
        <% else %>
          <div class="col-auto">Showing <%= @records.total_entries %></div>
        <% end %>
      </div>
    </form>

    <div class="mt-3 mb-2">
      <.table_records records={@records.entries} />
    </div>

    <.pagination records={@records} assoc={nil} />
    """
  end
end
