defmodule Dumper.ShowTable do
  use Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder
  import Dumper
  import Phoenix.HTML.Form

  def show_table(assigns) do
    ~H"""
    <PageBuilder.card_title title={module_name(@module)} />
    <.docs module={@module} />

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

    <div class="mb-4">
      <.table_records records={@records.entries} />
    </div>

    <.pagination records={@records} assoc={nil} />
    """
  end
end
