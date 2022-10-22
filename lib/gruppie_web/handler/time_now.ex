defmodule GruppieWeb.Handler.TimeNow do

  def bson_time() do
    DateTime.utc_now()
    |> DateTime.to_iso8601()
  end

  def indian_time() do
    DateTime.utc_now()
    |> Timex.shift(hours: 5, minutes: 30)
    |> DateTime.to_iso8601()
  end
end
