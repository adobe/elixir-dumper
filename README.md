# Dumper

_Takes your data and dumps it to the screen!_

Dumper uses reflection to find all your app's ecto schemas and provide routes
to browse their data.  This library provides a mix task to generate the
controller and components necessary to do that.

![dumper](assets/dumper.gif)


## Requirements

Dumper only works with Phoenix 1.7+ applications that use Ecto.

By default, Dumper also displays module docs for each schema.  To do this, your project must include [Earmark](https://hexdocs.pm/earmark/Earmark.html) as a dependency.


## About

Dumper aims to make it as easy as possible for everyone on a project to access and understand its data.

- All ids can be linked, so it's an incredibly fast way to explore a data model against real data.
- Because it's implemented with reflection, it automatically covers every schema module in your project.
- Styling is kept to a minimum so that data is front and center.
- All associations are also shown for a given record, all on the same page.
- Non-intrusive. No changes necessary to existing modules/files.
- Read-only.  No accidentally deleting or editing data while browsing.
- Shareable URLs. Having a shareable link to every record in your database is very useful for debugging. It gives everyone including non-technical teammates the ability to get a better understanding of your data model.


## Installation and Usage

Add `dumper` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dumper, "~> 0.1.0", only: [:dev]}
  ]
end
```

Update the dependencies and compile:
```sh
$ mix deps.get
$ mix compile
```

Run the `dumper.gen` mix task:

```sh
$ mix dumper.gen
* creating lib/foo_web/controllers/dumper_controller.ex
* creating lib/foo_web/controllers/dumper_html.ex
* creating lib/foo_web/controllers/dumper_html/index.html.heex
* creating lib/foo_web/controllers/dumper_html/show.html.heex
* creating lib/foo_web/controllers/dumper_html/home.html.heex
* creating lib/foo_web/controllers/dumper_html/table_records.html.heex
* creating lib/foo_web/controllers/dumper_html/pagination.html.heex

Add the following routes to router:

    get "/dumper", DumperController, :home
    get "/dumper/*resource", DumperController, :resource

It's recommended to put these routes behind some kind of admin plug or environment check
to avoid potentially leaking access to the public.
```

Like the output suggests, add the following routes to your router:

``` elixir
get "/dumper", DumperController, :home
get "/dumper/*resource", DumperController, :resource
```

It's recommended to put these routes behind some kind of admin plug or environment check to avoid potentially leaking access to the public.  For example:

``` elixir
scope "/dumper" do
  pipe_through [:browser, :require_admin_user]

  get "/", DumperController, :home
  get "/*resource", DumperController, :resource
end
```


## Customization

The Dumper is a mix generator, not a library, so once you run it you are free (and encouraged!) to modify the generated files to suit your needs.

It is *highly recommended* to add your own `DumperHTML.value/1` function definitions to customize how certain fields, data types, and values are displayed.

### Examples

To make all `user_id` column values render a link to that specific user:
``` elixir
defp value(%{field: :user_id} = assigns) do
  ~H"""
  <a href={~p"/dumper/users/user/#{@value}"}><%= @value %></a>
  """
end
```

But maybe the `user_id` on the `books` table refers to the author.  Pattern match on the module as well to provide the different implementation:
``` elixir
defp value(%{module: Book, field: :user_id} = assigns) do
  ~H"""
  <a href={~p"/dumper/authors/author/#{@value}"}><%= @value %></a>
  """
end
```

Editing the `controllers/dumper_html.ex` file is a great way to customize the Dumper to your specific application and business logic needs.


## Default Behaviour you may want to change

### Rendering Embeds
The index page and association tables on the show page by default omit columns that are embeds.  This is purely for display purposes, as those values tend to take up a lot of vertical space.  If you'd like them to be displayed, remove the `:if={field not in embeds(@records)}` on lines `10` and `19` of your generated `dumper_html/table_records.html.heex` file.

### Redactions
By default, schema fields with `redact: true` are hidden and replaced with the text `redacted`.  If you're running the Dumper in a non-production environment or against dummy data, you may want to disregard the redacted fields.  To do that, you can delete or modify the `defp value(%{redacted: true}) ...` function definition on lines `17-20` of `controllers/dumper_html.ex`.

### Tailwind
The dumper uses tailwind classes to give it some basic styling, since it is included by default with the most recent phoenix generators.  If your project doesn't use tailwind, they won't have an effect, and you are free to delete or replace them once generated.
