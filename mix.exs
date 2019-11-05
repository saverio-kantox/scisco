defmodule Scisco.MixProject do
  use Mix.Project

  @app :scisco
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/saverio-kantox/#{@app}",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Easy plug sort/filter/pagination into an Ecto query.
    """
  end

  defp package do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "postgrex",
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/saverio-kantox/#{@app}"}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Scisco.Query",
      logo: "scythe.png",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.1"},
      {:postgrex, "~> 0.15.1", only: [:dev, :test]},
      {:ex_doc, "> 0.0.0", only: [:dev], runtime: false},
      {:credo, "~> 1.0", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev, :test], runtime: false}
    ]
  end
end
