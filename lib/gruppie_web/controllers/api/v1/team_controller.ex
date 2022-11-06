defmodule GruppieWeb.Api.V1.TeamController do
  use GruppieWeb, :controller
  alias GruppieWeb.Team
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.TeamHandler
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.CommunityRepo

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "id", "user_id" => "login_user_id" }
  #friend auth(provided friend id is my friend in group or not)
  #plug Gruppie.Plugs.GroupFriendAuth, %{ "group_id" => "id", "friend_id" => "friend_id" } when action in [:deleteFriend]

  #create team inside group
  #post "/groups/:id/team/create"
  def createTeam(%Plug.Conn{ body_params: team_params } = conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    changeset = Team.changeset(%Team{}, team_params)
    if changeset.valid? do
      changesetChange = Map.put_new(changeset.changes, :category, group["category"])
      case TeamHandler.createTeam(conn, changesetChange, group_id) do
         {:ok, success} ->
          if group["category"] == "community" do
            CommunityRepo.incrementTotalTeamsCount(group)
          end
           data = %{ "teamId" => success }
           json conn, %{ data: data }
         {:error, _error}->
           conn
           |>put_status(500)
           |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #group index page where list of group and teams
  #get "/groups/:id/teams"
  def teams(conn, %{"id" => group_id}) do
   # if group_id == "5f06cca74e51ba15f5167b86" do
   #   conn
   #   |>put_status(426)
   #   |>json %JsonErrorResponse{code: 426, title: "Update Available: Please update app from Play Store", message: "Update Available"}
   # else
      loginUser = Guardian.Plug.current_resource(conn)
      group = GroupRepo.get(group_id)
      teams = TeamHandler.get_teams(loginUser, group)
      ##render(conn, "team_index.json", [teams: teams, loginUser: loginUser, group: group])
      render(conn, "team_index_new.json", [teams: teams, loginUser: loginUser, group: group])
   # end
  end


  #group index page where list of group and teams
  #get "/groups/:id/home"
  def groupHomePage(conn, %{"id" => group_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(group_id)
    teams = TeamHandler.get_teams(loginUser, group)
    render(conn, "group_home.json", [teams: teams, loginUser: loginUser, group: group])
  end


  #video conference teams
  #get "/groups/:id/class/video/conference"
  def videoConferenceTeams(conn, %{"id" => group_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(group_id)
    teams = TeamHandler.get_video_conference_teams(loginUser, group["_id"])
    render(conn, "video_conference_teams.json", [teams: teams, loginUser: loginUser, group: group])
  end


  #register zoom secret keys/sdk keys in groupId
  #post "/groups/:id/zoom/token/add"
  #{
  #  "name" : "RPA-PUC-1",
  #  "zoomId" : "RPA1",
  #  "zoomKey": "NezBAck80EPh2KCsJ5RiynKm20dznUI2lVIk",
  #  "zoomSecret" : "IXvTUJTYKplPT7KNZWhpOAQO328fR6OwEeAB"
  #}
  def addZoomMeetingToken(%Plug.Conn{ body_params: zoom_params } = conn, %{"id" => group_id}) do
    group = GroupRepo.get(group_id)
    #add params like zoomKey, zoomSecret
    case TeamHandler.addZoomToken(zoom_params, group["_id"]) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #get only my teams list
  #get "/groups/:group_id/my/teams"
  def myTeams(conn, %{ "id" => group_id }) do
    groupObjectId = decode_object_id(group_id)
    myTeam = TeamHandler.getMyTeams(conn, groupObjectId)
    render(conn, "myTeams.json", [myTeam: myTeam, groupId: groupObjectId])
  end


  #get class teams for login user as a admin / teacher who can post
  #get "/groups/:group_id/my/class/teams"
  def myClassTeams(conn, %{ "id" => group_id }) do
    groupObjectId = decode_object_id(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    myClassTeam = TeamHandler.getMyClassTeams(loginUser["_id"], groupObjectId)
    #text conn, myClassTeam
    render(conn, "myClassTeams.json", [myClassTeam: myClassTeam, groupObjectId: groupObjectId])
  end


  #get kids list for parent
  #get "/groups/:group_id/my/kids"
  def myKids123(conn, %{ "id" => group_id }) do
    groupObjectId = decode_object_id(group_id)
    myKids = TeamHandler.getMyKids(conn, groupObjectId)
    #text conn, myKids
    render(conn, "myKids.json", [myKids: myKids, groupObjectId: groupObjectId])
  end


  #get kids list for parent
  #get "/groups/:group_id/my/kids"
  def myKids(conn, %{ "id" => group_id }) do
    groupObjectId = decode_object_id(group_id)
    myKidsClass = TeamHandler.getMyKids(conn, groupObjectId)
    render(conn, "myKidsClass.json", [myKidsClass: myKidsClass])
  end
end
