defmodule GruppieWeb.Api.V1.TeamPostController do
  use GruppieWeb, :controller
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.TeamPostRepo
  alias GruppieWeb.Repo.NotificationRepo
  alias GruppieWeb.Post
  alias GruppieWeb.SchoolFees
  alias GruppieWeb.Handler.TeamHandler
  alias GruppieWeb.Handler.TeamPostHandler
  alias GruppieWeb.Handler.MessageHandler
  alias GruppieWeb.Handler.GroupHandler
  alias GruppieWeb.Handler.NotificationHandler
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.User
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Handler.SmsHandler

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }
  plug GruppieWeb.Plugs.TeamAuth when  action not in [:getTimeTable, :deleteTimeTable,
  :getAttendancePreschool, :studentOut, :studentIn, :sendMessageToAbsenties,
  :addMarksCard, :getMarksCard, :getTeamUsers, :index, :getNestedTeams, :getAttendance,
  :getClassSubjects, :createMarksCard, :addMarksToStudent, :getMarksCardList, :getStudentsToUploadMarks,
  :getMarksCardForStudent, :removeUploadedMarksForStudent, :getTeacherClassTeams, :create, :addSubjectsWithStaff,
  :removeSubjectWithStaff, :updateStaffToSubject, :createFeeForClass, :getFeeForClass, :getFeeStatusList, :approveOrHoldFeePaidByStudent,
  :updateDueDateCheckBoxForStudent, :updateIndividualStudentFeeStructure, :getIndividualStudentFee, :addYearTimeTable, :addYearTimeTableWithStaffAndSubject,
  :removeYearTimeTable, :getYearTimeTable]
  #check login user is team lead (team admin)
  plug GruppieWeb.Plugs.TeamAdminAuth, %{ "group_id" => "group_id", "team_id" => "team_id" } when action in
  [:addMembersToTeam, :addMembersToTeamFromContact, :tripStart ]
  #check user already in team
  plug GruppieWeb.Plugs.TeamUserAlreadyExistAuth when action in [:addMembersToTeam]
  #check user already in team when adding from contact
  plug GruppieWeb.Plugs.TeamUserAlreadyExistContactAuth when action in [:addMembersToTeamFromContact]
  #add team post add auth check
  plug GruppieWeb.Plugs.TeamPostAddAuth when action in [:startJitsiLive, :startLiveClass, :stopJitsiLive, :endLiveClass, :addAssignment, :addTimeTable,
                                                     :verifyStudentSubmittedAssignment, :deleteAssignment, :getOnlineAttendanceReport]
                                                     #auth to check user can post in group or not
  plug GruppieWeb.Plugs.GroupPostAddAuth, %{ "group_id" => "group_id" } when action in [:getFeeStatusList, :approveOrHoldFeePaidByStudent, :getFeeForClass,
                                                                                     :createFeeForClass, :updateDueDateCheckBoxForStudent, :updateIndividualStudentFeeStructure]


  #Add members to created teams by admin manually
  #/groups/:group_id/team/:team_id/user/add (Not Using)
  def addMembersToTeam(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    changeset = User.changeset_add_friend(%User{}, user_params)
    addFriendToTeam(conn, changeset, group, team_id)
  end


  #Add members to created teams from contact (Not Using)
  #/groups/:group_id/team/:team_id/user/add/contact?user[]=nithiin,IN,9999999999&user[]=nithiin,IN,9999999998
  def addMembersToTeamFromContact(%Plug.Conn{ query_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    userParams = user_params["user"]
    Enum.reduce(userParams, [], fn k, _acc ->
      userList = String.split(k, ",")
      userName = Enum.at(userList, 0)
      userCountryCode = Enum.at(userList, 1)
      userPhone = Enum.at(userList, 2)
      user_params = %{ "name" => userName, "countryCode" => userCountryCode, "phone" => userPhone }
      changeset = User.changeset_add_friend(%User{}, user_params)
      addFriendToTeam(conn, changeset, group, team_id)
    end)
  end



   #post "/groups/{group_id}/team/{team_id}/school/user/add?userId=1,2...&role=staff/student&teamId if student"
   def addSchoolUserToTeam(%Plug.Conn{ query_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    userIds = String.split(user_params["userId"], ",")
    Enum.reduce(userIds, [], fn k, _acc ->
      user = UserRepo.find_user_by_id(decode_object_id(k))
      #text conn, user
      #add user to team
      if Map.has_key?(user_params, "role") do
        cond do
          user_params["role"] == "student" && user_params["teamId"] ->
            case TeamHandler.addSchoolUserToTeam(group["_id"], team_id, user) do
              {:ok, _created}->
                TeamHandler.addStudentToNewTeam(group["_id"], team_id, user_params["teamId"], user["_id"])
                #update lastUserUpdatedAt time for team
                UserRepo.lastUserForTeamUpdatedAt(decode_object_id(team_id))
                conn
                |> put_status(200)
                |> json(%{})
              {:alreadyUserError, message} ->
                conn
                |> put_status(400)
                |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
              {:error, _error}->
                conn
                |> put_status(500)
                |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          user_params["role"] == "staff" ->
            case TeamHandler.addSchoolStaffToTeam(group["_id"], team_id, user) do
              {:ok, _created}->
                #update lastUserUpdatedAt time for team
                UserRepo.lastUserForTeamUpdatedAt(decode_object_id(team_id))
                conn
                |> put_status(200)
                |> json(%{})
              {:alreadyUserError, message} ->
                conn
                |> put_status(400)
                |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
              {:error, _error}->
                conn
                |> put_status(500)
                |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          user_params["role"] == "student" ->
            conn
            |> put_status(400)
            |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "teamId not passed"})
        end
      else
        conn
        |> put_status(400)
        |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "Role Not Passed"})
      end
    end)
  end


  #get team users list
  #/groups/:group_id/team/:team_id/users
  def getTeamUsers(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    teamUsers = if !is_nil(params["page"]) do
      #pagination
      TeamHandler.getTeamUsersPagination(loginUser["_id"], groupObjectId, teamObjectId, params["page"])
    else
      TeamHandler.getTeamUsers(loginUser["_id"], groupObjectId, teamObjectId)
    end
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      render(conn, "school_team_users.json", [teamUsers: teamUsers, loginUserId: loginUser["_id"], groupId: groupObjectId, teamId: teamObjectId])
    else
      render(conn, "team_users.json", [teamUsers: teamUsers, loginUserId: loginUser["_id"], groupId: groupObjectId, teamId: teamObjectId, params: params])
    end
  end


  defp addFriendToTeam(conn, changeset, group, team_id) do
    if changeset.valid? do
      case TeamHandler.addUserToTeamManually(changeset.changes, group, team_id) do
        {:ok, _created}->
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
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #add team post
  #post "/groups/:group_id/team/:team_id/posts/add"
  def create(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    team = TeamRepo.get(team_id)
    group = GroupRepo.get(group_id)
    changeset = Post.changeset(%Post{}, params)
    if changeset.valid? do
      case TeamPostHandler.add(changeset.changes, conn, group_id, team["_id"]) do
        {:ok, created}->
          #check team is subbooth or booth
          if Map.has_key?(team, "category") do
            if  team["category"] == "booth"  do
              TeamPostRepo.incrementBoothDiscussionCount(group["_id"])
            else
              if  team["category"] == "subBooth" do
                TeamPostRepo.incrementSubBoothDiscussionCount(group["_id"])
              end
            end
          end
          #add teamPost event for school
          GroupHandler.addTeamPostEvent(created.inserted_id, group_id, team_id)
          #add notification
          NotificationHandler.teamPostNotification(conn, group_id, team, created.inserted_id)
          conn
          |> put_status(200)
          |> json(%{data: [%{"postId" => encode_object_id(created.inserted_id)}]})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #update jitsi token and live going time only by team admin or canPost=true
  #put "/groups/:group_id/team/:team_id/jitsi/start"
  def startJitsiLive(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    team = TeamRepo.get(team_id)
    #add meetingId on live to get attendance for this meeting
    meetingIdOnLive = new_object_id()
    # update jitsi token and update jitsi live start time in teams col
    TeamPostHandler.updateJitsiTokenStartOrStop(loginUser, group, team, "start", meetingIdOnLive)
    render(conn, "jitsi_token_start.json", [ jitsiToken: team["zoomMeetingId"], className: team["name"], meetingIdOnLive: encode_object_id(meetingIdOnLive) ] )
  end


  #update jitsi token and live going time only by team admin or canPost=true
  #post "/groups/:group_id/team/:team_id/live/start"
  def startLiveClass(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(group_id)
    #if group["category"] != "school" do
    #  #not found error
    #  conn
    #  |>put_status(404)
    #  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    #end
    team = TeamRepo.get(team_id)
    #add meetingId on live to get attendance for this meeting
    meetingIdOnLive = new_object_id()
    # update live class started event to team and create meetingIdOnLive to capture attendance
    case TeamPostHandler.updateMeetingOnLiveIdOnStart(loginUser, group["_id"], team["_id"], meetingIdOnLive) do
      {:ok, _started}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #student join to meeting (For online attendance)
  #put "/groups/:group_id/team/:team_id/jitsi/join"
  def joinJitsiLive(%Plug.Conn{params: _params} = conn, %{"group_id" => _group_id, "team_id" => _team_id}) do
    ##loginUser = Guardian.Plug.current_resource(conn)
    ##group = GroupRepo.get(group_id)
    ##if group["category"] != "school" || !params["meetingOnLiveId"] do
      #not found error
    ##  conn
    ##  |>put_status(404)
    ##  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    ##end
    #check login user is in student register
    ##studentFromDb = TeamPostRepo.getStudentDbDetailById(group["_id"], decode_object_id(team_id), loginUser["_id"])
    ##if studentFromDb do
      #it is a student, so add to online attendance collection
    ##  case TeamPostHandler.addStudentOnlineAttendance(studentFromDb, params) do
    ##    {:ok, started}->
    ##      conn
    ##      |> put_status(200)
    ##      |> json(%{})
    ##    {:error, error}->
    ##      conn
    ##      |> put_status(500)
    ##      |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    ##  end
    ##else
      #not found error
    ##  conn
    ##  |>put_status(404)
    ##  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    ##end
    conn
    |> put_status(200)
    |> json(%{})
  end


  #student join to meeting (For online attendance)
  #put "/groups/:group_id/team/:team_id/live/join"
  def joinLiveClass(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    group = GroupRepo.get(group_id)
    if group["category"] != "school" || !params["meetingOnLiveId"] do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check login user is in student register
    studentFromDb = TeamPostRepo.getStudentDbDetailById(group["_id"], decode_object_id(team_id), loginUser["_id"])
    if studentFromDb do
      #it is a student, so add to online attendance collection
      case TeamPostHandler.addStudentLiveClassAttendance(studentFromDb, params) do
        {:ok, _started}->
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



  #update jitsi token and live going time only by team admin or canPost=true
  #put "/groups/:group_id/team/:team_id/jitsi/stop"
  def stopJitsiLive(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check params containing meetingOnLiveId and subjectId
  ##  if !params["meetingOnLiveId"] || !params["subjectId"] do
  ##    #not found error
  ##    conn
  ##    |>put_status(404)
  ##    |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  ##  end
    #check if login user has created/hosted the jitsi meeting
    loginUser = Guardian.Plug.current_resource(conn)
    team = TeamRepo.get(team_id)
    {:ok, checkLoginUserCreatedJitsi} = TeamPostRepo.checkLoginUserCreatedJitsiMeeting(loginUser["_id"], group["_id"], team["_id"])
    #IO.puts "#{checkLoginUserCreatedJitsi}"
    if checkLoginUserCreatedJitsi > 0 do
      # update jitsi token and update jitsi live start time in teams col
      TeamPostHandler.updateJitsiTokenStartOrStop(loginUser, group, team, "stop", params)
      render(conn, "jitsi_token_start.json", [ jitsiToken: team["zoomMeetingId"], className: team["name"], meetingIdOnLive: params["meetingIdOnLive"] ] )
    else
      conn
      |> put_status(200)
      |> json(%{})
    end
  end



  #remove liveClass event and submit attendance on meeting END
  #put "/groups/:group_id/team/:team_id/live/end"
  def endLiveClass(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    #if group["category"] != "school" do
    #  #not found error
    #  conn
    #  |>put_status(404)
    #  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    #end
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(team_id)
    {:ok, checkLoginUserCreatedLiveClass} = TeamPostRepo.checkLoginUserCreatedLiveMeeting(loginUser["_id"], group["_id"], teamObjectId)
    if checkLoginUserCreatedLiveClass > 0 do
      #first get list of students from online_attendance and remove liveClass event for this team/class
      case TeamPostHandler.liveClassEnd(loginUser["_id"], group["_id"], teamObjectId, params) do
        {:ok, _success}->
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
      |> put_status(200)
      |> json(%{})
    end
  end


  #add online attendance for this class to firebase and send data to server
  #post "/groups/:group_id/team/:team_id/online/attendance/push"
  # def pushOnlineAttendance(%Plug.Conn{ body_params: params } = conn, %{"group_id" => group_id, "team_id" => team_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "school" do
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   #online attendance push changeset
  #   changeset = OnlineAttendance.changeset_online_attendance(%OnlineAttendance{}, params)
  #   if changeset.valid? do
  #     #push online attendance to collections
  #     case TeamPostHandler.pushOnlineAttendance(changeset.changes, group["_id"], team_id) do
  #       {:ok, _}->
  #         conn
  #         |> put_status(201)
  #         |> json(%{})
  #       {:error, error}->
  #         conn
  #         |>put_status(500)
  #         |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #   end
  # end




  #get live attendance report only for admin/teacher on monthly basis
  #get "/groups/:group_id/team/:team_id/online/attendance/report"?month=1/2..12
  def getOnlineAttendanceReport(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" || is_nil(params["month"]) do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    month = params["month"]
    #text conn, group
    getOnlineAttendanceReport = TeamPostHandler.getOnlineAttendanceReport(group["_id"], team_id, month)
    #text conn, getOnlineAttendanceReport
    render(conn, "get_online_attendance_report.json", [getOnlineAttendanceReport: getOnlineAttendanceReport])
  end




  #get all posts of team
  #get "/groups/:group_id/team/:team_id/posts/get"
  def index(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
   # if group_id == "5f06cca74e51ba15f5167b86" do
   #   conn
   #   |>put_status(426)
   #   |>json %JsonErrorResponse{code: 426, title: "Update Available: Please update app from Play Store", message: "Update Available"}
   # else
      group = GroupRepo.get(group_id)
      team = TeamRepo.get(team_id)
      posts = TeamPostHandler.getAll(conn, group_id, team_id, pageLimit = 15)
      render(conn, "posts.json", [ posts: posts, group: group, team: team, conn: conn, limit: pageLimit ] )
   # end
  end




  #team post delete
  #PUT"/groups/:group_id/team/:team_id/post/:post_id/delete"
  def deleteTeamPost(conn, %{ "group_id" => group_id, "team_id" => team_id, "post_id" => post_id }) do
    team = TeamRepo.get(team_id)
    group = GroupRepo.get(group_id)
    case TeamPostHandler.deleteTeamPost(conn, group, team_id, post_id) do
      {:ok, _}->
        TeamPostRepo.updateTeamPostEvent(group["_id"])
        if Map.has_key?(team, "category") do
          if  team["category"] == "booth"  do
            TeamPostRepo.decrementBoothDiscussionCount(group["_id"])
          else
            if  team["category"] == "subBooth" do
              TeamPostRepo.decrementSubBoothDiscussionCount(group["_id"])
            end
          end
        end
        #add teamPost event
        GroupHandler.addTeamPostEvent("", group_id, team_id)
        #delete notification
        NotificationHandler.removeNotificationFromTeam(post_id)
        conn
        |> put_status(200)
        |> json(%{})
      {:changeset_error, message}->
        conn
        |>put_status(403)
        |>json(%JsonErrorResponse{code: 403, title: "Forbidden", message: message})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #driver trip start
  #post"/groups/:group_id/team/:team_id/trip/start?lat=23.123456&long=72.2345678"
  def tripStart(%Plug.Conn{ query_params: loc_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    if group["category"] == "school" && team["enableGps"] == true do
      case TeamPostHandler.startTrip(conn, loc_params, group["_id"], team) do
        {:ok, _started}->
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
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Given Url Not Found"})
    end
  end


  #end trip
  #DELETE "/groups/:group_id/team/:team_id/trip/end"
  def tripEnd(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    if group["category"] == "school" && team["enableGps"] == true do
      case TeamPostHandler.endTrip(conn, group["_id"], team) do
        {:ok, _}->
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
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Given Url Not Found"})
    end
  end



  #get trip location
  #get"/groups/:group_id/team/:team_id/trip/get"
  def getTripLocation(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    getTripLocation = TeamPostHandler.getTripLocation(group_id, team_id)
    if length(getTripLocation) > 0 do
      getLocation = hd(getTripLocation)
      data = %{
        "latitude" => getLocation["latitude"],
        "longitude" => getLocation["longitude"],
        "tripStartedAt" => getLocation["insertedAt"]
      }
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "Bad Request"})
    end
  end




  #get attendance list
  #"/groups/:group_id/team/:team_id/attendance/get"
  def getAttendance(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    #get Attendance list
    attendanceList = TeamHandler.getAttendanceList(conn, group_id, team_id)
    render(conn, "attendance.json", [ attendance: attendanceList, groupObjectId: decode_object_id(group_id), teamObjectId: decode_object_id(team_id) ] )
  end


  #get attendance list
  #"/groups/:group_id/team/:team_id/attendance/get/preschool"
  def getAttendancePreschool(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    currentTime = bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                     "minute" => datetime.minute,"seconds" => datetime.second}
    #get Attendance list
    attendanceList = TeamHandler.getAttendanceList(conn, group_id, team_id)
    render(conn, "attendancePreschool.json", [ attendance: attendanceList, dateTimeMap: dateTimeMap ] )
  end


  #send notification to get in kid
  #post "/groups/:group_id/team/:team_id/student/in?userId=id,rollNumber"
  def studentIn(%Plug.Conn{ query_params: user_ids } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" && team["category"] == "preschool" do
    #  if group["adminId"] == loginUser["_id"] || team["adminId"] == loginUser["_id"] do
        userParams = user_ids["userId"]
        if !is_nil(userParams) do
          #student IN/OUT attendance format
          userParameter = String.split(userParams, ",")
          userObjectId = decode_object_id(Enum.at(userParameter, 0))
          rollNumber = Enum.at(userParameter, 1)
          case TeamHandler.addStudentIn(group["_id"], team["_id"], userObjectId, rollNumber) do
            {:ok, _created}->
              #add notification
              NotificationHandler.studentINNotification(loginUser["_id"], group["_id"], team["_id"], userObjectId, rollNumber)
              #get device token for this user_id
              getDeviceToken = MessageHandler.getDeviceToken(userObjectId, group["_id"])
              render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: userObjectId, loginUser: loginUser["_id"]] )
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
          |>put_status(404)
          |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
        end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #send notification to get out kid
  #post "/groups/:group_id/team/:team_id/student/out?userId=id,rollNumber"
  def studentOut(%Plug.Conn{ query_params: user_ids } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" && team["category"] == "preschool" do
    #  if group["adminId"] == loginUser["_id"] || team["adminId"] == loginUser["_id"] do
        userParams = user_ids["userId"]
        if !is_nil(userParams) do
          #student IN/OUT attendance format
          userParameter = String.split(userParams, ",")
          userObjectId = decode_object_id(Enum.at(userParameter, 0))
          rollNumber = Enum.at(userParameter, 1)
          case TeamHandler.addStudentOut(group["_id"], team["_id"], userObjectId, rollNumber) do
            {:ok, _created}->
              #add notification
              NotificationHandler.studentOUTNotification(loginUser["_id"], group["_id"], team["_id"], userObjectId, rollNumber)
              #get device token for this user_id
              getDeviceToken = MessageHandler.getDeviceToken(userObjectId, group["_id"])
              render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: userObjectId, loginUser: loginUser["_id"]] )
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
          |>put_status(404)
          |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
        end
    #  else
    #    conn
    #    |>put_status(404)
    #    |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    #  end
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #send notification to absentees and present students
  #post "/groups/:group_id/team/:team_id/message/absenties?userIds[]=id1,rollNumber&userIds=id2,rollNumber..."
  def sendMessageToAbsenties(%Plug.Conn{ params: allParams } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if team["category"] == "preschool" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    userParams = allParams["userIds"]
    #if all are present then userParams will be null, so update all user to true
    if is_nil(userParams) do
      #update false for absenties student in student_database and present for other all students
      case TeamHandler.updateAttendanceReport(%{ "rollNumber" => [], "userObjectId" => [] }, group["_id"], team["_id"]) do
        {:ok, _updated} ->
          #add notification
          NotificationHandler.attendanceNotification(loginUser["_id"], %{ "rollNumber" => [], "userObjectId" => [] }, group["_id"], team["_id"])
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      studentsList = Enum.reduce(userParams, %{ "userObjectId" => [], "rollNumber" => [] }, fn k, acc ->
        userList = String.split(k, ",")
        userObjectId = [decode_object_id(Enum.at(userList, 0))]
        userIds = acc["userObjectId"] ++ userObjectId
        acc = Map.put(acc, "userObjectId", userIds)

        roll_numbers = acc["rollNumber"] ++ [Enum.at(userList, 1)]
        Map.put(acc, "rollNumber", roll_numbers)
      end)
      #update false for absenties student in student_database and present for other all students
      case TeamHandler.updateAttendanceReport(studentsList, group["_id"], team["_id"]) do
        {:ok, _updated} ->
          #add notification
          NotificationHandler.attendanceNotification(loginUser["_id"], studentsList, group["_id"], team["_id"])
          # find student db details using studentList["rollNumber"] and studentList["studentIds"]
          absentStudents = TeamHandler.findStudentByIdAndrollNumberForAttendance(studentsList, group["_id"], team["_id"])
          absentStdentsList = Enum.reduce(absentStudents, [], fn k, acc ->
            # studentName = k["name"]
            studentPhone = k["userDetails"]["phone"]
            acc ++ [studentPhone]
          end)
          studentMap = %{phone: absentStdentsList}
          #check if teacher selected subject to send attendance
          if is_nil(allParams["subjectName"]) do
            SmsHandler.sendAbsentMessage(studentMap)
          else
            SmsHandler.sendAbsentMessageWithSubject(studentMap, allParams["subjectName"])
          end
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end



  # #send notification to absentees and present students
  # #post "/groups/:group_id/team/:team_id/attendance/take
  # def takeAttendanceAndReportParents123(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "school" do
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   if !params["absentStudentIds"] do
  #     conn
  #     |>put_status(400)
  #     |>json(%JsonErrorResponse{code: 404, title: "Bad Request", message: "Parameters are missing"})
  #   end
  #   loginUser = Guardian.Plug.current_resource(conn)
  #   team = TeamRepo.get(team_id)
  #   case TeamPostHandler.takeAttendanceAndReportParents(params, group["_id"], team["_id"], loginUser) do
  #     {:ok, updated} ->
  #       #add notification
  #       if length(params["absentStudentIds"]) > 0 do
  #         #convert string Id to objectId of all absentStudentIds
  #         absentStudentObjectIds = for item <- params["absentStudentIds"] do
  #           decode_object_id(item)
  #         end
  #         NotificationHandler.attendanceNotification(loginUser["_id"], absentStudentObjectIds, group["_id"], team["_id"])
  #       else
  #         NotificationHandler.attendanceNotification(loginUser["_id"], [], group["_id"], team["_id"])
  #       end
  #       ##### send message to absent students
  #       # if length(params["absentStudentIds"]) > 0 do
  #       #   #convert string Id to objectId of all absentStudentIds
  #       #   absentStudentObjectIds = for item <- params["absentStudentIds"] do
  #       #     decode_object_id(item)
  #       #   end
  #       #   #get absent students phone number to send message
  #       #   absentStudentsPhoneNumber = TeamHandler.findStudentByIdForAttendance(absentStudentObjectIds, group["_id"], team["_id"])
  #       #   absentStudentsPhoneNumbers = for item <- absentStudentsPhoneNumber do
  #       #     item["phoneNumber"]
  #       #   end
  #       #   studentPhoneNumberMap = %{phone: absentStudentsPhoneNumbers}
  #       #   #check if teacher selected subject to send attendance
  #       #   if params["subjectId"] do
  #       #     #send message along with subject name
  #       #     getSubjectNameById = TeamRepo.getSubjectNameById(decode_object_id(params["subjectId"]))
  #       #     subjectName = getSubjectNameById["subjectName"]
  #       #     Gruppie.Handler.SmsHandler.sendAbsentMessageWithSubject(studentPhoneNumberMap, subjectName)
  #       #   else
  #       #     #send message without subjectName
  #       #     Gruppie.Handler.SmsHandler.sendAbsentMessage(studentPhoneNumberMap)
  #       #   end
  #       # end
  #       conn
  #       |> put_status(200)
  #       |> json(%{})
  #     {:error, error}->
  #       conn
  #       |>put_status(500)
  #       |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #   end
  # end


    #send notification to absentees and present students
    #post "/groups/:group_id/team/:team_id/attendance/take
    def takeAttendanceAndReportParents(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if !params["absentStudentIds"] do
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 404, title: "Bad Request", message: "Parameters are missing"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    team = TeamRepo.get(team_id)
    if group["subCategory"] == "School" ||  group["subCategory"] == "school"  do
      case TeamPostHandler.takeAttendanceAndReportParents(params, group, team["_id"], loginUser) do
        {:ok, _updated} ->
          #add notification
          if length(params["absentStudentIds"]) > 0 do
            #convert string Id to objectId of all absentStudentIds
            absentStudentObjectIds = for item <- params["absentStudentIds"] do
              decode_object_id(item)
            end
            NotificationHandler.attendanceNotification(loginUser["_id"], absentStudentObjectIds, group["_id"], team["_id"])
          else
            NotificationHandler.attendanceNotification(loginUser["_id"], [], group["_id"], team["_id"])
          end
          ##### send message to absent students
          # if length(params["absentStudentIds"]) > 0 do
          #   #convert string Id to objectId of all absentStudentIds
          #   absentStudentObjectIds = for item <- params["absentStudentIds"] do
          #     decode_object_id(item)
          #   end
          #   #get absent students phone number to send message
          #   absentStudentsPhoneNumber = TeamHandler.findStudentByIdForAttendance(absentStudentObjectIds, group["_id"], team["_id"])
          #   absentStudentsPhoneNumbers = for item <- absentStudentsPhoneNumber do
          #     item["phoneNumber"]
          #   end
          #   studentPhoneNumberMap = %{phone: absentStudentsPhoneNumbers}
          #   #check if teacher selected subject to send attendance
          #   if params["subjectId"] do
          #     #send message along with subject name
          #     getSubjectNameById = TeamRepo.getSubjectNameById(decode_object_id(params["subjectId"]))
          #     subjectName = getSubjectNameById["subjectName"]
          #     Gruppie.Handler.SmsHandler.sendAbsentMessageWithSubject(studentPhoneNumberMap, subjectName)
          #   else
          #     #send message without subjectName
          #     Gruppie.Handler.SmsHandler.sendAbsentMessage(studentPhoneNumberMap)
          #   end
          # end
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        {:attendance, message}->
          conn
          |>put_status(409)
          |>json(%JsonErrorResponse{code: 409, title: "Attendance Already Taken", message: message})
      end
    else
      case TeamPostHandler.takeAttendanceAndReportParents(params, group, team["_id"], loginUser) do
        {:ok, _updated} ->
          #add notification
          if length(params["absentStudentIds"]) > 0 do
            #convert string Id to objectId of all absentStudentIds
            absentStudentObjectIds = for item <- params["absentStudentIds"] do
              decode_object_id(item)
            end
            NotificationHandler.attendanceNotification(loginUser["_id"], absentStudentObjectIds, group["_id"], team["_id"])
          else
            NotificationHandler.attendanceNotification(loginUser["_id"], [], group["_id"], team["_id"])
          end
          ##### send message to absent students
          # if length(params["absentStudentIds"]) > 0 do
          #   #convert string Id to objectId of all absentStudentIds
          #   absentStudentObjectIds = for item <- params["absentStudentIds"] do
          #     decode_object_id(item)
          #   end
          #   #get absent students phone number to send message
          #   absentStudentsPhoneNumber = TeamHandler.findStudentByIdForAttendance(absentStudentObjectIds, group["_id"], team["_id"])
          #   absentStudentsPhoneNumbers = for item <- absentStudentsPhoneNumber do
          #     item["phoneNumber"]
          #   end
          #   studentPhoneNumberMap = %{phone: absentStudentsPhoneNumbers}
          #   #check if teacher selected subject to send attendance
          #   if params["subjectId"] do
          #     #send message along with subject name
          #     getSubjectNameById = TeamRepo.getSubjectNameById(decode_object_id(params["subjectId"]))
          #     subjectName = getSubjectNameById["subjectName"]
          #     Gruppie.Handler.SmsHandler.sendAbsentMessageWithSubject(studentPhoneNumberMap, subjectName)
          #   else
          #     #send message without subjectName
          #     Gruppie.Handler.SmsHandler.sendAbsentMessage(studentPhoneNumberMap)
          #   end
          # end
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        {:attendance, message}->
          conn
          |>put_status(409)
          |>json(%JsonErrorResponse{code: 409, title: "Attendance Taken", message: message})
      end
    end
  end



  #get offline attendance report for selected month
  #get "groups/:group_id/team/:team_id/offline/attendance/report/get"?month=3&year=2022  #&startDate=&endDate for getting report in weekly basis
  # def getOfflineAttendanceReport123(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "school" do
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   if !params["month"] || !params["year"] do
  #     conn
  #     |>put_status(400)
  #     |>json(%JsonErrorResponse{code: 404, title: "Bad Request", message: "Parameters are missing"})
  #   end
  #   teamObjectId = decode_object_id(team_id)
  #   getReport = TeamPostHandler.getOfflineAttendanceReport(params, group["_id"], teamObjectId)
  #   render(conn, "offline_attendance_report.json", [ attendanceReport: getReport, groupObjectId: group["_id"], teamObjectId: teamObjectId ] )
  # end


  #get offline attendance report for selected month
  #get "groups/:group_id/team/:team_id/offline/attendance/report/get"?month=3&year=2022  #&startDate=&endDate for getting report in weekly basis
  def getOfflineAttendanceReport(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => _team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if !params["month"] || !params["year"] do
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 404, title: "Bad Request", message: "Parameters are missing"})
    end
    #get student offline attendance report
    getReport = TeamPostHandler.getStudentOfflineAttendanceReport(params)
    render(conn, "student_offline_attendance_report.json", [ attendanceReport: getReport ] )
  end



  #leave request
  #get "/groups/:group_id/team/:team_id/leave/request/form"
  def getLeaveRequestForm(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    leaveForm = TeamPostHandler.getLeaveRequestForm(loginUser, group_id, team_id)
    render(conn, "leaveRequestForm.json", [ leaveForm: leaveForm ] )
  end


  #send leave request to teacher
  #post "/groups/:group_id/team/:team_id/leave/request?name=akash,anchi"
  def leaveRequest(%Plug.Conn{ query_params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    team = TeamRepo.get(team_id)
    # userNameList = String.split(params["name"], ",")
    if is_nil(conn.body_params["reason"]) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #send leave request to one kid
    body = conn.body_params["reason"]
    text = "Leave Request For "<>to_string(params["name"])<>". "<>body<>"."
    body_param = %{ text: text }
    changeset = Post.changeset(%Post{}, body_param)
    if changeset.valid? do
      #send leave request
      case MessageHandler.addMessageDirect(changeset.changes, conn, group_id, encode_object_id(team["adminId"])) do
        {:ok, created}->
          #add notification
          NotificationHandler.individualPostNotification(conn, group_id, encode_object_id(team["adminId"]), created.inserted_id)
          #get device token for this user_id
          getDeviceToken = MessageHandler.getDeviceToken(team["adminId"], decode_object_id(group_id))
          render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: team["adminId"], loginUser: loginUser] )
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
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end




  #add time tables belongs to class by teacher
  #post "/groups/:group_id/team/:team_id/timetable/add"
  #def addTimeTable(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #  team = TeamRepo.get(team_id)
  #  changeset = Post.changeset_timetable(%Post{}, params)
  #  if changeset.valid? do
  #    case TeamPostHandler.addTimeTable(changeset.changes, conn, group_id, team["_id"]) do
  #      {:ok, created}->
  #        #add notification
  #        NotificationHandler.timeTablePostNotification(conn, group_id, team, created.inserted_id)
  #        conn
  #        |> put_status(201)
  #        |> json(%{})
  #      {:error, error}->
  #        conn
  #        |> put_status(500)
  #        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #    end
  #  else
  #    conn
  #    |> put_status(400)
  #    |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #  end
  #end



  # #add/register subject to each classes with staffs array
  # #post "/groups/:group_id/team/:team_id/subject/staff/add"
  # def addSubjectsWithStaff(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #   group = GroupRepo.get(group_id)
  #   team = TeamRepo.get(team_id)
  #   changeset = Post.changeset_subject_staff_add(%Post{}, params)
  #   if changeset.valid? do
  #     case TeamPostHandler.addSubjectsWithStaff(changeset.changes, group["_id"], team["_id"]) do
  #       {:ok, created}->
  #         #add selected teacher to that partivular team and give canPost permission
  #         userList = Enum.reduce(changeset.changes.staffId, [], fn k, acc ->
  #           #get userId from staffId(_id) from staff_register
  #           staffUserId = TeamPostRepo.getStaffUserId(group["_id"], decode_object_id(k))
  #           #text conn, staffUserId
  #           user = UserRepo.find_user_by_id(staffUserId["userId"])
  #           #add user to team
  #           case TeamHandler.addSubjectStaffToTeam(group["_id"], team_id, user) do
  #             {:ok, created}->
  #               conn
  #               |> put_status(201)
  #               |> json(%{})
  #             {:alreadyUserError, message} ->
  #               #conn
  #               #|> put_status(400)
  #               #|> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
  #               conn
  #               |> put_status(201)
  #               |> json(%{})
  #             {:error, error}->
  #               conn
  #               |> put_status(500)
  #               |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #           end
  #         end)
  #       {:error, error}->
  #         conn
  #         |> put_status(500)
  #         |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #   end
  # end


  # #get list of subjects of each classes with staffs array
  # #get "/groups/:group_id/team/:team_id/subject/staff/get"...?subjectId=subject_id (to get only selected subject staff details)
  # #get "/groups/:group_id/team/:team_id/subject/staff/get"...?option=more (to get complete subject/staff register from subjectRegister table)
  # def getSubjectsWithStaff(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #   group = GroupRepo.get(group_id)
  #   loginUser = Guardian.Plug.current_resource(conn)
  #   if group["category"] != "school" do
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   #check if timetable added to this team to fetch subject/staff based on time table added
  #   {:ok, isTimeTableAddedForTeam} = TeamPostHandler.checkTimeTableAddedForThisTeam(group["_id"], team_id)
  #   if isTimeTableAddedForTeam > 1 && is_nil(params["option"]) do
  #     #check if admin/authorized user or student
  #     checkGroupAdmin = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUser["_id"])
  #     ##checkUserIsStudent = TeamRepo.findStudentFromDatabaseForLoginUser(loginUser["_id"], group["_id"])
  #     {:ok, checkUserIsStudent} = TeamRepo.checkLoginUserIsStudent(group["_id"], decode_object_id(team_id), loginUser["_id"])
  #     if checkGroupAdmin["canPost"] == true || checkUserIsStudent > 0 do
  #       #get list of all subject-staff belongs to class
  #       #time table added for this team, so pull subject-staff based on timetable
  #       if params["subjectId"] do
  #         #get only subject id selected
  #         getSubjectStaff = TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
  #         render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
  #       else
  #         #get subjectStaff list registered to the class/team in "time table"
  #         getSubjectStaff = TeamPostHandler.getSubjectsWithStaffFromTimeTable(group_id, team_id)
  #         render(conn, "subjectsWithStaffFromTimetable.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
  #       end
  #     else
  #       #get only subject belongs to loginUser - teacher
  #       if params["subjectId"] do
  #         #get only subject id selected
  #         getSubjectStaff = TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
  #         render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
  #       else
  #         #get only subject list belongs to teacher
  #         getSubjectStaff = TeamPostHandler.getSubjectsWithStaffForTeacher(loginUser["_id"], group_id, team_id)
  #         render(conn, "subjectsWithStaffFromTimetable.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
  #       end
  #     end
  #   else
  #     #pull subject staff from subject register
  #     if params["subjectId"] do
  #       #get only subject id selected
  #       getSubjectStaff = TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
  #     else
  #       #get all subjectStaff list registered to the class/team
  #       getSubjectStaff = TeamPostHandler.getSubjectsWithStaff(group_id, team_id)
  #     end
  #     render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
  #   end
  # end


  #add/register subject to each classes with staffs array
  #post "/groups/:group_id/team/:team_id/subject/staff/add"
  def addSubjectsWithStaff(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    changeset = Post.changeset_subject_staff_add(%Post{}, params)
    if changeset.valid? do
      case TeamPostHandler.addSubjectsWithStaff(changeset.changes, group["_id"], team["_id"]) do
        {:ok, _created}->
          #add selected teacher to that partivular team and give canPost permission
          Enum.reduce(changeset.changes.staffId, [], fn k, _acc ->
            #get userId from staffId(_id) from staff_register
            staffUserId = TeamPostRepo.getStaffUserId(group["_id"], decode_object_id(k))
            # #text conn, staffUserId
            user = UserRepo.find_user_by_id(staffUserId["userId"])
            userObjectId = user["_id"]
            #add user to team
            case TeamHandler.addSubjectStaffToTeam(group["_id"], team_id, userObjectId) do
              {:ok, _created}->
                conn
                |> put_status(201)
                |> json(%{})
              {:alreadyUserError, _message} ->
                #conn
                #|> put_status(400)
                #|> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
                conn
                |> put_status(201)
                |> json(%{})
              {:error, _error}->
                conn
                |> put_status(500)
                |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          end)
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #get list of subjects of each classes with staffs array
  #get "/groups/:group_id/team/:team_id/subject/staff/get"...?subjectId=subject_id (to get only selected subject staff details)
  #get "/groups/:group_id/team/:team_id/subject/staff/get"...?option=more (to get complete subject/staff register from subjectRegister table)
  def getSubjectsWithStaff(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check if timetable added to this team to fetch subject/staff based on time table added
    {:ok, isTimeTableAddedForTeam} = TeamPostHandler.checkTimeTableAddedForThisTeam(group["_id"], team_id)
    if isTimeTableAddedForTeam > 1 && is_nil(params["option"]) do
      #check if admin/authorized user or student
      checkGroupAdmin = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUser["_id"])
      ##checkUserIsStudent = TeamRepo.findStudentFromDatabaseForLoginUser(loginUser["_id"], group["_id"])
      {:ok, checkUserIsStudent} = TeamRepo.checkLoginUserIsStudent(group["_id"], decode_object_id(team_id), loginUser["_id"])
      if checkGroupAdmin["canPost"] == true || checkUserIsStudent > 0 do
        #get list of all subject-staff belongs to class
        #time table added for this team, so pull subject-staff based on timetable
        if params["subjectId"] do
          #get only subject id selected
          getSubjectStaff = TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
          render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
        else
          #get subjectStaff list registered to the class/team in "time table"
          getSubjectStaff = TeamPostHandler.getSubjectsWithStaffFromTimeTable(group_id, team_id)
          render(conn, "subjectsWithStaffFromTimetable.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
        end
      else
        #get only subject belongs to loginUser - teacher
        if params["subjectId"] do
          #get only subject id selected
          getSubjectStaff = TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
          render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
        else
          #get only subject list belongs to teacher
          getSubjectStaff = TeamPostHandler.getSubjectsWithStaffForTeacher(loginUser["_id"], group_id, team_id)
          render(conn, "subjectsWithStaffFromTimetable.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
        end
      end
    else
      #pull subject staff from subject register
      getSubjectStaff = if params["subjectId"] do
        #get only subject id selected
        TeamPostHandler.getSubjectsWithStaffById(group_id, team_id, params["subjectId"])
      else
        #get all subjectStaff list registered to the class/team
        TeamPostHandler.getSubjectsWithStaff(group_id, team_id)
      end
      render(conn, "subjectsWithStaff.json", [subjectStaff: getSubjectStaff, group: group, loginUser: loginUser])
    end
  end


  #remove subjectStaff added
  #delete "/groups/:group_id/team/:team_id/subject/:subject_id/remove?staffId=id1" if only staff need to be remove
  def removeSubjectWithStaff(%Plug.Conn{ params: params } = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case TeamPostHandler.removeSubjectWithStaff(group["_id"], team_id, subject_id, params) do
      {:ok, _created}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #add/update staffs to subject
  #put "/groups/:group_id/team/:team_id/subject/:subject_id/staff/update"
  def updateStaffToSubject(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Post.changeset_subject_staff_add(%Post{}, params)
    if changeset.valid? do
      case TeamPostHandler.updateStaffToSubject(changeset.changes, group["_id"], team_id, subject_id) do
        {:ok, _created}->
          #add selected teacher to that partivular team and give canPost permission
          Enum.reduce(changeset.changes.staffId, [], fn k, _acc ->
            #get userId from staffId(_id) from staff_register
            staffUserId = TeamPostRepo.getStaffUserId(group["_id"], decode_object_id(k))
            # #text conn, staffUserId
            user = UserRepo.find_user_by_id(staffUserId["userId"])
            userObjectId = user["_id"]
            #add user to team
            case TeamHandler.addSubjectStaffToTeam(group["_id"], team_id, userObjectId) do
              {:ok, _created}->
                conn
                |> put_status(201)
                |> json(%{})
              {:alreadyUserError, _message} ->
                conn
                |> put_status(201)
                |> json(%{})
              {:error, _error}->
                conn
                |> put_status(500)
                |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          end)
          # conn
          # |> put_status(200)
          # |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #create fee for class/team
  #post "/groups/:group_id/team/:team_id/fee/create"
  def createFeeForClass(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    params = Map.put(params, "reminder", [7,0])
    changeset = SchoolFees.changeset_create_fee(%SchoolFees{}, params)
    if changeset.valid? do
      case TeamPostHandler.createFeeForClass(changeset.changes, group["_id"], team_id) do
        {:ok, _created}->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong we are working on it"})
        {:studentError, error} ->
          conn
          |> put_status(400)
          |> json(%JsonErrorResponse{code: 400, title: "No Students Found", message: error})
      end
    else
      conn
      |> put_status(400)
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #put "groups/:group_id/team/:team_id/fee/edit"
  def editFeesSchool(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      params = Map.put(params, "reminder", [7,0])
      changeset = SchoolFees.changeset_create_fee(%SchoolFees{}, params)
      if changeset.valid? do
        teamObjectId = decode_object_id(team_id)
        case TeamPostHandler.updateFeeForClass(changeset.changes, group["_id"], teamObjectId, params) do
          {:ok, _created}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong we are working on it"})
          {:studentError, error} ->
            conn
            |> put_status(400)
            |> json(%JsonErrorResponse{code: 400, title: "No Students Found", message: error})
        end
      else
        conn
        |> put_status(400)
        |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end


  #update individual student fee
  #put "/groups/:group_id/team/:team_id/student/:user_id/fee/update"
  def updateIndividualStudentFeeStructure(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = SchoolFees.changeset_create_fee(%SchoolFees{}, params)
    if changeset.valid? do
      case TeamPostHandler.updateFeeStructureForIndividualStudent(changeset.changes, group["_id"], team_id, user_id) do
        {:ok, _created}->
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
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #get class wise fee created (to upate fee master if needed)
  #get "/groups/:group_id/team/:team_id/fee/get"
  def getFeeForClass(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getFeeForClass = TeamPostHandler.getFeeForClass(group["_id"], team_id)
    if getFeeForClass do
      render(conn, "get_fee_for_class.json", [getFeeForClass: getFeeForClass])
    else
      conn
        |> put_status(200)
        |> json(%{ data: [] })
    end
  end





  # #get student wise fee individually for class
  # #get "/groups/:group_id/team/:team_id/student/:user_id/fee/get"
  # def getIndividualStudentFee123(conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "school" do
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   getIndividualStudentFeeDetails = TeamPostHandler.getIndividualStudentFeeDetails(group["_id"], team_id, user_id)
  #   # text conn, getIndividualStudentFeeDetails
  #   render(conn, "get_individual_student_fees_details.json", [getStudentsFeeDetails: getIndividualStudentFeeDetails])
  # end


  #TEMPORARY - After bug fix use above function
  #get student wise fee individually for class
  #get "/groups/:group_id/team/:team_id/student/:user_id/fee/get"
  def getIndividualStudentFee(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #take user_id manually from loginuserId
    loginUser = Guardian.Plug.current_resource(conn)
    userId = if params["user_id"] == nil do
      encode_object_id(loginUser["_id"])
    else
      user_id
    end
    getIndividualStudentFeeDetails = TeamPostHandler.getIndividualStudentFeeDetails(group["_id"], team_id, userId)
    # text conn, getIndividualStudentFeeDetails
    render(conn, "get_individual_student_fees_details.json", [getStudentsFeeDetails: getIndividualStudentFeeDetails])
  end


  # #fee pay add - Student
  # #post "/groups/:group_id/team/:team_id/student/:user_id/fee/paid"
  # def addFeePaidDetailsByStudent(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] != "school" do
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  #   loginUser = Guardian.Plug.current_resource(conn)
  #   if loginUser["_id"] == decode_object_id(user_id) do
  #     #pay fee changeset
  #     changeset = SchoolFees.changeset_student_fee_paid(%SchoolFees{}, params)
  #     if changeset.valid? do
  #       case TeamPostHandler.addFeePaidDetailsByStudent(changeset.changes, group["_id"], team_id, user_id) do
  #         {:ok, success}->
  #           conn
  #           |> put_status(200)
  #           |> json(%{})
  #         {:error, error}->
  #           conn
  #           |> put_status(500)
  #           |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #       end
  #     else
  #       conn
  #       |> put_status(400)
  #       |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #     end
  #   else
  #     #pay fee changeset
  #     changeset = SchoolFees.changeset_student_fee_paid(%SchoolFees{}, params)
  #     if changeset.valid? do
  #       case TeamPostHandler.addFeePaidDetailsByStudent(changeset.changes, group["_id"], team_id, user_id) do
  #         {:ok, success}->
  #           conn
  #           |> put_status(200)
  #           |> json(%{})
  #         {:error, error}->
  #           conn
  #           |> put_status(500)
  #           |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #       end
  #     else
  #       conn
  #       |> put_status(400)
  #       |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #     end
  #   end
  # end



  #approve or keep on hold - by admin
  #put "/groups/:group_id/team/:team_id/student/:user_id/fee/:payment_id/approve"?status=approve/hold/notApprove
  def approveOrHoldFeePaidByStudent(%Plug.Conn{query_params: query_params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id, "payment_id" => payment_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUserId = Guardian.Plug.current_resource(conn)
    if query_params["status"] do
      #check status is approve/hold and handle accordingly
      case TeamPostHandler.approveOrHoldFeePaidByStudent(group["_id"], team_id, user_id, payment_id, query_params["status"], loginUserId["_id"], loginUserId["name"]) do
        {:ok, _success}->
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
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #update due date checkbox status by admin
  #put "/groups/:group_id/tea/:team_id/student/:user_id/duedate/update"?status=completed/notCompleted
  def updateDueDateCheckBoxForStudent(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" || !params["dueDate"] do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #update competed status
    case TeamPostHandler.addCompletedOrNotStatusForFeeDueDates(group["_id"], team_id, user_id, params) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #add year time tables belongs to class by admin/allowed to post user
  #post "/groups/:group_id/team/:team_id/year/timetable/add"
  def addYearTimeTable(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    changeset = Post.changeset_year_timetable(%Post{}, params)
    if changeset.valid? do
      getSubjectsWithStaffList = TeamPostHandler.addDayPeriodForTimeTable(changeset.changes, group["_id"], team["_id"])
      render(conn, "year_time_table_add.json", [changeset: changeset.changes, getSubjectsWithStaffList: getSubjectsWithStaffList,
                                                groupObjectId: group["_id"], teamObjectId: team["_id"]])
    else
      conn
      |> put_status(400)
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #add subject with staff to selected day and period returned from above response
  #put "/groups/:group_id/team/:team_id/subject/:subjectWithStaffId/staff/:staffId/year/timetable/add"
  def addYearTimeTableWithStaffAndSubject(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_with_staff_id" => subjectStaffId, "staff_id" => staff_id}) do
    changeset = Post.changeset_year_timetable(%Post{}, params)
    if changeset.valid? do
      #text conn, changeset.changes
      #add subject and staff for the selected day, period
      case TeamPostHandler.addYearTimeTableWithStaffAndSubject(changeset.changes, group_id, team_id, subjectStaffId, staff_id) do
        {:ok, _ok}->
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
      |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #get year time table added based on classes/team
  #get "/groups/:group_id/team/:team_id/year/timetable/get"
  #get "/groups/:group_id/team/:team_id/year/timetable/get?day=1/2/3..."   // to select and get result based on days
  def getYearTimeTable(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    #get timetable added to this team
    getYearTimeTableAdded = if params["day"] do
      #get timetable based on days selected
      TeamPostHandler.getYearTimeTableByDays(group_id, team_id, params["day"])
    else
      #get whole timetable for the class, Mon to Sat
      TeamPostHandler.getYearTimeTable(group_id, team_id)
    end
    render(conn, "getYearTimeTable.json", [getYearTimeTable: getYearTimeTableAdded, groupObjectId: decode_object_id(group_id)])
  end


  #remove/delete timetable added, #delete complete team timetable or day wise timetable
  #delete "/groups/:group_id/team/:team_id/year/timetable/remove?day=1/2/3..." // to select and delete based on days
  def removeYearTimeTable(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    removeYearTimeTableAdded = if params["day"] do
      #remove particular day selected
      TeamPostHandler.removeYearTimeTableByDays(group_id, team_id, params["day"])
    else
      #remove entire TT updated for the class
      TeamPostHandler.removeYearTimeTable(group_id, team_id)
    end
    case removeYearTimeTableAdded do
      {:ok, _ok}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end





  #get class/team subjects
  #get "/groups/:group_id/team/team_id/subjects/get"
  def getClassSubjects(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    teamObjectId = decode_object_id(team_id)
    if group["category"] == "school" do
      classSubjects = TeamRepo.getClassSubjects(group["_id"], teamObjectId)
      if length(Enum.to_list(classSubjects)) > 0 do
        #subject list is found (not empty) so return subjects list
        render(conn, "classwise_subjects.json", [ subjects: classSubjects ])
      else
        #return empty set {}
        conn
        |> put_status(200)
        |> json(%{})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #add subject vice posts/notes/videos for class/team (Video record class)
  #post "/groups/:group_id/team/:team_id/subject/:subject_id/posts/add"
  def addSubjectWisePosts(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    subject = TeamPostRepo.getSubjectById(subject_id)
    if group["category"] == "school" do
      loginUser = Guardian.Plug.current_resource(conn)
      team = TeamRepo.get(team_id)
      changeset = Post.changesetAddSubjectVicePosts(%Post{}, params)
      if changeset.valid? do
        case TeamPostHandler.addToSubjectToMasterSyllabusAndNotes(changeset.changes, loginUser, group["_id"], team["_id"], subject["_id"]) do
          {:ok, created}->
            #add class/team notesVideos event
            GroupHandler.addNotesAndVideosEvent(created.inserted_id, group["_id"], team["_id"], subject["_id"])
            #add notification
            NotificationRepo.teamSubjectPostNotification(loginUser, group["_id"], team, created.inserted_id, subject)
            #send to team post
            title =  ~s"Subject: "<>subject["subjectName"]<>"\n"<>"Chapter: "<> changeset.changes.chapterName<>"\n"<>"Topic: "<>changeset.changes.topicName
            postMap = changeset.changes
            |> Map.put(:title, title)
            |> Map.put(:postType, "notesAndVideos")
            changeset = Post.changeset(%Post{}, postMap)
            TeamPostRepo.add(changeset.changes, loginUser["_id"], group["_id"], team["_id"])
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
        |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get subject vice posts added
  #get "/groups/:group_id/team/:team_id/subject/:subject_id/posts/get"
  def getSubjectWisePosts(conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      getSubjectPosts = TeamPostHandler.getSubjectVicePosts(group["_id"], team_id, subject_id)
      #text conn, Enum.to_list(getSubjectPosts)
      render(conn, "subject_vice_posts.json", [ subjectVicePosts: getSubjectPosts,  loginUser: loginUser, group: group, team_id: team_id])
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #add/update topics to chapter
  #put "/groups/:group_id/team/:team_id/subject/:subject_id/chapter/:chapter_id/topics/add"
  def addTopicsToChapter(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "chapter_id" => chapter_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    subject = TeamPostRepo.getSubjectById(subject_id)
    team = TeamRepo.get(team_id)
    if group["category"] == "school" do
      changeset = Post.changesetAddTopicsToChapter(%Post{}, params)
      if changeset.valid? do
        #add Topics to chapter
        case TeamPostHandler.addTopicsToChapterNotesAndSyllabus(loginUser, group["_id"], team["_id"], subject["_id"], chapter_id, changeset.changes) do
          {:ok, created}->
            #add class/team notesVideos event
            GroupHandler.addNotesAndVideosEvent(decode_object_id(chapter_id), group["_id"], team["_id"], subject["_id"])
            #add notification
            NotificationRepo.teamSubjectTopicPostNotification(loginUser, group["_id"], team, decode_object_id(chapter_id), subject, created.topicId)
            #send to team post
            title =  "Subject: "<>subject["subjectName"]<>" Chapter: "<> changeset.changes.chapterName<>" Topic: "<>changeset.changes.topicName
            postMap = changeset.changes
            |> Map.put(:title, title)
            |> Map.put(:postType, "notesAndVideos")
            changeset = Post.changeset(%Post{}, postMap)
            TeamPostRepo.add(changeset.changes, loginUser["_id"], group["_id"], team["_id"])
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
        |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #add status completed for students for each topics (provide Completed with checkbox below topics for only students)
  #put "/groups/:group_id/team/:team_id/subject/:subject_id/chapter/:chapter_id/topic/:topic_id/completed"
  def addStatusCompletedToTopicsByStudent(conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "chapter_id" => chapter_id, "topic_id" => topic_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    #provide this checkbox feature for canPost: false coming in "team/:team_id/subject/staff/get" api
    case TeamPostHandler.addStatusCompletedToTopicsByStudent(loginUser["_id"], group["_id"], team_id, subject_id, chapter_id, topic_id) do
      {:ok, _added}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end



  #remove chapter or topics added to the subject
  #delete "/groups/:group_id/team/:team_id/subject/:subject_id/chapter/:chapter_id/remove?topicId=id1"
  def removeChapterOrTopicsAdded(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "chapter_id" => chapter_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      if params["topicId"] do
        #remove selected topic from chapter
        case TeamPostHandler.removeTopicFromChapter(group["_id"], team_id, subject_id, chapter_id, params["topicId"]) do
          {:ok, _removedTopic}->
            #add class/team notesVideos event
            GroupHandler.addNotesAndVideosEvent("", group["_id"], decode_object_id(team_id), decode_object_id(subject_id))
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        #remove whole chapter
        case TeamPostHandler.removeChapterFromSubject(group["_id"], team_id, subject_id, chapter_id) do
          {:ok, _removedChapter}->
            #add class/team notesVideos event
            GroupHandler.addNotesAndVideosEvent("", group["_id"], decode_object_id(team_id), decode_object_id(subject_id))
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
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end



  # #create marks card for new marks entry inside the class/team
  # #post "/groups/:group_id/team/:team_id/markscard/create"
  # def createMarksCard123(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] == "school" do
  #     changeset = MarksCard.changeset(%MarksCard{}, params)
  #     if changeset.valid? do
  #       case TeamPostHandler.createMarksCard(changeset.changes, group, team_id) do
  #         {:ok, _}->
  #           conn
  #           |> put_status(201)
  #           |> json(%{})
  #         {:error, error}->
  #           conn
  #           |>put_status(500)
  #           |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #       end
  #     else
  #       conn
  #       |> put_status(400)
  #       |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #     end
  #   else
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end


  # #get created mrks cards list of class/team
  # #get "/groups/:group_id/team/:team_id/markscard/get"
  # def getMarksCardList123(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] == "school" do
  #     marksCardList = TeamPostHandler.getMarksCardList(group["_id"], team_id)
  #     render(conn, "marks_card_list.json", [ marksCardList: marksCardList ] )
  #   else
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end


  # #get students list to upload markscard for selected exam
  # #get "/groups/:group_id/team/:team_id/markscard/:markscard_id/students/get"
  # def getStudentsToUploadMarks123(conn, %{ "group_id" => group_id, "team_id" => team_id, "markscard_id" => markscard_id }) do
  #   group = GroupRepo.get(group_id)
  #   marksCardObjectId = decode_object_id(markscard_id)
  #   if group["category"] == "school" do
  #     studentsList = AdminHandler.getClassStudentsForMarkscard(group, team_id)
  #     render(conn, "studentsListToUploadMarks.json", [studentsList: studentsList, marksCardId: marksCardObjectId])
  #   else
  #     #not found error
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end


  # #add marks to student in marks card
  # #groups/:group_id/team/:team_id/markscard/:markscard_id/student/:student_id/marks/add?rollNo=2
  # def addMarksToStudent123(conn, %{"group_id" => group_id, "team_id" => team_id, "markscard_id" => markscard_id, "student_id" => student_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] == "school" do
  #     rollNumber = conn.query_params["rollNo"]
  #     changeset = MarksCard.changeset_marks_add(%MarksCard{}, conn.body_params)
  #     if changeset.valid? do
  #       case TeamPostHandler.addMarksToStudent(changeset.changes, group, team_id, markscard_id, student_id, rollNumber) do
  #         {:ok, success}->
  #           conn
  #           |> put_status(200)
  #           |> json(%{})
  #         {:error, mongo_error}->
  #           conn
  #           |> put_status(500)
  #           |> json%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"}
  #       end
  #     else
  #       conn
  #       |> put_status(400)
  #       |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #     end
  #   else
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end




  # #get marks card for student based on exams/marks card selection
  # #get "/groups/:group_id/team/:team_id/student/:student_id/markscard/:markscard_id/get?rollNo=1/2/3..."
  # def getMarksCardForStudent123(conn, %{ "group_id" => group_id, "team_id" => team_id, "student_id" => student_id, "markscard_id" => markscard_id }) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] == "school" do
  #     rollNumber = conn.query_params["rollNo"]
  #     getStudentMarksCard = TeamPostHandler.getMarksCardForStudent(group, team_id, student_id, markscard_id, rollNumber)
  #     #text conn, getStudentMarksCard
  #     render(conn, "student_marks_card.json", [ markscard: getStudentMarksCard["marksCard"] ] )
  #   else
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end



  # #remove marks card
  # #put "/groups/:group_id/team/team_id/student/:student_id/markscard/:markscard_id/remove?rollNo=1"
  # def removeUploadedMarksForStudent123(conn, %{ "group_id" => group_id, "team_id" => team_id, "student_id" => student_id, "markscard_id" => markscard_id}) do
  #   group = GroupRepo.get(group_id)
  #   if group["category"] == "school" do
  #     rollNumber = conn.query_params["rollNo"]
  #     case TeamPostHandler.removeUploadedMarksForStudent(group, team_id, student_id, markscard_id, rollNumber) do
  #       {:ok, success}->
  #         conn
  #         |> put_status(200)
  #         |> json(%{})
  #       {:error, mongo_error}->
  #         conn
  #         |> put_status(500)
  #         |> json%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"}
  #     end
  #   else
  #     conn
  #     |>put_status(404)
  #     |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
  #   end
  # end





  # #add marks card file by class teacher
  # #"/groups/:group_id/team/:team_id/student/:user_id/markscard/add?rollNumber=123"
  # def addMarksCard123(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
  #   group = GroupRepo.get(group_id)
  #   changeset = Post.changeset_timetable(%Post{}, params)
  #   rollNumber = params["rollNumber"]
  #   if changeset.valid? && !is_nil(rollNumber) && group["category"] == "school" do
  #     case TeamPostHandler.addMarksCard(group["_id"], team_id, user_id, rollNumber, changeset.changes) do
  #       {:ok, created}->
  #         #add notification
  #         NotificationHandler.marksCardAddNotification(conn, group["_id"], team_id, user_id, rollNumber)
  #         #get device token for this user_id
  #         getDeviceToken = MessageHandler.getDeviceToken(decode_object_id(user_id), group["_id"])
  #         render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: decode_object_id(user_id), loginUser: Guardian.Plug.current_resource(conn)] )
  #         conn
  #         |> put_status(201)
  #         |> json(%{})
  #       {:error, error}->
  #         conn
  #         |> put_status(500)
  #         |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
  #   end
  # end



  # #get student marks card
  # #get"/groups/:group_id/team/:team_id/student/:user_id/markscard/get?rollNumber"
  # def getMarksCard123(%{ query_params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
  #   group = GroupRepo.get(group_id)
  #   rollNumber = params["rollNumber"]
  #   if group["category"] == "school" do
  #     getmarksCard = TeamPostHandler.getMarksCard(group["_id"], team_id, user_id, rollNumber)
  #     if !is_nil(getmarksCard) do
  #       render(conn, "marksCard.json", [ marksCard: getmarksCard ] )
  #     else
  #       json(conn, %{data: []})
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
  #   end
  # end


  # #delete marks card
  # #put "/groups/:group_id/team/:team_id/student/:user_id/markscard/:markscard_id/delete?rollNumber=123"
  # def deleteMarksCard123(%{ query_params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id, "markscard_id" => markscard_id }) do
  #   group = GroupRepo.get(group_id)
  #   rollNumber = params["rollNumber"]
  #   if group["category"] == "school" do
  #     case TeamPostHandler.deleteMarksCard(group["_id"], team_id, user_id, markscard_id, rollNumber) do
  #       {:ok, updated}->
  #         conn
  #         |> put_status(200)
  #         |> json(%{})
  #       {:error, error}->
  #         conn
  #         |> put_status(500)
  #         |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
  #     end
  #   else
  #     conn
  #     |> put_status(400)
  #     |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
  #   end
  # end



  #get time table
  #get "/groups/:group_id/timetable/get"
  def getTimeTable(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    timeTable = TeamPostHandler.getTimeTable(loginUser["_id"], group["_id"])
    render(conn, "timeTable.json", [ timeTable: timeTable, loginUserId: loginUser["_id"], group: group ] )
  end


  # by one who created
  #put "/groups/:group_id/timetable/:timetable_id/delete"
  def deleteTimeTable(conn, %{ "group_id" => group_id, "timetable_id" => timetable_id }) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    case TeamPostHandler.deleteTimeTable(loginUser["_id"], group, timetable_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error_message, message}->
        conn
        |>put_status(403)
        |>json(%JsonErrorResponse{code: 403, title: "Forbidden", message: message})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #get teams/class for teachers to add assignment
  #get "/groups/:group_id/teacher/class/teams"
  def getTeacherClassTeams(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      classTeams = TeamPostHandler.getTeacherClassTeamsList(conn, group["_id"])
      #render list of classes for teacher to take attendande/Assign test and Assignments
      render(conn, "teacherClassTeams.json", [ classTeams: classTeams ] )
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end


  #create/add assignment for class
  #post "/groups/:group_id/team/:team_id/subject/:subject_id/assignment/add"
  def addAssignment(%Plug.Conn{ body_params: assignment_params } = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    subject = TeamPostRepo.getSubjectById(subject_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      team = TeamRepo.get(team_id)
      changeset = Post.changesetAddAssignment(%Post{}, assignment_params)
      #text conn, changeset
      if changeset.valid? do
        case TeamPostHandler.addAssignment(conn, changeset.changes, group["_id"], team_id, subject_id) do
          {:ok, success} ->
            #add class/team assignment event
            GroupHandler.addAssignmentEvent(success.inserted_id, group["_id"], team["_id"], subject["_id"])
            #add notification
            NotificationRepo.teamAddAssignmentNotification(loginUser, group["_id"], team, success.inserted_id, subject)
            #uploading to team post
            title = if Map.has_key?(changeset.changes, :title) do
              ~s"Subject: "<>subject["subjectName"]<>"\n"<>changeset.changes.title
            else
              ~s"Subject: "<>subject["subjectName"]<>"\n"<>changeset.changes.text
            end
            postMap = changeset.changes
            |> Map.put(:postType, "homeWork")
            |> Map.put(:title, title)
            changeset = Post.changeset(%Post{}, postMap)
            TeamPostRepo.add(changeset.changes, loginUser["_id"], group["_id"], team["_id"])
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
        |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end


  #get list of assignments added to the class subject
  #get "/groups/:group_id/team/:team_id/subject/:subject_id/assignment/get"
  def getAssignments(conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #get list of assignment added
      getAssignments = TeamPostHandler.getAssignments(group["_id"], team_id, subject_id)
      render(conn, "getAssignments.json", [getAssignments: getAssignments, loginUserId: loginUser["_id"], group: group] )
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end



  #delete assignment added from teacher
  #put "/groups/:group_id/team/:team_id/subject/:subject_id/assignment/:assignment_id/delete"
  def deleteAssignment(conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "assignment_id" => assignment_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #if login user is teacher who created assignment
      {:ok, checkAssignmentCreatedBy} = TeamPostHandler.checkAssignmentCreatedByLoginUser(loginUser["_id"], group["_id"], team_id, subject_id, assignment_id)
      if checkAssignmentCreatedBy > 0 do
        #delete assignment
        case TeamPostHandler.deleteAssignment(group["_id"], team_id, subject_id, assignment_id) do
          {:ok, _success} ->
            #add class/team assignment event
            GroupHandler.addAssignmentEvent("", group["_id"], decode_object_id(team_id), decode_object_id(subject_id))
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
        |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end



  #Assignment submit from student
  #post "/groups/:group_id/team/:team_id/subject/:subject_id/assignment/:assignment_id/submit"
  def studentSubmitAssignment(%Plug.Conn{ body_params: assignment_params } = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "assignment_id" => assignment_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      changeset = Post.changesetAddAssignment(%Post{}, assignment_params)
      #text conn, changeset
      if changeset.valid? do
        case TeamPostHandler.studentSubmitAssignment(conn, changeset.changes, group["_id"], team_id, subject_id, assignment_id) do
          {:ok, _success} ->
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
        |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end



  #get submitted assignment
  #get "/groups/:group_id/team/:team_id/subject/:subject_id/assignment/:assignment_id/get"?list=verified/notVerified/notSubmittedn (Only if checkAssignmentCreatedBy > 0)
  def getStudentSubmittedAssignment(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "assignment_id" => assignment_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #if login user is teacher who created assignment or students who submitted assignment
      {:ok, checkAssignmentCreatedBy} = TeamPostHandler.checkAssignmentCreatedByLoginUser(loginUser["_id"], group["_id"], team_id, subject_id, assignment_id)
      #check login user is authorized user
      #check login user can post in group or not
      checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUser["_id"])
      if checkAssignmentCreatedBy > 0 || checkCanPost["canPost"] == true || group["adminId"] == loginUser["_id"] do
        #assignment createdBy login user, So get list of verified, not verified and not submitted students list
        if !is_nil(params["list"]) do
          getAssignmentList = TeamPostHandler.getStudentSubmittedAssignmentList(params["list"], group["_id"], team_id, subject_id, assignment_id)
          if params["list"] == "notVerified" || params["list"] == "verified" do
            render(conn, "getStudentSubmittedAssignment.json", [getAssignmentList: getAssignmentList, groupObjectId: group["_id"], teamObjectId: decode_object_id(team_id)])
          else
            #get not submitted student details
            if params["list"] == "notSubmitted" do
              render(conn, "getAssignmentNotSubmittedStudentDetails.json", [notSubmittedStudentDetails: getAssignmentList])
            end
          end
        else
          conn
          |> put_status(400)
          |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
        end
      else
        #Students (Assignment submitted) get particular student assignment list
        getLoginStudentAssignment = TeamPostHandler.getLoginStudentAssignmentList(loginUser["_id"], group["_id"], team_id, subject_id, assignment_id)
        render(conn, "getStudentSubmittedAssignment.json", [getAssignmentList: getLoginStudentAssignment, groupObjectId: group["_id"], teamObjectId: decode_object_id(team_id)])
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end



  #delete still notVerified or not reassigned assignment by student
  #(Provide delete option only for "canPost: false" in "getAssignments" API and "assignmentVerified: false" , "assignmentReassigned: false" in submitted assignment get API)
  #put "/groups/:group_id/team/team_id/subject/:subject_id/assignment/:assignment_id/delete/:studentAssignment_id"
  def deleteStudentSubmittedAssignment(conn, %{"group_id" => group_id, "team_id" => team_id, "subject_id" => subject_id, "assignment_id" => assignment_id, "studentAssignment_id" => studentAssignment_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #check login user id student or teacher
      {:ok, checkAssignmentCreatedBy} = TeamPostHandler.checkAssignmentCreatedByLoginUser(loginUser["_id"], group["_id"], team_id, subject_id, assignment_id)
      if checkAssignmentCreatedBy > 0 do
        #teacher, so not required
        conn
        |> put_status(400)
        |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
      else
        #student, provide delete option
        case TeamPostHandler.deleteStudentSubmittedAssignment(loginUser["_id"], group["_id"], team_id, subject_id, assignment_id, studentAssignment_id) do
          {:ok, _success} ->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |>put_status(500)
            |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end


  #verify student submitted assignment
  #put, /groups/{group_id}/team/{team_id}/subject/{subject_id}/assignment/{assignment_id}/verify/{studentAssignment_id}?verify=true  ##For verify assignment
  #put, /groups/{group_id}/team/{team_id}/subject/{subject_id}/assignment/{assignment_id}/verify/{studentAssignment_id}?reassign=true  ##For reassign assignment
  def verifyStudentSubmittedAssignment(%Plug.Conn{params: params} = conn, %{}) do
    group = GroupRepo.get(params["group_id"])
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #if login user is teacher who created assignment
      {:ok, checkAssignmentCreatedBy} = TeamPostHandler.checkAssignmentCreatedByLoginUser(loginUser["_id"], group["_id"], params["team_id"], params["subject_id"], params["assignment_id"])
      if checkAssignmentCreatedBy > 0 do
        #check verify or reassign
        if params["verify"] do
          #if verify=true then changeset required
          if params["verify"] == "true" do
            #reassign assignment (Adding comment is mandatory)
            changeset = Post.changesetStudentAssignmentVerify(%Post{}, params)
            if changeset.valid? do
              #verify assignment
              case TeamPostHandler.verifyStudentSubmittedAssignment(params, changeset.changes, group["_id"]) do
                {:ok, _success} ->
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
              |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
            end
          else
            #unVerify assignment // false
            case TeamPostHandler.verifyStudentSubmittedAssignment(params, "", group["_id"]) do
              {:ok, _success} ->
                conn
                |> put_status(200)
                |> json(%{})
              {:error, _error}->
                conn
                |>put_status(500)
                |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
            end
          end
        else
          if params["reassign"] == "true" do
            #reassign assignment (Adding comment is mandatory)
            changeset = Post.changesetStudentAssignmentVerify(%Post{}, params)
            if changeset.valid? do
              case TeamPostHandler.reassignStudentSubmittedAttendance(params, changeset.changes, group["_id"]) do
                {:ok, _success} ->
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
              |>render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
            end
          else
            case TeamPostHandler.reassignStudentSubmittedAttendance(params, "", group["_id"]) do
              {:ok, _success} ->
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
      else
        conn
        |> put_status(400)
        |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
      end
    else
      conn
      |> put_status(400)
      |> json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page not found"})
    end
  end


  #create test for class
  #post "/groups/:group_id/team/:team_id/test/create"
  #def createTestForClass(conn, %{"group_id" => group_id, "team_id" => team_id}) do
  #  text conn, group_id
  #end



  #get nested friends team list
  #get "/groups/:group_id/team/:team_id/user/:user_id/teams"
  def getNestedTeams(conn, %{ "group_id" => group_id, "team_id" => _team_id, "user_id" => user_id }) do
    # groupObjectId = decode_object_id(group_id)
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    teams = TeamHandler.getCreatedTeamsForThisUser(group["_id"], user_id)
    render(conn, "nestedUserTeams.json", [loginUserId: loginUser["_id"], teams: teams, group: group] )
  end


  #get "/groups/:group_id/team/:team_id/post/:post_id/read/unread"
  def postReadUnread(conn, %{ "group_id" => group_id, "team_id" => team_id, "post_id" => post_id }) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    postObjectId = decode_object_id(post_id)
    loginUser = Guardian.Plug.current_resource(conn)
    post = TeamPostRepo.findTeamPostById(groupObjectId, teamObjectId, postObjectId)
    team = TeamRepo.get(team_id)
    group = GroupRepo.get(group_id)
    if post["userId"] == loginUser["_id"] || team["adminId"] == loginUser["_id"] || group["adminId"] == loginUser["_id"] do
      #get people read or unread this post
      postReadUsers = TeamPostHandler.getPostReadUsers(loginUser["_id"], groupObjectId, teamObjectId, post)
      postUnreadUsers = TeamPostHandler.getPostUnreadUsers(loginUser["_id"], groupObjectId, teamObjectId, post)
      render(conn, "postReadUnread.json", [postReadUsers: postReadUsers, postUnreadUsers: postUnreadUsers] )
    else
      conn
      |>put_status(403)
      |>json(%JsonErrorResponse{code: 403, title: "Forbidden", message: "You cannot access this url"})
    end
  end



end
