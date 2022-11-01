defmodule GruppieWeb.Api.V1.GroupSettingsController do
  use GruppieWeb, :controller
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.GroupHandler
  alias GruppieWeb.Structs.JsonErrorResponse

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }

  #allow admin change setting
  #put "admin/groups/:id/admin/change/allow"
  def allowAdminChange(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    case GroupHandler.allowAdminChangeSetting(group) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow share post
  #put "/groups/:id/post/share/allow"
  def allowPostShare(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    case GroupHandler.postShareAllowSetting(group) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow everyone to post in group
  #put "/groups/:id/allow/post/all"
  def allowPostAll(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    case GroupHandler.allowPostAllSetting(group) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #group settings list
  #get"/groups/:id/settings"
  def groupSettings(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    data = %{
        "allowPostAll" => group["allowPostAll"],
        "allowPostShare" => group["isPostShareAllowed"],
        "allowAdminChange" => group["isAdminChangeAllowed"]
      }

    json conn, %{ data: data }
  end



  #allow parent to pay fee
  #put "/groups/:id/allow/fee/pay/parent"
  def allowParentToPayFee(conn, %{ "group_id" => group_id }) do
    text conn, group_id
  end


  #allow parent to pay fee
  #put "/groups/:id/allow/fee/pay/parent"
  def allowParentToPayFee123(conn, %{ "id" => group_id }) do
    group = GroupRepo.get(group_id)
    text conn, group
    #update fee pay setting on groups col
    case GroupRepo.allowParentToPayFee(group["_id"]) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



end
