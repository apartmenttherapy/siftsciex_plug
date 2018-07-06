# Siftsciex Plug

The Siftsciex Plug provides a very small API and logic for helping process Sift Science Decisions.  If you need to handle a Decision Web Hook from Sift Science then you may find this useful.

The Decision Plug really does three things:

1. Checks for the Sift Science Signature in the request
2. Processes the body and transforms it into a `Siftsciex.Decision.t` struct
3. Maps specific endpoints to specific handlers

## Installation

[Available in Hex](https://hex.pm/packages/siftsciex_plug), the package can be installed
by adding `siftsciex_plug` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:siftsciex_plug, "~> 0.1.0"}
  ]
end
```

## Example

The first thing you need to do is configure the expected Signature from Sift Science:

```elixir
  config :siftsciex_plug,
    hook_key: <sift_science_signature>
```

Then you can configure the `Plug` to process and route specific paths for you.

```elixir
  alias Siftsciex.DecisionPlug

  forward "/sift_science", DecisionPlug, %{
    "bad_user" => {User, :sift_ban},
    "bad_listing" => {Listing, :sift_delete}
  }
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/siftsciex_plug](https://hexdocs.pm/siftsciex_plug).

