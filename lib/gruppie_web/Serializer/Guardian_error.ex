defmodule GruppieWeb.Serializer.GuardianError do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse

  def auth_error(conn, _,_opts) do
    conn
    |> put_status(401)
    |>json(%JsonErrorResponse{code: 401, title: "Unauthorized", message: "Your Not Allowed To Access The Url"})
  end
end
