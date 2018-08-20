defmodule Siftsciex.HookSig do
  @moduledoc """
  Logic for calculating the signature for verifying a hook.
  """

  defstruct alg: nil, value: nil
  @type t :: %__MODULE__{alg: nil | alg, value: nil | String.t}
  @type alg :: :md5 | :sha | :sha224 | :sha256 | :sha384 | :sha512

  @doc """
  Calculates a signature for the given payload.

  ## Parameters

    - `algorithm`: The algorithm to use for the hmac the default is `:sha`, this should be a `t:Siftsciex.HookSig.alg/0` value.
    - `key`: The signature key
    - `payload`: The payload for the signature

  ## Examples

      iex> HookSig.calculate(:sha, "key", "payload")
      "2f3902cd1626fa7fdfb67e93109f50412ad71531"

  """
  @spec calculate(alg, String.t, String.t) :: String.t
  def calculate(alg \\ :sha, key, payload) do
    alg
    |> :crypto.hmac(key, payload)
    |> Base.encode16()
    |> String.downcase()
  end

  @doc """
  Verifies a signature for a `{key, payload}` pair.

  ## Parameters

    - `sig`: The signature to be verified (`t:Siftsciex.HookSig.t/0`)
    - `parts`: The `key` and `payload` to be checked against the signature, this should be in the form of `{key, payload}`
    - `algorithm`: The hmac algorithm in the form of `t:Siftsciex.HookSig.alg/0`, the default is `:sha`

  ## Examples

      iex> HookSig.valid?(%HookSig{alg: :sha, value: "2f3902cd1626fa7fdfb67e93109f50412ad71531"}, {"key", "payload"})
      true

      iex> HookSig.valid?(%HookSig{alg: :sha, value: "bullshit"}, {"key", "payload"})
      false

  """
  @spec valid?(__MODULE__.t, {String.t, String.t}) :: boolean
  def valid?(sig, {key, payload}) do
    sig.value() == calculate(sig.alg(), key, payload)
  end

  @doc """
  Extracts the signature from the request.

  ## Parameters

    - `value`: The value from the signature header

  ## Examples

      iex> HookSig.from("sha1=2f3902cd1626fa7fdfb67e93109f50412ad71531")
      {:ok, %HookSig{alg: :sha, value: "2f3902cd1626fa7fdfb67e93109f50412ad71531"}}

      iex> HookSig.from("super=__*__")
      {:error, "unknown_alg", "super=__*__"}

  """
  @spec from(String.t) :: {:ok, __MODULE__.t} | {:error, String.t}
  def from("sha1=" <> sig), do: {:ok, %__MODULE__{alg: :sha, value: sig}}
  def from(value), do: {:error, "unknown_alg", value}
end
