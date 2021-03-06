defmodule Max.MixProject do
  use Mix.Project

  @version "0.1.4"
  @github "https://github.com/preciz/max"

  def project do
    [
      app: :max,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      homepage_url: @github,
      description: """
      A matrix library in pure Elixir based on Erlang array.
      """
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end

  defp docs do
    [
      main: "Max",
      source_ref: "v#{@version}",
      source_url: @github,
    ]
  end

  defp package do
    [
      maintainers: ["Barna Kovacs"],
      licenses: ["MIT"],
      links: %{"GitHub" => @github}
    ]
  end
end
