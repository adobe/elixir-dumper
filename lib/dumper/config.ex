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

        def ids_to_schema() do
          %{
            book_id: Library.Book,
            author_id: Library.Author
          }
        end

        def display(%{field: :last_name} = assigns) do
          ~H|<span style="color: red"><%= @value %></span>|
        end

        def custom_record_links(%Library.Book{} = book) do
          [
            {~p"/logging/#{book.id}", "Logs"},
            {"https://goodreads.com/search?q=#{book.title}", "Goodreads"},
          ]
        end
      end

  Then update the `live_dashboard` entry in the `router.ex` file to add the config module:

      live_dashboard "/dashboard", additional_pages:
        [dumper: {Dumper.LiveDashboardPage, repo: MyApp.Repo, config_module: MyApp.DumperConfig}]

  Implementing each callback provides a different way to control how the data is rendered:
  - `c:ids_to_schema/0`: turn id values into clickable links
  - `c:display/1`: define a functional component for complete control over how fields are rendered
  - `c:custom_record_links/1`: display custom links when viewing an indivisual record
  - `c:Dumper.Config.additional_associations/1`: display custom associations not defined in the Ecto schema
  - `c:Dumper.Config.allowed_fields/0`: any fields not included will be ignored
  - `c:Dumper.Config.excluded_fields/0`: any fields included will be ignored
  - `c:Dumper.Config.large_tables/0`: tables included will not render the total record count and won't sort by inserted_at

  The `use Dumper.Config` brings in the default definitions of behaviour, so you can
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
  @callback ids_to_schema() :: map()

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
  Tables so large they timeout when querying the row count.

  By including schema modules in this list, Dumper will omit querying and displaying of the
  total number of entries and order by `id` instead of `inserted_at`.  A clue you may need
  to add a table to this list is if the page errors out when rendering the list of records.

      @impl Dumper.Config
      def large_tables, do: [Book, Patrons]
  """
  @callback large_tables() :: [atom]

  @doc """
  Additional records to be rendered on the given record's page.

      @impl Dumper.Config
      def additional_associations(%Book{id: book_id}) do
        # look up reviews on goodreads
        [goodreads_reviews: [top_review, lowest_review]]
      end

  For a given record, return a keyword list of association name to list of records.  Overriding
  this callback allows you to render more data at the bottom of the page.  This is useful
  when the given record doesn't explicitly define an association, or the data you want to
  display doesn't live in the database.

  Note that while regular associations are paginated, since these are custom we can't
  automatically paginate them.  It's recommended to cap the number of records returned.
  """
  @callback additional_associations(record :: map) :: Keyword.t()

  @doc """
  A mapping from schema module => list of its fields that will be rendered.

  Can return
  - `nil`: all fields in all tables are shown
  - a map: a field is only displayed if the exact Schema + field pairing exists in the map
  - `{map, :strict}`: a field is only displayed if the exact Schema + field pairing exists in the map
  - `{map, :lenient}`: a field is displayed if the exact Schema + field pairing exists in the map **or** the schema module is not present in the map

  Here's an example where we return a mapping of schema modules to the fields we want to allow displayed:

      @impl Dumper.Config
      def allowed_fields() do
        %{
          Patron => [:id, :last_name],
          Book => [:title]
        }
      end

  In the above example, the returned map defaults to strict mode.  Rendered fields would
  include `patron.last_name` and `book.title`.  Hidden fields would include fields like
  `patron.first_name` and `author.last_name`.

      @impl Dumper.Config
      def allowed_fields() do
        map = %{
          Patron => [:id, :last_name],
          Book => [:title]
        }
        {map, :lenient}
      end


  In the above example, `lenient` strictness means that `author.last_name` would now be rendered even though the `Author` key not explicitly defined in the returned mapping.

  It's recommended to at least include the primary key field in the list so that there is at least
  one field to display.

  `c:excluded_fields/0` is ignored if:
  - this callback is implemented and returns strict mode (or returns only a map)
  - this callback is implemented and returns lenient mode, but the schema key is present in the map
  """
  @callback allowed_fields() :: nil | map() | {map(), :strict | :lenient}

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

  See `c:allowed_fields/0` for cases where `c:excluded_fields/0` is ignored.
  """
  @callback excluded_fields() :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Dumper.Config

      use Phoenix.Component

      @impl Dumper.Config
      def ids_to_schema, do: %{}

      @impl Dumper.Config
      def large_tables, do: []

      @impl Dumper.Config
      def allowed_fields, do: nil

      @impl Dumper.Config
      def excluded_fields, do: %{}

      @before_compile {Dumper.Config, :add_display_fallback}
      @before_compile {Dumper.Config, :add_custom_record_links_fallback}
      @before_compile {Dumper.Config, :add_additional_associations_fallback}

      defoverridable ids_to_schema: 0
      defoverridable large_tables: 0
      defoverridable allowed_fields: 0
      defoverridable excluded_fields: 0
    end
  end

  @doc false
  defmacro add_additional_associations_fallback(_env) do
    quote do
      @impl true
      def additional_associations(_), do: []
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
  def large_tables, do: []

  @doc false
  def allowed_fields, do: nil

  @doc false
  def excluded_fields, do: %{}

  @doc false
  def additional_associations(_), do: []

  @doc false
  def custom_record_links(_), do: []

  @doc false
  def display(assigns), do: default_display(assigns)

  @doc false
  def default_display(assigns) do
    assigns = assign(assigns, id_link_schema: assigns.config_module.ids_to_schema()[assigns.field])
    default_style_value(assigns)
  end

  defp default_style_value(%{id_link_schema: schema} = assigns) when not is_nil(schema) do
    ~H|<.link navigate={"#{@dumper_home}?module=#{@id_link_schema}&id=#{@value}"}>
  <%= @value %>
</.link>|
  end

  defp default_style_value(%{redacted: true} = assigns), do: ~H|<span class="badge badge-secondary">redacted</span>|
  defp default_style_value(%{value: nil} = assigns), do: ~H|<span class="badge badge-secondary">nil</span>|
  defp default_style_value(%{value: true} = assigns), do: ~H|<span class="badge badge-success">true</span>|
  defp default_style_value(%{value: false} = assigns), do: ~H|<span class="badge badge-danger">false</span>|
  defp default_style_value(%{type: :binary_id} = assigns), do: ~H|<pre class="mb-0"><%= @value %></pre>|
  defp default_style_value(%{type: :date} = assigns), do: ~H/<%= @value |> Calendar.strftime("%b %d, %Y") %>/

  defp default_style_value(%{type: type} = assigns)
       when type in ~w/utc_datetime_usec naive_datetime_usec utc_datetime naive_datetime/a do
    ~H"""
    <span><%= Calendar.strftime(@value, "%b %d, %Y") %></span>
    &nbsp; <span><%= Calendar.strftime(@value, "%I:%M:%S.%f %p") %></span>
    """
  end

  defp default_style_value(assigns), do: ~H|<pre class="mb-0"><%= inspect(@value, pretty: true) %></pre>|
end
