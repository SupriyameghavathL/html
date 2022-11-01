defmodule GruppieWeb.Api.V1.UserBlockController do
  use GruppieWeb, :controller
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.UserBlockHandler
  alias GruppieWeb.Repo.TeamRepo


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }


  #post "/groups/:group_id/team/:team_id/user/:user_id"?type=block/leaveteam/changeadmin
  def blockUser(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" ||  group["category"] == "community" do
      team = TeamRepo.get(team_id)
      loginUserId = Guardian.Plug.current_resource(conn)
      userObjectId = decode_object_id(user_id)
      cond do
        String.downcase(params["type"]) == "block" ->
          if loginUserId["_id"] == team["adminId"] do
            conn
            |>put_status(400)
            |>json(%JsonErrorResponse{code: 400, title: "Can't Block Self", message: "Can't Block Self"})
          else
            case UserBlockHandler.blockUser(group["_id"], userObjectId, team["_id"]) do
              {:ok, _}->
                conn
                |> put_status(201)
                |> json(%{})
              {:error, _mongo_error}->
                conn
                |>put_status(500)
                |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          end
        String.downcase(params["type"]) == "leaveteam" ->
          if loginUserId["_id"] == team["adminId"] do
            conn
            |>put_status(400)
            |>json(%JsonErrorResponse{code: 400, title: "Change admin to leave Team", message: "Change admin to leave Team"})
          else
            case UserBlockHandler.leaveTeam(group["_id"], userObjectId, team["_id"]) do
              {:ok, _}->
                conn
                |> put_status(201)
                |> json(%{})
              {:error, _mongo_error}->
                conn
                |>put_status(500)
                |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          end
        true ->
          conn
          |>put_status(200)
          |>json(%{})
      end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #put "/groups/:group_id/team/:team_id/user/:user_id/unblock"
  def unblockUser(conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" ||  group["category"] == "community" do
      teamObjectId = decode_object_id(team_id)
      # loginUserId = Guardian.Plug.current_resource(conn)
      userObjectId = decode_object_id(user_id)
      case UserBlockHandler.unblockUser(group["_id"], teamObjectId, userObjectId) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #put "/groups/:group_id/team/:team_id/user/:user_id/change/admin"
  def changeAdmin(conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id})  do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" ||  group["category"] == "community" do
      team = TeamRepo.get(team_id)
      loginUserId = Guardian.Plug.current_resource(conn)
      userObjectId = decode_object_id(user_id)
      if group["adminId"] == loginUserId["_id"] do
        case UserBlockHandler.changeAdmin(group["_id"], team["_id"], userObjectId) do
          {:ok, _}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |>put_status(500)
            |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
          {:adminChange, message} ->
            conn
            |>put_status(400)
            |>json(%JsonErrorResponse{code: 400, title: message, message: message})
        end
      else
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "You'r Not Authorized To Change", message: "You'r Not Authorized To Change"})
      end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end
end
