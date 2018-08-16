defmodule Siftsciex.DecisionPlug do
  @moduledoc """
  This Plug simplifies the handling of Decisions from Sift Science.

  The Decision Plug basically performs three functions:

    1. Mapping specific endpoints to specific handlers in your code
    2. Verifying the signature in the request
    3. Processing the Decision body and automatically converting it to a `t:Siftsciex.Decision.t/0` struct

  ### Configuration

  There is a single piece of configuration to set.  Sift Science sends a "signature" with each WebHook.  It is recommended that you verify this signature, in fact this Plug will not process any requests that are not properly "signed".  The signature should be set in the `:hook_key` attribute for the `:siftsciex_plug` application.

  ```
  config :siftsciex_plug,
    hook_key: <sift_hook_sig>
  ```

  ### Example

  ```
    forward "/sift_science", Siftsciex.DecisionPlug, %{
      "bad_listing" => {ListingHandler, :process}}
    }
  ```
  """

  import Plug.Conn

  alias Plug.Conn
  alias Siftsciex.Decision

  @type opts :: %{required(String.t) => {module, atom}}
  @auth_header "x-sift-science-signature"

  @spec init(opts) :: map
  def init(opts) do
    opts
  end

  @spec call(Conn.t, map) :: Conn.t
  def call(conn, opts) do
    conn
    |> valid?()
    |> case do
         true ->
           process(conn, opts)
         false ->
           conn
           |> send_resp(403, "Nope")
           |> halt()
       end
  end

  defp valid?(conn) do
    headers = conn.req_headers()

    headers
    |> Enum.find_value(fn
         {@auth_header, value} -> value
         {_header, _value} -> false
       end)
    |> Kernel.==(Application.get_env(:siftsciex_plug, :hook_key))
  end

  defp process(conn, opts) do
    opts
    |> Map.get(path(conn))
    |> handle(conn.body_params(), conn)
  end

  defp path(conn), do: Enum.join(conn.path_info(), "/")

  defp handle(nil, _, conn) do
    conn
    |> send_resp(404, "No such Hook")
    |> halt()
  end
  defp handle(handler, %Plug.Conn.Unfetched{aspect: :body_params}, conn) do
    {:ok, payload, conn} = Conn.read_body(conn)
    {:ok, payload} = Poison.decode(payload)

    handle(handler, payload, conn)
  end
  defp handle({mod, fun}, payload, conn) do
    Kernel.apply(mod, fun, [decision(payload)])

    send_resp(conn, 200, "")
  end

  defp decision(body) do
    Decision.new(body)
  end
end
