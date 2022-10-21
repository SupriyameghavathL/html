defmodule GruppieWeb.Api.V1.SecurityController do
  use GruppieWeb, :controller
  # alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Handler.SecurityHandler
  alias GruppieWeb.User


  #to check whether user exist in gruppie or not
  #post "/user/exist"
  def userExist(conn, params) do
    changeset = User.changeset_user_exist(%User{}, params)
    if changeset.valid? do
      {:ok, result} = SecurityHandler.findUserExistByPhoneNumber(changeset.changes)
      data = if result > 0 do
        %{
          "countryCode" => params["countryCode"],
          "phone" => params["phone"],
          "isUserExist" => true,
        }
      else
        %{
          "countryCode" => params["countryCode"],
          "phone" => params["phone"],
          "isUserExist" => false,
        }
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end
end
