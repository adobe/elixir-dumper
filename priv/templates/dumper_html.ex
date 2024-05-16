# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule <%= @web_module %>.DumperHTML do
  @moduledoc """
    The view for dumper index and show pages.
    Put any value overrides here if you want special formatting of a
    certain field or data type.
  """
  use Phoenix.Component
  use Phoenix.HTML

  use Phoenix.VerifiedRoutes,
    endpoint: <%= @web_module %>.Endpoint,
    router: <%= @web_module %>.Router,
    statics: <%= @web_module %>.static_paths()

  embed_templates "dumper_html/*"

  ##################################################
  ## Redacted trumps all else

  defp value(%{redacted: true} = assigns), do: ~H|<span class="bg-slate-700 text-white px-2 rounded">redacted</span>|

  ##################################################
  ## Nil, true, and false

  defp value(%{value: nil} = assigns), do: ~H|<span class="bg-gray-200 px-2 rounded">nil</span>|

  defp value(%{value: true} = assigns), do: ~H|<span class="bg-emerald-100 px-2 rounded">true</span>|

  defp value(%{value: false} = assigns), do: ~H|<span class="bg-rose-200 px-2 rounded">false</span>|

  ##################################################
  ## By field/column name

  # For example, the following turns all `user_id` columns into links

  # defp value(%{field: :user_id} = assigns) do
  #   ~H"""
  #   <a href={~p"/dumper/users/user/#{@value}"}><%%= @value %></a>
  #   """
  # end


  ##################################################
  ## By Type

  defp value(%{type: :binary_id} = assigns), do: ~H|<pre><%%= @value %></pre>|

  defp value(%{type: :date} = assigns) do
    ~H"""
    <%%= @value |> Calendar.strftime("%b %d, %Y") %>
    """
  end

  defp value(%{type: type} = assigns) when type in ~w/utc_datetime_usec naive_datetime_usec utc_datetime naive_datetime/a do
    ~H"""
    <%%= @value |> Calendar.strftime("%b %d, %Y --- %I:%M:%S.%f %p") %>
    """
  end

  ##################################################
  ## Default

  defp value(assigns), do: ~H|<pre><%%= inspect(@value, pretty: true) %></pre>|

  ##################################################
  ## Helpers

  defp module_name(module), do: module |> to_string() |> String.replace(~r/^Elixir\./, "")

  defp humanize_association_name(module) do
    module |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp fields([record | _]), do: record.__struct__.__schema__(:fields)
  defp embeds([record | _]), do: record.__struct__.__schema__(:embeds)
  defp redacted_fields(record), do: record.__struct__.__schema__(:redact_fields)
end
