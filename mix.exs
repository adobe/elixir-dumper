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

  @version "0.1.1"
  @url "https://github.com/adobe/elixir-dumper"

  def project do
    [
      app: :dumper,
      version: @version,
      elixir: "~> 1.15",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.33", runtime: false, only: :dev}
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
      assets: "assets",
      source_ref: "v#{@version}",
      source_url: @url,
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "Dumper"],
      ]
    ]
  end
end
