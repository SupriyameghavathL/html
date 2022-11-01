defmodule GruppieWeb.Repo.AdminRepo do

  @conn :mongo

  @view_group_team_members_col "VW_GROUP_TEAM_MEMBERS"

  @group_col "groups"

  @users_col "users"

  @user_category_apps_col "user_category_apps"

  @view_teams_details_col "VW_TEAMS_DETAILS"

  @group_team_members_col "group_team_members"

  @student_database_col "student_database"

  @staff_database_col "staff_database"

  @subject_staff_database_col "subject_staff_database"

  @view_teams_col "VW_TEAMS"

  @fee_db "school_fees_database"


  @doc """
  find count based on query
  """
  def findGroupAdmin(userObjectId, groupObjectId) do
    filter = %{"_id" => groupObjectId, "adminId" => userObjectId}
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_col, filter, [projection: project])
  end



  def getAllUsersOfGroup(query_params, groupObjectId, loginUserId, limit) do
    filter = %{ "groupId" => groupObjectId, "userId" => %{ "$nin" => [loginUserId] }}
    project = %{ "userId" => 1, "name" => "$$CURRENT.userDetails.name",
                "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image"}
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"name" => 1}}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_group_team_members_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"name" => 1}} ]
      Mongo.aggregate(@conn, @view_group_team_members_col, pipeline)
    end
  end


  #from view
  def checkUserAllowedToPost(userObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId, "canPost" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end

  #from view
  def getAllUsersOfGroupLength(groupObjectId, loginUserId) do
    filter = %{ "groupId" => groupObjectId, "userId" => %{ "$nin" => [loginUserId] }}
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end


  def allowUserToAddGroupPost(groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    update = %{ "$set" => %{ "canPost" => true } }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end


  def removeUserToAddGroupPost(groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    update = %{ "$set" => %{ "canPost" => false } }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end


  def removeUserFromGroupByAdmin(groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    Mongo.delete_one(@conn, @group_team_members_col, filter)
  end


  def removeGroupAvatar(group) do
    filter = %{ "_id" => group["_id"] }
    update = %{"$unset" => %{ "avatar" => group["avatar"] }}
    Mongo.update_one(@conn, @group_col, filter, update)
  end


  def getAllAuthorisedUsersList(query_params, loginUserId, groupObjectId, limit) do
    filter = %{ "groupId" => groupObjectId, "canPost" => true, "userId" => %{"$nin" => [loginUserId]} }
    project = %{ "userId" => 1, "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image" }
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"name" => 1}}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_group_team_members_col, pipeline)
    else
      pipeline = [%{"$match" => filter},%{"$project" => project}, %{"$sort" => %{"name" => 1}}]
      Mongo.aggregate(@conn, @view_group_team_members_col, pipeline)
    end
  end


  def getAllAuthorisedUsersListLength(loginUserId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => %{"$nin" => [loginUserId]}, "canPost" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end


  def changeGroupAdmin(loginUserId, groupObjectId, userObjectId) do
    #first update in group collection 'adminId'
    filter = %{ "adminId" => loginUserId, "_id" => groupObjectId, "isActive" => true }
    update = %{ "$set" => %{ "adminId" => userObjectId } }
    Mongo.update_one(@conn, @group_col, filter, update)

    #update in group_team_members (isAdmin = true, adminId = userObjectId)
    filterUpdate = %{ "groupId" => groupObjectId, "userId" => userObjectId, "isActive" => true }
    updateGTM = %{ "$set" => %{ "isAdmin" => true, "canPost" => true } }
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, updateGTM)

    #update of old admin (isAdmin = false, canPost = false)
    filterUpdate1 = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    updateGTM1 = %{ "$set" => %{ "isAdmin" => false, "canPost" => false } }
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate1, updateGTM1)
  end


  #get list of classes in student register
  def getClassesForAdmin(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "class" => true, "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "gruppieClassName" => 1,
                 "adminName" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone",
                 "subjectId" => 1, "ebookId" => 1, "zoomKey" => 1, "zoomSecret" => 1}
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
    Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
  end



  #get list of classes in student register
  def getBusesForAdmin(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "bus" => true, "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "adminName" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone" }
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "name" => 1 } }]
    Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
  end


  def findStaffAleadyExist(groupObjectId, staffId) do
    filter = %{ "groupId" => groupObjectId, "userId" => staffId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @staff_database_col, filter, [projection: project])
  end


  def addStaffToDatabase(groupObjectId, changeset, staffId) do
    #check this staff is soft deleted before
    {:ok, checkStaffExist} = checkStaffAlreadyDeleted(groupObjectId, staffId)
    if checkStaffExist == 0 do
      #insert newly
      final_map = Map.delete(changeset, :phone)
      |>Map.put(:userId, staffId)
      |>Map.put(:groupId, groupObjectId)
      Mongo.insert_one(@conn, @staff_database_col, final_map)
    else
      #update isActive: true
      filter = %{
        "groupId" => groupObjectId,
        "userId" => staffId
      }
      update = %{"$set" => %{"isActive" => true}}
      Mongo.update_one(@conn, @staff_database_col, filter, update)
    end
  end

  defp checkStaffAlreadyDeleted(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => false
    }
    Mongo.count(@conn, @staff_database_col, filter)
  end


  def checkStudentAlreadyExistInClass(groupObjectId, teamObjectId, studentUserId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => studentUserId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @student_database_col, filter, [projection: project])
  end



  def addStudentToDatabase(groupObjectId, teamObjectId, changeset, studentId) do
    final_map = Map.delete(changeset, :phone)
                  |>Map.put(:userId, studentId)
                  |>Map.put(:groupId, groupObjectId)
                  |>Map.put(:teamId, teamObjectId)
                  |>Map.put(:attendance, [])
                  |>Map.put(:marksCard, [])
    Mongo.insert_one(@conn, @student_database_col, final_map)
  end



  #get students count in student register
  def getTotalStudentsCountInStudentRegister(teamObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @student_database_col, filter, [projection: project])
  end


  #def getClassStudents123(groupObjectId, teamObjectId) do
  #  filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId }
  #  pipeline = [%{ "$match" => filter }]
  #  Mongo.aggregate(@conn, @view_student_db, pipeline)
  #end


  def getClassStudents(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    Mongo.find(@conn, @student_database_col, filter)
    |>Enum.to_list
  end

  def getClassStudentsForMarkscard(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    project = %{"_id" => 0, "userId" => 1, "name" => 1, "image" => 1, "rollNumber" => 1}
    Mongo.find(@conn, @student_database_col, filter, [projection: project])
    |>Enum.to_list
  end


  def getUserPhoneDetailFromUsersCol(userObjectId) do
    filter = %{
      "_id" => userObjectId
    }
    project = %{"_id" => 0, "phone" => 1}
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end


  def getIsAccountant(groupObjectId, userObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "accountantIds.userId" => userObjectId,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_col, filter, [projection: project])
  end


  def getIsExaminer(groupObjectId, userObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "examinerIds.userId" => userObjectId,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_col, filter, [projection: project])
  end


  def getStudentInUserCategoryApps(userObjectId, appCategory) do
    filter = %{
      "userId" => userObjectId,
      "category" => appCategory,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_apps_col, filter, [projection: project])
  end



  def getBusStudents(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "teams.isTeamAdmin" => false }
    project = %{ "_id" => 0, "userId" => 1, "name" => "$$CURRENT.userDetails.name",
              "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image" }
    pipeline = [%{ "$match" => filter}, %{"$project" => project }]
    Mongo.aggregate(@conn, @view_teams_col, pipeline)
  end


  def updateStaffDetailsInDB(changeset, groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    update = %{ "$set" => changeset }
    Mongo.update_one(@conn, @staff_database_col, filter, update)
  end


  def updateStudentStaffPhoneNumber(userObjectId, changesetPhone) do
    filter = %{
      "_id" => userObjectId
    }
    #update phone in users_col
    update = %{"$set" => changesetPhone}
    Mongo.update_one(@conn, @users_col, filter, update)
    #remove other accounts from user_category_apps for this old phone userId
    filterRemove = %{
      "userId" => userObjectId
    }
    Mongo.delete_many(@conn, @user_category_apps_col, filterRemove)
  end



  def updateStudentDetailsInDB(changeset, groupObjectId, teamObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "isActive" => true }
    update = %{ "$set" => changeset }
    Mongo.update_one(@conn, @student_database_col, filter, update)
  end


  def getStaffId(groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    project = %{"_id" => 1}
    Mongo.find(@conn, @staff_database_col, filter, [projection: project])
    |> Enum.to_list
    |> hd
  end


  def removeStaffFromSubjectStaffRegister(groupObjectId, staffUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    update = %{"$pull" => %{ "staffId" => staffUserId }}
    Mongo.update_many(@conn, @subject_staff_database_col, filter, update)
  end

  def removeAllTeamsForStaffRemoved(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"teams" => []}}
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end



  def removeStaff(groupObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    update = %{ "$set" => %{"isActive" => false} }
    Mongo.update_one(@conn, @staff_database_col, filter, update)
  end



  def removeStudent(groupObjectId, teamObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId }
    update = %{ "$set" => %{"isActive" => false} }
    Mongo.update_many(@conn, @student_database_col, filter, update)
  end


  def removeStudentFromFeeDB(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
    }
    update = %{
      "$set" => %{
        "isActive" => false
      }
    }
    Mongo.update_one(@conn, @fee_db, filter, update)
  end

  #constituency user installed application check
  def getUserInUserCategoryApps(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "constituencyName" => %{
        "$exists" => true,
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @user_category_apps_col, filter, [projection: project])
  end
end
