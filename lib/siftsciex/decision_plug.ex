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

  ### Notes

  Currently this Plug assumes that a Plug.Parser is being used upstream in conjunction with the `Siftsciex.HookValidator` to check incomming requests for a valid signature.
  """

  import Plug.Conn

  require Logger

  alias Plug.Conn
  alias Siftsciex.{Decision, HookValidator}

  @type opts :: %{required(String.t) => {module, atom}}

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
    case conn.body_params() do
      %Plug.Conn.Unfetched{} ->
        {:ok, body, conn} = HookValidator.validate(conn, [])
        case valid?(conn) do
          true ->
            {:ok, body} = Poison.decode(body)
            opts
            |> Map.get(path(conn))
            |> handle(body, conn)
          false ->
            Logger.error("Invalid signature on Hook")
            forbid(conn)
        end
      body ->
        case valid?(conn) do
          true ->
            opts
            |> Map.get(path(conn))
            |> handle(body, conn)
          false ->
            Logger.error("Invalid signature on Hook")
            forbid(conn)
        end
    end
  end

  @spec valid?(Plug.Conn.t) :: boolean
  def valid?(conn) do
    !!conn.assigns()[:siftsciex_sig] && true
  end

  defp forbid(conn) do
    conn
    |> send_resp(403, "Nope")
    |> halt()
  end

  @spec sig_key() :: String.t
  def sig_key, do: Application.get_env(:siftsciex_plug, :hook_key)

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
