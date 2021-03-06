defmodule Siftsciex.DecisionPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import Siftsciex.Plug.Data

  alias Siftsciex.DecisionPlug
  alias Siftsciex.Plug.TestHandler

  describe "Without a Plug.Parser" do
    test "If the request is signed it is allowed" do
      result =
        "test"
        |> req(decision())
        |> put_req_header("x-sift-science-signature", signature())
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

    test "If the request has an invalid signature then it returns a 403 response" do
      result =
        "test"
        |> req(decision())
        |> put_req_header("x-sift-science-signature", "bogus")
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 403
    end

    test "If the request is to a known path it is processed" do
      result =
        "test"
        |> req(decision())
        |> put_req_header("x-sift-science-signature", signature())
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 200
    end

    test "If the request is to an unknown path it returns a 404 response" do
      result =
        "random"
        |> req(decision())
        |> put_req_header("x-sift-science-signature", signature())
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 404
    end
  end

  describe "With a Plug.Parser" do
    test "If the request is signed it is allowed" do
      result =
        "test"
        |> req(decision())
        |> struct(body_params: parsed_body())
        |> assign(:siftsciex_sig, true)
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 200
    end

    test "If the request is not signed it returns a 403 response" do
      result =
        "test"
        |> req(decision())
        |> struct(body_params: parsed_body())
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 403
    end

    test "If the request has an invalid signature then it returns a 403 response" do
      result =
        "test"
        |> req(decision())
        |> struct(body_params: parsed_body())
        |> assign(:siftsciex_sig, false)
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 403
    end

    test "If the request is to a known path it is processed" do
      result =
        "test"
        |> req(decision())
        |> struct(body_params: parsed_body())
        |> assign(:siftsciex_sig, true)
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 200
    end

    test "If the request is to an unknown path it returns a 404 response" do
      result =
        "random"
        |> req(decision())
        |> struct(body_params: parsed_body())
        |> assign(:siftsciex_sig, true)
        |> DecisionPlug.call(%{"test" => {TestHandler, :run}})

      assert result.status() == 404
    end
  end

  def parsed_body do
    {:ok, body} = Poison.decode(decision())

    body
  end

  def req(path, body \\ nil) do
    :post
    |> conn(path, body)
    |> put_req_header("content-type", "application/json")
  end
end
