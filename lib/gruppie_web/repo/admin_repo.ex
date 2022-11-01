defmodule GruppieWeb.Repo.AdminRepo do


  @conn :mongo

  # @view_group_team_members_col "VW_GROUP_TEAM_MEMBERS"

  @group_col "groups"

  @users_col "users"

  @user_category_apps_col "user_category_apps"

  @view_teams_details_col "VW_TEAMS_DETAILS"

  @group_team_members_col "group_team_members"

  @student_database_col "student_database"

  # @staff_database_col "staff_database"

  # @subject_staff_database_col "subject_staff_database"

  # @view_teams_col "VW_TEAMS"

  # @view_student_db "VW_STUDENT_DB"

  # @fee_db "school_fees_database"



  def findGroupAdmin(userObjectId, groupObjectId) do
    filter = %{"_id" => groupObjectId, "adminId" => userObjectId}
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_col, filter, [projection: project])
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


  #constituency user installed application check
  def getUserInUserCategoryApps(userObjectId, _groupObjectId) do
    filter = %{
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


  #get list of classes in student register
  def getClassesForAdmin(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "class" => true, "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "gruppieClassName" => 1,
                 "adminName" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone",
                 "subjectId" => 1, "ebookId" => 1, "zoomKey" => 1, "zoomSecret" => 1}
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
    Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
  end


  def getClassStudents(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    Mongo.find(@conn, @student_database_col, filter)
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


  #from view
  def checkUserAllowedToPost(userObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId, "canPost" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end


  #get students count in student register
  def getTotalStudentsCountInStudentRegister(teamObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @student_database_col, filter, [projection: project])
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


end
