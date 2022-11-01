defmodule GruppieWeb.Handler.TeamHandler do
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.GroupRepo


  def createTeam(conn, changeset, group_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    TeamRepo.createTeam(loginUser, changeset, groupObjectId)
  end



  #get all teams belong to login user
  def get_teams(loginUser, group) do
    #get public team
    publicTeamList = TeamRepo.get_public_teams(group["_id"])
    publicTeamList = for team <- publicTeamList do
      team
      |> Map.put("allowedToAddComment", true)
      |> Map.put("isTeamAdmin", false)
      |> Map.put("canAddUser", false)
      |> Map.put("allowedToAddPost", false)
    end
    if group["category"] == "constituency" do
      groupAdminTeams(loginUser, group, publicTeamList)
    else
      groupObjectId = group["_id"]
      #get all teams list as it is for school app
      teamIdsList = TeamRepo.get_teams(loginUser["_id"], groupObjectId)
      teamIds = for item <- teamIdsList["teams"] do
        item["teamId"]
      end
      #get team details
      teamDetail = TeamRepo.teamDetails(teamIds)
      viewOfTeamList = Enum.reduce(teamIdsList["teams"], [], fn k, acc ->
        list = Enum.reduce(teamDetail, [], fn s, acc ->
          map = if k["teamId"] == s["_id"] do
            Map.merge(k, s)
          end
          acc ++ [map]
        end)
        acc ++ list
      end)
      publicTeamList ++ viewOfTeamList
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1["teamId"])
    end
  end


  defp groupAdminTeams(loginUser, group, publicTeamList) do
    if group["adminId"] == loginUser["_id"] do
      groupObjectId = group["_id"]
      #get all teams list as it is for school app
      teamIdsList = TeamRepo.get_teams(loginUser["_id"], groupObjectId)
      teamIds = for item <- teamIdsList["teams"] do
        item["teamId"]
      end
      #get team details
      teamDetail = TeamRepo.teamDetailsForAdmin(teamIds)
      # IO.puts "#{teamDetail}"
      viewOfTeamList = Enum.reduce(teamIdsList["teams"], [], fn k, acc ->
        list = Enum.reduce(teamDetail, [], fn s, acc ->
          map = if k["teamId"] == s["_id"] do
            Map.merge(k, s)
          end
          acc ++ [map]
        end)
        acc ++ list
      end)
      publicTeamList ++ viewOfTeamList
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1["teamId"])
    else
      groupObjectId = group["_id"]
      #get all teams list as it is for school app
      teamIdsList = TeamRepo.get_teams(loginUser["_id"], groupObjectId)
      teamIds = for item <- teamIdsList["teams"] do
        if item != nil do
          if !Map.has_key?(item, "blocked") do
            item["teamId"]
          end
        end
      end
      |>  Enum.reject(&is_nil/1)
      #get team details
      teamDetail = TeamRepo.teamDetails(teamIds)
      viewOfTeamList = Enum.reduce(teamIdsList["teams"], [], fn k, acc ->
        list = Enum.reduce(teamDetail, [], fn s, acc ->
          map = if k["teamId"] == s["_id"] do
            Map.merge(k, s)
          end
          acc ++ [map]
        end)
        acc ++ list
      end)
      publicTeamList ++ viewOfTeamList
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1["teamId"])
    end
  end


  def addZoomToken(changeset, groupObjectId) do
    TeamRepo.addZoomToken(changeset, groupObjectId)
  end



  #get all teams belong to login user
  def get_video_conference_teams(loginUser, groupObjectId) do
    TeamRepo.get_video_conference_teams(loginUser["_id"], groupObjectId)
  end


  #get my teams list
  def getMyTeams(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    TeamRepo.getMyTeams(groupObjectId, loginUser["_id"])
  end




  def getMyClassTeams(userObjectId, groupObjectId) do
    #loginUser = Guardian.Plug.current_resource(conn)
    TeamRepo.findClassTeamForLoginUser(userObjectId, groupObjectId)
  end


  #get list of class teams for my kids
  def getMyKids(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    TeamRepo.getMyKidsClassForSchool(loginUser["_id"], groupObjectId)
  end


  def addUserToTeamManually(changeset, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc
    checkUserExistInUserDoc(changeset, group, teamObjectId)
  end

  defp checkUserExistInUserDoc(changeset, group, teamObjectId) do
    #IO.puts "#{changeset}"
    ###check member adding to booth teams to add default teams
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) < 1 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      UserRepo.addUserToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
      {:ok, userRegisterToUserDoc}
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in this team
        {:ok, teamCount} = GroupRepo.checkUserAlreadyInTeam(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamCount == 0 do
          #not exist in this team. So push this team newly
          UserRepo.addNewTeamForUserInGroup(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
        else
          userDoc = hd(userAlreadyExistInUserDoc)
          {:ok, userDoc}
        end
      else
        #add new doc to group_team_members because he is new user to group
        UserRepo.addUserToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
      end
      {:ok, hd(userAlreadyExistInUserDoc)}
    end
  end


  def addSchoolUserToTeam(groupObjectId, team_id, user) do
    teamObjectId = decode_object_id(team_id)
    #check user already in team
    {:ok, teamUserCount} = TeamRepo.isTeamMemberByUserId(user["_id"], groupObjectId, teamObjectId)
    if teamUserCount < 1 do
      #user already in group / Just push new team for the user
      UserRepo.addSchoolMembersToTeam(groupObjectId, teamObjectId, user)
    else
      {:alreadyUserError, "User Already Exist In team"}
    end
  end

  def addSchoolStaffToTeam(groupObjectId, team_id, user) do
    teamObjectId = decode_object_id(team_id)
    #check user already in team
    {:ok, teamUserCount} = TeamRepo.isTeamMemberByUserId(user["_id"], groupObjectId, teamObjectId)
    if teamUserCount < 1 do
      #user already in group / Just push new team for the user
      UserRepo.addStaffMembersToTeam(groupObjectId, teamObjectId, user)
    else
      {:alreadyUserError, "User Already Exist In team"}
    end
  end


  def addStudentToNewTeam(groupObjectId, newTeamId, existingTeamId, userObjectId) do
    existingTeamObjectId = decode_object_id(existingTeamId)
    newTeamObjectId = decode_object_id(newTeamId)
    studentDetails = UserRepo.getStudentDetailsFromExistingTeam(groupObjectId, existingTeamObjectId, userObjectId)
    insertStudentDataBaseDoc = if Map.has_key?(studentDetails, "gruppieRollNumber") do
      %{
        "name" => studentDetails["name"],
        "rollNumber" =>  studentDetails["rollNumber"],
        "marksCard" => [],
        "groupId" => groupObjectId,
        "teamId" => newTeamObjectId,
        "isActive" => true,
        "insertedAt" => bson_time(),
        "updatedAt" => bson_time(),
        "userId" => userObjectId,
        "gruppieRollNumber" => studentDetails["gruppieRollNumber"],
      }

    else
       %{
        "name" => studentDetails["name"],
        "rollNumber" =>  studentDetails["rollNumber"],
        "marksCard" => [],
        "groupId" => groupObjectId,
        "teamId" => newTeamObjectId,
        "isActive" => true,
        "insertedAt" => bson_time(),
        "updatedAt" => bson_time(),
        "userId" => userObjectId,
        "gruppieRollNumber" => encode_object_id(new_object_id()),
      }
    end
    #check student already in student register
    {:ok, checkStudentAlreadyExist} = TeamRepo.checkStudentAlreadyExistInClass(groupObjectId, newTeamObjectId, userObjectId)
    if checkStudentAlreadyExist == 0 do
      UserRepo.addStudentToStudentDb(insertStudentDataBaseDoc)
    end
  end


  def addSubjectStaffToTeam(groupObjectId, team_id, userObjectId) do
    teamObjectId = decode_object_id(team_id)
    #check user already in team
    {:ok, teamUserCount} = TeamRepo.isTeamMemberByUserId(userObjectId, groupObjectId, teamObjectId)
    if teamUserCount < 1 do
      #user already in group / Just push new team for the user
      UserRepo.addSubjectStaffToTeam(groupObjectId, teamObjectId, userObjectId)
    else
      {:alreadyUserError, "User Already Exist In team"}
    end
  end


  def addStaffToSchoolManually(changeset, group) do
    # IO.puts "#{changeset}"
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) < 1 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      UserRepo.addStaffToGroupTeamMembersDoc(userRegisterToUserDoc, group)
      userRegisterToUserDoc["_id"]
    else
      #check user already in group
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        hd(userAlreadyExistInUserDoc)["_id"]
      else
        UserRepo.addStaffToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group)
        hd(userAlreadyExistInUserDoc)["_id"]
      end
    end
  end


  def getSchoolStaff(groupObjectId) do
    staffs = UserRepo.getSchoolStaff(groupObjectId)
    staffs
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end



  def addStudentsToTeamManually(changeset, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc
    checkStudentExistInUserDoc(changeset, group, teamObjectId)
  end



  def addStudentsToBusTeamManually(changeset, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc
    checkStudentExistInUserDocBus(changeset, group, teamObjectId)
  end




  def getTeamUsersPagination(_loginUserId, groupObjectId, teamObjectId, page) do
    pageNo = String.to_integer(page)
    # 1. Get all the userIds belongs to this team from group_team_mem
    TeamRepo.getTeamUsersListPage(groupObjectId, teamObjectId, pageNo)
  end

  def getTeamUsers(loginUserId, groupObjectId, teamObjectId) do
    team = TeamRepo.get(encode_object_id(teamObjectId))
    # 1. Get all the userIds belongs to this team from group_team_mem
    usersWithTeam = TeamRepo.getTeamUsersList(groupObjectId, teamObjectId, loginUserId)
    #checking for Blocked User
    usersWithTeam = if Map.has_key?(team, "blockedUsers") do
      for userId <- usersWithTeam do
        if encode_object_id(userId["userId"]) in team["blockedUsers"] do
          Map.put(userId, "blocked", true)
        else
          Map.put(userId, "blocked", false)
        end
      end
    else
      usersWithTeam
    end
    # convert teamList to map
    usersWithTeamList = for teams <- usersWithTeam do
      #IO.puts "#{hd(teams["teams"])}"
      Map.put(teams, "teams", hd(teams["teams"]))
    end
    # get all userIds in list
    userIds = for userId <- usersWithTeamList do
      [] ++ userId["userId"]
    end
    # 2. Now get user details from user_col
    userDetailsList = TeamRepo.getUserDetailsForTeam(userIds)
    # Now merge two lists based on _id and userId
    Enum.map(usersWithTeamList, fn k ->
      userWithTeamMap = Enum.find(userDetailsList, fn v -> v["_id"] == k["userId"] end)
      if userWithTeamMap do
        Map.merge(k, userWithTeamMap)
      end
    end)
  end



  def getAttendanceList(conn, group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    loginUser = Guardian.Plug.current_resource(conn)
    user = TeamRepo.getAttendanceList(loginUser["_id"], groupObjectId, teamObjectId)
    user
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end



  def getIndividualStudentAttendanceReport(_conn, group_id, team_id, user_id, rollNumber, month, year) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    studentObjectId = decode_object_id(user_id)
    TeamRepo.getIndividualStudentAttendanceReport(groupObjectId, teamObjectId, studentObjectId, month, year, rollNumber)
  end



  def updateAttendanceReport(studentsList, groupObjectId, teamObjectId) do
    absentStudentIds = studentsList["userObjectId"]
    rollNumbers = studentsList["rollNumber"]
    #convert to ISO Date and get all parameters of date
    currentTime = bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    time = DateTime.to_time(datetime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                     "minute" => datetime.minute,"seconds" => datetime.second}
    if to_string(time) < "06:30:00.000000" do
      #morning attendance
      #first check morning attendance already taken for this day
      checkMorningAttendanceAlreadyCount = TeamRepo.checkMorningAttendanceAlreadyTaken(groupObjectId, teamObjectId, dateTimeMap)
      if checkMorningAttendanceAlreadyCount > 0 do
        #already taken. so, just update
        TeamRepo.updateMorningAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
      else
        #push newly
        TeamRepo.pushMorningAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
      end
    else
      #afternoon attendance
      #first check afternoon attendance already taken for this day
      checkAfrenoonAttendanceAlreadyCount = TeamRepo.checkAfternoonAttendanceAlreadyTaken(groupObjectId, teamObjectId, dateTimeMap)
      if checkAfrenoonAttendanceAlreadyCount > 0 do
        #already taken. so, just update
        TeamRepo.updateAfternoonAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
      else
        #push newly
        TeamRepo.pushAfternoonAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
      end
    end
  end



  def findStudentByIdAndrollNumberForAttendance(studentsList, groupObjectId, teamObjectId) do
    absentStudentIds = studentsList["userObjectId"]
    rollNumbers = studentsList["rollNumber"]
    TeamRepo.findStudentByIdAndrollNumberForAttendance(absentStudentIds, rollNumbers, groupObjectId, teamObjectId)
  end

  def findStudentByIdForAttendance(absentStudentObjectIds, groupObjectId, teamObjectId) do
    TeamRepo.findStudentByIdForAttendance(absentStudentObjectIds, groupObjectId, teamObjectId)
  end



  def addStudentIn(groupObjectId, teamObjectId, userObjectId, rollNumber) do
    #convert to ISO Date and get all parameters of date
    currentTime = bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                     "minute" => datetime.minute,"seconds" => datetime.second}
    #find alrady attendance taken for this kid
    {:ok, alreadyCount} = TeamRepo.findKidAttendanceINAlreadyTaken(groupObjectId, teamObjectId, userObjectId, rollNumber, dateTimeMap)
    if alreadyCount > 0 do
      #already taken so just update time
      ####################################################################################################
      {:ok, "created"}
    else
      #push status for new day (1st time attendance in a day)
      TeamRepo.addStudentIn(groupObjectId, teamObjectId, userObjectId, rollNumber, currentTime, dateTimeMap)
    end
  end


  def addStudentOut(groupObjectId, teamObjectId, userObjectId, rollNumber) do
    #convert to ISO Date and get all parameters of date
    currentTime = bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                     "minute" => datetime.minute,"seconds" => datetime.second}
    #find alrady attendance taken for this kid
    {:ok, alreadyCount} = TeamRepo.findKidAttendanceOUTAlreadyTaken(groupObjectId, teamObjectId, userObjectId, rollNumber, dateTimeMap)
    if alreadyCount > 0 do
      #already taken so just update time
      ####################################################################################################
      {:ok, "created"}
    else
      #push status for new day (1st time attendance in a day)
      TeamRepo.addStudentOut(groupObjectId, teamObjectId, userObjectId, rollNumber, currentTime, dateTimeMap)
    end
  end




  def getCreatedTeamsForThisUser(groupObjectId, user_id) do
    userObjectId = decode_object_id(user_id)
    TeamRepo.getMyTeams(groupObjectId, userObjectId)
  end




  defp checkStudentExistInUserDoc(changeset, group, teamObjectId) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) < 1 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      UserRepo.addUserToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
      userRegisterToUserDoc["_id"]
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in team
        {:ok, teamUserCount} = TeamRepo.isTeamMemberByUserId(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamUserCount < 1 do
          #user already in group / Just push new team for the user
          UserRepo.addNewTeamForUserInGroup(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
        end
      else
        #add new doc to group_team_members because he is new user to group
        UserRepo.addUserToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
      end
      hd(userAlreadyExistInUserDoc)["_id"]
    end
  end



  defp checkStudentExistInUserDocBus(changeset, group, teamObjectId) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) < 1 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      UserRepo.addUserToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in team
        {:ok, teamUserCount} = TeamRepo.isTeamMemberByUserId(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamUserCount < 1 do
          #user already in group / Just push new team for the user
          UserRepo.addNewTeamForUserInGroup(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
        end
      else
        #add new doc to group_team_members because he is new user to group
        UserRepo.addUserToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
      end
    end
  end



end
