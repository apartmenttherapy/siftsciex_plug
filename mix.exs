defmodule SiftsciexPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :siftsciex_plug,
      version: "0.1.0",
      elixir: "~> 1.6",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]]
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
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:plug, ">= 0.0.0"},
      {:siftsciex, ">= 0.0.0"}
    ]
  end

  defp description do
    "A Plug for handling Sift Science Web Hooks"
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["LGPLv3"],
      maintainers: ["Glen Holcomb"],
      links: %{"GitHub" => "https://github.com/apartmenttherapy/siftsciex_plug"},
      source_url: "https://github.com/apartmenttherapy/siftsciex_plug"
    ]
  end
end
