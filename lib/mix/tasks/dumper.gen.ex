# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Mix.Tasks.Dumper.Gen do
  @moduledoc """
  The Dumper uses reflection to find all your app's ecto schemas, and then provide
  routes to browse their data.  This mix task generates the controller and components
  necessary to do that.

  Once run, follow the on-screen instructions to add dumper routes to your router.
  From there, you can customize all aspects of the dumper.

  ## Example

      $ mix dumper.gen

  ## Requirements

  - Ecto
  - Ability to call `use *_web, :controller`.
    - This is included in most phoenix apps by default

  """
  use Mix.Task

  @shortdoc "Generates files necessary for the dumper"
  def run(_args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix dumper.gen must be invoked from within your *_web application root directory"
      )
    end

    copy_new_files()
    print_shell_instructions()
  end

  defp copy_new_files() do
    app_dir = File.cwd!()
    app_name = Path.basename(app_dir)
    web_path = Path.join([app_dir, "lib", app_name]) <> "_web"

    Mix.Generator.copy_template(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_controller.ex"]),
      Path.join([web_path, "controllers", "dumper_controller.ex"]),
      application: ":#{app_name}",
      app_module: Macro.camelize(app_name),
      web_module: Macro.camelize(app_name) <> "Web"
    )

    Mix.Generator.copy_template(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html.ex"]),
      Path.join([web_path, "controllers", "dumper_html.ex"]),
      web_module: Macro.camelize(app_name) <> "Web"
    )

    Mix.Generator.copy_file(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html", "index.html.heex"]),
      Path.join([web_path, "controllers", "dumper_html", "index.html.heex"])
    )

    Mix.Generator.copy_file(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html", "show.html.heex"]),
      Path.join([web_path, "controllers", "dumper_html", "show.html.heex"])
    )

    Mix.Generator.copy_file(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html", "home.html.heex"]),
      Path.join([web_path, "controllers", "dumper_html", "home.html.heex"])
    )

    Mix.Generator.copy_file(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html", "table_records.html.heex"]),
      Path.join([web_path, "controllers", "dumper_html", "table_records.html.heex"])
    )

    Mix.Generator.copy_file(
      Path.join([:code.priv_dir(:dumper), "templates", "dumper_html", "pagination.html.heex"]),
      Path.join([web_path, "controllers", "dumper_html", "pagination.html.heex"])
    )
  end

  defp print_shell_instructions() do
    Mix.shell().info("""

    Add the following routes to router:

        get "/dumper", DumperController, :home
        get "/dumper/*resource", DumperController, :resource

    It's recommended to put these routes behind some kind of admin plug or environment check
    to avoid potentially leaking access to the public.
    """)
  end
end
