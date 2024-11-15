# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.ShowRecord do
  @moduledoc false
  use Phoenix.Component

  import Dumper

  def show_record(assigns) do
    ~H"""
    <div class="mb-3">
      <div class="d-flex justify-content-between align-items-end">
        <div class="d-flex align-items-baseline pt-3">
          <% # <PageBuilder.card_title title={module_name(@module)} /> %>
          <h5 class="mb-0"><%= module_name(@module) %></h5>
          <span class="ml-3">
            <.module_link module={@module}>See all</.module_link>
          </span>
        </div>

        <div class="btn-group rounded border border-secondary" role="group" aria-label="Basic example">
          <a
            :for={{{route, text}, i} <- Enum.with_index(custom_record_links(@record))}
            href={route}
            class="btn btn-link"
            style={if i > 0, do: "border-left: 1px solid #6c757d"}
          >
            <%= text %>
          </a>
        </div>
      </div>

      <.docs module={@module} />
    </div>

    <div class="card tabular-card mb-4">
      <div class="card-body p-0">
        <div class="dash-table-wrapper">
          <table class="table table-sm table-hover table-bordered mt-0 dash-table">
            <tr :for={field <- fields(@module)}>
              <td scope="row" style="background-color: #f2f4f9;"><strong><%= field %></strong></td>
              <td data-field={field}>
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

    <div
      :for={{assoc, result} <- @associations}
      :if={!Enum.empty?(result.entries)}
      data-association={assoc}
    >
      <details open class="mb-3">
        <summary>
          <span><%= humanize_association_name(assoc) %></span>
        </summary>
        <div class="d-flex flex-column mt-2" style="gap: 0.5rem">
          <.table_records records={result.entries} />
          <.pagination records={result} assoc={assoc} />
        </div>
      </details>
    </div>

    <%!-- Additional associations are defined by the user, so we do not have pagination --%>
    <div
      :for={{assoc, records} <- @additional_associations}
      :if={!Enum.empty?(records)}
      data-association={assoc}
    >
      <details open class="mb-3">
        <summary>
          <span><%= humanize_association_name(assoc) %></span>
        </summary>
        <div class="d-flex flex-column mt-2" style="gap: 0.5rem">
          <.table_records records={records} />
        </div>
      </details>
    </div>
    """
  end
end
