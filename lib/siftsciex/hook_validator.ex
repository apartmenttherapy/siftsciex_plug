defmodule Siftsciex.HookValidator do
  @moduledoc """
  The SigPlug is responsible for checking for a Sift Science signature header and if present verifying that the body is valid.
  """

  import Plug.Conn

  require Logger

  alias Siftsciex.HookSig

  @auth_header Application.get_env(:siftsciex_plug, :sig_header)
  @hook_key Application.get_env(:siftsciex_plug, :hook_key)

  @doc """
  Validates a Sift Science Web Hook request against the provided signature.  The result of the validation is stored on the `t:Plug.Conn.t/0` struct in `assigns` -> `:siftsciex_plug`.  In the case where the request did not have a signature value then `assigns` -> `:siftsciex_plug` will be `nil`.

  ## Parameters

    - `conn`: The Plug connection which should be checked and validated
    - `opts`: Any options for the `read_body` call

  """
  @spec validate(Plug.Conn.t, Keyword.t) :: {:ok, String.t, Plug.Conn.t}
  def validate(conn, opts) do
    {:ok, body, conn} = read_body(conn, opts)

    conn.req_headers()
    |> get_sig()
    |> verify(conn, body)
  end

  @spec get_sig([{binary, binary}]) :: binary | nil
  def get_sig(headers) do
    headers
    |> Enum.find_value(fn
      {@auth_header, value} -> value
      {_header, _value} -> nil
    end)
  end

  @spec verify(nil | HookSig.t, Plug.Conn.t, String.t) :: {:ok, String.t, Plug.Conn.t}
  def verify(nil, conn, body) do
    {:ok, body, conn}
  end
  def verify(sig, conn, body) do
    sig
    |> HookSig.from()
    |> valid?(conn, body)
  end

  @spec valid?({:ok, HookSig.t} | {:error, String.t, String.t}, Plug.Conn.t, String.t) :: {:ok, String.t, Plug.Conn.t}
  def valid?({:ok, signature}, conn, body) do
    valid_sig = HookSig.valid?(signature, {@hook_key, body})
    conn = assign(conn, :siftsciex_sig, valid_sig)

    {:ok, body, conn}
  end
  def valid?({:error, _reason, header}, conn, body) do
    Logger.error("Received unknown signature type:  #{header}")
    conn = assign(conn, :siftsciex_sig, false)

    {:ok, body, conn}
  end
end
