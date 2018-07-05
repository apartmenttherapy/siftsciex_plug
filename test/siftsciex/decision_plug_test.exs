defmodule Siftsciex.DecisionPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Siftsciex.DecisionPlug
  alias Siftsciex.Plug.TestHandler

  test "If the request is signed it is allowed" do
    result =
      "test"
      |> req(decision())
      |> put_req_header("x-sift-science-signature", "test")
      |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

    assert result.status() == 200
  end

  test "If the request is not signed it returns a 403 response" do
    result =
      "test"
      |> req(decision())
      |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

    assert result.status() == 403
  end

  test "If the request is to a known path it is processed" do
    result =
      "test"
      |> req(decision())
      |> put_req_header("x-sift-science-signature", "test")
      |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

    assert result.status() == 200
  end

  test "If the request is to an unknown path it returns a 404 response" do
    result =
      "random"
      |> req(decision())
      |> put_req_header("x-sift-science-signature", "test")
      |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

    assert result.status() == 404
  end

  def req(path, body \\ nil) do
    :post
    |> conn(path, body)
    |> put_req_header("content-type", "application/json")
  end

  def decision do
    """
    {
      "entity": {
        "type": "user",
        "id": "USER123"
      },
      "decision": {
        "id": "block_user_payment_abuse"
      },
      "time": 1530633228
    }
    """
  end
end