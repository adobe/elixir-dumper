# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper do
  @moduledoc false
  use Phoenix.Component

  import Ecto.Query

  embed_templates "dumper/components/*"

  def docs(assigns) do
    doctext =
      case Code.fetch_docs(assigns.module) do
        {_, _, _, _, %{"en" => doctext} = _module_doc, _, _} -> String.trim(doctext)
        _ -> ""
      end

    markdown_html =
      doctext
      |> Earmark.as_html!(code_class_prefix: "lang- language-")
      |> Phoenix.HTML.raw()

    assigns = assign(assigns, markdown: markdown_html, doctext: doctext)

    ~H"""
    <details :if={@doctext != ""} class="markdown mt-2">
      <summary class="cursor-pointer">Documentation</summary>
      <div class="card bg-light mt-1 p-3 small"><%= @markdown %></div>
    </details>
    """
  end

  def module_name(module), do: module |> to_string() |> String.replace(~r/^Elixir\./, "")

  def humanize_association_name(module) when is_atom(module) do
    module |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
  end

  def fields(module, config_module) do
    all = module.__schema__(:fields)
    excluded = config_module.excluded_fields()

    {allowed_map, allowed_strict?} =
      case config_module.allowed_fields() do
        nil -> {%{}, false}
        %{} = m -> {m, true}
        {m, :lenient} -> {m, false}
        {m, _strict} -> {m, true}
      end

    cond do
      allowed_strict? || Map.has_key?(allowed_map, module) ->
        allowed_map |> Map.get(module, []) |> Enum.filter(fn f -> f in all end)

      Map.has_key?(excluded, module) ->
        Enum.reduce(excluded[module], all, fn f, acc -> List.delete(acc, f) end)

      :all_fields ->
        all
    end
  end

  def embeds(module), do: module.__schema__(:embeds)
  def redacted_fields(module), do: module.__schema__(:redact_fields)
  def custom_record_links(record, config_module), do: config_module.custom_record_links(record)
  def additional_associations(record, config_module), do: config_module.additional_associations(record)

  def value(assigns) do
    assigns.config_module.display(assigns)
  end

  def paginate(query, %{"pagenum" => page, "page_size" => page_size}, repo) do
    page = if is_binary(page), do: String.to_integer(page), else: page
    page = max(1, page)

    page_size = if is_binary(page_size), do: String.to_integer(page_size), else: page_size
    page_size = max(1, page_size)

    entries =
      query
      |> limit(^page_size)
      |> offset(^(page_size * (page - 1)))
      |> repo.all()

    total_entries = repo.aggregate(query, :count)
    total_pages = ceil(total_entries / page_size)

    %{
      entries: entries,
      has_prev?: page > 1,
      has_next?: page < total_pages,
      page: page,
      page_size: page_size,
      total_entries: total_entries
    }
  end
end
