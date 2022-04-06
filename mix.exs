defmodule MalanPhoenixUtils.MixProject do
  use Mix.Project

  @source_url "https://github.com/freedomben/malan_phoenix_utils"
  @version "0.1.0"

  def project do
    [
      app: :malan_phoenix_utils,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: "Set of utility functions initially written for the Malan project, but now independent.  Provides Phoenix-related utility functions.",
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  def package do
    [
      name: "malan_phoenix_utils",
      maintainers: ["Benjmain Porter"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
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
      {:malan_utils, "~> 0.1.0"},
      {:ex_doc, "~> 0.28.0"},
      {:plug_cowboy, "~> 2.0", only: :dev, runtime: false},
      {:ecto, "~> 3.7", only: :dev, runtime: false}
      #{:pbkdf2_elixir, "~> 1.2"},
    ]
  end

  defp docs do
    [
      main: "MalanPhoenixUtils",
      source_url: @source_url,
      extra_section: [],
      api_reference: false
    ]
  end
end
