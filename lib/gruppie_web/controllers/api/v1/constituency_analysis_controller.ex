defmodule GruppieWeb.Api.V1.ConstituencyAnalysisController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.ConstituencyAnalysisHandler
  alias GruppieWeb.Constituency
  alias GruppieWeb.Handler.ConstituencyHandler
  alias GruppieWeb.Repo.ConstituencyRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.ConstituencyAnalysis


  #auth to check user is in group or not
  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }

  # post "/groups/:group_id/constituency/panchayat/add"?type=zp/tp/ward
  def addZpToConstituency(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id})  do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      changeset = ConstituencyAnalysis.changeset_add_zp_tp(%ConstituencyAnalysis{}, params)
      if changeset.valid? do
        #adding zp,tp,ward to db
        case ConstituencyAnalysisHandler.addZpTpToDb(group["_id"], changeset.changes, params) do
          {:ok, _success} ->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end


  # get "/groups/:group_id/constituency/panchayat/get"
  def getZpTpConstituency(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      #get zp,tp, ward from db based on params
      getPanchayat = ConstituencyAnalysisHandler.getZpTpToDb(group["_id"], params)
      render(conn, "panchayatList.json", [getPanchayatList: getPanchayat, params: params])
    end
  end

  #put "/groups/:group_id/constituency/panchayat/panchayat_id/edit"
  def editZpTpWardConstituency(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "panchayat_id" => panchayat_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      changeset = ConstituencyAnalysis.changeset_edit_zp_tp(%ConstituencyAnalysis{}, params)
      if changeset.valid? do
        panchayatObjectId = decode_object_id(panchayat_id)
        #edit zp,tp,ward to db
        case ConstituencyAnalysisHandler.editZpTpWard(group["_id"], changeset.changes, panchayatObjectId) do
          {:ok, _success} ->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end

  #put "/groups/:group_id/constituency/panchayat/:panchayat_id/delete"
  def deleteZpTpWardConstituency(%Plug.Conn{ params: _params } = conn, %{ "group_id" => group_id, "panchayat_id" => panchayat_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      panchayatObjectId = decode_object_id(panchayat_id)
      case ConstituencyAnalysisHandler.deleteZpTpWard(group["_id"], panchayatObjectId) do
        {:ok, _success} ->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end


  # post "/groups/:group_id/constituency/president/citizen/add"
  def addPresidentCitizenToConstituency(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUserId = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      cond do
        String.downcase(params["type"]) == "worker" ->
          #getting booth president teamId and committeeMap
          teamMap = ConstituencyAnalysisHandler.getCommitteeMapAndTeam(group["_id"], loginUserId["_id"])
          if teamMap do
            if teamMap["boothCommittees"] != [] do
              for user <- params["data"] do
                boothCommittee = hd(teamMap["boothCommittees"])
                changeset = Constituency.changeset_add_booth_members(%Constituency{}, user)
                if changeset.valid? do
                  boothCommitteeMap = %{teamCategory: teamMap["category"], dafaultCommittee: boothCommittee["defaultCommittee"], committeeId: boothCommittee["committeeId"]}
                  changesetMap = Map.merge(boothCommitteeMap, changeset.changes)
                  case ConstituencyHandler.addUserToBoothTeam(changesetMap, group, teamMap["_id"]) do
                    {:ok, _insertedUser}->
                      #incrementing userCount
                      ConstituencyRepo.incrementUsers(group)
                      UserRepo.lastUserForTeamUpdatedAt(teamMap["_id"])
                      conn
                      |> put_status(200)
                      |> json(%{})
                    {:error, _error}->
                      conn
                      |> put_status(500)
                      |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
                  end
                else
                  conn
                  |> put_status(400)
                  |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
                end
              end
            end
          else
            conn
            |>put_status(404)
            |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
          end
        String.downcase(params["type"]) == "voter" ->
          teamMap = ConstituencyAnalysisHandler.getTeamDetails(group["_id"], loginUserId["_id"])
          # IO.puts "#{teamMap}"
          if teamMap do
            for user <- params["data"] do
              changeset = Constituency.changeset_add_booth_members(%Constituency{}, user)
              if changeset.valid? do
                case  ConstituencyHandler.addUserToSubBoothTeam(changeset.changes, group, teamMap["_id"]) do
                  {:ok, _insertedUser} ->
                    ConstituencyRepo.incrementUsers(group)
                    checkUserKeyExists = ConstituencyRepo.checkUserKey(group["_id"], teamMap["boothTeamId"])
                    if checkUserKeyExists do
                      #key does not exists
                      ConstituencyRepo.appendUsersCount(group["_id"], teamMap["_id"], teamMap["boothTeamId"])
                    else
                      #key exits increment users count in teams
                      ConstituencyRepo.incrementUsersCount(group["_id"], teamMap["boothTeamId"], teamMap["_id"])
                    end
                    #update lastUserUpdatedAt time for team
                    UserRepo.lastUserForTeamUpdatedAt(teamMap["_id"])
                    conn
                    |> put_status(200)
                    |> json(%{})
                  {:error, _error}->
                    conn
                    |> put_status(500)
                    |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
                end
              else
                conn
                |> put_status(400)
                |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
              end
            end
          else
            conn
            |>put_status(404)
            |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
          end
        true ->
          conn
          |>put_status(404)
          |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #post "/groups/:group_id/constituency/team/push"
  def pushToTeam(%Plug.Conn{ params: _params } = conn, %{ "group_id" => group_id})  do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      list = ConstituencyAnalysisHandler.pushToTeam(group["_id"])
      if is_list(list) do
        case hd(list) do
          {:ok, _success} ->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        case list do
          {:ok, _success} ->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      end
    end
  end
end
