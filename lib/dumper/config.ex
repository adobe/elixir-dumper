# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.Config do
  @moduledoc ~S"""
  Provides sensible defaults for how data should be rendered.

  If you'd like your own customizations, define a module that implements
  the `m:Dumper.Config` behaviour:

      # An example dumper config module
      defmodule MyApp.DumperConfig do
        use Dumper.Config

        @impl Dumper.Config
        def ids_to_schema() do
          %{
            book_id: Library.Book,
            author_id: Library.Author
          }
        end

        @impl Dumper.Config
        def display(%{field: :last_name} = assigns) do
          ~H|<span style="color: red"><%= @value %></span>|
        end

        @impl Dumper.Config
        def custom_record_links(%Library.Book{} = book) do
          [
            {~p"/logging/#{book.id}", "Logs"},
            {"https://goodreads.com/search?q=#{book.title}", "Goodreads"},
          ]
        end
      end

  Then tell your `config.exs` where to find the module:

      config :dumper,
        repo: MyApp.Repo,
        config_module: MyApp.DumperConfig # <---- add this

  See `c:ids_to_schema/0` for examples of how you can configure
  automatic links of ids to records, `c:display/1` for examples of fine-grained
  control over how column values are rendered, and `c:custom_record_links/1` for examples of
  how to add custom metadata to the record page.

  The `use Dumper.Config` brings in the default definitions of behavior, so you can
  choose to define one, all, or none of them.  As such, even this is a valid implementation
  (although it would be functionally the same as not defining a config module at all):

      defmodule MyApp.DumperConfig do
        use Dumper.Config
      end
  """

  use Phoenix.Component

  @doc """
  A map of ids (as atoms) to the schema module they should link to.

  Each key/value pair in the map will automatically render as a clickable link that
  navigates the user to the dumper page for that specific record.

  By default this map is empty.

  Example:

      def ids_to_schema() do
        %{
          book_id: Library.Book,
          author_id: Library.Author
        }
      end

  Here, any field in any schema named `book_id` would render as a link to the `Book` record,
  via a `Repo.get!(id)` call under the hood, instead of just printing the value.  This allows
  you to easily navigate through your data by clicking connected links.
  """
  @callback ids_to_schema() :: :map

  @doc """
  Fine-grained control over how any field is rendered.  This is a functional component that takes
  in an `assigns` map and returns a valid `heex` expression.

  By default, Dumper has some sensible defaults for how redacted fields, values like `true`, `false`, `nil`, and data types like dates and datetimes are rendered.

  It is useful to define as many `c:display/1` function heads as you want, pattern matching on specific values to pick out the specific ones you'd like to customize.

  The `assigns` that is passed in is a map of the following form:

      # assigns
      %{
        module: Library.Author,
        field: :last_name,
        resource: %Library.Author{ ... }, # the entire ecto struct
        value: "Smith",
        type: :binary, # the Ecto data type
        redacted: false
      %}

  So for example, if you wanted every last name to be red except for the Author table, which should have blue last names, you could do the following:

      @impl Dumper.Config
      def display(%{field: :last_name, module: Library.Author} = assigns) do
        ~H|<span style="color: blue"><%= @value %></span>|
      end

      def display(%{field: :last_name} = assigns) do
        ~H|<span style="color: red"><%= @value %></span>|
      end

  In this way, you can have near complete control over how a particular field, data type, or entire module is displayed.

  Note that LiveDashboard ships with [Bootstrap 4.6](https://getbootstrap.com/docs/4.6), so you are free to use Bootstrap classes in your styling to help achieve a consistent look and feel.
  """
  @callback display(assigns :: map) :: Phoenix.LiveView.Rendered.t()

  @doc ~S"""
  Custom links rendered when viewing a specific record.

  This function takes a record you can pattern match on, and must return a list of `{route, text}`
  tuples.

      @impl Dumper.Config
      def custom_record_links(%Book{} = book) do
        [
          {~p"/logging/#{book.id}", "Logs"},
          {"https://goodreads.com/search?q=#{book.title}", "Goodreads"},
        ]
      end

      def custom_record_links(%Ticket{} = ticket),
        do: [{"https://jira.com/#{ticket.project}/#{ticket.id}", "Jira"}]

  In the above example, any `Book` record you visit in the Dumper will display two links labelled
  "Logs" and "Goodreads" at the top of the page.  Any `Ticket` record will likewise display one
  link, "Jira", in that spot.  Routes can be internal or external, verified routes, or plain strings.

  Logs, dashboards, traces, support portals, etc are all common use cases, but any `{route, text}`
  pair is possible.
  """
  @callback custom_record_links(record :: map) :: [{route :: binary, display_text :: binary}]

  @doc """
  A mapping from schema module => list of its fields that will be rendered.

      @impl Dumper.Config
      def allowed_fields() do
        %{
          Library.Patron => [:id, :last_name],
          Library.Book => [:title]
        }
      end

  In the above example, when displaying any patron record, the only fields that will be rendered
  at all will be the `id` and `last_name` fields.  All others will be completely hidden, and not
  even sent down through the `c:display/1` callback.  The same for any book record; only the title
  will be rendered.  All other schemas are unaffected - for example a `Author` schema would display
  all of its fields, even though it is not included in the returned map.

  The allowed fields will only hide fields for a module if the module exists as a key in the
  returned map.

  It's recommended to at least include the primary key field in the list so that there is at least
  one field to display.

  If a module exists as a key in this map, its entry (or lack thereof) in the `c:excluded_fields/0`
  callback is ignored.
  """
  @callback allowed_fields() :: :map

  @doc """
  A mapping from schema module => list of its fields that will be excluded from being rendered.

      @impl Dumper.Config
      def excluded_fields() do
        %{
          Library.Patron => [:email_address, :date_of_birth],
          Library.Book => [:purchase_price]
        }
      end

  In the above example, when displaying any patron record, the `email_address` and `date_of_birth`
  fields will not be rendered.  All others fields will be displayed.  The `email_address` and
  `date_of_birth` fields will not even be sent down through the `c:display/1` callback.  The
  same for any book record; the `purchase_price` field will never be rendered.  All other
  schemas are unaffected - for example a `Author` schema would display all of its fields, even
  though it is not included in the returned map.

  The excluded fields will only hide fields for a module if the module exists as a key in the
  returned map.

  It's recommended to at least include the primary key field in the list so that there is at least
  one field to display.

  If a module exists as a key in this map as well as the `c:allowed_fields/0` map, the excluded fields list
  is ignored.
  """
  @callback excluded_fields() :: :map

  defmacro __using__(_opts) do
    quote do
      @behaviour Dumper.Config

      use Phoenix.Component

      @impl Dumper.Config
      def ids_to_schema, do: %{}

      @impl Dumper.Config
      def allowed_fields, do: %{}

      @impl Dumper.Config
      def excluded_fields, do: %{}

      @before_compile {Dumper.Config, :add_display_fallback}
      @before_compile {Dumper.Config, :add_custom_record_links_fallback}

      defoverridable ids_to_schema: 0
      defoverridable allowed_fields: 0
      defoverridable excluded_fields: 0
    end
  end

  @doc false
  defmacro add_custom_record_links_fallback(_env) do
    quote do
      @impl true
      def custom_record_links(_), do: []
    end
  end

  @doc false
  defmacro add_display_fallback(_env) do
    quote do
      @impl true
      def display(assigns) do
        Dumper.Config.default_display(assigns)
      end
    end
  end

  @doc false
  def ids_to_schema, do: %{}

  @doc false
  def allowed_fields, do: %{}

  @doc false
  def excluded_fields, do: %{}

  @doc false
  def custom_record_links(_), do: []

  @doc false
  def display(assigns), do: default_display(assigns)

  @doc false
  def default_display(assigns) do
    assigns = assign(assigns, :schema, Dumper.config_module().ids_to_schema()[assigns.field])

    if assigns.schema && assigns.value do
      ~H|<Dumper.record_link module={@schema} record_id={@value}><%= @value %></Dumper.record_link>|
    else
      Dumper.default_style_value(assigns)
    end
  end
end
