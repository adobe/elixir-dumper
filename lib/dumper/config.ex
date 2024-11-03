defmodule Dumper.Config do
  @callback ids_to_schema() :: :map
  @callback display(assigns :: map) :: :any

  use Phoenix.Component

  defmacro __using__(_opts) do
    quote do
      @behaviour Dumper.Config

      use Phoenix.Component

      @impl Dumper.Config
      def ids_to_schema(), do: %{}

      @before_compile {Dumper.Config, :add_display_fallback}

      defoverridable ids_to_schema: 0
    end
  end

  defmacro add_display_fallback(_env) do
    quote do
      @impl true
      def display(assigns) do
        Dumper.Config.default_display(assigns)
      end
    end
  end

  def default_display(assigns) do
    assigns = assign(assigns, :schema, Dumper.config_module().ids_to_schema()[assigns.field])

    if assigns.schema do
      ~H|<Dumper.record_link module={@schema} record_id={@value}><%= @value %></Dumper.record_link>|
    else
      Dumper.default_style_value(assigns)
    end
  end
end
