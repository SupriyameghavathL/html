defmodule GruppieWeb.Api.V1.CommunityController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Handler.CommunityHandler
  alias GruppieWeb.Community
  alias GruppieWeb.Post
  alias GruppieWeb.Handler.ConstituencyHandler


  #auth to check user is in group or not
  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" } when  action not in [:getListBasedOnSearch]


  #Add members to community teams
  #post, /groups/:group_id/team/:team_id/user/add/community
  #Body_req: {
  #  "user" : ["nithiin,IN,99999999759", "nithiin,IN,9999999750"]
  #}
  def addMembersToBoothTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      userParams = params["user"]
      users = Enum.reduce(userParams, [], fn k, acc ->
        userList = String.split(k, ",")
        userName = Enum.at(userList, 0)
        userCountryCode = Enum.at(userList, 1)
        userPhone = Enum.at(userList, 2)
        relation = if length(userList) > 3 do
           Enum.at(userList, 3)
        else
          ""
        end
        user_params = %{ "name" => userName, "countryCode" => userCountryCode, "phone" => userPhone, "relation" => relation }
        acc ++ [user_params]
      end)
      #remove duplicate phone entered
      users = Enum.uniq_by(users, & &1["phone"])
      if team["category"] != "public" do
        Enum.reduce(users, [], fn user_params, _acc ->
          group = GroupRepo.get(group_id)
          changeset = Community.changeset_add_user_community(%Community{}, user_params)
          addMembersToCommunityTeam(conn, changeset, group, team)
        end)
      else
        Enum.reduce(users, [], fn user_params, _acc ->
          group = GroupRepo.get(group_id)
          changeset = Community.changeset_add_user_community(%Community{}, user_params)
          addMembersToPublicTeam(conn, changeset, group, team)
        end)
      end
    end
  end


  defp addMembersToPublicTeam(conn, changeset, group, team) do
    if changeset.valid? do
      # don't allow login user to add by himself
      loginUser = Guardian.Plug.current_resource(conn)
      if loginUser["phone"] != changeset.changes.phone do
        case ConstituencyHandler.addUserToSubBoothTeam(changeset.changes, group, team["_id"]) do
          {:ok, _insertedUser} ->
            UserRepo.lastUserForTeamUpdatedAt(team["_id"])
            conn
            |> put_status(200)
            |> json(%{})
          {:noIncrement, _} ->
            UserRepo.lastUserForTeamUpdatedAt(team["_id"])
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  defp addMembersToCommunityTeam(conn, changeset, group, team) do
    if changeset.valid? do
      case CommunityHandler.addUserToCommunityTeam(changeset.changes, group, team) do
        {:ok, _insertedUser} ->
          #update lastUserUpdatedAt time for team
          UserRepo.lastUserForTeamUpdatedAt(team["_id"])
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


  # post "/groups/:group_id/add/branches/community"
  def addBranchesToCommunity(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      changeset = Community.branchEditDetails(%Community{}, params)
      if changeset.valid? do
        case CommunityHandler.addBranches(group["_id"], changeset.changes) do
          {:ok, _success}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end

  #post "/groups/:group_id/branch/:branch_id/posts/add"
  def addPostToBranches(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      loginUser = Guardian.Plug.current_resource(conn)
      branchObjectId = decode_object_id(branch_id)
      changeset = Post.changeset(%Post{}, params)
      if changeset.valid? do
        case CommunityHandler.addPostToBranches(group["_id"], changeset.changes, loginUser["_id"], branchObjectId) do
          {:ok, _success}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end


  # put "/groups/:group_id/branch/:branch_id/edit"
  def editBranches(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      branchObjectId = decode_object_id(branch_id)
      changeset = Community.branchEditDetails(%Community{}, params)
      if changeset.valid? do
        case CommunityHandler.editBranches(group["_id"], branchObjectId, changeset.changes) do
          {:ok, _success}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end


  #put "/groups/:group_id/branch/:branch_id/delete"
  def deleteBranches(%Plug.Conn{ params: _params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      branchObjectId = decode_object_id(branch_id)
        case CommunityHandler.deleteBranches(group["_id"], branchObjectId) do
          {:ok, _success}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
    end
  end


  # get "/groups/:group_id/branch/:branch_id/posts/get"
  def getBranchPosts(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      branchObjectId = decode_object_id(branch_id)
      getBranchPostList = CommunityHandler.getBranchPosts(group["_id"], branchObjectId, params)
      render(conn, "branchPost.json", [getBranchPostList: getBranchPostList, group: group, loginUser: loginUser])
    end
  end


  #post "/groups/:group_id/user/add/community"
  def addUsersToDefaultTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      #get default Team Of Login User
      teamObjectId = CommunityHandler.getDefaultTeamId(group["_id"], loginUser["_id"])
      if teamObjectId do
        for userMap <- params["data"] do
          changeset = Community.changeset_add_user_community(%Community{}, userMap)
          team = TeamRepo.get(encode_object_id(teamObjectId["_id"]))
          group = GroupRepo.get(group_id)
          addMembersToCommunityTeam(conn, changeset, group, team)
        end
      else
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "No Authorized Team To Add"})
      end

    end
  end


  #post "/groups/:group_id/branch/:branch_id/admin/add"
  def addAdminToTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id}) do
    group = GroupRepo.get(group_id)
    branchObjectId = decode_object_id(branch_id)
    if group["category"] != "community" || group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      userIdsList = for adminMap <- params["adminList"] do
        changeset = Community.changeset_add_user_community(%Community{}, adminMap)
        if changeset.valid? do
          CommunityHandler.addAdminToUserAndTeamDoc(group["_id"], changeset.changes)
        else
          conn
          |> put_status(400)
          |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
        end
      end
      case CommunityHandler.addAdminToTeam(group["_id"], branchObjectId, userIdsList) do
        {:ok, _success}->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
    end
  end


  #put "/groups/:group_id/branch/:branch_id/user/:user_id/admin/delete"
  def deleteAdminFromTeam(%Plug.Conn{ params: _params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    branchObjectId = decode_object_id(branch_id)
    userObjectId = decode_object_id(user_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "community" || group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      if loginUser["_id"] == userObjectId do
        conn
        |> put_status(400)
        |> json(%JsonErrorResponse{code: 400, title: "System Error", message: "You Have No Authorization To Delete Self Contact Admin"})
      else
        case CommunityHandler.deleteAdminFromTeam(group["_id"], branchObjectId, userObjectId) do
          {:ok, _success}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
      end
    end
  end

  #get "/groups/:group_id/branch/:branch_id/admin/get"
  def getAdminFromTeam(%Plug.Conn{ query_params: _params } = conn, %{ "group_id" => group_id, "branch_id" => branch_id }) do
    group = GroupRepo.get(group_id)
    branchObjectId = decode_object_id(branch_id)
    if group["category"] != "community" || group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      adminList = CommunityHandler.getAdminFromTeam(group["_id"], branchObjectId)
      render(conn, "adminList.json", [getAdminList: adminList])
    end
  end


  #get "/search/filter"
  def getListBasedOnSearch(conn, params) do
    searchList = CommunityHandler.getListBasedOnSearch(params)
    render(conn, "searchList.json", [getSearchList: searchList])
  end


  #post "/groups/:group_id/community/id/append"
  def addCommunityIdNo(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "community" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      list = CommunityHandler.addCommunityIdNo(group["_id"], group["appName"])
      if is_list(list) do
        case hd(list) do
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
        |> put_status(200)
        |> json(%{})
      end
    end
  end


  #post "/groups/:group_id/admin/add"
  def makeAdminToApp(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] not in ["community", "constituency"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      userIdsList = for user <- params["data"] do
        changeset = Community.changeset_add_user_community(%Community{}, user)
        if changeset.valid? do
          CommunityHandler.makeAdminToApp(group["_id"], user, changeset.changes)
        else
          conn
          |> put_status(400)
          |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
        end
      end
      if is_list(userIdsList) do
        case hd(userIdsList) do
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
        |> put_status(200)
        |> json(%{})
      end
    end
  end


  #get "/groups/:group_id/admin/get"
  def getAppAdmins(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] not in ["community", "constituency"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      adminList = CommunityHandler.getAppAdmins(group["_id"])
      render(conn, "adminList.json", [getAdminList: adminList])
    end
  end


  #put "/groups/:group_id/user/:user_id/admin/delete"
  def deleteAppAdmin(conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] not in ["community", "constituency"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      userObjectId = decode_object_id(user_id)
      case CommunityHandler.deleteAppAdmin(group["_id"], userObjectId) do
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


  def addPublicTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] not in ["community", "constituency"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      changeset = Community.branchEditDetails(%Community{}, params)
      if changeset.valid? do
        case CommunityHandler.addPublicTeam(group["_id"], changeset.changes) do
          {:ok, _success}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _mongo_error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end
end
