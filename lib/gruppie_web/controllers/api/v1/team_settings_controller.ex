defmodule GruppieWeb.Api.V1.TeamSettingsController do
  use GruppieWeb, :controller
  alias GruppieWeb.Team
  alias GruppieWeb.Handler.TeamSettingsHandler
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.TeamSettingsRepo
  alias GruppieWeb.Repo.CommunityRepo
  alias GruppieWeb.Repo.ConstituencyRepo

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }
  #is team member auth
  plug GruppieWeb.Plugs.TeamAuth when action not in [:getArchiveTeam, :deleteTeam, :removeTeamUser, :teamDetailEdit, :archiveTeam, :restoreArchiveTeam]
  #check login user is team lead (team admin)
  plug GruppieWeb.Plugs.TeamAdminAuth, %{ "group_id" => "group_id", "team_id" => "team_id" } when action not in [:leaveTeam, :getArchiveTeam, :allowOrDisallowUserToAddTeamPost,
                                                                    :allowOrDisallowUserToAddTeamPostComment, :allowOrDisallowUserToAddUser, :deleteTeam, :removeTeamUser,
                                                                    :teamDetailEdit, :archiveTeam, :restoreArchiveTeam]


  #allow everyone to post in team
  #put "/groups/:group_id/team/:team_id/allow/post/all"
  def allowTeamPostAll(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.allowTeamPostAll(conn, group_id, team_id) do
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



  #allow everyone to put comment for team post
  #put "/groups/:group_id/team/:team_id/allow/comment/all"
  def allowTeamPostCommentAll(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.allowTeamPostCommentAll(conn, group_id, team_id) do
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


  #get team settings list
  #"/groups/:group_id/team/:team_id/settings"
  def teamSettings(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    teamSettingsList = TeamSettingsHandler.getTeamSettingList(group_id, team_id)
    data = %{
        "allowTeamPostAll" => teamSettingsList["allowTeamPostAll"],
        "allowTeamPostCommentAll" => teamSettingsList["allowTeamPostCommentAll"],
        "enableGps" => teamSettingsList["enableGps"],
        "enableAttendance" => teamSettingsList["enableAttendance"]
      }

    json conn, %{ data: data }
  end


  #remove team user
  #put "/groups/:group_id/team/:team_id/user/:user_id/remove"
  def removeTeamUser(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if loginUser["_id"] == decode_object_id(user_id) do
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Admin Cannot Be Deleted", message: "Admin Cannot Be Deleted"})
    else
      case TeamSettingsHandler.removeTeamUser(group, team_id, user_id) do
        {:ok, _}->
          if Map.has_key?(team, "boothTeamId") do
            # decrement user count in booth
            TeamSettingsRepo.decrementUserCount(group["_id"], team["boothTeamId"])
          else
            if team["category"] == "booth" do
              TeamSettingsRepo.decrementWorkersCount(group["_id"], team["_id"])
            end
          end
          cond do
            group["category"] == "constituency" ->
              if Map.has_key?(group, "feederMap") do
                TeamSettingsRepo.decrementTotalUserCount(group["_id"])
              end
            group["category"] == "community" ->
              if Map.has_key?(group, "feederMap") do
                CommunityRepo.decrementTotalUserCountCommunity(group)
              end
          end
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end

  end



  #leave team
  #put "/groups/:group_id/team/:team_id/leave"
  def leaveTeam(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.leaveTeam(conn, group_id, team_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #team detail edit
  #put "/groups/:group_id/team/:team_id/edit"
  def teamDetailEdit(%Plug.Conn{ body_params: team_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    changeset = Team.changeset_team_edit(%Team{}, team_params)
    if changeset.valid? do
      case TeamSettingsHandler.editTeam(conn, changeset.changes, group_id, team_id) do
        {:ok, _}->
          conn
          |> put_status(200)
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



  #delete team when no users
  #delete "/groups/:group_id/team/:team_id/delete"
  def deleteTeam(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    case TeamSettingsHandler.deleteTeam(conn, group_id, team_id) do
      {:ok, _}->
        cond do
          group["category"] == "constituency" ->
            if Map.has_key?(group, "feederMap") do
              if team["category"] == "booth" do
                #decrement booth count
                TeamSettingsRepo.decrementBoothCount(group["_id"])
                #updating zp time for events
                if Map.has_key?(team, "zpId") do
                  ConstituencyRepo.updateZp(team["zpId"])
                end
              else
                if team["category"] == "subBooth" do
                  TeamSettingsRepo.decrementSubBoothCount(group["_id"])
                end
              end
            end
          group["category"] == "community" ->
            if Map.has_key?(group, "feederMap") do
              CommunityRepo.decrementTotalTeamsCount(group)
            end
        end
        #check team is booth category and remove all subBooth
        conn
        |> put_status(200)
        |> json(%{})
      {:error1, message}->
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #archive team
  #put "/groups/:group_id/team/:team_id/archive"
  def archiveTeam(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.archiveTeam(group_id, team_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #get archived team list
  #get "/groups/:group_id/team/archive"
  def getArchiveTeam(conn, %{ "group_id" => group_id }) do
    getArchiveTeam = TeamSettingsHandler.getArchiveTeam(conn, group_id)
    render(conn, "archiveTeam.json", archiveTeam: getArchiveTeam)
  end


  #restore archive team
  #put "/groups/:group_id/team/:team_id/archive/restore"
  def restoreArchiveTeam(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.restoreArchiveTeam(group_id, team_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #enable gps setting
  #"/groups/:group_id/team/:team_id/gps/enable"
  def gpsEnable(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      case TeamSettingsHandler.gpsEnableOrDisable(group["_id"], team_id) do
        {:ok, success}->
          data = %{"gpsEnable" => success}
          json conn, %{ data: data }
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Given Url Not Found"})
    end
  end


  #enable gps setting
  #put"/groups/:group_id/team/:team_id/attendance/enable"
  def attendanceEnable(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      case TeamSettingsHandler.attendanceEnableOrDisable(group["_id"], team_id) do
        {:ok, success}->
          data = %{"attendanceEnable" => success}
          json conn, %{ data: data }
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Given Url Not Found"})
    end
  end


  #restrict users to add other users into the group
  #put"/groups/:group_id/team/:team_id/user/add/disallow"
  def disAllowUserToAddUser(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.findAndDisAllowUserToAddOtherUsers(conn, group_id, team_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow users to add other users into the group
  #put"/groups/:group_id/team/:team_id/user/add/allow"
  def allowUserToAddUser(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    case TeamSettingsHandler.findAndAllowUserToAddOtherUsers(conn, group_id, team_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow or disallow user to add other user to the group by team lead
  #put "/groups/:group_id/team/:team_id/user/:user_id/user/add/disallow"
  def allowOrDisallowUserToAddUser(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    case TeamSettingsHandler.findIndividuallyAndDisAllowUserToAddOtherUsers(group, team_id, user_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow or disallow user to add post in team individually
  #put "/groups/:group_id/team/:team_id/user/:user_id/team/post/allow"
  def allowOrDisallowUserToAddTeamPost(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    case TeamSettingsHandler.findIndividuallyAndAllowUserToAddTeamPost(group, team_id, user_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #allow or disallow user to add post in team individually
  #put "/groups/:group_id/team/:team_id/user/:user_id/team/comment/allow"
  def allowOrDisallowUserToAddTeamPostComment(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    case TeamSettingsHandler.findIndividuallyAndAllowUserToAddTeamPostComment(group, team_id, user_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #change admin
  #put "/groups/:group_id/team/:team_id/user/:user_id/change/admin"
  def changeTeamAdmin(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    case TeamSettingsHandler.changeTeamAdmin(conn, group_id, team_id, user_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



end
