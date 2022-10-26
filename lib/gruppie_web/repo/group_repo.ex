defmodule GruppieWeb.Repo.GroupRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.GroupMembership
  alias GruppieWeb.Repo.TeamRepo

  @conn :mongo

  @group_coll "groups"

  @group_action_events_col "group_action_events"

  @group_team_members_coll "group_team_members"

  @staff_db_col "staff_database"

  @student_db_col "student_database"

  @teams_col "teams"

  @view_group_team_members_coll "VW_GROUP_TEAM_MEMBERS"

  @subject_staff_db_col "subject_staff_database"

  @view_teams_coll "VW_TEAMS"

  @saved_notifications_col "saved_notifications"

  @user_category_app_col "user_category_apps"


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
      appendIdForAdmin(login_user["_id"], changeset, object_id)
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


  def  appendIdForAdmin(userObjectId, changeset, object_id) do
    filter = %{
      "groupId" => object_id,
      "userId" => userObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "userCommunityId" => changeset.name<>"001"
      }
    }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def checkUserCanPostInGroup(group_object_id, login_user_id) do
    filter = %{ "groupId" => group_object_id, "userId" => login_user_id, "isActive" => true }
    project = %{ "_id" => 0, "canPost" => 1 }
    hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filter, [ projection: project ])))
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




  def get(groupId) do
    groupObjectId = decode_object_id(groupId)
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    projection =  %{ "updated_at" => 0 }
    #hd(Enum.to_list(Mongo.find(@conn, @group_coll, filter, [ projection: projection ])))
    Mongo.find(@conn, @group_coll, filter, [ projection: projection ])
    |> Enum.to_list
    |> hd
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



  #remove authorizedToAdmin event from group_action_event col when user logout
  def removeAuthorizedToAdminEventForLoginUser(userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "eventType" => 5  #authorizedToAdmin event
    }
    Mongo.delete_many(@conn, @group_action_events_col, filter)
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


  #get all teamIds of user in group
  def getUserTeamIds(groupObjectId, userObjectId) do
    filterTeam = %{ "groupId" => groupObjectId, "userId" => userObjectId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    #teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teams = Mongo.find_one(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])
    Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
  end


  #########*************Event Action queries*****************#############

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
    # filterNotification3 = %{
    #   "groupId" => groupObjectId,
    #   "receiverId" => loginUserId,
    #   "notification" => %{"$in" => [3,4]}
    # }
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
    # list3 = Mongo.find(@conn, @saved_notifications_col, filterNotification3, [projection: project, sort: %{"insertedAt" => -1}, limit: 1])
    # |> Enum.to_list
    # list3 = if list3 == [] do
    #   []
    # else
    #   hd(list3)["insertedAt"]
    # end
    # finalList = [list1] ++ [list2] ++ [list3]
    finalList = [list1] ++ [list2]
    if length(finalList) > 0 do
      #return maximum date-time from list
      %{"insertedAt" => Enum.max(finalList)}
    else
      #return current date-time from list
      %{"insertedAt" => bson_time()}
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


  def checkGroupPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 1, #groupPost event
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


  def checkGroupGalleryEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 102 #gallery post event
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
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


  def updateConstituencyBannerToGroup(changeset, groupObjectId) do
    filter = %{ "_id" => groupObjectId, "isActive" => true }
    update = %{ "$set" => changeset }
    Mongo.update_one(@conn, @group_coll, filter, update)
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









end
