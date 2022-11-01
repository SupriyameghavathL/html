defmodule GruppieWeb.Handler.AdminHandler do
  alias GruppieWeb.Repo.AdminRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupMembershipRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.User
  alias GruppieWeb.Handler.TeamSettingsHandler
  import GruppieWeb.Repo.RepoHelper


  def getAllUsersOfGroup(query_params, groupObjectId, loginUserId, limit) do
    userList = AdminRepo.getAllUsersOfGroup(query_params, groupObjectId, loginUserId, limit)
    userList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def allowPost(group_id, user_id) do
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.allowUserToAddGroupPost(groupObjectId, userObjectId)
    #check authorizedToAdmin event is already exist
    {:ok, authorizedToAdminEvent} = GroupRepo.checkAuthorizedToAdminEvent(groupObjectId, userObjectId)
    if authorizedToAdminEvent > 0 do
      #already exist. So, update
      GroupRepo.updateAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
    else
      #add authorizedToAdmin event for this user
      GroupRepo.addAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
    end
  end


  def removePost(group_id, user_id) do
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.removeUserToAddGroupPost(groupObjectId, userObjectId)
    #check authorizedToAdmin event is already exist
    {:ok, authorizedToAdminEvent} = GroupRepo.checkAuthorizedToAdminEvent(groupObjectId, userObjectId)
    if authorizedToAdminEvent > 0 do
      #already exist. So, update
      GroupRepo.updateAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
    else
      #add authorizedToAdmin event for this user
      GroupRepo.addAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
    end
  end


  def deleteUserFromGroupByAdmin(group_id, user_id) do
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.removeUserFromGroupByAdmin(groupObjectId, userObjectId)
  end


  def removeGroupAvatar(group) do
    AdminRepo.removeGroupAvatar(group)
  end


  def getAllAuthorisedUsersList(query_params, loginUserId, groupObjectId, limit) do
    AdminRepo.getAllAuthorisedUsersList(query_params, loginUserId, groupObjectId, limit)
  end


  def changeGroupAdmin(conn, group_id, user_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.changeGroupAdmin(loginUser["_id"], groupObjectId, userObjectId)
  end


  def addTeacherToUserTableIfNotExist(changeset, group) do
    #check user exist in user doc by phone
    checkUserExist = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExist) > 0 do
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(checkUserExist)["_id"], group["_id"])
      if count < 1 do
        #insert to group_team_members
        GroupMembershipRepo.joinUserToGroup(hd(checkUserExist)["_id"], group["_id"])
        hd(checkUserExist)
      else
        hd(checkUserExist)
      end
    else
      #add user to uer doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      GroupMembershipRepo.joinUserToGroup(userRegisterToUserDoc["_id"], group["_id"])
      userRegisterToUserDoc
    end
  end



  def addDriverToUserTableIfNotExist(changeset, group) do
    #check user exist in user doc by phone
    checkUserExist = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExist) > 0 do
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(checkUserExist)["_id"], group["_id"])
      if count < 1 do
        #insert to group_team_members
        GroupMembershipRepo.joinUserToGroup(hd(checkUserExist)["_id"], group["_id"])
        hd(checkUserExist)
      else
        hd(checkUserExist)
      end
    else
      #add user to uer doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      GroupMembershipRepo.joinUserToGroup(userRegisterToUserDoc["_id"], group["_id"])
      userRegisterToUserDoc
    end
  end


  def getClasses(groupObjectId) do
    #get class teams of this group
    AdminRepo.getClassesForAdmin(groupObjectId)
  end



  def getBuses(groupObjectId) do
    #get class teams of this group
    AdminRepo.getBusesForAdmin(groupObjectId)
  end

  def addStaffToDatabaseSingle(conn, addedStaffId, group) do
    parameters = conn.params
    changeset = User.addStaffToDB(%User{}, parameters)
    #find staf already added to db
    {:ok, staffAlready} = AdminRepo.findStaffAleadyExist(group["_id"], addedStaffId)
    if staffAlready > 0 do
      #staff already exist
      {:staffError, "Staff Already Exist"}
    else
      #add to staff db
      AdminRepo.addStaffToDatabase(group["_id"], changeset.changes, addedStaffId)
    end
  end


  def addStaffToDatabase(parameters, addedStaffId, group) do
    #parameters = conn.params
    changeset = User.addStaffToDB(%User{}, parameters)
    #find staf already added to db
    {:ok, staffAlready} = AdminRepo.findStaffAleadyExist(group["_id"], addedStaffId)
    if staffAlready > 0 do
      #staff already exist
      {:staffError, "Staff Already Exist"}
    else
      #add to staff db
      AdminRepo.addStaffToDatabase(group["_id"], changeset.changes, addedStaffId)
    end
  end



  def addStudentToDatabase(conn, addedStudentId, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    parameters = conn.params
    changeset = User.addStudentToDB(%User{}, parameters)
    #first check this student is already inside class from student register
    {:ok, checkStudentAlreadyExistInClass} = AdminRepo.checkStudentAlreadyExistInClass(group["_id"], teamObjectId, addedStudentId)
    if checkStudentAlreadyExistInClass > 0 do
      #already exist
      {:ok, "already exist"}
    else
      #add to student database
      AdminRepo.addStudentToDatabase(group["_id"], teamObjectId, changeset.changes, addedStudentId)
    end
  end



  def getClassStudents(group, team_id) do
    teamObjectId = decode_object_id(team_id)
    studentsList = AdminRepo.getClassStudents(group["_id"], teamObjectId)
    studentsList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def getClassStudentsForMarkscard(group, team_id) do
    teamObjectId = decode_object_id(team_id)
    studentsList = AdminRepo.getClassStudentsForMarkscard(group["_id"], teamObjectId)
    studentsList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def getBusStudents(group, team_id) do
    teamObjectId = decode_object_id(team_id)
    students = AdminRepo.getBusStudents(group["_id"], teamObjectId)
    students
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def updateStaffDetailsInDB(changeset, groupObjectId, user_id) do
    userObjectId = decode_object_id(user_id)
    AdminRepo.updateStaffDetailsInDB(changeset, groupObjectId, userObjectId)
  end


  def updateStudentStaffPhoneNumber(changesetPhone, user_id) do
    userObjectId = decode_object_id(user_id)
    AdminRepo.updateStudentStaffPhoneNumber(userObjectId, changesetPhone)
  end



  def updateStudentDetailsInDB(changeset, groupObjectId, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.updateStudentDetailsInDB(changeset, groupObjectId, teamObjectId, userObjectId)
  end


  def removeStaffFromDB123(groupObjectId, user_id) do
    userObjectId = decode_object_id(user_id)
    #get staffId and check this staff is registered to subjects
    getStaffId = AdminRepo.getStaffId(groupObjectId, userObjectId)
    if getStaffId do
      staffDbId = encode_object_id(getStaffId["_id"])
      #pull this staff from subject_staff_register
      AdminRepo.removeStaffFromSubjectStaffRegister(groupObjectId, staffDbId)
    end
    #remove staff from staf_database (staff register)
    AdminRepo.removeStaff(groupObjectId, userObjectId)
  end


  def removeStaffFromDB(groupObjectId, user_id) do
    userObjectId = decode_object_id(user_id)
    #get staffId and check this staff is registered to subjects
    #1. pull this staff from subject_staff_register
    AdminRepo.removeStaffFromSubjectStaffRegister(groupObjectId, user_id)
    #2. Remove all teams from group_team_members
    AdminRepo.removeAllTeamsForStaffRemoved(groupObjectId, userObjectId)
    #3. remove staff from staf_database (staff register)
    AdminRepo.removeStaff(groupObjectId, userObjectId)
  end


  def removeStudentFromDB(group, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #remove student from stuen
    AdminRepo.removeStudent(group["_id"], teamObjectId, userObjectId)
    #remove user from team as well when removed from student register
    TeamSettingsHandler.removeTeamUser(group, team_id, user_id)
  end


  def removeStudentFromFeeDB(groupObjectId, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    AdminRepo.removeStudentFromFeeDB(groupObjectId, teamObjectId, userObjectId)
  end



end
