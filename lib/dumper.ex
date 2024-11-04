# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper do
  use Phoenix.Component

  embed_templates "dumper/components/*"
  import Ecto.Query

  def repo(), do: Application.fetch_env!(:dumper, :repo)
  def config_module(), do: Application.get_env(:dumper, :config_module, Dumper.Config)

  attr :module, :any, required: true
  slot :inner_block, required: true

  def module_link(assigns) do
    ~H"""
    <a href="#" phx-click="show_table" phx-value-module={@module}><%= render_slot(@inner_block) %></a>
    """
  end

  attr :module, :any, required: true
  attr :record_id, :any, required: true
  slot :inner_block, required: true

  def record_link(assigns) do
    ~H"""
    <a href="#" phx-click="show_record" phx-value-module={@module} phx-value-id={@record_id}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

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

  def humanize_association_name(module) do
    module |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
  end

  def fields(module) do
    config = config_module()
    all = module.__schema__(:fields)
    allowed = config.allowed_fields()
    excluded = config.excluded_fields()

    cond do
      Map.has_key?(allowed, module) ->
        Enum.filter(allowed[module], fn f -> f in all end)

      # MapSet.new(allowed[module]) |> MapSet.intersection(MapSet.new(all)) |> MapSet.to_list()

      Map.has_key?(excluded, module) ->
        Enum.reduce(excluded[module], all, fn f, acc -> List.delete(acc, f) end)

      # MapSet.new(all) |> MapSet.difference(MapSet.new(excluded[module])) |> MapSet.to_list()

      :all_fields ->
        all
    end
  end

  def embeds(module), do: module.__schema__(:embeds)
  def redacted_fields(module), do: module.__schema__(:redact_fields)
  def custom_record_links(record), do: config_module().custom_record_links(record)

  def value(assigns) do
    config_module().display(assigns)
  end

  def default_style_value(%{redacted: true} = assigns),
    do: ~H|<span class="badge badge-secondary">redacted</span>|

  def default_style_value(%{value: nil} = assigns),
    do: ~H|<span class="badge badge-secondary">nil</span>|

  def default_style_value(%{value: true} = assigns),
    do: ~H|<span class="badge badge-success">true</span>|

  def default_style_value(%{value: false} = assigns),
    do: ~H|<span class="badge badge-danger">false</span>|

  def default_style_value(%{type: :binary_id} = assigns),
    do: ~H|<pre class="mb-0"><%= @value %></pre>|

  def default_style_value(%{type: :date} = assigns) do
    ~H"""
    <%= @value |> Calendar.strftime("%b %d, %Y") %>
    """
  end

  def default_style_value(%{type: type} = assigns)
      when type in ~w/utc_datetime_usec naive_datetime_usec utc_datetime naive_datetime/a do
    ~H"""
    <span><%= Calendar.strftime(@value, "%b %d, %Y") %></span>
    &nbsp; <span><%= Calendar.strftime(@value, "%I:%M:%S.%f %p") %></span>
    """
  end

  def default_style_value(assigns),
    do: ~H|<pre class="mb-0"><%= inspect(@value, pretty: true) %></pre>|

  def paginate(query, %{"pagenum" => page, "page_size" => page_size}) do
    page = if is_binary(page), do: String.to_integer(page), else: page
    page = max(1, page)

    page_size = if is_binary(page_size), do: String.to_integer(page_size), else: page_size
    page_size = max(1, page_size)

    entries =
      query
      |> limit(^page_size)
      |> offset(^(page_size * (page - 1)))
      |> repo().all()

    total_entries = repo().aggregate(query, :count)
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
