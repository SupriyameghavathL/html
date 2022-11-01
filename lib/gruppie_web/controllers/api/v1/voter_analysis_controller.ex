defmodule GruppieWeb.Api.V1.VoterAnalysisController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Handler.VoterAnalysisHandler
  alias GruppieWeb.Repo.GroupRepo
  import GruppieWeb.Repo.RepoHelper


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }


  # post "/groups/:group_id/team/:team_id/constituency/voters/add/bulk"
  def addVotersToBoothBulk(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id, "team_id" => team_id})  do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      #check whether array is created for booth in db
      VoterAnalysisHandler.checkVoterListCreated(group["_id"], teamObjectId)
      votersData = params["voters_data"]
      votersDataList = CSV.decode(File.stream!(votersData.path), headers: true)
      |> Enum.to_list
      for {:ok, voters} <- votersDataList do
        voterDetailsMap = %{
          "name" => voters["Name"],
          "houseNo" => voters["HouseNo"],
          "husbandName" => voters["HusbandName"],
          "voterId" => voters["VoterId"],
          "fatherName" => voters["fatherName"],
          "uniqueId" => encode_object_id(new_object_id())
        }
        # VoterAnalysisHandler.voterDetails(voterDetailsMap)
        VoterAnalysisHandler.pushToArray(group["_id"], teamObjectId, voterDetailsMap)
      end
      conn
      |>put_status(201)
      |>json(%{})
    end
  end


  #get "/groups/:group_id/team/:team_id/constituency/booth/voters/get"
  def getVotersDetailsBooth(conn,  %{ "group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      boothVoters = VoterAnalysisHandler.getVotersDetailsBooth(group["_id"], teamObjectId)
      render(conn, "boothVoterList.json", [getBoothVoterList: boothVoters])
    end
  end


  #put "/groups/:group_id/team/:team_id/constituency/voter/delete"
  def deleteVoterFromList(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      case VoterAnalysisHandler.deleteVotersFromList(group["_id"], teamObjectId, params["deletedUsersIds"]) do
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


  # post "/groups/:group_id/team/:team_id/constituency/voter/add"
  def addVotersToList(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      VoterAnalysisHandler.checkVoterListCreated(group["_id"], teamObjectId)
      for voterDetailsMap <- params["voterDeatils"] do
        VoterAnalysisHandler.pushToArray(group["_id"], teamObjectId, voterDetailsMap)
      end
      conn
      |>put_status(201)
      |>json(%{})
    end
  end


  # get "/groups/:group_id/booths/posts/get"
  def getBoothPost(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      loginUser = Guardian.Plug.current_resource(conn)
      if group["adminId"] == loginUser["_id"] do
        pageLimit = 15
        postsList = VoterAnalysisHandler.getBoothPost(group["_id"], params)
        render(conn, "boothsPost.json", [getBoothsPostList: postsList, groups: group, conn: conn, limit: pageLimit])
      else
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #get "/groups/:group_id/workers/get"
  def getWorkersList(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      workersList = VoterAnalysisHandler.getWorkers(group["_id"], params)
      pageLimit = 15
      render(conn, "workersList.json", [getWorkersList: workersList, limit: pageLimit])
    end
  end


  #get "/groups/:group_id/search/users/get"
  def getSearchUsers(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    getUsersBasedOnSearch = VoterAnalysisHandler.getUsers(group["_id"], params["filter"])
    render(conn, "usersList.json", [getUsersList: getUsersBasedOnSearch])
  end

  #get "/groups/:group_id/team/:team_id/search/users/get"
  def getTeamSearchUsers(%Plug.Conn{params: params} = conn,  %{ "group_id" => group_id, "team_id" => team_id})  do
    group = GroupRepo.get(group_id)
    teamObjectId = decode_object_id(team_id)
    getUsersBasedOnSearch = VoterAnalysisHandler.getTeamUsers(group["_id"], teamObjectId, params["filter"])
    render(conn, "usersList.json", [getUsersList: getUsersBasedOnSearch])
  end
end
