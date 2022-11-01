defmodule GruppieWeb.Repo.GroupRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.GroupMembership
  alias GruppieWeb.Repo.TeamRepo

  @conn :mongo

  @group_coll "groups"

  @group_team_members_coll "group_team_members"

  @view_group_team_members_coll "VW_GROUP_TEAM_MEMBERS"

  @view_teams_coll "VW_TEAMS"

  @teams_col "teams"

  @group_action_events_col "group_action_events"

  @subject_staff_db_col "subject_staff_database"

  @user_category_app_col "user_category_apps"

  @saved_notifications_col "saved_notifications"

  @view_group_teams_col "VW_GROUP_TEAMS"

  @staff_db_col "staff_database"

  @student_db_col "student_database"

  @users_coll "users"

  @post_coll "posts"

  @panchayat_coll "panchayat_database"


  def insert(changeset, login_user) do
    object_id = new_object_id()
    #insert to groups doc
    final_group_map = changeset
                          |>update_map_with_key_value(:_id, object_id)
                          |>update_map_with_key_value(:adminId, login_user["_id"])
    # update constituencyApp = true
    final_group_map = if Map.has_key?(changeset, :constituencyName) do
      Map.put_new(final_group_map, :constituencyApp, true)
    else
      final_group_map
    end
    final_group_map = if changeset.category == "community" do
      #append id for the user
      appendIdForAdmin(login_user["_id"], changeset)
      Map.put(final_group_map, :idGenerationNo, 1)
    else
      final_group_map
    end
    Mongo.insert_one(@conn, @group_coll, final_group_map)
    #insert to group_team_members doc
    group_member_doc = GroupMembership.insertGroupMemberWhileGroupCreate(changeset, login_user, final_group_map)
    insert = Mongo.insert_one(@conn, @group_team_members_coll, group_member_doc)
    #create default team if group category is not school and corporate
    if Map.has_key?(changeset, :category) do
      if changeset.category == "school" || changeset.category == "corporate" do
        insert
      else
        if changeset.category == "community" do
          #create default team
          getCurrentTime = bson_time()
          teamChangeset = %{ name: login_user["name"], image: login_user["image"], insertedAt: getCurrentTime, updatedAt: getCurrentTime, defaultTeam: true }
          TeamRepo.createTeam(login_user, teamChangeset, object_id)
        else
          #create default team
          getCurrentTime = bson_time()
          teamChangeset = %{ name: login_user["name"], image: login_user["image"], insertedAt: getCurrentTime, updatedAt: getCurrentTime }
          TeamRepo.createTeam(login_user, teamChangeset, object_id)
        end
      end
    else
      #create default team
      getCurrentTime = bson_time()
      teamChangeset = %{ name: login_user["name"], image: login_user["image"], insertedAt: getCurrentTime, updatedAt: getCurrentTime }
      TeamRepo.createTeam(login_user, teamChangeset, object_id)
    end
  end


  def  appendIdForAdmin(userObjectId, changeset) do
    filter = %{
      "_id" => userObjectId
    }
    update = %{
      "$set" => %{
        "userCommunityId" => changeset.name<>"001"
      }
    }
    Mongo.update_one(@conn, @users_coll, filter, update)
  end



  def getAll(logged_in_user) do
    filter_doc = %{ "userId" => logged_in_user["_id"], "isActive" => true, "groupDetails.isActive" => true  }
    project_doc = %{ "_id" => 0, "teams" => 0, "groupPostLastSeen" => 0, "insertedAt" => 0, "updatedAt" => 0, "isActive" => 0, "groupDetails.adminId" => 0,
                    "groupDetails.insertedAt" => 0, "groupDetails.updatedAt" => 0, "groupDetails.isActive" => 0, "groupDetails._id" => 0}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$sort" => %{"groupDetails.place" => -1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline))
  end


  def getCategoryGroups(logged_in_user, category) do
    filter_doc = %{ "userId" => logged_in_user["_id"], "isActive" => true, "groupDetails.category" => category, "groupDetails.isActive" => true  }
    project_doc = %{ "_id" => 0, "teams" => 0, "groupPostLastSeen" => 0, "insertedAt" => 0, "updatedAt" => 0, "isActive" => 0, "groupDetails.adminId" => 0,
                    "groupDetails.insertedAt" => 0, "groupDetails.updatedAt" => 0, "groupDetails.isActive" => 0, "groupDetails._id" => 0}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$sort" => %{"groupDetails.place" => -1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline))
  end


  def getCategoryGroupsByAppName(logged_in_user, category, appName) do
    filter_doc = %{ "userId" => logged_in_user["_id"], "isActive" => true, "groupDetails.category" => category, "groupDetails.appName" => appName, "groupDetails.isActive" => true }
    project_doc = %{ "_id" => 0, "teams" => 0, "groupPostLastSeen" => 0, "insertedAt" => 0, "updatedAt" => 0, "isActive" => 0, "groupDetails.adminId" => 0,
                    "groupDetails.insertedAt" => 0, "groupDetails.updatedAt" => 0, "groupDetails.isActive" => 0, "groupDetails._id" => 0}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$sort" => %{"groupDetails.place" => -1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline))
  end


  def getCategoryGroupsByTalukName(logged_in_user, category, talukName) do
    filter_doc = %{ "userId" => logged_in_user["_id"], "isActive" => true, "groupDetails.category" => category, "groupDetails.taluk" => talukName, "groupDetails.isActive" => true  }
    project_doc = %{ "_id" => 0, "teams" => 0, "groupPostLastSeen" => 0, "insertedAt" => 0, "updatedAt" => 0, "isActive" => 0, "groupDetails.adminId" => 0,
                    "groupDetails.insertedAt" => 0, "groupDetails.updatedAt" => 0, "groupDetails.isActive" => 0, "groupDetails._id" => 0}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$sort" => %{"groupDetails.place" => -1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline))
  end


  def getCategoryGroupsByConstituencyCategoryName(logged_in_user, category, constituency_CategoryName) do
    filter_doc = %{ "userId" => logged_in_user["_id"], "isActive" => true, "groupDetails.category" => category, "groupDetails.categoryName" => constituency_CategoryName, "groupDetails.isActive" => true  }
    #IO.puts "#{filter_doc}"
    project_doc = %{ "_id" => 0, "teams" => 0, "groupPostLastSeen" => 0, "insertedAt" => 0, "updatedAt" => 0, "isActive" => 0, "groupDetails.adminId" => 0,
                    "groupDetails.insertedAt" => 0, "groupDetails.updatedAt" => 0, "groupDetails.isActive" => 0, "groupDetails._id" => 0}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$sort" => %{"groupDetails.place" => -1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline))
  end



  def get(groupId) do
    groupObjectId = decode_object_id(groupId)
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    projection =  %{ "updated_at" => 0 }
    #hd(Enum.to_list(Mongo.find(@conn, @group_coll, filter, [ projection: projection ])))
    Mongo.find(@conn, @group_coll, filter, [ projection: projection ])
    |> Enum.to_list
    |> hd
  end



  def getTotalUsersCount(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end



  #get total posts count in this group for about group response
  def getTotalPostsCount(groupObjectId) do
    filter = %{ "groupId" => groupObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, "group_posts", filter, [projection: project])
  end


  def checkUserCanPostInGroup(group_object_id, login_user_id) do
    filter = %{ "groupId" => group_object_id, "userId" => login_user_id, "isActive" => true }
    project = %{ "_id" => 0, "canPost" => 1 }
    hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filter, [ projection: project ])))
  end


  def checkIsAccountant(groupObjectId, userObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "accountantIds.userId" => userObjectId,
      "isActive" => true,
    }
    Mongo.count(@conn, @group_coll, filter)
  end


  def checkIsExaminer(groupObjectId, userObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "examinerIds.userId" => userObjectId,
      "isActive" => true,
    }
    Mongo.count(@conn, @group_coll, filter)
  end


  def checkIsTeacher(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1
    }
    Mongo.find_one(@conn, @staff_db_col, filter, [projection: project])
  end


  def checkIsStudent(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1
    }
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
  end



  def update(changeset, groupObjectId) do
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    update = %{ "$set" => changeset }
    Mongo.find_one_and_update(@conn, @group_coll, filter, update)
  end

  def updateConstituencyBannerToGroup(changeset, groupObjectId) do
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    update = %{ "$set" => changeset }
    Mongo.update_one(@conn, @group_coll, filter, update)
  end


  def delete(groupObjectId) do
    filter = %{ "groupId" => groupObjectId }
    Mongo.delete_one(@conn, @group_team_members_coll, filter)
    Mongo.delete_one(@conn, @group_coll, %{ "_id" => groupObjectId })
  end


  def checkUserAlreadyInGroup(userObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def checkUserAlreadyInTeam(userObjectId, groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId, "teams.teamId" => teamObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end



  def checkUserIsAllowedToAdd(loginUserId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId,
               "teamDetails.adminId" => %{ "$nin" => [loginUserId] }, "teams.allowedToAddUser" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end


  def checkLoginUserIsBoothPresident(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "booth",
      #"booth" => true,
      "isActive" => true
    }
    project = %{"_id" => 1, "name" => 1}
    #Mongo.count(@conn, @teams_col, filter)
    Mongo.find(@conn, @teams_col, filter, [projection: project])
    |> Enum.to_list
  end


  def checkLoginUserIsBoothPresidentForEvent(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @teams_col, filter, [projection: project])
    #Mongo.find_one(@conn, @teams_col, filter, [projection: project])
    #|>Enum.to_list
  end


  #########*************Event Action queries*****************#############
  def getLoginUserDashboardTeamcounts123(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true
    }
    project = %{"_id" => 0, "teams" => 1}
    teamsList = Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list()
    {:ok, length(hd(teamsList)["teams"])}
  end

  def getLoginUserDashboardTeamcounts(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true,
      "teamDetails.isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end


  def getLoginUserLiveClassTeamsCount(loginUserId, groupObjectId) do
    #get ;list of teams for login user where zoomKey exist teams
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true,
      "teamDetails.isActive" => true,
      "teamDetails.zoomKey" => %{
        "$exists" => true
      }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end


  def getLoginUserClassTeamsCount(loginUserId, groupObjectId) do
    #check login user is admin/authorized user to get list of all class team count
    {:ok, checkAdminOrAuthorizedUser} = checkLoginUserIsAdminOrAuthorizedUser(groupObjectId, loginUserId)
    if checkAdminOrAuthorizedUser > 0 do
      #get ;list of all class teams for admin/authorized user user where zoomKey exist teams
      filter = %{
        "groupId" => groupObjectId,
        "isActive" => true,
        "class" => true
      }
      project = %{"_id" => 1}
      Mongo.count(@conn, @teams_col, filter, [projection: project])
    else
      #get ;list of teams for login user where zoomKey exist teams
      filter = %{
        "groupId" => groupObjectId,
        "userId" => loginUserId,
        "isActive" => true,
        "teamDetails.class" => true
      }
      project = %{"_id" => 1}
      Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
    end
  end


  def getSchoolGroupCountForLoginUser(loginUserId) do
    filter = %{
      "userId" => loginUserId,
      "groupDetails.category" => "school",
      "groupDetails.isActive" => true,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_group_team_members_coll, filter, [projection: project])
  end



  def checkLoginUserIsAdminOrAuthorizedUser(group_object_id, login_user_id) do
    filter = %{ "groupId" => group_object_id, "userId" => login_user_id, "canPost" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end




  def getEventsListForSchoolGroup(groupObjectId, loginUserId) do
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], %{"teamIds" => [], "subjectCountForClass" => []}, fn k, acc ->
      #get each teams/class subjects count
      filterSubjectCount = %{
        "groupId" => groupObjectId,
        "teamId" => k["teamId"],
        "isActive" => true
      }
      project = %{"_id" => 1}
      #get subject count for each team
      {:ok, subjectCount} = Mongo.count(@conn, @subject_staff_db_col, filterSubjectCount, [projection: project])
      subjectCountForClass = acc["subjectCountForClass"] ++ [%{"subjectCount" => subjectCount, "teamId" => encode_object_id(k["teamId"])}]
      teamIdsList = acc["teamIds"] ++ [k["teamId"]]
      %{"teamIds" => teamIdsList, "subjectCountForClass" => subjectCountForClass}
    end)
    #IO.puts "#{teamIdList}"
    filter = %{
      "$or" => [
        %{"groupId" => groupObjectId, "eventType" => 1},
        %{"groupId" => groupObjectId, "userId" => loginUserId, "eventType" => 5},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList["teamIds"]}, "eventType" => %{"$in" => [3,4,6]}},
        ####%{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList["teamIds"]}, "eventType" => 4},
      ]
    }
    #events list from group_action_events_col
    eventsList = Enum.to_list(Mongo.find(@conn, @group_action_events_col, filter))
    #subject count list for teams
    subjectCountList = teamIdList["subjectCountForClass"]
    [%{"eventsList" => eventsList}] ++ [%{"subjectCount" => subjectCountList}]
  end


  def getLiveClassEventsListForGroup(groupObjectId, loginUserId) do
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    #IO.puts "#{teamIdList}"
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => %{"$in" => teamIdList},
      "eventType" => 7
    }
    #events list from group_action_events_col
    Enum.to_list(Mongo.find(@conn, @group_action_events_col, filter))
  end


  def getLiveTestExamEventsListForGroup(groupObjectId, loginUserId) do
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    #IO.puts "#{teamIdList}"
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => %{"$in" => teamIdList},
      "eventType" => 8
    }
    #events list from group_action_events_col
    Enum.to_list(Mongo.find(@conn, @group_action_events_col, filter))
  end



  def getLoginUserLastInsertedTeamTime(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true
    }
    projectTeam = %{ "_id" => 0, "teams.updatedAt" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filter, [projection: projectTeam])))
    teamLastInsertedAtList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["updatedAt"]]
    end)
    if length(teamLastInsertedAtList) > 0 do
      #return maximum date-time from list
      Enum.max(teamLastInsertedAtList)
    else
      bson_time()
    end
  end



  def getLoginUserLastInsertedTeamTime1234(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true
    }
    projectTeam = %{ "_id" => 0, "teams.updatedAt" => 1 }
    Mongo.find(@conn, @view_group_teams_col, filter, [projection: projectTeam, sort: %{"teams.updatedAt" => -1}, limit: 1])
    |> Enum.to_list
  end



  #get all teamIds of user in group
  def getUserTeamIds(groupObjectId, userObjectId) do
    filterTeam = %{ "groupId" => groupObjectId, "userId" => userObjectId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    #teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teams = Mongo.find_one(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])
    Enum.reduce(teams["teams"], [], fn k, acc ->
      if k["teamId"] != nil do
        #check team is active or not
        team = TeamRepo.get(encode_object_id(k["teamId"]))
        if team != [] do
          acc ++ [k["teamId"]]
        else
          acc ++ []
        end
      else
        acc ++ []
      end
    end)
  end


  def getAllActiveIdsOfTeam(userTeamIds) do
    filter = %{
      "_id" => %{"$in" => userTeamIds},
      "isActive" => true
    }
    project = %{"_id" => 1}
    teamsActive = Enum.to_list(Mongo.find(@conn, @teams_col, filter, [projection: project]))
    Enum.reduce(teamsActive, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
  end



  def getLatesNotificationUpdatedAtTime123(groupObjectId, loginUserId, userTeamIdList) do
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => userTeamIdList}, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ]
    }
    project = %{"_id" => 0, "insertedAt" => 1}
    #sort = %{"insertedAt" => -1}
    list = Mongo.find(@conn, @saved_notifications_col, filterNotification, [projection: project, sort: %{"insertedAt" => -1}, limit: 1])
    |> Enum.to_list
    if list == [] do
      # []
      bson_time()
    else
      hd(list)
    end
  end


  def getLatestSocialMediaLinkUpdatedAt(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true
    }
    project = %{"mediaLinkUpdatedAt" => 1, "_id" => 1}
    findOne = Mongo.find_one(@conn, @group_coll, filter, [projection: project])
    if findOne["mediaLinkUpdatedAt"] do
      findOne["mediaLinkUpdatedAt"]
    else
      []
    end
  end


  def getLatesNotificationUpdatedAtTime(groupObjectId, loginUserId, userTeamIdList) do
    filterNotification1 = %{
      "groupId" => groupObjectId,
      "createdById" => %{"$nin" => [loginUserId]},
      "notification" => 1
    }
    filterNotification2 = %{
      "groupId" => groupObjectId,
      "createdById" => %{"$nin" => [loginUserId]},
      "teamId" => %{"$in" => userTeamIdList},
      "notification" => 2
    }
    project = %{"_id" => 0, "insertedAt" => 1}
    list1 = Mongo.find(@conn, @saved_notifications_col, filterNotification1, [projection: project, sort: %{"insertedAt" => -1}, limit: 1])
    |> Enum.to_list
    list1 = if list1 == [] do
      # []
      bson_time()
    else
      hd(list1)["insertedAt"]
    end
    list2 = Mongo.find(@conn, @saved_notifications_col, filterNotification2, [projection: project, sort: %{"insertedAt" => -1}, limit: 1])
    |> Enum.to_list
    list2 = if list2 == [] do
      # []
      bson_time()
    else
      hd(list2)["insertedAt"]
    end
    finalList = [list1] ++ [list2]
    if length(finalList) > 0 do
      #return maximum date-time from list
      %{"insertedAt" => Enum.max(finalList)}
    else
      #return current date-time from list
      %{"insertedAt" => bson_time()}
    end
  end




  def getLoginUserTeamIds(groupObjectId, loginUserId) do
    #get login user teamId list to get notification for team post also along with other notifications
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    #hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    Mongo.find_one(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])
  end



  #################### GROUP EVENTS #############################
  #school Events type : 1. groupPost, 2. teamPost, 3. notesVideos, 4. assignment, 5. authorizedToAdmin, 6. testexam, 7. liveClass, 8. liveTestExam
  #constituency events type: 101. Issue tickets, 102. galleryPost, 103. calendarPost




  def checkGroupPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 1, #groupPost event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def checkGroupGalleryEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 102 #gallery post event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def checkGroupCalendarEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 103 #calendar post add event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def addGroupPostEvent(insertedPostId, groupObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "insertedId" => insertedPostId,
      "eventName" => "groupPost",
      "eventType" => 1, #groupPost event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def addGroupGalleryPostEvent(groupObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "eventName" => "galleryPost",
      "eventType" => 102, #groupPost event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def addGroupCalendarPostEvent(groupObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "eventName" => "calendarPost",
      "eventType" => 103, #groupPost event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateGroupPostEvent(insertedPostId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 1 #groupPost event
    }
    updateDoc = %{"$set" => %{
      "insertedId" => insertedPostId,
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end


  def updateGroupGalleryPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 102 #groupPost event
    }
    updateDoc = %{"$set" => %{
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end


  def updateGroupCalendarPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 103 #groupPost event
    }
    updateDoc = %{"$set" => %{
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end



  def checkTeamPostEvent(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 2 #teamPost event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def addTeamPostEvent(insertedPostId, groupObjectId, teamObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "insertedId" => insertedPostId,
      "eventName" => "teamPost",
      "eventType" => 2, #teamPost event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateTeamPostEvent(insertedPostId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 2 #teamPost event
    }
    updateDoc = %{"$set" => %{
      "insertedId" => insertedPostId,
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end


  def checkAssignmentEvent(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 4 #assignment event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def checkTestExamEvent(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 6 #testexam event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def addAssignmentEvent(assignmentInsertedId, groupObjectId, teamObjectId, subjectObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "insertedId" => assignmentInsertedId,
      "eventName" => "assignment",
      "eventType" => 4, #assignment event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def addTestExamEvent(insertedTestExamId, groupObjectId, teamObjectId, subjectObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "insertedId" => insertedTestExamId,
      "eventName" => "testexam",
      "eventType" => 6, #testexam event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateAssignmentEvent(insertedAssignmentId, groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 4 #assignment event
    }
    updateDoc = %{"$set" => %{
      "insertedId" => insertedAssignmentId,
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end


  def updateTestExamEvent(insertedTestExamId, groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 6 #testexam event
    }
    updateDoc = %{"$set" => %{
      "insertedId" => insertedTestExamId,
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end



  def checkNotesAndVideosEvent(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 3 #notesVideos event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end



  def addNotesAndVideosEvent(insertedNotesId, groupObjectId, teamObjectId, subjectObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "insertedId" => insertedNotesId,
      "eventName" => "notesVideos",
      "eventType" => 3, #notesVideos event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateNotesAndVideosEvent(insertedNotesId, groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "eventType" => 3 #notesVideos event
    }
    updateDoc = %{"$set" => %{
      "insertedId" => insertedNotesId,
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end



  #event for authorizedToAdmin
  def checkAuthorizedToAdminEvent(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "eventType" => 5  #authorizedToAdmin event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def addAuthorizedToAdminEventForUser(groupObjectId, userObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "eventName" => "authorizedToAdmin",
      "eventType" => 5,  #authorizedToAdmin event
      "eventAt" => bson_time()
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateAuthorizedToAdminEventForUser(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "eventType" => 5 #authorizedToAdmin event
    }
    updateDoc = %{"$set" => %{
      "eventAt" => bson_time()
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end

  #remove authorizedToAdmin event from group_action_event col when user logout
  def removeAuthorizedToAdminEventForLoginUser(userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "eventType" => 5  #authorizedToAdmin event
    }
    Mongo.delete_many(@conn, @group_action_events_col, filter)
  end


  ########**********LIVE CLASS event************************###########
  def checkLiveClassEvent(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 7  #liveClass event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def addLiveClassEvent(loginUser, groupObjectId, teamObjectId, meetingIdOnLive) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventName" => "liveClass",
      "eventType" => 7,  #authorizedToAdmin event
      #"eventAt" => bson_time(),
      "meetingOnLiveId" => meetingIdOnLive,
      "createdById" => loginUser["_id"],
      "createdByName" => loginUser["name"]
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end


  def updateLiveClassEvent(loginUser, groupObjectId, teamObjectId, meetingIdOnLive) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 7  #liveClass event
    }
    updateDoc = %{"$set" => %{
      "meetingOnLiveId" => meetingIdOnLive,
      "createdById" => loginUser["_id"],
      "createdByName" => loginUser["name"]
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end



  #########*********************LIVE TEST EXAM EVENT**************************#######
  #start test/exam event already exist
  def checkLiveTestExamEvent(groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "testExamId" => testexamObjectId,
      "eventType" => 8  #liveTestExam event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end



  def addLiveTestExamEvent(loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    eventInsertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "testExamId" => testexamObjectId,
      "eventName" => "liveTestExam",
      "eventType" => 8,  #liveTestExam event
      #"eventAt" => bson_time(),
      #"meetingOnLiveId" => meetingIdOnLive,
      "createdById" => loginUser["_id"],
      "createdByName" => loginUser["name"]
    }
    Mongo.insert_one(@conn, @group_action_events_col, eventInsertDoc)
  end



  def updateLiveTestExamEvent(loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "testExamId" => testexamObjectId,
      "eventType" => 8  #liveTestExam event
    }
    updateDoc = %{"$set" => %{
      "createdById" => loginUser["_id"],
      "createdByName" => loginUser["name"]
    }}
    Mongo.update_one(@conn, @group_action_events_col, filter, updateDoc)
  end


  def removeLiveTestExamEvent(_loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "testExamId" => testexamObjectId,
      "eventType" => 8  #liveTestExam event
    }
    Mongo.delete_many(@conn, @group_action_events_col, filter)
  end



  ####********Taluk role dashboard page**********####
  def checkLoginUserRoleTaluk(loginUserId) do
    filter = %{
      "userId" => loginUserId,
      "category" => "school",
      "role" => "taluk"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end



  def getListOfGroupIdsForLoginUser(loginUserId) do
    filter = %{
      "userId" => loginUserId,
      "isActive" => true
    }
    project = %{"_id" => 0, "groupId" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list
    |> Enum.uniq
  end



  def getTaluksListForSchoolGroup(groupIdList) do
    filter = %{
      "_id" => %{"$in" => groupIdList},
      "taluk" => %{"$exists" => true},
      "isActive" => true
    }
    #project = %{"_id" => 0, "taluk" => 1, "district" => 1, "state" => 1, "country" => 1}
    project = %{"_id" => 0, "taluk" => 1}
    Mongo.find(@conn, @group_coll, filter, [projection: project])
    |> Enum.to_list
    |> Enum.uniq
  end


  def getTalukGroupsListForSchoolGroup(taluk) do
    filter = %{
      "taluk" => taluk,
      "category" => "school",
      "isActive" => true
    }
    Mongo.find(@conn, @group_coll, filter)
    |>Enum.to_list
  end



  def getConstituencyGroupsCategoryList(groupIdList, constituencyName) do
    filter = %{
      "_id" => %{"$in" => groupIdList},
      "constituencyName" => constituencyName,
      "constituencyApp" => true,  #to get list of all categories belongs to constituency. So check it is constitueny app
      "isActive" => true
    }
    project = %{"_id" => 0, "constituencyName" => 1, "categoryName" => 1, "category" => 1}
    Mongo.find(@conn, @group_coll, filter, [projection: project])
    |> Enum.to_list
    |> Enum.uniq
  end


  def getGroupsCountForConstituencyCategory(changeset, groupIdList, loginUserId) do
    filter_doc = %{
      "groupId" => %{"$in" => groupIdList},
      "userId" => loginUserId,
      "groupDetails.category" => changeset["category"],
      "groupDetails.categoryName" => changeset["categoryName"],
      "groupDetails.constituencyName" => changeset["constituencyName"],
      "groupDetails.constituencyApp" => true,
      "groupDetails.isActive" => true
    }
    project_doc = %{ "_id" => 0, "groupId" => 1, "groupDetails.name" => 1, "groupDetails.avatar" => 1, "isAdmin" => 1, "canPost" => 1}
    pipeline = [ %{ "$match" => filter_doc}, %{"$project" => project_doc}, %{"$limit" => 2}]   #limit to 2 because more than 1 we require just count
    #IO.puts "#{pipeline}"
    Mongo.aggregate(@conn, @view_group_team_members_coll, pipeline)
    |> Enum.to_list
    |> Enum.uniq
  end


  def allowParentToPayFee(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true
    }
    #find parent allowed to pay fee
    project = %{"parentAllowedToPayFee" => 1}
    findStatus = Mongo.find_one(@conn, @group_coll, filter, [projection: project])
    update = if findStatus["parentAllowedToPayFee"] == true do
      %{"$set" => %{"parentAllowedToPayFee" => false}}
    else
      %{"$set" => %{"parentAllowedToPayFee" => true}}
    end
    Mongo.update_one(@conn, @group_coll, filter, update)
  end


  def getTotalPostCount(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getCommunityId(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true,
    }
    project = %{
      "userCommunityId" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def checkLoginUserIsZp(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "isActive" => true,
    }
    project = %{"_id" => 1}
    #Mongo.count(@conn, @teams_col, filter)
    Mongo.find(@conn, @panchayat_coll, filter, [projection: project])
    |> Enum.to_list
  end
end
