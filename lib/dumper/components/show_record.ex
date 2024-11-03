defmodule Dumper.ShowRecord do
  use Phoenix.Component

  alias Phoenix.LiveDashboard.PageBuilder
  import Dumper

  def show_record(assigns) do
    ~H"""
    <PageBuilder.card_title title={module_name(@module)} />
    <.module_link module={@module}>See all</.module_link>
    <.docs module={@module} />

    <div class="card tabular-card mb-4 mt-4">
      <div class="card-body p-0">
        <div class="dash-table-wrapper">
          <table class="table table-sm table-hover table-bordered mt-0 dash-table">
            <tr :for={field <- @module.__schema__(:fields)}>
              <td scope="row" style="background-color: #f2f4f9;"><strong><%= field %></strong></td>
              <td class="">
                <.value
                  module={@module}
                  field={field}
                  resource={@record}
                  value={Map.get(@record, field)}
                  type={@module.__schema__(:type, field)}
                  redacted={field in redacted_fields(@record)}
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
        <div class="mb-4"><.table_records records={result.entries} /></div>
        <.pagination records={result} assoc={assoc} />
      </details>
    </div>
    """
  end
end
