defmodule NimbleStrftime.MixProject do
  use Mix.Project
  @version "0.1.1"
  @source_url "https://github.com/plataformatec/nimble_strftime"

  def project do
    [
      app: :nimble_strftime,
      version: @version,
      elixir: "~> 1.9",
      name: "NimbleStrftime",
      description: "strftime-based datetime formatter for Elixir",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  defp docs do
    [
      main: "NimbleStrftime",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Gustavo Santos Ferreira", "José Valim"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
