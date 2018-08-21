defmodule Siftsciex.HookValidatorTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Siftsciex.Plug.Data

  alias Siftsciex.HookValidator

  test "validate/2 indicates the signature is good if it matches the payload" do
    {:ok, _body, conn} = HookValidator.validate(good_conn(), [])

    assert conn.assigns[:siftsciex_sig]
  end

  test "validate/2 indicates the signature is bad if it doesn't match the payload" do
    {:ok, _body, conn} = HookValidator.validate(bad_conn(), [])

    refute conn.assigns[:siftsciex_sig]
  end

  test "validate/2 does not modify the conn if there is no signature present" do
    {:ok, _body, conn} = HookValidator.validate(neutral_conn(), [])

    assert conn.assigns[:siftsciex_sig] == nil
  end

  test "validate/2 does not modify the raw body in any way" do
    {:ok, body, _conn} = HookValidator.validate(neutral_conn(), [])

    assert ^body = decision()
  end

  def req(path, body \\ nil) do
    :post
    |> conn(path, body)
    |> put_req_header("content-type", "application/json")
  end

  defp good_conn do
    "test"
    |> req(decision())
    |> put_req_header("x-sift-science-signature", signature())
  end

  defp bad_conn do
    "test"
    |> req(decision())
    |> put_req_header("x-sift-science-signature", "sha1=bogus")
  end

  defp neutral_conn, do: req("test", decision())
end
