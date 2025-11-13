defmodule BloomFilterEx.MixProject do
  use Mix.Project

  @version "0.1.3"
  @source_url "https://github.com/aspett/bloom_filter_elixir"

  def project do
    [
      app: :bloom_filter_ex,
      description: "Simple Bloom Filter wrapping the fastbloom Rust crate",
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      package: package()
    ]
  end

  defp docs do
    [
      main: "BloomFilterEx",
      extras: ["README.md"]
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
      {:rustler, "~> 0.36", runtime: false},
      {:rustler_precompiled, "~> 0.8"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      name: "bloom_filter_ex",
      licenses: ["MIT", "Apache-2.0"],
      links: %{
        "GitHub": @source_url
      },
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE*"
      ],
    ]
  end
end
