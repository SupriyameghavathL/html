defmodule GruppieWeb.Api.V1.TeamPostView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.TeamPostRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.TeamPostCommentsRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  alias GruppieWeb.Repo.GroupPostRepo
  import GruppieWeb.Repo.RepoHelper
  # import GruppieWeb.Handler.TimeNow


  # def render("school_team_users123.json", %{ teamUsers: teamUsers, loginUserId: loginUserId, groupId: groupObjectId, teamId: teamObjectId }) do
  #   usersList = Enum.reduce(teamUsers, [], fn k, acc ->
  #     #get number of teams of this user
  #     ##{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
  #     map = %{
  #       "id" => encode_object_id(k["userId"]),
  #       "phone" => k["userDetails"]["phone"],
  #       "image" => k["userDetails"]["image"],
  #       "allowedToAddUser" => k["teams"]["allowedToAddUser"],
  #       "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
  #       "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
  #       #"teamCount" => getTeamsCount,
  #       "name" => k["name"]
  #     }
  #     #find user is staff or not
  #     findUserIsStaffAndName =  TeamRepo.findUserIsStaffForUsersName(k["userId"], groupObjectId);
  #     if findUserIsStaffAndName do
  #        #staff
  #        map = map
  #        |> Map.put_new("staff", true)
  #        |> Map.put("name", findUserIsStaffAndName["name"]<>" (Staff)")
  #     else
  #       #not a staff
  #       map = Map.put_new(map, "staff", false)
  #       #check user is student or not
  #       findUserIsStudentAndName =  TeamRepo.findUserIsStudentForUsersName(k["userId"], groupObjectId, teamObjectId);
  #       # IO.puts "#{findUserIsStudentAndName}"
  #       if findUserIsStudentAndName do
  #         map = map
  #         |> Map.put("name", findUserIsStudentAndName["name"])
  #       end
  #     end
  #     acc ++ [map]
  #   end)
  #   %{ data: usersList }
  # end

  def render("school_team_users.json", %{ teamUsers: teamUsers, loginUserId: _loginUserId, groupId: groupObjectId, teamId: teamObjectId }) do
    teamUsers = teamUsers
    |> Enum.reject(&is_nil/1)
    usersList = Enum.reduce(teamUsers, [], fn k, acc ->
      #get number of teams of this user
      ##{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
      map = %{
        "id" => encode_object_id(k["userId"]),
        "phone" => k["phone"],
        "image" => k["image"],
        "allowedToAddUser" => k["teams"]["allowedToAddUser"],
        "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
        "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
        #"teamCount" => getTeamsCount,
        "name" => k["name"]
      }
      #find user is staff or not
      findUserIsStaffAndName =  TeamRepo.findUserIsStaffForUsersName(k["userId"], groupObjectId);
      map = if findUserIsStaffAndName do
         #staff
         map
         |> Map.put_new("staff", true)
         |> Map.put("name", findUserIsStaffAndName["name"]<>" (Staff)")
      else
        #not a staff
        map = Map.put_new(map, "staff", false)
        #check user is student or not
        findUserIsStudentAndName =  TeamRepo.findUserIsStudentForUsersName(k["userId"], groupObjectId, teamObjectId);
        # IO.puts "#{findUserIsStudentAndName}"
        if findUserIsStudentAndName do
          map
          |> Map.put("name", findUserIsStudentAndName["name"])
        end
      end
      acc ++ [map]
    end)
    usersList = usersList
    |> Enum.sort_by(& String.downcase(&1["name"]))

    %{ data: usersList }
  end


  # def render("team_users123.json", %{ teamUsers: teamUsers, loginUserId: loginUserId, groupId: groupObjectId, teamId: teamObjectId }) do
  #   usersList = Enum.reduce(teamUsers, [], fn k, acc ->
  #     #get number of teams of this user
  #     ####{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
  #     #get this userId notification_token
  #     userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
  #     map = %{
  #       "id" => encode_object_id(k["userId"]),
  #       "phone" => k["userDetails"]["phone"],
  #       "image" => k["userDetails"]["image"],
  #       "allowedToAddUser" => k["teams"]["allowedToAddUser"],
  #       "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
  #       "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
  #       ####"teamCount" => getTeamsCount,
  #       "name" => k["name"],
  #       "roleOnConstituency" => k["userDetails"]["roleOnConstituency"],
  #       "dob" => k["userDetails"]["dob"],
  #       "gender" => k["userDetails"]["gender"],
  #       "bloodGroup" => k["userDetails"]["bloodGroup"],
  #       "voterId" => k["userDetails"]["voterId"],
  #       "aadharNumber" => k["userDetails"]["aadharNumber"],
  #       "email" => k["userDetails"]["email"],
  #       "religion" => k["userDetails"]["religion"],
  #       "caste" => k["userDetails"]["caste"],
  #       "subCaste" => k["userDetails"]["subCaste"],
  #       "designation" => k["userDetails"]["designation"],
  #       "qualification" => k["userDetails"]["qualification"],
  #       "voterId" => k["userDetails"]["voterId"],
  #       "roleOnConstituency" => k["userDetails"]["roleOnConstituency"],
  #       "pushTokens" => userNotificationPushToken,
  #       "isLoginUser" => if k["userId"] == loginUserId do
  #         true
  #       else
  #         false
  #       end
  #     }
  #     acc ++ [map]
  #   end)
  #   #IO.puts "#{length(usersList)}"
  #   %{ data: usersList }
  # end

  def render("team_users.json", %{ teamUsers: teamUsers, loginUserId: loginUserId, groupId: groupObjectId, teamId: teamObjectId, params: params }) do
    if params["page"] do
      usersList = Enum.reduce(teamUsers, [], fn k, acc ->
        #get number of teams of this user
        ####{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
        #get this userId notification_token
        userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
        map = %{
          "id" => encode_object_id(k["userDetails"]["_id"]),
          "phone" => k["userDetails"]["phone"],
          "image" => k["userDetails"]["image"],
          "allowedToAddUser" => k["teams"]["allowedToAddUser"],
          "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
          "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
          ####"teamCount" => getTeamsCount,
          "name" => k["userDetails"]["name"],
          "roleOnConstituency" => k["roleOnConstituency"],
          "dob" => k["userDetails"]["dob"],
          "gender" => k["userDetails"]["gender"],
          "bloodGroup" => k["userDetails"]["bloodGroup"],
          "voterId" => k["userDetails"]["voterId"],
          "aadharNumber" => k["userDetails"]["aadharNumber"],
          "email" => k["userDetails"]["email"],
          "religion" => k["userDetails"]["religion"],
          "caste" => k["userDetails"]["caste"],
          "subCaste" => k["userDetails"]["subCaste"],
          "designation" => k["userDetails"]["designation"],
          "qualification" => k["userDetails"]["qualification"],
          "pushTokens" => userNotificationPushToken,
          "blocked" => k["teams"]["bolcked"],
          "isLoginUser" => if k["userId"] == loginUserId do
            true
          else
            false
          end
        }
        map = if Map.has_key?(k["userDetails"], "state") do
          Map.put(map, "state", Recase.to_title(k["userDetails"]["state"]))
        end
        map = if Map.has_key?(k["userDetails"], "district") do
          Map.put(map, "district", Recase.to_title(k["userDetails"]["district"]))
        end
        map = if Map.has_key?(k["userDetails"], "taluk") do
          Map.put(map, "taluk", Recase.to_title(k["userDetails"]["taluk"]))
        end
        map = if Map.has_key?(k["userDetails"], "place") do
          Map.put(map, "place", Recase.to_title(k["userDetails"]["place"]))
        end
        acc ++ [map]
      end)
      {:ok, pages} = TeamRepo.getUsersCountTeam(groupObjectId, teamObjectId)
      pageCount = Float.ceil(pages / 15)
      totalPages = round(pageCount)
      %{
        data: usersList,
        totalNumberOfPages: totalPages
      }
    else
      teamUsers = teamUsers
      |> Enum.reject(&is_nil/1)
      usersList = Enum.reduce(teamUsers, [], fn k, acc ->
        #get number of teams of this user
        ####{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
        #get this userId notification_token
        userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
        map = %{
          "id" => encode_object_id(k["userId"]),
          "phone" => k["phone"],
          "image" => k["image"],
          "allowedToAddUser" => k["teams"]["allowedToAddUser"],
          "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
          "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
          ####"teamCount" => getTeamsCount,
          "name" => k["name"],
          "roleOnConstituency" => k["roleOnConstituency"],
          "dob" => k["dob"],
          "gender" => k["gender"],
          "bloodGroup" => k["bloodGroup"],
          "voterId" => k["voterId"],
          "aadharNumber" => k["aadharNumber"],
          "email" => k["email"],
          "religion" => k["religion"],
          "caste" => k["caste"],
          "subCaste" => k["subCaste"],
          "designation" => k["designation"],
          "qualification" => k["qualification"],
          # "voterId" => k["voterId"],
          # "roleOnConstituency" => k["roleOnConstituency"],
          "pushTokens" => userNotificationPushToken,
          "blocked" => k["blocked"],
          "isLoginUser" => if k["userId"] == loginUserId do
            true
          else
            false
          end
        }
        map = if Map.has_key?(k, "state") do
          Map.put(map, "state", Recase.to_title(k["state"]))
        end
        map = if Map.has_key?(k, "district") do
          Map.put(map, "district", Recase.to_title(k["district"]))
        end
        map = if Map.has_key?(k, "taluk") do
          Map.put(map, "taluk", Recase.to_title(k["taluk"]))
        end
        map = if Map.has_key?(k, "place") do
          Map.put(map, "place", Recase.to_title(k["place"]))
        end
        acc ++ [map]
      end)
      usersList
      |> Enum.sort_by(& String.downcase(&1["name"]))
    end
  end


  def render("posts.json", %{ posts: posts, group: group, team: team, conn: conn, limit: limit }) do
    login_user = Guardian.Plug.current_resource(conn)
    final_list = Enum.reduce(posts,[], fn post, acc ->
      canEdit = if post["userId"] == login_user["_id"] || group["adminId"] == login_user["_id"] || team["adminId"] == login_user["_id"]  do
        true
      else
        false
      end
      {:ok ,isLikedPostCount} = TeamPostRepo.findTeamPostIsLiked(login_user["_id"], group["_id"], team["_id"], post["_id"])
      isLiked = if isLikedPostCount == 0 do
          false
        else
          true
        end
      #get total comments count for this post
      {:ok, commentsCount} = TeamPostCommentsRepo.getTotalTeamPostCommentsCount(group["_id"], team["_id"], post["_id"])
      postMap = %{
        "id" => encode_object_id(post["_id"]),
        "title" => post["title"],
        "text" => post["text"],
        "type" => post["type"],
        "createdById" => encode_object_id(post["userId"]),
        "createdBy" => post["name"],
        "phone" => post["phone"],
        "createdByImage" => post["image"],
        "comments" => commentsCount,
        "canEdit" => canEdit,
        "isLiked" => isLiked,
        "likes" => post["likes"],
        "createdAt" => post["insertedAt"],
        "updatedAt" => post["updatedAt"]
      }
      postMap = if !is_nil(post["body"]) do
        Map.put_new(postMap, "body", post["body"])
      end
      postMap = if !is_nil(post["fileName"]) do
        postMap
        |> Map.put_new("fileName", post["fileName"])
        |> Map.put_new("fileType", post["fileType"])
      end
      postMap = if !is_nil(post["video"]) do
        if post["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>post["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>post["video"]<>"/0.jpg"
          postMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", post["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        end
      end
      #if thumbnailImage for video and pdf is not nil then display
      postMap = if !is_nil(post["thumbnailImage"]) do
        postMap
        |> Map.put_new("thumbnailImage", post["thumbnailImage"])
      end
      ########TEMPORARiLY REMOVED#### Please add this to production
      #if post type is "birthdayPost" then fetch that bdayUserId name and profile
      postMap = if post["type"] == "birthdayPost" do
        bdayUserDetail = GroupPostRepo.getBdayUserDetail(post["bdayUserId"])
        postMap
        |> Map.put_new("bdayUserId", encode_object_id(post["bdayUserId"]))
        |> Map.put_new("bdayUserName", bdayUserDetail["name"])
        |> Map.put_new("bdayUserImage", bdayUserDetail["image"])
      else
        postMap
      end
      acc ++ [ postMap ]
    end)
    #get total number of pages
    {:ok, postCount} = TeamPostRepo.getTeamPostsCount(group["_id"], team["_id"])
    pageCount = Float.ceil(postCount / limit)
    totalPages = round(pageCount)

    %{ data: final_list, totalNumberOfPages: totalPages }
  end


#  def render("attendance.json", %{ attendance: attendance }) do
#  list = Enum.reduce(attendance, [], fn k, acc ->
#      map = %{
#        "id" => encode_object_id(k["_id"]),
#        "studentName" => k["studentName"],
#        "parentNumber" => k["parentNumber"],
#        "rollNumber" => k["rollNumber"],
#        "userId" => encode_object_id(k["userId"])
#      }
#      acc ++ [map]
#    end)
#    %{ data: list }
#  end



  def render("jitsi_token_start.json", %{ jitsiToken: zoomMeetingId, className: className, meetingIdOnLive: meetingIdOnLive }) do
    map = %{
      "jitsiToken" =>  zoomMeetingId,
      "name" => className,
      "meetingCreatedBy" => true,
      "meetingIdOnLive" => meetingIdOnLive
    }
    %{ data: [map] }
  end


  def render("get_online_attendance_report.json", %{getOnlineAttendanceReport: getOnlineAttendanceReport}) do
    list = Enum.reduce(getOnlineAttendanceReport, [], fn k, acc ->
      #get meeting created at time and date
      #IO.puts "#{k}"
      #merge
      mergeList = Enum.reduce(k, %{}, fn v, acc ->
        #IO.puts "#{v}"
        Map.merge(acc, v)
        #IO.puts "#{map}"
      end)
      #IO.puts "#{mergeList}"
      acc ++ [mergeList]
    end)
    %{ data: list }
  end



  def render("attendance.json", %{ attendance: attendance, groupObjectId: groupObjectId, teamObjectId: teamObjectId }) do
    list = Enum.reduce(attendance, [], fn k, acc ->
      getLastFiveAttendanceForStudent = TeamPostRepo.getLastFiveAttendanceForStudent(groupObjectId, teamObjectId, k["userId"])
      attendanceList = for lastFiveAttendance <- getLastFiveAttendanceForStudent do
        [] ++ lastFiveAttendance["offlineAttendance"]
      end
      map = %{
        "studentName" => k["name"],
        "studentImage" => k["image"],
        "rollNumber" => k["rollNumber"],
        "userId" => encode_object_id(k["userId"]),
        "lastDaysAttendance" => attendanceList,
      }
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("attendancePreschool.json", %{ attendance: attendance, dateTimeMap: dateTimeMap }) do
    list = Enum.reduce(attendance, [], fn k, acc ->
      #find student IN attendance already taken
      {:ok, alreadyCountIN} = TeamRepo.findKidAttendanceINAlreadyTaken(k["groupId"], k["teamId"], k["userDetails"]["_id"], k["rollNumber"], dateTimeMap)
      attendanceIn = if alreadyCountIN > 0 do
        true
      else
        false
      end
      #find student OUT attendance already taken
      {:ok, alreadyCountOUT} = TeamRepo.findKidAttendanceOUTAlreadyTaken(k["groupId"], k["teamId"], k["userDetails"]["_id"], k["rollNumber"], dateTimeMap)
      attendanceOut = if alreadyCountOUT > 0 do
        true
      else
        false
      end
      map = %{
        #"id" => encode_object_id(k["_id"]),
        "studentName" => k["name"],
        "studentImage" => k["image"],
        "rollNumber" => k["rollNumber"],
        #"studentId" => k["studentId"],
        #"parentNumber" => k["userDetails"]["phone"],
        #"admissionNumber" => k["admissionNumber"],
        #"class" => k["class"],
        #"section" => k["section"],
        #"dob" => k["dob"],
        #"doj" => k["doj"],
        #"email" => k["email"],
        #"fatherName" => k["fatherName"],
        #"motherName" => k["motherName"],
        #"fatherNumber" => k["fatherNumber"],
        #"motherNumber" => k["motherNumber"],
        "userId" => encode_object_id(k["userId"]),
        "attendanceIn" => attendanceIn,
        "attendanceOut" => attendanceOut,
      }
      acc ++ [map]
    end)
    %{ data: list }
  end




  #get all replies of comments along with parent comments
  def render("deviceToken.json", %{ deviceToken: deviceToken }) do
    list = Enum.reduce(deviceToken, [], fn k, acc ->
      map = %{
        "deviceToken" => k["deviceToken"],
        "deviceType" => k["deviceType"]
      }
      acc ++ [map]
    end)
    %{ data: list }
  end




  #get team time table
  def render("timeTable.json", %{ timeTable: timeTable, loginUserId: loginUserId, group: group }) do
    resultList = Enum.reduce(timeTable, [], fn k, acc ->
      canEdit = if group["adminId"] == loginUserId || k["userId"] == loginUserId do
        true
      else
        false
      end
      map = %{
        "timeTableId" => encode_object_id(k["_id"]),
        "title" => k["title"],
        "groupId" => encode_object_id(k["groupId"]),
        "createdById" => encode_object_id(k["userId"]),
        "createdBy" => k["userDetails"]["name"],
        "phone" => k["userDetails"]["phone"],
        "createdByImage" => k["userDetails"]["image"],
        "createdAt" => k["insertedAt"],
        "updatedAt" => k["updatedAt"],
        "canEdit" => canEdit,
      }
      map = if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      end
      #if thumbnailImage for video and pdf is not nil then display
      map = if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      end
      acc ++ [ map ]
    end)
    %{ data: resultList }
  end




  def render("teacherClassTeams.json", %{classTeams: classTeams}) do
    list = Enum.reduce(classTeams, [], fn k, acc ->
      map = %{
        "teamId" => encode_object_id(k["teamDetails"]["_id"]),
        "name" => k["teamDetails"]["name"]
      }
      acc ++ [ map ]
    end)
    %{ data: list }
  end




  def render("nestedUserTeams.json", %{ loginUserId: loginUserId, teams: teams, group: group }) do
    list = Enum.reduce(teams, [], fn k, acc ->
      {:ok, teamMembersCount} = TeamRepo.getCreatedTeamMembersCount(group["_id"], k["_id"])
      isAdmin = if k["adminId"] == loginUserId || group["adminId"] == loginUserId do
        true
      else
        false
      end
      map = %{
        "teamId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "image" => k["image"],
        "members" => teamMembersCount,
        "allowedToAddTeamPost" => true,
        "allowedToAddTeamPostComment" => true,
        "enableAttendance" => k["enableAttendance"],
        "category" => k["category"],
        "isTeamAdmin" => isAdmin
      }
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("postReadUnread.json", %{ postReadUsers: postReadUsers, postUnreadUsers: postUnreadUsers }) do
    #post read users
    postReadUsersList = Enum.reduce(postReadUsers, [], fn k, acc ->
      postReadUsersMap = %{
        "userId" => encode_object_id(k["userId"]),
        "name" => k["name"],
        "phone" => k["phone"],
        "image" => k["image"],
        "postSeenTime" => k["postSeenTime"]
      }
      acc ++ [postReadUsersMap]
    end)
    #post unread users
    postUnreadUsersList = Enum.reduce(postUnreadUsers, [], fn v, acc ->
      postUnreadUsersMap = %{
        "userId" => encode_object_id(v["userId"]),
        "name" => v["name"],
        "phone" => v["phone"],
        "image" => v["image"]
      }
      acc ++ [postUnreadUsersMap]
    end)
    %{ data: [%{ unreadUsers: postUnreadUsersList, readUsers: postReadUsersList }] }
  end



  def render("subjectsWithStaffFromTimetable.json", %{subjectStaff: subjectStaff, group: group, loginUser: loginUser}) do
    list = Enum.reduce(subjectStaff, [], fn k, acc ->
      map = %{
        "subjectId" => encode_object_id(k["subjectStaffId"]),
        "subjectName" => k["subjectName"],
        "staffName" => k["staffDetail"],
        "canPost" => false
      }
      #check login user is group admin or staff of group to provide add chapter icon
      {:ok, checkLoginUserIsStaff} = TeamRepo.findUserIsStaff(loginUser["_id"], group["_id"])
      map = if group["adminId"] == loginUser["_id"] || checkLoginUserIsStaff > 0 do
        Map.put(map, "canPost", true)
      end
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("subjectsWithStaff.json", %{subjectStaff: subjectStaff, group: group, loginUser: loginUser}) do
    list = Enum.reduce(subjectStaff, [], fn k, acc ->
      map = %{
        "subjectId" => encode_object_id(k["_id"]),
        "subjectName" => k["subjectName"],
        "staffName" => k["staffName"],
        "canPost" => false
      }
      #check login user is group admin or staff of group to provide add chapter icon
      {:ok, checkLoginUserIsStaff} = TeamRepo.findUserIsStaff(loginUser["_id"], group["_id"])
      if group["adminId"] == loginUser["_id"] || checkLoginUserIsStaff > 0 do
        Map.put(map, "canPost", true)
      end
      acc ++ [map]
    end)
    %{ data: list }
  end


  def render("subject_vice_posts.json", %{subjectVicePosts: subjectVicePosts, loginUser: loginUser, group: group, team_id: team_id}) do
    list = Enum.reduce(subjectVicePosts, [], fn chapter, acc ->
      map = %{
        "chapterId" => encode_object_id(chapter["_id"]),
        "chapterName" => chapter["chapterName"],
        #"insertedAt" => k["insertedAt"],
        "createdById" => encode_object_id(chapter["userId"]),
        #"createdByName" => chapter["userDetails"]["name"],
        #"topics" => chapter["topics"],
        "canEditChapter" => false,
      }
      #find chapter created by login user
      map = if chapter["userId"] == loginUser["_id"] do
        map
        |> Map.put("canEditChapter", true)
      end
      #add thumbnailImage if video or pdf type and youtubeThumbnail for youtube type
      topicsList = Enum.reduce(chapter["topics"], [], fn k, acc ->
        #IO.puts "#{[k["studentStatusCompleted"]]}"
        #check login user is group admin or staff of group to provide studentTopicsCompleted list
        {:ok, checkLoginUserIsStaff} = TeamRepo.findUserIsStaff(loginUser["_id"], group["_id"])
        #IO.puts "#{checkLoginUserIsStaff == 0}"   # TRUE AND FALSE = FALSE
        k = if group["adminId"] != loginUser["_id"] && checkLoginUserIsStaff == 0 do
          #remove students status completed from map
          Map.delete(k, "studentStatusCompleted")
        else
          #get student name for using "studentStatusCompleted" studentIds array (student_db_col)
          getstudentDetails = TeamPostRepo.getStudentDetailFromDb(group["_id"], decode_object_id(team_id), k["studentStatusCompleted"])
          Map.put(k, "studentStatusCompleted", getstudentDetails)
        end
        #provide student topic completed list to all staffs
        #find student status: completed for topics
        {:ok, findStudentCompleted} = TeamPostRepo.findStudentCompletedTopics(loginUser["_id"], group["_id"], decode_object_id(team_id), chapter["_id"], k["topicId"])
        k = if findStudentCompleted > 0 do
          k
          |> Map.put("topicCompleted", true)
        else
          k
          |> Map.put("topicCompleted", false)
        end
        #assign canPost to false initially
        k = k
            |> Map.put_new("canEditTopic", false)
        #get posted user name using createdById from topics added
        k = if !is_nil(k["createdById"]) do
          createdByIdDetails = UserRepo.find_user_by_id(decode_object_id(k["createdById"]))
          createdByName = createdByIdDetails["name"]
          k
          |> Map.put_new("createdByName", createdByName)
          #check login user created this post for canPost: true/false
          if encode_object_id(loginUser["_id"]) == k["createdById"] do
            k
            |> Map.put("canEditTopic", true)
          end
        end
        #if file is youtube
        k = if !is_nil(k["video"]) do
          if k["fileType"] == "youtube" do
            watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
            thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
            #k["video"] =  "https://www.youtube.com/watch?v="<>k["video"]<>""
            k
            |> Map.put_new("thumbnail", thumbnail)
            |> Map.put("video", watch)
          end
        end
        #if thumbnailImage for video and pdf is not nil then display
        if !is_nil(k["thumbnailImage"]) do
          k
          |> Map.put_new("thumbnailImage", k["thumbnailImage"])
        end
        acc ++ [k]
      end)
      #IO.puts "#{topicsList}"
      map = Map.put_new(map, "topics", topicsList)
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("get_fee_for_class.json", %{getFeeForClass: getFeeForClass}) do
    map = %{
      #"feeTitle" => getFeeForClass["feeTitle"],
      "groupId" => encode_object_id(getFeeForClass["groupId"]),
      "teamId" => encode_object_id(getFeeForClass["teamId"]),
      "feeDetails" => getFeeForClass["feeDetails"],
      "totalFee" => getFeeForClass["totalFee"],
      "dueDates" => getFeeForClass["dueDates"],
      "insertedAt" => getFeeForClass["insertedAt"],
      "fineAmount" => getFeeForClass["addFineAmount"],
    }
    %{ data: [map] }
  end





  def render("get_individual_student_fees_details.json", %{getStudentsFeeDetails: k}) do
    #IO.puts "#{k["feePaidDetails"]}"
    if k != [] do
      map = %{
        ##"studentDbId" => encode_object_id(k["studentDbId"]),
        "groupId" => encode_object_id(k["groupId"]),
        "teamId" => encode_object_id(k["teamId"]),
        "userId" => encode_object_id(k["studentDbDetails"]["userId"]),
        #"feeTitle" => k["feeTitle"],
        "totalFee" => k["totalFee"],
        "feeDetails" => k["feeDetails"],
        "dueDates" => k["dueDates"],
        "feePaidDetails" => k["feePaidDetails"],
        "studentName" => k["studentDbDetails"]["name"],
        "studentRollNumber" => k["studentDbDetails"]["rollNumber"],
        "studentImage" => k["studentDbDetails"]["image"],
        "totalAmountPaid" => k["totalAmountPaid"],
        "totalBalanceAmount" => k["totalBalance"]
      }
      #IO.puts "#{k["totalBalanceAmount"]}"
      # check totalBalanceAmount is NULL, if NULL then totalBalanceAmount will be equal to totalFee
      map = if is_nil(k["totalBalanceAmount"]) do
        #total fee will be total balance
        Map.put_new(map, "totalBalanceAmount", k["totalFee"])
      else
        Map.put_new(map, "totalBalanceAmount", k["totalBalanceAmount"])
      end
      %{ data: [map] }
    else
      %{ data: [] }
    end
  end




  def render("getAssignments.json", %{getAssignments: getAssignments, loginUserId: loginUserId, group: group}) do
    list = Enum.reduce(getAssignments, [], fn k, acc ->
      #IO.puts "#{k}"
      map = %{
        "assignmentId" => encode_object_id(k["_id"]),
        "groupId" => encode_object_id(k["groupId"]),
        "teamId" => encode_object_id(k["teamId"]),
        "subjectId" => encode_object_id(k["subjectId"]),
        "topic" => k["title"],
        "description" => k["text"],
        "createdById" => encode_object_id(k["createdById"]),
        "createdByName" => k["userDetails"]["name"],
        "createdByImage" => k["userDetails"]["image"],
        "canPost" => false,
        "lastSubmissionDate" => k["lastSubmissionDate"],
        "insertedAt" => k["insertedAt"]
      }
      map = if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      end
      #if thumbnailImage for pdf is not nil then display
      map = if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      end
      #check login user can post in group or not
      checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUserId)
      can_post = checkCanPost["canPost"]
      #check assignment is created by loginUser
      map = if k["createdById"] == loginUserId || group["adminId"] == loginUserId || can_post == true do
        Map.put(map, "canPost", true)
      end
      acc ++ [map]
    end)
    %{ data: list }
  end




  def render("getStudentSubmittedAssignment.json", %{getAssignmentList: getAssignmentList, groupObjectId: groupObjectId, teamObjectId: teamObjectId}) do
    list = Enum.reduce(getAssignmentList, [], fn k, acc ->
      #IO.puts "#{k["submittedStudents"]}"
      map = %{
        "studentAssignmentId" => encode_object_id(k["submittedStudents"]["studentAssignmentId"]),
        "assignmentReassigned" => k["submittedStudents"]["assignmentReassigned"],
        "assignmentVerified" => k["submittedStudents"]["assignmentVerified"],
        "insertedAt" => k["submittedStudents"]["insertedAt"],
        "description" => k["submittedStudents"]["text"],
        "submittedById" => encode_object_id(k["submittedStudents"]["submittedById"])
      }
      #get student name from studentDb
      getStudentDetail = TeamPostRepo.getStudentDbDetailById(groupObjectId, teamObjectId, k["submittedStudents"]["submittedById"])
      #put student name and image from student_db
      map = map
      |> Map.put_new("studentName", getStudentDetail["name"])
      |> Map.put_new("studentImage", getStudentDetail["image"])
      #if fileName is not null
      map = if !is_nil(k["submittedStudents"]["fileName"]) do
        map
        |> Map.put_new("fileName", k["submittedStudents"]["fileName"])
        |> Map.put_new("fileType", k["submittedStudents"]["fileType"])
      end
      #if thumbnailImage for pdf is not nil then display
      map = if !is_nil(k["submittedStudents"]["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["submittedStudents"]["thumbnailImage"])
      end
      #if reassigned then show comments entered to it
      map = if k["submittedStudents"]["assignmentReassigned"] == true do
        map
        |> Map.put_new("reassignComment", k["submittedStudents"]["reassignComment"])
        |> Map.put_new("reassignedAt", k["submittedStudents"]["reassignedAt"])
      end
      #if verified then show comments entered to it
      map = if k["submittedStudents"]["assignmentVerified"] == true do
        map
        |> Map.put_new("verifiedComment", k["submittedStudents"]["verifiedComment"])
        |> Map.put_new("verifiedAt", k["submittedStudents"]["verifiedAt"])
      end
      acc ++ [map]
    end)
    %{ data: list }
  end


  def render("getAssignmentNotSubmittedStudentDetails.json", %{notSubmittedStudentDetails: notSubmittedStudentDetails}) do
    list = Enum.reduce(notSubmittedStudentDetails, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "studentDbId" => encode_object_id(k["_id"]),
        "studentName" => k["name"],
        "rollNumber" => k["rollNumber"],
        "studentImage" => k["image"]
      }
      acc ++ [map]
    end)
    %{data: list}
  end




  # def render("year_time_table_add.json", %{changeset: changeset, getSubjectsWithStaffList: getSubjectsWithStaffList, groupObjectId: groupObjectId, teamObjectId: teamObjectId}) do
  #   list = Enum.reduce(getSubjectsWithStaffList, [], fn k, acc ->
  #     #IO.puts "#{k}"
  #     if length(k["staffIdNew"]) > 0 do
  #       #get number of periods/sessions for subjectname in a week
  #       {:ok, getSubjectSessionCount} = TeamPostRepo.getSubjectSessionCountForTimeTable(groupObjectId, teamObjectId, k["_id"])
  #       #IO.puts "#{Enum.to_string(getSubjectSessionCount)}"
  #       #show subject_staff list
  #       map = %{
  #         "subjectWithStaffId" => encode_object_id(k["_id"]),
  #         "subjectName" => k["subjectName"]<>" ("<>Integer.to_string(getSubjectSessionCount)<>")",  #subjectSessionCount is the number of periods subjects allotted to the class
  #         "day" => changeset.day,
  #         "period" => changeset.period,
  #         #"startTime" => changeset.startTime,
  #         #"endTime" => changeset.endTime
  #       }
  #       if Map.has_key?(changeset, :startTime) do
  #         map = Map.put_new(map, "startTime", changeset.startTime)
  #       end
  #       if Map.has_key?(changeset, :endTime) do
  #         map = Map.put_new(map, "endTime", changeset.endTime)
  #       end
  #       #get staff name from id
  #       staffIdList = Enum.reduce(k["staffIdNew"], [], fn v, acc ->
  #         #IO.puts "#{decode_object_id(v)}"
  #         staffDetails = TeamPostRepo.getStaffDetailsById(groupObjectId, teamObjectId, v)
  #         #get staff sessions allotted count for this day
  #         {:ok, getStaffSessionCount} = TeamPostRepo.getStaffSessionCountForTimeTable(groupObjectId, decode_object_id(v), changeset.day)
  #         #IO.puts "#{getStaffSessionCount}"
  #         staffMap = %{
  #           "staffId" => v,
  #           "staffName" => staffDetails["name"]<>" ("<>Integer.to_string(getStaffSessionCount)<>")"
  #         }
  #         acc = acc ++ [staffMap]
  #       end)
  #       #IO.puts "#{staffIdList}"
  #       map = Map.put_new(map, "subjectWithStaffs", staffIdList)
  #       acc ++ [map]
  #     else
  #       acc ++ []
  #     end
  #   end)
  #   %{ data: list }
  # end


  def render("year_time_table_add.json", %{changeset: changeset, getSubjectsWithStaffList: getSubjectsWithStaffList, groupObjectId: groupObjectId, teamObjectId: teamObjectId}) do
    list = Enum.reduce(getSubjectsWithStaffList, [], fn k, acc ->
      #IO.puts "#{k}"
      if length(k["staffIdNew"]) > 0 do
        #get number of periods/sessions for subjectname in a week
        {:ok, getSubjectSessionCount} = TeamPostRepo.getSubjectSessionCountForTimeTable(groupObjectId, teamObjectId, k["_id"])
        #IO.puts "#{Enum.to_string(getSubjectSessionCount)}"
        #show subject_staff list
        map = %{
          "subjectWithStaffId" => encode_object_id(k["_id"]),
          "subjectName" => k["subjectName"]<>" ("<>Integer.to_string(getSubjectSessionCount)<>")",  #subjectSessionCount is the number of periods subjects allotted to the class
          "day" => changeset.day,
          "period" => changeset.period,
          #"startTime" => changeset.startTime,
          #"endTime" => changeset.endTime
        }
        map = if Map.has_key?(changeset, :startTime) do
          Map.put_new(map, "startTime", changeset.startTime)
        end
        map = if Map.has_key?(changeset, :endTime) do
          Map.put_new(map, "endTime", changeset.endTime)
        end
        #get staff name from id
        staffIdList = Enum.reduce(k["staffIdNew"], [], fn v, acc ->
          #IO.puts "#{decode_object_id(v)}"
          staffDetails = TeamPostRepo.getStaffDetailsById(groupObjectId, v)
          #get staff sessions allotted count for this day
          {:ok, getStaffSessionCount} = TeamPostRepo.getStaffSessionCountForTimeTable(groupObjectId, decode_object_id(v), changeset.day)
          #IO.puts "#{getStaffSessionCount}"
          staffMap = %{
            "staffId" => v,
            "staffName" => staffDetails["name"]<>" ("<>Integer.to_string(getStaffSessionCount)<>")"
          }
          acc ++ [staffMap]
        end)
        #IO.puts "#{staffIdList}"
        map = Map.put_new(map, "subjectWithStaffs", staffIdList)
        acc ++ [map]
      else
        acc ++ []
      end
    end)
    %{ data: list }
  end



  # def render("getYearTimeTable123.json", %{getYearTimeTable: getYearTimeTable, groupObjectId: groupObjectId}) do
  #   #lastListElem = List.last(getYearTimeTable)
  #   #IO.puts "#{lastListElem["day"]}"
  #   #dayCount = lastListElem["day"]
  #   listGroup = Enum.group_by(getYearTimeTable, &{&1["day"]})
  #   #IO.puts "#{listGroup}"
  #   list = Enum.reduce(listGroup, [], fn k, acc ->
  #     #IO.puts "#{k}"
  #     {{day}, list} = k
  #     map = %{
  #       #"session" => list,
  #       "day" => day
  #     }
  #     sessionList = Enum.reduce(list, [], fn k, acc ->
  #       #IO.puts "#{k}"
  #       k = %{
  #         "period" => k["period"],
  #         "startTime" => k["startTime"],
  #         "endTime" => k["endTime"],
  #         "teacherName" => k["staffDetails"]["name"],
  #         "subjectName" => k["subjectStaffDetails"]["subjectName"]
  #       }
  #       acc = acc ++ [k]
  #     end)
  #     #sort based on periods = 1,2,3
  #     sortSessionList = Enum.sort_by(sessionList, fn(p) -> p["period"] end)
  #     map = Map.put_new(map, "sessions", sortSessionList)
  #     acc ++ [map]
  #   end)
  #   %{ data: list }
  # end


  def render("getYearTimeTable.json", %{getYearTimeTable: getYearTimeTable, groupObjectId: groupObjectId}) do
    listGroup = Enum.group_by(getYearTimeTable, &{&1["day"]})
    list = Enum.reduce(listGroup, [], fn k, acc ->
      {{day}, list} = k
      map = %{
        #"session" => list,
        "day" => day
      }
      sessionList = Enum.reduce(list, [], fn k, acc ->
        if k["staffId"] do
          #get staff name from staff_database
          getStaffName = TeamPostRepo.getStaffNameByDb(groupObjectId, k["staffId"])
          #get subject name from subject_staff_db
          getSubjectName = TeamPostRepo.getSubjectNameForMeeting(groupObjectId, k["subjectWithStaffId"])
          %{
            "period" => k["period"],
            "startTime" => k["startTime"],
            "endTime" => k["endTime"],
            "teacherName" => getStaffName["name"],
            "subjectName" => getSubjectName["subjectName"],
            "staffId" => encode_object_id(k["staffId"]),
            "subjectId" => encode_object_id(k["subjectWithStaffId"])
          }
        else
          acc
        end
        acc ++ [k]
      end)
      #sort based on periods = 1,2,3
      sortSessionList = Enum.sort_by(sessionList, fn(p) -> p["period"] end)
      map = Map.put_new(map, "sessions", sortSessionList)
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("leaveRequestForm.json", %{ leaveForm: leaveFormName }) do
    nameList = Enum.reduce(leaveFormName, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "name" => k["name"]
      }
      acc ++ [map]
    end)
    %{ data: nameList }
  end


  def render("marksCard.json", %{ marksCard: marksCard }) do
    marksCardList = Enum.reduce(marksCard, [], fn k, acc ->
      map = %{
        "marksCardId" => encode_object_id(k["id"]),
        "title" => k["title"],
        "fileName" => k["fileName"],
        "fileType" => k["fileType"],
        "insertedAt" => k["insertedAt"]
      }
      acc ++ [map]
    end)
    %{ data: marksCardList }
  end



  #get list of class subjects
  def render("classwise_subjects.json", %{ subjects: subjects, loginUser: _loginUser, group: _group }) do
    subjectList = Enum.reduce(subjects, [], fn k, acc ->
      map = %{
        "subjectId" => encode_object_id(k["subjectDetails"]["_id"]),
        "subjects" => k["subjectDetails"]["classSubjects"],
        "groupId" => encode_object_id(k["groupId"]),
        "teamId" => encode_object_id(k["_id"])
      }
      acc ++ [map]
    end)
    %{ data: subjectList }
  end


  #get list of marks card of class/team
  def render("marks_card_list.json", %{ marksCardList: marksCardList }) do
    marksCard = Enum.reduce(marksCardList, [], fn k,  acc ->
      map = %{
        "marksCardId" => encode_object_id(k["_id"]),
        "title" => k["title"],
        #{}"duration" => k["duration"],
        #{}"subjects" => k["subjects"]
      }
      acc ++ [map]
    end)
    %{ data: marksCard }
  end


  #get list of students to upload marks for selected exam
  def render("studentsListToUploadMarks.json", %{ studentsList: studentsList, marksCardId: marksCardId }) do
    students = Enum.reduce(studentsList, [], fn k, acc ->
      #check selected exam markscard uploaded to this student
      {:ok, marksUploaded} = TeamPostRepo.checkMarksAlreadyUploadedForThisStudent(k["userId"], k["rollNumber"], k["groupId"], k["teamId"], marksCardId)
      uploaded = if marksUploaded > 0 do
        true
      else
        false
      end
      #get markscard subjects
      subjects = TeamPostRepo.getMarksCardSubjects(k["groupId"], k["teamId"], marksCardId)
      map = %{
        "studentId" => encode_object_id(k["userId"]),
        "rollNumber" => k["rollNumber"],
        "name" => k["name"],
        "image" => k["image"],
        "isMarksCardUploaded" => uploaded,
        "subjects" => subjects["subjects"],
        "duration" => subjects["duration"]
      }
      acc ++ [map]
    end)
    %{ data: students }
  end



  def render("student_marks_card.json", %{ markscard: markscard }) do
    if markscard do
      marksCardList = Enum.reduce(markscard, [], fn k, acc ->
        #find max marks for subjects in marks_card
        maxMinMarks = TeamPostRepo.findMaxMarksForSubjects(k["markscardId"])
        # to get max marks for the subject
        marks = Enum.reduce(hd(maxMinMarks["subjects"]), %{"maxMarks" => %{}, "minMarks" => %{}}, fn k, acc ->
          {sub, marks} = k     #sub: ENG/KAN/MAT     &   marks: %{"max" => 25, "min" => 9}
          maxAcc = Map.put_new(acc["maxMarks"], sub, marks["max"])
          minAcc = Map.put_new(acc["minMarks"], sub, marks["min"])
          %{ "maxMarks" => maxAcc, "minMarks" => minAcc }
        end)
        #get student total marks scored
        sudentTotalMarks = Enum.reduce(hd(k["subjectMarks"]), [], fn k, acc ->
          {_subject, marks} = k
          if is_integer(marks) do
            acc ++ [marks]
          else
            acc ++ [0]
          end
        end)
        #get max marks total marks
        maxTotalMarks = Enum.reduce(marks["maxMarks"], [], fn k, acc ->
          {_subject, marks} = k
          if is_integer(marks) do
            acc ++ [marks]
          else
            acc ++ [0]
          end
        end)
        #get min marks total marks
        minTotalMarks = Enum.reduce(marks["minMarks"], [], fn k, acc ->
          {_subject, marks} = k
          if is_integer(marks) do
            acc ++ [marks]
          else
            acc ++ [0]
          end
        end)
        subjectMarks = Map.put_new(hd(k["subjectMarks"]), "totalMarks", Enum.sum(sudentTotalMarks))
        maximumMarks = Map.put_new(marks["maxMarks"], "totalMarks", Enum.sum(maxTotalMarks))
        minimumMarks = Map.put_new(marks["minMarks"], "totalMarks", Enum.sum(minTotalMarks))
        map = %{
          "markscardId" => encode_object_id(k["markscardId"]),
          #{}"subjectMarks" => Enum.sort_by([subjectMarks], mapper, sorter),
          "subjectMarks" => [subjectMarks],
          "maxMarks" => [maximumMarks],
          "minMarks" => [minimumMarks],
          "insertedAt" => k["insertedAt"]
        }
        acc ++ [map]
      end)
      %{ data: marksCardList }
    else
      %{ data: [] }
    end
  end




  def render("offline_attendance_report.json", %{ attendanceReport: attendanceReport, groupObjectId: groupObjectId, teamObjectId: teamObjectId }) do
    if attendanceReport == [] do
      %{data: []}
    else
      attendanceReportList = Enum.reduce(attendanceReport, [], fn k, acc ->
        #get student detail for this userId, groupId and teamId
        getStudentDetail = TeamPostRepo.getIndividualStudentDetailFromDb(groupObjectId, teamObjectId, k["userId"])
        map = if getStudentDetail["name"] do
          %{
            "userId" => encode_object_id(k["userId"]),
            "attendanceReport" => k["offlineAttendance"],
            "studentName" => getStudentDetail["name"],
            "rollNumber" => getStudentDetail["rollNumber"]
          }
        else
          []
        end
        acc ++ [map]
      end)
      attendanceReportList = attendanceReportList
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(& String.downcase(&1["studentName"]))
      %{data: attendanceReportList}
    end
  end


  def render("student_offline_attendance_report.json", %{ attendanceReport: attendanceReport }) do
    if attendanceReport == [] do
      %{data: []}
    else
      attendanceReportList = Enum.reduce(attendanceReport, [], fn k, acc ->
        map = %{
          "userId" => encode_object_id(k["userId"]),
          "studentName" => k["name"],
          "rollNumber" => k["rollNumber"]
        }
        if Map.has_key?(k, "offlineAttendance") do
          ### Temporary show teacher name for subjectname because of null value to subject name in attendance report
          offlineAttendanceArray = for item <- k["offlineAttendance"] do
            Map.put(item, "subjectName", item["teacherName"])
          end
          map
          |> Map.put("attendanceReport", offlineAttendanceArray)
        else
          map
          |> Map.put("attendanceReport", [])
        end
        acc ++ [map]
      end)
      attendanceReportList = attendanceReportList
      |> Enum.sort_by(& String.downcase(&1["studentName"]))
      %{data: attendanceReportList}
    end
  end



end
