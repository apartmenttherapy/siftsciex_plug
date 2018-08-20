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

  require Logger

  alias Plug.Conn
  alias Siftsciex.{Decision, HookSig}

  @type opts :: %{required(String.t) => {module, atom}}
  @auth_header "x-sift-science-signature"

  @spec init(opts) :: map
  def init(opts) do
    opts
  end

  @spec call(Conn.t, map) :: Conn.t
  def call(conn, opts) do
    process(conn, opts)
  end

  @spec process(Plug.Conn.t, map) :: Plug.Conn.t
  def process(conn, opts) do
    conn.req_headers()
    |> signature()
    |> execute(conn, opts)
  end

  defp execute({:ok, signature}, conn, opts) do
    {:ok, body, conn} = Conn.read_body(conn)

    case HookSig.valid?(signature, {sig_key(), body}) do
      true ->
        {:ok, parsed_body} = Poison.decode(body)
        opts
        |> Map.get(path(conn))
        |> handle(parsed_body, conn)
      false ->
        forbid(conn)
    end
  end
  defp execute({:error, "unknown_alg", signature}, conn, _opts) do
    Logger.error("Received a Hook with an unknown algorithm: #{signature}")

    forbid(conn)
  end
  defp execute(nil, conn, _opts) do
    Logger.error("Received a Hook with no signature")

    forbid(conn)
  end

  defp forbid(conn) do
    conn
    |> send_resp(403, "Nope")
    |> halt()
  end

  def sig_key, do: Application.get_env(:siftsciex_plug, :hook_key)

  @spec signature(Keyword.t) :: {:ok, HookSig.t} | {:error, String.t, String.t} | nil
  defp signature(headers) do
    headers
    |> Enum.find_value(fn
      {@auth_header, value} -> HookSig.from(value)
      {_header, _value} -> nil
    end)
  end

  defp path(conn), do: Enum.join(conn.path_info(), "/")

  defp handle(nil, _, conn) do
    conn
    |> send_resp(404, "No such Hook")
    |> halt()
  end
  defp handle({mod, fun}, payload, conn) do
    Kernel.apply(mod, fun, [decision(payload)])

    send_resp(conn, 200, "")
  end

  defp decision(body) do
    Decision.new(body)
  end
end
