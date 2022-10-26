defmodule GruppieWeb.Api.V1.ConstituencyCategoryController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.ConstituencyCategoryHandler
  alias GruppieWeb.ConstituencyCategory
  alias GruppieWeb.Repo.TeamRepo


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" } when  action not in [:addSpecialName ]

  # post "/groups/:group_id/constituency/category/list/add"
  def addCategoriesToDb(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      case ConstituencyCategoryHandler.addCategoriesToDb(group["_id"], params["categories"]) do
        {:ok, _success} ->
          conn
          |>put_status(201)
          |> json(%{})
        {:error, _error} ->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB ERROR", message: "Something Went Wrong"})
      end
    end
  end


  #get "/groups/:group_id/constituency/category/list/get"
  def getCategoriesFromDb(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      constituencyCategoryList = ConstituencyCategoryHandler.getCategoriesFromDb(group["_id"])
      render(conn, "getConstituencyList.json", [getConstituencyList: constituencyCategoryList])
    end
  end


  # post "/groups/:group_id/constituency/category/types/add"
  def addCategoriesTypeToDb(%Plug.Conn{params: params} = conn,  %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      case ConstituencyCategoryHandler.addCategoriesTypeToDb(group["_id"], params["categoryTypes"]) do
        {:ok, _success} ->
          conn
          |>put_status(201)
          |> json(%{})
        {:error, _error} ->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB ERROR", message: "Something Went Wrong"})
      end
    end
  end


  # get "/groups/:group_id/constituency/category/types/get"
  def getCategoriesTypeFromDb(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      constituencyTypesList = ConstituencyCategoryHandler.getCategoriesTypeFromDb(group["_id"])
      render(conn, "getConstituencyTypesList.json", [getConstituencyTypesList: constituencyTypesList])
    end
  end


   # get "/groups/:group_id/constituency/category/get?category=EDUCATION&categorySelection=MALE&categoryType=1&page=1
   def getUsersBasedOnFilter(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getUserListBasedOnQueryFilter = ConstituencyCategoryHandler.userListBasedOnFilter(group["_id"], params)
    render(conn, "usersListBasedOnFilter.json", [getUserListBasedOnFilter: getUserListBasedOnQueryFilter])
  end


  # post "/groups/:group_id/constituency/special/post/add"
  def addSpecialPostBasedOnFilter(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    changeset = ConstituencyCategory.specialPost(%ConstituencyCategory{}, params)
    if changeset.valid? do
      case ConstituencyCategoryHandler.addSpecialPostBasedOnFilter(changeset.changes, group["_id"], loginUser["_id"]) do
        {:ok, _success} ->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error} ->
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

  # get "/groups/:group_id/constituency/special/post/get"
  def getSpecialPostBasedOnFilter(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    # checking whether canPost true for login userId
    canPost = ConstituencyCategoryHandler.checkCanPost(group["_id"], loginUser["_id"])
    #get all post for superAdmin and canPost true users
    specialPostList = if group["adminId"] == loginUser["_id"] || canPost["canPost"] == true do
     ConstituencyCategoryHandler.getSpecialPostBasedForAdmin(group["_id"])
    else
     ConstituencyCategoryHandler.getSpecialPostBasedOnFilter(group["_id"], loginUser, params)
    end
    render(conn, "specialPostList.json", [getSpecialPostList: specialPostList, group: group, login_user: loginUser, canPost: canPost["canPost"]])
  end


  #post "/groups/:group_id/constituency/special/post/:post_id/like"
  def addLikesToSpecialPost(%Plug.Conn{params: _params} = conn, %{"group_id" => group_id, "post_id" => post_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      postObjectId = decode_object_id(post_id)
        case ConstituencyCategoryHandler.addLikesToSpecialPost(group["_id"], postObjectId, loginUser["_id"]) do
          {:ok, _success} ->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _error} ->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
    end
  end


  #put "/groups/:group_id/constituency/special/post/:post_id/delete"
  def deleteSpecialPost(conn, %{"group_id" => group_id, "post_id" => post_id}) do
    group = GroupRepo.get(group_id)
    # loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      case ConstituencyCategoryHandler.deleteSpecialPost(group["_id"], post_id) do
        {:ok, _success} ->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error} ->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end


  # get "/groups/:group_id/constituency/special/post/events"
  def getEventsForSpecialPost(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
     loginUser = Guardian.Plug.current_resource(conn)
     canPost = ConstituencyCategoryHandler.checkCanPost(group["_id"], loginUser["_id"])
     specialPostEvents = if group["adminId"] == loginUser["_id"] || canPost["canPost"] == true do
        ConstituencyCategoryHandler.getSpecialPostBasedForAdminEvents(group["_id"])
      else
        ConstituencyCategoryHandler.getSpecialPostBasedOnFilterEvents(group["_id"], loginUser)
      end
      render(conn, "constituency_special_post_events.json", %{getSpecialPostEvents: specialPostEvents})
    end
  end


  #get "/groups/:group_id/constituency/install/voter/get"?role=admin
  def getInstalledAndVoterUsers(%Plug.Conn{params: _params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      getVoterAndInstallList = ConstituencyCategoryHandler.getInstalledAndVoterUsers(group["feederMap"])
      render(conn, "getInstalledUsersAndVoters.json", [getTotalUsersInstall: getVoterAndInstallList])
      # if params["role"] == "isAdmin" do
      #   #to get voters and installed list users
      #   getVoterAndInstallList = ConstituencyCategoryHandler.getInstalledAndVoterUsers()
      #   render(conn, "getInstalledUsersAndVoters.json", [getTotalUsersInstall: getVoterAndInstallList])
      # else
      #   #not found error
      #   conn
      #   |>put_status(404)
      #   |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      # end
    end
  end


  #post "/groups/:group_id/constituency/voter/analytics/field"
  def addProfileExtraFields(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      case ConstituencyCategoryHandler.addProfileExtraFields(group["_id"], params["voterAnalysisFields"]) do
        {:ok, _success} ->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error} ->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end

  #get "groups/:group_id/constituency/voter/analytics/field/get"
  def getAnalysisFields(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      analysisFields = ConstituencyCategoryHandler.getAnalysisFields(group["_id"])
      render(conn, "getAnalysisFields.json", [getAnalysisFields: analysisFields])
    end
  end


  #get "groups/:group_id/constituency/search/list/users"
  def getSearchListConstituency(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      getUserOnSearchList = ConstituencyCategoryHandler.getUserListBasedOnSearch(group["_id"], params)
      if params["category"] && params["categorySelection"] do
        render(conn, "filterBasedOnName.json", [getNameBasedOnFilter: getUserOnSearchList])
      else
       userList = ConstituencyCategoryHandler.getActiveUsers(group["_id"], getUserOnSearchList)
       count = hd(getUserOnSearchList)["pageCount"]
       render(conn, "filterBasedOnNameList.json", [getNameBasedOnFilterList: userList, count: count])
      end
    end
  end


  # #get "groups/:group_id/constituency/userlist/get"
  # def getUserListOfConstituency(%Plug.Conn{params: params} = conn, %{"group_id" => group_id})  do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "constituency" do
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   else
  #     getUserList = ConstituencyCategoryHandler.getUserListOfConstituency(params)
  #     # IO.puts "#{getUserList}"
  #     render(conn, "constituencyUserList.json", [getConstituencyUserList: getUserList])
  #   end
  # end

  #post "users/specialname/insert"
  def addSpecialName(conn, _params) do
    list = ConstituencyCategoryHandler.getUserList()
    specialNameList = for name <- list do
      name = name
      |> Map.put("searchName", String.downcase(name["name"]))
      ConstituencyCategoryHandler.updateNames(name)
    end
    success = hd(specialNameList)
    case success do
    {:ok, _}  ->
      conn
      |> put_status(201)
      |> json(%{})
   end
  end


  #get "/groups/:group_id/constituency/booth/members/get"?page=1
  def getBoothMembersTeam(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      boothTeamList = ConstituencyCategoryHandler.getBoothMembersTeams(group["_id"], params)
      render(conn, "boothTeamList.json", [getBoothTeamList: boothTeamList, group: group])
    end
  end

  # get "/groups/:group_id/team/:team_id/constituency/booth/members"?page=1
  def getTeamUsersList(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    boothTeam = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      boothTeamUsersList = ConstituencyCategoryHandler.getTeamUsersList(group["_id"], teamObjectId, params)
      render(conn, "boothTeamMembersList.json", [getBoothTeamUsersList: boothTeamUsersList, groupObjectId: group["_id"], team: boothTeam, loginUser: loginUser])
    end
  end


  # get "/groups/:group_id/team/:team_id/constituency/booth/users?page=1"
  def getBoothTeamUsers(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      loginUserId = Guardian.Plug.current_resource(conn)
      teamObjectId = decode_object_id(team_id)
      boothTeamUsersList = if params["committeeId"] do
        ConstituencyCategoryHandler.getBoothTeamMembersCommitteeList(group["_id"], teamObjectId, params)
      else
        ConstituencyCategoryHandler.getBoothTeamMembersList(group["_id"], teamObjectId, params)
      end
      render(conn, "booth_team_members.json", [boothUsers: boothTeamUsersList, loginUserId: loginUserId["_id"], group: group, teamObjectId: teamObjectId, params: params ])
    end
  end
end
