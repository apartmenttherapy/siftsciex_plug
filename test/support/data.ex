defmodule Siftsciex.Plug.Data do
  def signature do
    "sha1=#{:crypto.hmac(:sha, "test", decision()) |> Base.encode16() |> String.downcase()}"
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
