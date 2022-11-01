defmodule GruppieWeb.Api.V1.GroupController do
  use GruppieWeb, :controller
  alias GruppieWeb.Handler.GroupHandler
  # alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Group
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper




  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "id", "user_id" => "login_user_id" } when action in
  [:show, :getEventsListForGroup, :getLiveClassActionEventList, :getLiveTestExamActionEventList]



  #Group create
  #post "/groups"
  def create(conn, parameters) do
    changeset = Group.changeset_create(%Group{}, parameters)
    if changeset.valid? do
      case GroupHandler.insert(conn, changeset.changes) do
        {:ok, _created}->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
         |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #get all groups for login user
  #get "/groups?category=school"&appName=RPES/{if you pass app name then only get that appName category groups. Eg: RPES for RPES-JSPS, RPA-PUC, RPA-Degree}
  # Query_params: {category=school&appName=RPES/talukName=gpet/categoryName="DODDAGOUDAR FOUNDATION"}
  def index(conn, _params) do
    category = conn.query_params["category"]
    appName = conn.query_params["appName"]
    talukName = conn.query_params["talukName"]
    categoryName = conn.query_params["categoryName"]  #constituency category name
    groups = if is_nil(category) do
      #get all groups
      GroupHandler.getAll(conn);
    else
      #get only passed category groups
      GroupHandler.getCategoryGroups(conn, category, appName, talukName, categoryName);
    end
    render(conn, "groups.json", [ groups: groups, conn: conn ])
  end


  #show group details for the user
  #get "/groups/:id"
  def show(conn, %{ "id" => group_id }) do
    group = GroupRepo.get(group_id)
    render(conn, "group_show.json", [group: group, conn: conn])
  end


  #get list of actions on group for login user
  #get, "/groups/:id/events"
  def getEventsListForGroupSchool(%Plug.Conn{query_params: _query_params} = conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = group["_id"]
    cond do
      group["category"] == "school" ->
        #get list of action events for login user in school group
        getEventsList = GroupHandler.getEventsListForSchoolGroup(loginUser["_id"], groupObjectId)
        #chec eventList is not empty list
        if length(getEventsList) > 0 do
          render(conn, "group_events.json", [getEventsList: getEventsList, loginUserId: loginUser["_id"],
                                            group: group])
        else
          conn
          |> put_status(201)
          |> json(%{data: [%{}]})
        end
      true ->
        #get list of action events for login user in school group
        getEventsList = GroupHandler.getEventsListForSchoolGroup(loginUser["_id"], groupObjectId)
        #chec eventList is not empty list
        if length(getEventsList) > 0 do
          render(conn, "group_events.json", [getEventsList: getEventsList, loginUserId: loginUser["_id"], group: group])
        else
          conn
          |> put_status(201)
          |> json(%{data: [%{}]})
        end
    end
  end



  #get groups category list.    // for constituency app
  #get "/constituency/groups/category"?constituencyName="Namma Gundlupet"
  def getConstituencyGroupsCategory(%Plug.Conn{params: params} = conn, _params) do
    loginUser = Guardian.Plug.current_resource(conn)
    if params["constituencyName"] do
      #get constituency groups category list in dashboard for constituin app
      constituencyCategoryList = GroupHandler.getConstituencyGroupsCategoryList(loginUser["_id"], params["constituencyName"])
      render(conn, "getConstituencyGroupsCategory.json", [constituencyCategoryList: constituencyCategoryList])
    else
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Not Found"})
    end
  end


  #get all booths events for admin/MLA
  #get "/groups/:id/events/all/booths"
  def getEventListForConstituencyAllBooths(conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" do
      render(conn, "group_events_constituency_all_booth.json", [groupObjectId: group["_id"]])
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Not Found"})
    end
  end

  #get list of actions on group for login user
  #get, "/groups/:id/events/constituency"
  def getEventsListForGroupConstituency(%Plug.Conn{query_params: _query_params} = conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = group["_id"]
    cond do
      group["category"] == "constituency" ->
        render(conn, "group_events_constituency.json", [loginUserId: loginUser["_id"], group: group])
      group["category"] == "community" ->
        render(conn, "group_events_community.json", [loginUser: loginUser, group: group])
      true ->
        #get list of action events for login user in school group
        getEventsList = GroupHandler.getEventsListForSchoolGroup(loginUser["_id"], groupObjectId)
        #chec eventList is not empty list
        if length(getEventsList) > 0 do
          render(conn, "group_events.json", [getEventsList: getEventsList, loginUserId: loginUser["_id"], groupObjectId: groupObjectId])
        else
          conn
          |> put_status(201)
          |> json(%{data: [%{}]})
        end
    end
  end


  #get last team post updated time for teams
  #get "/groups/:id/team/:team_id/events/team/post"
  def getEventForTeamPost(conn, %{"id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" || group["category"] == "school" || group["category"] == "community" do
      loginUser = Guardian.Plug.current_resource(conn)
      render(conn, "team_post_events.json", [groupObjectId: group["_id"], teamObjectId: decode_object_id(team_id),
            loginUserId: loginUser["_id"]])
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Not Found"})
    end
  end


  #get last team user updated at time and if booth category team get last committee updated at time
  #get "/groups/:id/team/:team_id/events/team"
  def getEventForTeam(conn, %{"id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "constituency" || group["category"] == "school" || group["category"] == "community" do
      team = TeamRepo.get(team_id)
      # loginUser = Guardian.Plug.current_resource(conn)
      render(conn, "team_events.json", [groupObjectId: group["_id"], team: team])
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Not Found"})
    end
  end


  #get events for subBooth teams
  #get, "/groups/:id/team/:team_id/events/subbooth"
  def getEventListForConstituencySubBoothTeams(conn, %{"id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    # groupObjectId = group["_id"]
    if group["category"] == "constituency" do
      render(conn, "group_events_constituency_subbooth.json", [loginUserId: loginUser["_id"], groupObjectId: group["_id"], boothTeamId: team_id])
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Not Found"})
    end
  end


  #get events for my booth teams (For booth president if more than 1 booth)
  #get "/groups/:id/events/my/booths"
  def getEventListForConstituencyMyBoothTeams(conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    #groupObjectId = group["_id"]
    if group["category"] == "constituency" do
      render(conn, "group_events_constituency_my_booth.json", [loginUserId: loginUser["_id"], groupObjectId: group["_id"]])
    else
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Not Found"})
    end
  end


  #get events for my subBooth teams (For booth worker if more than 1 sub booth)
  #get "/groups/:id/events/my/subbooths"
  def getEventListForConstituencyMySubBoothTeams(conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    # groupObjectId = group["_id"]
    if group["category"] == "constituency" do
      render(conn, "group_events_constituency_my_subbooth.json", [loginUserId: loginUser["_id"], groupObjectId: group["_id"]])
    else
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Not Found"})
    end
  end



  #get live class event list for login user
  #get "/api/v1/live/class/events"
  def getLiveClassActionEventList(conn, %{"id" => group_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #get list of action events for login user
    getLiveClassEventsList = GroupHandler.getLiveClassEventsListForGroup(loginUser["_id"], groupObjectId)
    if length(getLiveClassEventsList) > 0 do
      render(conn, "group_live_class_events.json", [getLiveClassEventsList: getLiveClassEventsList, loginUserId: loginUser["_id"], groupObjectId: groupObjectId])
    else
      conn
        |> put_status(201)
        |> json(%{data: [%{}]})
    end
  end


  #get live class event list for login user
  #get "/api/v1/live/testexam/events"
  def getLiveTestExamActionEventList(conn, %{"id" => group_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #get list of action events for login user
    getLiveTestExamEventsList = GroupHandler.getLiveTestExamEventsListForGroup(loginUser["_id"], groupObjectId)
    if length(getLiveTestExamEventsList) > 0 do
      render(conn, "group_live_testexam_events.json", [getLiveTestExamEventsList: getLiveTestExamEventsList, loginUserId: loginUser["_id"], groupObjectId: groupObjectId])
    else
      conn
      |> put_status(201)
      |> json(%{data: [%{}]})
    end
  end


  #get list of taluks where MLA belongs to school group
  #get "/taluks"
  def getListOfTaluks(conn, _params) do
    loginUser = Guardian.Plug.current_resource(conn)
    #check login user role: "taluk" parameter is coming
    {:ok, checkRoleTaluk} = GroupRepo.checkLoginUserRoleTaluk(loginUser["_id"])
    if checkRoleTaluk > 0 do
      getTaluks = GroupHandler.getListOfTaluks(loginUser["_id"])
      render(conn, "getTalukList.json", [talukList: getTaluks, loginUser: loginUser])
    else
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Not Found"})
    end
  end

end
