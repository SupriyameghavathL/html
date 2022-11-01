defmodule GruppieWeb.Api.V1.ConstituencyController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  alias GruppieWeb.Handler.ConstituencyHandler
  alias GruppieWeb.Handler.ProfileHandler
  alias GruppieWeb.User
  alias GruppieWeb.Constituency
  alias GruppieWeb.Repo.UserRepo
  import GruppieWeb.Handler.TimeNow

  #auth to check user is in group or not
  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }
  #auth to check user can post in group or not
  plug GruppieWeb.Plugs.GroupPostAddAuth, %{ "group_id" => "group_id" } when action in [:addBoothsToConstituency, :getAllBoothTeams, :constituencyIssuesRegister,
                                                                      :deleteConstituencyIssueRegistered, :addVotersToTeamFromMasterList, :addBannerInConstituencyGroup]
  #check user already in team when adding from contact
  ####plug Gruppie.Plugs.TeamUserAlreadyExistContactAuth when action in [:addMembersToBoothTeam]


  #add booths to constituency by admin/authorized user
  #post "/groups/:group_id/constituency/booths/add"
  # {
  #   "boothName" : "Booth 456",
  #   "boothImage" : "boothImage.png",
  #   "category" : "booth",
  #   "boothPresidentName" : "test",
  #   "countryCode" : "IN",
  #   "phone" : "8596748596"
  # }
  def addBoothsToConstituency(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #create booth under booth president
    case ConstituencyHandler.addBoothsToConstituency(params, group, loginUser) do
      {:ok, success} ->
        #count and add booth count to this group/constituency
        # addBoothCounts = ConstituencyHandler.addBoothCountsInGroup(group["_id"])
        # text conn, addBoothCounts
        user = ConstituencyRepo.getUserIdAndImage(params["phone"])
        data = %{ "teamId" => success }
        teamChangeset = %{
          name: params["boothPresidentName"]<>" Team",
          image: params["boothImage"],
          category: "subBooth",
          insertedAt: bson_time(),
          updatedAt: bson_time(),
          boothTeamId: decode_object_id(success)
        }
        TeamRepo.createTeam(user, teamChangeset, group["_id"])
        json conn, %{ data: data }
      #{:changeset_error, changeset} ->
      #  conn
      #  |> put_status(400)
      #  |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #get booths list in booth register
  #get "/groups/:group_id/all/booths/get" ?type=masterList/finalList (For election voters list)
  def getAllBoothTeams(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    booths = if params["zpId"] do
      #getting booth based on zp
      zpObjectId = decode_object_id(params["zpId"])
      ConstituencyHandler.getAllBoothsTeamsBasedOnZp(group["_id"], zpObjectId)
    else
      ConstituencyHandler.getAllBoothsTeams(group["_id"])
    end
    #check type is coming in query_param
    if params["type"] do
      #get list for election master list/ final list
      render(conn, "all_booths_election_list.json", [booths: booths, groupObjectId: group["_id"]])
    else
      #text conn, Enum.to_list(booths)
      render(conn, "all_booths.json", [booths: booths, groupObjectId: group["_id"]])
    end
  end



  #add committees to booth teams (Other than default committee team)
  #post "/groups/:group_id/booth/team/:team_id/committee/add" ?committeeId=:committeeId   //to update existing committee details
  def addCommitteesToBoothTeam(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check committeeId coming from query_params
    #add new committee
    changeset = Constituency.changeset_add_booth_committees(%Constituency{}, params)
    if changeset.valid? do
      case ConstituencyHandler.addCommitteesToBoothTeam(group["_id"], team_id, changeset.changes, params) do
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



  #get list of committee for booth team
  #get "/groups/:group_id/booth/team/:team_id/committees/get"
  def getCommitteeListForBoothTeam(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #get list of committees for team booth
    committeesList = ConstituencyHandler.getCommitteeListForBoothTeam(group["_id"], team_id)
    render(conn, "booth_committees_list.json", [committeesList: committeesList])
  end



  #remove committee from booth team
  #put "/groups/:group_id/booth/team/:team_id/committee/remove?committeeId=:committeeId"
  def removeCommitteeFromBoothTeam(%Plug.Conn{query_params: query_params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if query_params["committeeId"] do
      teamObjectId = decode_object_id(team_id)
      committeeId = query_params["committeeId"]
      case ConstituencyRepo.removeCommitteeFromBoothTeam(group["_id"], teamObjectId, committeeId) do
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
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end




  #Add members to created booth/teams
  #post, /groups/:group_id/team/:team_id/user/add/booth ?category=booth/subBooth/constituency
  #Body_req: {
  #  "user" : ["nithiin,IN,99999999759", "nithiin,IN,9999999750,PP"]
  #}
  def addMembersToBoothTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    if group["category"] != "constituency" do
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
        roleOnConstituency = Enum.at(userList, 3)
        user_params = %{ "name" => userName, "countryCode" => userCountryCode, "phone" => userPhone, "roleOnConstituency" => roleOnConstituency }
        acc ++ [user_params]
      end)
      #remove duplicate phone entered
      users = Enum.uniq_by(users, & &1["phone"])
      if !is_nil(params["category"]) do
        Enum.reduce(users, [], fn user_params, _acc ->
          changeset = Constituency.changeset_add_booth_members(%Constituency{}, user_params)
          cond do
            params["category"] == "booth" ->
              addMembersToBoothTeam(conn, changeset, group, team)
            params["category"] == "subBooth" || params["category"] == "constituency" ->
              if team["category"] == "public" do
                addMembersToPublicTeam(conn, changeset, group, team)
              else
                addMembersToSubBoothTeam(conn, changeset, group, team)
              end
          end
        end)
      else
        #not found error
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    end
  end

  defp addMembersToBoothTeam(%Plug.Conn{ params: params } = conn, changeset, group, team) do
    if changeset.valid? do
      #pass query params map along with changeset, So merge two maps
      boothCommitteeMap = %{teamCategory: params["category"], dafaultCommittee: params["dafaultCommittee"], committeeId: params["committeeId"]}
      changesetMap = Map.merge(boothCommitteeMap, changeset.changes)
      # don't allow login user to add by himself
      loginUser = Guardian.Plug.current_resource(conn)
      if loginUser["phone"] != changesetMap["phone"] do
        case ConstituencyHandler.addUserToBoothTeam(changesetMap, group, team["_id"]) do
          {:ok, _insertedUser}->
            #incrementing userCount
            ConstituencyRepo.incrementUsers(group)
            # if team["category"] == "booth" do
            #   checkWorkerKeyExists = ConstituencyRepo.checkWorkerKey(group["_id"], team["_id"])
            #   if checkWorkerKeyExists do
            #     #key does not exists
            #     ConstituencyRepo.appendWorkersCount(group["_id"], team["_id"])
            #   else
            #     #key exits increment workers count in teams
            #     ConstituencyRepo.incrementWorkersCount(group["_id"], team["_id"])
            #   end
            # end
            #add user to voters Register (Voters List)
            #ConstituencyHandler.registerUserToVotersList(group["_id"], team_id, insertedUser)
            #update lastUserUpdatedAt time for team
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


  defp addMembersToSubBoothTeam(conn, changeset, group, team) do
    if changeset.valid? do
      # don't allow login user to add by himself
      loginUser = Guardian.Plug.current_resource(conn)
      if loginUser["phone"] != changeset.changes.phone do
        case ConstituencyHandler.addUserToSubBoothTeam(changeset.changes, group, team["_id"]) do
          {:ok, _insertedUser} ->
            ConstituencyRepo.incrementUsers(group)
            checkUserKeyExists = ConstituencyRepo.checkUserKey(group["_id"], team["boothTeamId"])
            if checkUserKeyExists do
              #key does not exists
              ConstituencyRepo.appendUsersCount(group["_id"], team["_id"], team["boothTeamId"])
            else
              #key exits increment users count in teams
              ConstituencyRepo.incrementUsersCount(group["_id"], team["boothTeamId"], team["_id"])
            end
            #add user to voters Register (Voters List)
            #ConstituencyHandler.registerUserToVotersList(group["_id"], team_id, insertedUser)
            #update lastUserUpdatedAt time for team
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



  #add coordinator to booths and same coordinator should get added to booth coordinator team along with MLA
  #post, /groups/:group_id/team/:team_id/coordinator/add/booth
  def addCoordinatorsToBoothTeam(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_add_booth_coordinator(%Constituency{}, params)
    if changeset.valid? do
      #add coordinator to booth team and also add coordinator and MLA to "Booth Coordinators" team
      case ConstituencyHandler.addCoordinatorsToBoothTeam(changeset.changes, group, team_id) do
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


  #get list of booth coordinators
  #get "/groups/:group_id/team/:team_id/booth/coordinator/get"
  def getListOfBoothCoordinators(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getBoothCoordinators = ConstituencyHandler.getListOfBoothCoordinators(group["_id"], team_id)
    render(conn, "booth_coordinators.json", [getBoothCoordinators: getBoothCoordinators])
  end


  #update booth member information
  #put "/groups/:group_id/team/:team_id/user/:user_id/update/booth/member"
  def updateBoothMemberInformation(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_update_booth_member(%Constituency{}, params)
    if changeset.valid? do
      loginUser = Guardian.Plug.current_resource(conn)
      #update user information to constituency app
      case ConstituencyHandler.updateBoothMemberInformation(changeset.changes, user_id, loginUser["_id"]) do
        {:ok, _updated}->
          #update lastUserUpdatedAt time for team
          UserRepo.lastUserForTeamUpdatedAt(decode_object_id(team_id))
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


  #get booth all members
  #/groups/:group_id/team/:team_id/booth/members ?committeeId=:committeeId //to filter based on committees
  def getBoothTeamMembers(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    #loginUser = Guardian.Plug.current_resource(conn)
    #groupObjectId = decode_object_id(group_id)
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    teamObjectId = decode_object_id(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    boothUsers = if params["committeeId"] do
     ConstituencyHandler.getBoothTeamMembersByCommitteeId(group["_id"], teamObjectId, params["committeeId"])
    else
      ConstituencyHandler.getBoothTeamMembers(group["_id"], teamObjectId)
    end
    #text conn, boothUsers
    render(conn, "booth_team_members.json", [boothUsers: boothUsers, loginUserId: loginUser["_id"], group: group])
  end


  #get user profile detail in constituency app
  #get "/groups/:group_id/user/:user_id/profile/get"
  def getConstituencyUserProfileDetail(conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #logged_in_user = Guardian.Plug.current_resource(conn)
    userObjectId = decode_object_id(user_id)
    userDetail = UserRepo.find_user_by_id(userObjectId)
    #get teamIDs of users
    teams = ConstituencyRepo.getTeamsIdUser(group["_id"], userObjectId)
    #get teamName
    teamNamesList = ConstituencyHandler.getTeamIdsName(group["_id"], teams)
    userDetail = Map.to_list(userDetail)
    userDetail = Enum.reduce(userDetail, %{}, fn {k, v}, acc ->
      if k not in ["_id", "password_hash", "image", "email", "searchName" ] do
        Map.put(acc, k, Recase.to_title(v))
      else
        Map.put(acc, k, v)
      end
    end)
    #text conn, logged_in_user
    render conn, "user_profile_detail.json", user: userDetail, teams: teamNamesList
  end


  #update profile for user in constituency group
  #get "/groups/:group_id/user/:user_id/profile/edit"
  def getConstituencyUserProfileEdit(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    user_changeset = User.changeset_user_update(%User{}, params)
    if user_changeset.valid? do
      userDetail = UserRepo.find_user_by_id(decode_object_id(user_id))
      case ProfileHandler.updateProfile(user_changeset, userDetail ) do
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
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: user_changeset.errors, status: 400 ])
    end
  end



  #add family member to constituency voters list
  #post, "/groups/:group_id/user/:user_id/register/family/voters"
  def addMyFamilyToConstituencyDb(%Plug.Conn{params: parameter} = conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "constituency" || user_id != encode_object_id(loginUser["_id"]) do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case ConstituencyHandler.addMyFamilyToConstituencyDb(group["_id"], user_id, parameter["familyMembers"], loginUser) do
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


  #get list of family voters added under userId
  #get "/groups/:group_id/user/:user_id/family/voters/get"
  def getFamilyRegisterList(conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    familyVotersList = ConstituencyHandler.getFamilyRegisterList(group["_id"], user_id)
    #text conn, familyVotersList
    render(conn, "family_voters_list.json", [familyVotersList: familyVotersList])
  end



  #get list of only my booths
  #get "/groups/:group_id/my/booth/teams"
  def getMyBoothTeams(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    myBoothTeams = ConstituencyHandler.getMyBoothTeams(conn, group["_id"])
    render(conn, "myBoothTeams.json", [myBoothTeams: myBoothTeams, groupObjectId: group["_id"]])
  end


  #get list of only my sub-booths
  #get "/groups/:group_id/my/subbooth/teams"
  def getMySubBoothTeams(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    mySubBoothTeams = ConstituencyHandler.getMySubBoothTeams(conn, group["_id"])
    render(conn, "mySubBoothTeams.json", [mySubBoothTeams: mySubBoothTeams, groupObjectId: group["_id"]])
  end


  #get list of teams under booth team workers
  #get "/groups/:group_id/team/:team_id/booth/members/teams" ?type=masterList/finalList //for election master list
  def getBoothMembersTeamList(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    boothTeam = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    #get booth members under sub booth teams list for selected booth/teams
    boothMembersTeams = ConstituencyHandler.getBoothMembersTeams(group["_id"], team_id)
    if params["type"] do
      #get list for election master list/ final list
      render(conn, "booth_workers_teams_election_list.json", [booths: boothMembersTeams, groupObjectId: group["_id"]])
    else
      #get booth members under sub booth teams list for selected booth/teams
      render(conn, "booth_workers_teams.json", [booths: boothMembersTeams, groupObjectId: group["_id"], team: boothTeam, loginUser: loginUser])
    end
    ##render(conn, "sub_booth_teams.json", [subBooths: boothMembersTeams, groupObjectId: group["_id"]])
  end


  #register issues only by admin/authorized user
  #post "/groups/:group_id/constituency/issues/register"
  def constituencyIssuesRegister(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_issues_register(%Constituency{}, params)
    if changeset.valid? do
      #register issues for constituency
      case ConstituencyHandler.constituencyIssuesRegister(changeset.changes, group["_id"]) do
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


  #get list of issues registered for constituency
  #get "/groups/:group_id/constituency/issues"
  def constituencyIssuesGet(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getConstituencyIssues = ConstituencyHandler.constituencyIssuesGet(group["_id"])
    render(conn, "constituency_issues.json", [constituencyIssues: getConstituencyIssues])
  end



  #register department user and party user to each constituency issues registered
  #post "/groups/:group_id/issue/:issue_id/department/user/add"
  def addDepartmentAndPartyUserToConstituencyIssues(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issue_id" => issue_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_department_party_user_add(%Constituency{}, params)
    if changeset.valid? do
      #add party user and department user to issues registered
      case ConstituencyHandler.addDepartmentAndPartyUserToConstituencyIssues(changeset.changes, group["_id"], issue_id) do
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


  #delete constituency_issue registered
  #put "/groups/:group_id/issue/:issue_id/delete"
  def deleteConstituencyIssueRegistered(conn, %{"group_id" => group_id, "issue_id" => issue_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case ConstituencyHandler.deleteConstituencyIssue(group["_id"], issue_id) do
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


  #get login user belongs to booths/subBooth teams to select which booth while adding issues ticket
  #get "/groups/group_id/booth/subbooth/teams"
  def getBoothOrSubBoothTeamForLoginUser(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #get booth and sub booth team for login user
    loginUser = Guardian.Plug.current_resource(conn)
    getBoothOrSubBoothTeams = ConstituencyHandler.getBoothOrSubBoothTeamsForLoginUser(loginUser["_id"], group["_id"])
    render(conn, "my_booth_subbooth_teams.json", [myBoothOrSubBoothTeams: getBoothOrSubBoothTeams])
  end



  #Select the issue and raise ticket on issue
  #post "/groups/:group_id/team/:booth_id/issue/:issue_id/ticket/add" ?userId=:userId //if worker is raising ticket on behalf of users then pass that userId
  def addTicketOnIssueOfConstituency(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "booth_id" => booth_id, "issue_id" => issue_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    userObjectId = if params["userId"] do
      decode_object_id(params["userId"])
    else
      loginUser = Guardian.Plug.current_resource(conn)
      loginUser["_id"]
    end
    #changeset to add/raise issue ticket
    changeset = Constituency.changeset_add_issue_ticket(%Constituency{}, params)
    if changeset.valid? do
      #add/raise ticket to issue
      case ConstituencyHandler.addTicketOnIssueOfConstituency(group["_id"], booth_id, issue_id, userObjectId, changeset.changes) do
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



  #get list of issues for not approved, approved, hold on role: admin, booth president, coordinator, public
  #get "/groups/:group_id/issues/tickets/get"?role=isDepartmentTaskForce/isPartyTaskForce/isBoothPresident/isAdmin/isBoothMember/isBoothCoordinator
                                            # &option=notApproved/approved/hold&page=1/2/3...
  def getConstituencyIssuesTickets(%Plug.Conn{query_params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    limit = 20 #result limit per page
    #check query_params role and option are coming
    if !is_nil(params["role"]) && !is_nil(params["option"]) && !is_nil(params["page"]) do
      #for role isBoothCoordinator
      if params["role"] == "isBoothCoordinator" do
        #get issues list for booth coordinator (private function)
        ##getBoothCoordinatorConstituencyIssuesTickets(conn, group["_id"], loginUser["_id"], params, limit)
      else
        if params["role"] == "isPartyTaskForce" do #one who 1st approves the issues from public and it will get escaleted to admin
          #is party person then option=notApproved/approved/denied (role=isPartyTaskForce)
          #get issues list belongs to this party person / taskforce (private function) (Same for both department and party person)
          getPartyTaskForceConstituencyIssuesTickets(conn, group["_id"], loginUser["_id"], params, limit)
        else
          if params["role"] == "isAdmin" do #2nd and final level approval from admin. Then escalate status: open to department task force
            #is admin to group then option=notApproved/approved/denied (role: isAdmin)
            #get all issues tickets based on status form admin
            getAdminConstituencyIssuesTickets(conn, group["_id"], params, limit)
          else
            if params["role"] == "isDepartmentTaskForce" do
              #is department person then option=open/overdue/closed/hold (role=isDepartmentTaskForce)
              #get issues list belongs to this department person / taskforce (private function)
              getDepartmentTaskForceConstituencyIssuesTickets(conn, group["_id"], loginUser["_id"], params, limit)
            else
              if params["role"] == "isBoothPresident" do
                #is booth president, so show list of issues raised under his booth/subBooths team
                #option=notApproved/approved/closed
                getBoothPresidentConstituencyIssueTickets(conn, group["_id"], loginUser["_id"], params, limit)
              else
                if params["role"] == "isBoothMember" do
                  #is booth member. So, only get issues under his team
                  #option=notApproved/approved/closed
                  getBoothMembersConstituencyIssueTickets(conn, group["_id"], loginUser["_id"], params, limit)
                else
                  #get issues list for public (private function)
                  getPublicUserConstituencyIssuesTickets(conn, group["_id"], loginUser["_id"], params, limit)
                end
              end
            end
          end
        end
      end
    else
      #for public not passing any role on query_param
      if is_nil(params["role"]) do
        #get issues list for public (private function)
        getPublicUserConstituencyIssuesTickets(conn, group["_id"], loginUser["_id"], params, limit)
      else
        conn
          |>put_status(400)
          |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "Params are missing"})
      end
    end
  end

  #get coordinator role side issues
  ##defp getBoothCoordinatorConstituencyIssuesTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get issues of only his booth teams and subBooth teams. So get list of all team Ids belongs to this boothCoordinator (booth and under subBooths)
    ##coordinatorTeamsIdArray = ConstituencyRepo.getTeamsListForBoothCoordinator(groupObjectId, loginUserId)
    ##getList = ConstituencyHandler.getConstituencyIssuesTickets(groupObjectId, coordinatorTeamsIdArray, params, pageLimit)
    ##render(conn, "get_issues_tickets_list.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, teamIds: coordinatorTeamsIdArray,
    ##                                              params: params, pageLimit: pageLimit])
  ##end

  #get party task force role side issues
  defp getPartyTaskForceConstituencyIssuesTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get issues list where he is allocated as party task force for the issue. So first get list of issues id where login user is party task force
    partyTaskForceIssuesId = ConstituencyRepo.getIssuesIdForPartyTaskForce(groupObjectId, loginUserId)
    getList = ConstituencyHandler.getConstituencyIssuesTicketsForPartyTaskForce(groupObjectId, partyTaskForceIssuesId, params, pageLimit)
    render(conn, "get_issues_tickets_list_party_taskforce.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, issueIds: partyTaskForceIssuesId,
                                                                  params: params, pageLimit: pageLimit])
  end

  #get party task force role side issues
  defp getAdminConstituencyIssuesTickets(conn, groupObjectId, params, pageLimit) do
    #get all issues list for group based on status/options selected
    getList = ConstituencyHandler.getConstituencyIssuesTicketsForAdmin(groupObjectId, params, pageLimit)
    render(conn, "get_issues_tickets_list_admin.json", [issuesTicketsList: getList, groupObjectId: groupObjectId,
                                                                  params: params, pageLimit: pageLimit])
  end

  #get department task force role side issues
  defp getDepartmentTaskForceConstituencyIssuesTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get issues list where he is allocated as department task force for the issue. So first get list of issues id where login user is department task force
    deptTaskForceIssuesId = ConstituencyRepo.getIssuesIdForDepartmentTaskForce(groupObjectId, loginUserId)
    getList = ConstituencyHandler.getConstituencyIssuesTicketsDepartmentTaskForce(groupObjectId, deptTaskForceIssuesId, params, pageLimit)
    render(conn, "get_issues_tickets_list_department_taskforce.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, issueIds: deptTaskForceIssuesId,
                                                            params: params, pageLimit: pageLimit])
  end

  #get booth president role side
  defp getBoothPresidentConstituencyIssueTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get issues of only his booth teams and subBooth teams. So get list of all team Ids belongs to this boothCoordinator (booth and under subBooths)
    boothPresidentTeamsIdArray = ConstituencyRepo.getTeamsListForBoothPresident(groupObjectId, loginUserId)
    getList = ConstituencyHandler.getConstituencyIssuesTicketsForBoothPresident(groupObjectId, boothPresidentTeamsIdArray, params, pageLimit)
    render(conn, "get_issues_tickets_list_booth_president.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, teamIds: boothPresidentTeamsIdArray,
                                                                  params: params, pageLimit: pageLimit])
  end

  #get booth member role side
  defp getBoothMembersConstituencyIssueTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get issues of only his booth teams and subBooth teams. So get list of all team Ids belongs to this boothCoordinator (booth and under subBooths)
    boothMembersTeamsIdArray = ConstituencyRepo.getTeamsListForBoothMembers(groupObjectId, loginUserId)
    getList = ConstituencyHandler.getConstituencyIssuesTicketsForBoothPresident(groupObjectId, boothMembersTeamsIdArray, params, pageLimit)
    render(conn, "get_issues_tickets_list_booth_president.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, teamIds: boothMembersTeamsIdArray,
                                                                  params: params, pageLimit: pageLimit])
  end

  #get public role side issue
  defp getPublicUserConstituencyIssuesTickets(conn, groupObjectId, loginUserId, params, pageLimit) do
    #get list of issues raised by login user if role is not defined (If role is not coming then user is public)
    getList = ConstituencyHandler.getConstituencyIssuesTicketsForPublic(groupObjectId, loginUserId, params, pageLimit)
    render(conn, "get_issues_tickets_list_public.json", [issuesTicketsList: getList, groupObjectId: groupObjectId, loginUserId: loginUserId,
                                                         params: params, pageLimit: pageLimit])
  end




  #get last event updatedAt time for issues tickets list for each role(isAdmin, isPartyTaskForce, isDepartmentTaskForce, isBoothPresident, isBoothMember, isPublic)
  #get "groups/:group_id/issues/tickets/events"?role=isDepartmentTaskForce/isPartyTaskForce/isBoothPresident/isAdmin/isBoothMember/isBoothCoordinator
                                            # &option=notApproved/approved/hold&page=1/2/3...
  def getEventListForConstituencyIssuesTickets(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    #check query_params role and option are coming
    if !is_nil(params["role"]) && !is_nil(params["option"]) do
      eventTimeAt = cond do
        params["role"] == "isPartyTaskForce" ->
          #is party person then option=notApproved/approved/denied (role=isPartyTaskForce)
          #get issues event last updated datetime to this party person / taskforce (private function) (Same for both department and party person)
          ConstituencyHandler.getPartyTaskForceConstituencyIssuesTicketsEvents(group["_id"], loginUser["_id"], params["option"])
        params["role"] == "isAdmin" ->
          #is admin to group then option=notApproved/approved/denied (role: isAdmin)
          #get all issues tickets based on status form admin
          ConstituencyHandler.getAdminConstituencyIssuesTicketsEvents(group["_id"],  params["option"])
        params["role"] == "isDepartmentTaskForce" ->
          #is department person then option=open/overdue/closed/hold (role=isDepartmentTaskForce)
          #get issues list belongs to this department person / taskforce (private function)
          ConstituencyHandler.getDepartmentTaskForceConstituencyIssuesTicketsEvents(group["_id"], loginUser["_id"], params["option"])
        params["role"] == "isBoothPresident" ->
          #is booth president, so show list of issues raised under his booth/subBooths team
          #option=notApproved/approved/closed
          ConstituencyHandler.getBoothPresidentConstituencyIssueTicketsEvents(group["_id"], loginUser["_id"], params["option"])
        params["role"] == "isBoothMember" ->
          #is booth member. So, only get issues under his team
          #option=notApproved/approved/closed
          ConstituencyHandler.getBoothMembersConstituencyIssueTicketsEvents(group["_id"], loginUser["_id"], params["option"])
        params["role"] == "isPublic" ->
          #get issues list for public (private function)
          ConstituencyHandler.getPublicUserConstituencyIssuesTicketsEvents(group["_id"], loginUser["_id"], params["option"])
      end
      #render view
      render(conn, "get_issues_tickets_list_event_at.json", [eventAt: eventTimeAt])
    else
      #get issues list for public (private function)
      eventTimeAt = ConstituencyHandler.getPublicUserConstituencyIssuesTicketsEvents(group["_id"], loginUser["_id"], params["option"])
      #render view
      render(conn, "get_issues_tickets_list_event_at.json", [eventAt: eventTimeAt])
    end
  end




  # #approve issues from coordinator
  # #put "/groups/:group_id/issue/post/:issuePost_id/approve?status=approved/denied/notApproved"
  # def changeStatusOfNotApprovedIssuesTickets123(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "constituency"  do
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   #check login user is boothCoordinator(to provide approve option to only him)
  #   loginUser = Guardian.Plug.current_resource(conn)
  #   {:ok, checkIsBoothCoordinator} = ConstituencyRepo.checkUserIsBoothCoordinator(loginUser["_id"], group["_id"])
  #   if checkIsBoothCoordinator > 0 do
  #     #is booth coordinator (provide option to approved/denied/notApproved)
  #     if !is_nil(params["status"]) do
  #       #allow
  #       case ConstituencyHandler.changeStatusOfNotApprovedIssuesTickets(group["_id"], issuePost_id, params["status"]) do
  #         {:ok, _success} ->
  #           conn
  #           |> put_status(200)
  #           |> json(%{})
  #         {:error, _error}->
  #           conn
  #           |> put_status(500)
  #           |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #       end
  #     else
  #       #not found error
  #       conn
  #       |>put_status(404)
  #       |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #     end
  #   else
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end


  #approve issues from party taskforce
  #put "/groups/:group_id/issue/post/:issuePost_id/approve?status=approved/denied/notApproved"
  def changeStatusOfNotApprovedIssuesTickets(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check login user is partyTaskForce(to provide approve option to only him)
    loginUser = Guardian.Plug.current_resource(conn)
    ##{:ok, checkIsBoothCoordinator} = ConstituencyRepo.checkUserIsBoothCoordinator(loginUser["_id"], group["_id"])
    {:ok, checkIsPartyTaskForce} = ConstituencyRepo.checkUserIsPartyPerson(loginUser["_id"], group["_id"])
    if checkIsPartyTaskForce > 0 do
      #is partyTaskForce (provide option to approved/denied/notApproved)
      if !is_nil(params["status"]) do
        #allow
        case ConstituencyHandler.changeStatusOfNotApprovedIssuesTicketsByPartyTaskForce(group["_id"], issuePost_id, params["status"]) do
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
        #not found error
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #approve issues from admin
  #put "/groups/:group_id/issue/post/:issuePost_id/admin/approve?status=approved/denied/notApproved"
  def changeStatusOfNotApprovedIssuesTicketsByAdmin(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check login user is admin(to provide approve option to only him)
    loginUser = Guardian.Plug.current_resource(conn)
    if loginUser["_id"] == group["adminId"] do
      #is partyTaskForce (provide option to approved/denied/notApproved)
      if !is_nil(params["status"]) do
        #allow
        case ConstituencyHandler.changeStatusOfNotApprovedIssuesTicketsByAdmin(group["_id"], issuePost_id, params["status"]) do
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
        #not found error
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #close/hold/open issues from department taskforce
  #put "/groups/:group_id/issue/post/:issuePost_id/taskforce/close?status=closed/hold/open"
  def closeOrHoldIssueOnOpenByDepartmentTaskForce(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check login user is departmenttaskForce(to provide approve option to only him)
    loginUser = Guardian.Plug.current_resource(conn)
    ####{:ok, checkIsDepartmentTaskForce} = ConstituencyRepo.checkUserIsDepartmentPerson(loginUser["_id"], group["_id"])
    checkIsDepartmentTaskForce = ConstituencyRepo.checkUserIsDepartmentPerson(loginUser["_id"], group["_id"])
    if checkIsDepartmentTaskForce > 0 do
      #is booth coordinator (provide option to approved/denied/notApproved)
      if !is_nil(params["status"]) do
        #allow
        case ConstituencyHandler.closeOrHoldStatusForOpenIssue(group["_id"], issuePost_id, params["status"]) do
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
        #not found error
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end



  #remove raised ticket from user
  #put "/groups/:group_id/issue/:issuePost_id/remove"
  def removeIssueAddedByLoginUser(conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    #issuePostObjectId = decode_object_id(issuePost_id)
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    #remove issue raised by login user
    case ConstituencyHandler.removeIssueAddedByLoginUser(loginUser["_id"], group["_id"], issuePost_id) do
      {:ok, _success} ->
        conn
        |> put_status(200)
        |> json(%{})
      {:not_found, _error}->
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #add comment to issue
  #post "/groups/:group_id/issue/post/:issuePost_id/comment/add"
  def addCommentToIssueTickets(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_comment_issue_ticket(%Constituency{}, params)
    if changeset.valid? do
      loginUser = Guardian.Plug.current_resource(conn)
      #add comment
      case ConstituencyHandler.addCommentToIssueTickets(group["_id"], loginUser["_id"], issuePost_id, changeset.changes) do
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



  #get comment list for issue tickets
  #get "/groups/:group_id/issue/post/:issuePost_id/comments/get"
  def getCommentsOnIssueTickets(conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    getComments = ConstituencyHandler.getCommentsOnIssueTickets(group["_id"], issuePost_id)
    render(conn, "get_issues_comments_list.json", [issuesCommentsList: getComments, loginUserId: loginUser["_id"]])
  end




  #remove comments added for issue tickets
  #put "/groups/:group_id/issue/post/:issuePost_id/comment/:comment_id/remove"
  def removeCommentAddedForIssueTicket(conn, %{"group_id" => group_id, "issuePost_id" => issuePost_id, "comment_id" => comment_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check comment added by login user
    loginUser = Guardian.Plug.current_resource(conn)
    issuePostObjectId = decode_object_id(issuePost_id)
    {:ok, checkCommentCreatedBy} = ConstituencyRepo.checkLoginUserAddedCommentForIssueTicket(issuePostObjectId, group["_id"], loginUser["_id"], comment_id)
    if checkCommentCreatedBy > 0 do
      #allow to remove
      case ConstituencyRepo.removeCommentAddedForIssueTicket(issuePostObjectId, group["_id"], comment_id) do
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
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #search user by name, phone and voterId
  #get "/groups/:group_id/user/search" ?filter=nishanth&filterType=name/phone/voterId
  def searchUserInGroup(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if params["filter"] do
      #get user by search name, phone, voterId
      getSearchUser = ConstituencyHandler.searchUserInGroup(group["_id"], params)
      render(conn, "search_user.json", [searchUser: getSearchUser])
    else
      #not found error
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "Filter Not Found"})
    end
  end




  ######################################### ELECTION CONTROLLER ##############################################
  #add voters from master election list to booth/subBooth or booth/street team accordingly
  #post "/groups/:group_id/team/:team_id/add/voters/masterlist"
  def addVotersToTeamFromMasterList(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Constituency.changeset_add_voters_master_list(%Constituency{}, params)
    if changeset.valid? do
      #add voters to constituency voters database
      case ConstituencyHandler.addVotersToTeamFromMasterList(changeset.changes, group, team_id) do
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



  #get list of voters as master list from constituency_voters_database
  #get "/groups/:group_id/team/:team_id/get/voters/masterlist"
  def getVotersFromMasterList(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #get voters list for street/subbooth
    getVotersMasterList = ConstituencyHandler.getVotersFromMasterList(group["_id"], team_id)
    render(conn, "get_voters_master_list.json", [votersMasterList: getVotersMasterList])
  end


  #remove voter from master list
  #put "/groups/:group_id/team/:team_id/voter/remove"?voterId=HFYF5464
  def removeVoterFromMasterList(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if !params["voterId"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #remove
    case ConstituencyRepo.removeVoterFromMasterList(group["_id"], decode_object_id(team_id), params["voterId"]) do
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


  #allocate voters to booth workers
  #put "/groups/:group_id/booth/worker/:user_id/voters/allocate?voterIds=id1,id2..." //here user_id is boothWorker user_id
  def allocateVotersToBoothWorkers(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if is_nil(params["voterIds"]) do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "Argument Missing"})
    end
    #allocate voterId under selected booth worker
    allocateVoter = ConstituencyHandler.allocateVotersToBoothWorkers(group["_id"], user_id, params["voterIds"])
    text conn, allocateVoter
  end



  #get admin feeder in home page
  #get "/groups/:group_id/constituency/feeder" ?role=isAdmin
  def getAdminFeederInConstituencyGroup(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    cond do
      group["category"] == "constituency" && params["role"] == "isAdmin"->
        checkFeederMapPresentInGroup(conn, group)
        getAdminFeederList = ConstituencyHandler.getAdminFeederInConstituencyGroup(group["_id"])
        render(conn, "get_admin_feeder_list.json", [adminFeederList: getAdminFeederList])
      group["category"] == "community" && params["role"] == "isAdmin" ->
        checkFeederMapPresentInGroupCommunity(conn, group)
        getAdminFeederList = ConstituencyHandler.getAdminFeederInConstituencyGroup(group["_id"])
        render(conn, "get_admin_feeder_list.json", [adminFeederList: getAdminFeederList])
      true ->
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  defp checkFeederMapPresentInGroup(_conn, group) do
    ConstituencyHandler.checkFeederMapPresentInGroup(group)
  end

  defp  checkFeederMapPresentInGroupCommunity(_conn, group) do
    ConstituencyHandler.checkFeederMapPresentInGroupCommunity(group)
  end


  #add banner image by MLA/Admin in constituency group
  #post "/groups/:group_id/banner/add"
  def addBannerInConstituencyGroup(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" || group["category"] == "community"  do
      changeset = Constituency.changeset_add_banner(%Constituency{}, params)
      if changeset.valid? do
        #update banner to groups_col
        case GroupRepo.updateConstituencyBannerToGroup(changeset.changes, group["_id"]) do
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
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get constituency group banner
  #get "/groups/:group_id/banner/get"
  def getConstituencyGroupBanner(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" || group["category"] == "community"  do
      groupBanner = %{
        "fileName" => group["bannerFile"],
        "fileType" => group["bannerFileType"],
        "updatedAt" => group["bannerUpdatedAt"]
      }
      render(conn, "get_constituency_group_banner.json", [groupBanner: groupBanner])
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #add user will vote for us or not status
  #post "/groups/:group_id/user/:user_id/voter/status"
  def addVoterStatus(conn, %{"group_id" => group_id, "user_id" => _user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "constituency"  do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    text conn, group
  end


end
