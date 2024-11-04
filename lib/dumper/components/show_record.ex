defmodule Dumper.ShowRecord do
  use Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder
  import Dumper

  def show_record(assigns) do
    ~H"""
    <div class="d-flex justify-content-between align-items-baseline">
      <div class="d-flex align-items-baseline">
        <PageBuilder.card_title title={module_name(@module)} />
        <span class="ml-3">
          <.module_link module={@module}>See all</.module_link>
        </span>
      </div>

      <div class="btn-group rounded border" role="group" aria-label="Basic example">
        <a :for={{route, text} <- custom_record_links(@record)} href={route} class="btn btn-link">
          <%= text %>
        </a>
      </div>
    </div>

    <.docs module={@module} />

    <div class="card tabular-card mb-4 mt-2">
      <div class="card-body p-0">
        <div class="dash-table-wrapper">
          <table class="table table-sm table-hover table-bordered mt-0 dash-table">
            <tr :for={field <- fields(@module)}>
              <td scope="row" style="background-color: #f2f4f9;"><strong><%= field %></strong></td>
              <td class="">
                <.value
                  module={@module}
                  field={field}
                  resource={@record}
                  value={Map.get(@record, field)}
                  type={@module.__schema__(:type, field)}
                  redacted={field in redacted_fields(@module)}
                />
              </td>
            </tr>
          </table>
        </div>
      </div>
    </div>

    <div :for={{assoc, result} <- @associations} :if={!Enum.empty?(result.entries)}>
      <details open>
        <summary>
          <span><%= humanize_association_name(assoc) %></span>
        </summary>
        <div class="d-flex flex-column mb-4" style="gap: 0.5rem">
          <.table_records records={result.entries} />
          <.pagination records={result} assoc={assoc} />
        </div>
      </details>
    </div>
    """
  end
end
