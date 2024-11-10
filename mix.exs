# Copyright 2024 Adobe. All rights reserved.
# This file is licensed to you under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
# OF ANY KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.

defmodule Dumper.MixProject do
  use Mix.Project

  @version "0.2.0"
  @url "https://github.com/adobe/elixir-dumper"

  def project do
    [
      app: :dumper,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      ## Hex
      package: package(),
      description: "A mix task to generate an interactive view of your database",

      # Docs
      name: "Dumper",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:earmark, ">= 1.4.0"},
      {:ecto, ">= 3.7.0"},
      {:phoenix_ecto, ">= 4.4.0"},
      {:phoenix_live_dashboard, ">= 0.8.3"},
      {:phoenix_live_view, ">= 0.19.0"},
      {:phoenix_html, ">= 3.3.0"},
      {:ex_doc, "~> 0.33", runtime: false, only: :dev},
      {:ecto_sql, "~> 3.5", only: [:dev, :test]},
      {:ecto_sqlite3, "~> 0.7", only: :test},
      {:floki, "~> 0.36.0", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Ryan Young"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @url}
    ]
  end

  defp docs do
    [
      main: "readme",
      assets: %{"assets" => "assets"},
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "Dumper"]
      ],
      filter_modules: "Dumper.Config"
    ]
  end
end
