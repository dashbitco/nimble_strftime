defmodule NimbleStrftime.MixProject do
  use Mix.Project

  def project do
    [
      app: :nimble_strftime,
      version: "0.1.0",
      elixir: "~> 1.9",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end
end
