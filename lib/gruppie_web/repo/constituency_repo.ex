defmodule GruppieWeb.Repo.ConstituencyRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias  GruppieWeb.Constituency
  alias  GruppieWeb.Repo.TeamRepo


  @conn :mongo

  @group_team_members_coll "group_team_members"

  @team_coll "teams"

  @view_teams_details_col "VW_TEAMS_DETAILS"

  @view_teams_coll "VW_TEAMS"

  @constituency_family_db_col "constituency_family_database"

  @users_col "users"

  @posts_col "posts"

  @gallery_col "gallery"

  @calendar_col "school_calendar"

  @constituency_issues_col "constituency_issues"

  @constituency_issues_posts_col "constituency_issues_posts"

  @constituency_voters_database_col "constituency_voters_database"

  @view_group_teams_coll "VW_GROUP_TEAMS"

  @group_action_events_col "group_action_events"

  @user_notification_token_col "notification_tokens"

  @groups_coll "groups"

  @panchayat_coll "panchayat_database"


  def checkUserAlreadyInConstituency(userObjectId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def checkUserIsBoothPresident(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "booth",
      ##"booth" => true,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_coll, filter, [projection: project])
  end


  def checkIsBoothWorker(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    #Mongo.count(@conn, @team_coll, filter)
    Mongo.find(@conn, @team_coll, filter)
    |> Enum.to_list
  end


  def checkIsBoothWorkerForEvent(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_coll, filter, [projection: project])
  end


  def checkIsBoothMember(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teamDetails.category" => "booth",
      "teamDetails.isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end




  def checkUserIsBoothCoordinator(userObjectId, groupObjectId) do
   filter = %{
     "groupId" => groupObjectId,
     "userId" => userObjectId,
     "teams.role" => "boothCoordinator",
     "isActive" => true
   }
   Mongo.count(@conn, @group_team_members_coll, filter)
  end


  def checkUserIsDepartmentPerson(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "departmentUserId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_col, filter, [projection: project])
  end


  def checkUserIsPartyPerson(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "partyUserId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_col, filter, [projection: project])
  end


  def joinUserToConstituency(loginUserId, groupObjectId) do
    insertDoc = Constituency.insertGroupMemberWhileJoining(loginUserId, groupObjectId)
    Mongo.insert_one(@conn, @group_team_members_coll, insertDoc)
  end



  #create booth team by admin
  def createBoothTeam(user, changeset, groupObjectId) do
    #create new object id as team id
    teamObjectId = new_object_id()
    team_create_doc = insert_booth_team_doc(teamObjectId, user["_id"], groupObjectId, changeset)
    Mongo.insert_one(@conn, @team_coll, team_create_doc)
    #increment booth count in groups table
    incrementBoothCount(groupObjectId)
    #1. insert into new booth/team created group_team_members doc
    team_members_doc = Constituency.insertGroupTeamMembersForAdmin(teamObjectId, user)
    #2. insert into boothPresident team under MLA
    #get boothPresident teamId
    boothPresidentTeamId = getBoothPresidentTeamId(groupObjectId)
    boothPresidentTeamObjectId = boothPresidentTeamId["_id"]
    #insert into bothPresident team
    boothPresidentTeamMemdoc = Constituency.insertGroupTeamMembersForUser(boothPresidentTeamObjectId, user)
    #check this user is already in booth presidents team
    checkUserAlreadyFilter = %{
      "userId" => user["_id"],
      "groupId" => groupObjectId,
      "teams.teamId" => boothPresidentTeamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, count} = Mongo.count(@conn, @group_team_members_coll, checkUserAlreadyFilter, [projection: project])
    insert = if count > 0 do
      #if already exist in booth president team then insert only to new booth team
      #update two teams at one time using $each to group_team_mem
      %{
        filter: %{ "groupId" => groupObjectId, "userId" => user["_id"] },
        update: %{ "$push" => %{ "teams" => %{"$each" => [team_members_doc]} } }
      }
    else
      #add to booth president and new booth team
      #update two teams at one time using $each to group_team_mem
      %{
        filter: %{ "groupId" => groupObjectId, "userId" => user["_id"] },
        update: %{ "$push" => %{ "teams" => %{"$each" => [boothPresidentTeamMemdoc, team_members_doc]} } }
      }
    end
    Mongo.update_one(@conn, @group_team_members_coll, insert.filter, insert.update)
    {:ok, encode_object_id(teamObjectId)}
  end

  defp insert_booth_team_doc(teamObjectId, userId, groupObjectId, changeset) do
    changeset = changeset
    |> update_map_with_key_value(:_id, teamObjectId)
    |> update_map_with_key_value(:adminId, userId)
    |> update_map_with_key_value(:groupId, groupObjectId)
    |> update_map_with_key_value(:isActive, true)
    |> update_map_with_key_value(:booth, true)
    |> update_map_with_key_value(:category, "booth")
    |> update_map_with_key_value(:allowTeamPostAll, true)
    |> update_map_with_key_value(:allowTeamPostCommentAll, true)
    |> update_map_with_key_value(:allowUserToAddOtherUser, true)
    |> update_map_with_key_value(:boothName, changeset.name)
    |> update_map_with_key_value(:committeeUpdatedAt, bson_time())
    |> update_map_with_key_value(:workersCount, 1)
    if Map.has_key?(changeset, :zpId) do
      updateZp(decode_object_id(changeset.zpId))
      Map.put(changeset, :zpId, decode_object_id(changeset.zpId))
    else
      changeset
    end
  end

  def updateZp(zpObjectId) do
    filter = %{
      "_id" => zpObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @panchayat_coll, filter, update)
  end


  def getUserIdAndImage(phone) do
    filter = %{
      "phone" => "+91"<>phone
    }
    project = %{
      "_id" => 1,
      "image" => 1,
    }
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end

  defp incrementBoothCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalBoothsCount" => 1
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end



  def getBoothPresidentTeamId(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "constituency",
      "subCategory" => "boothPresidents",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end



  #get list of booths in booth register
  def getAllBoothsTeams(groupObjectId) do
    #filter = %{ "groupId" => groupObjectId, "booth" => true, "isActive" => true }
    filter = %{ "groupId" => groupObjectId, "category" => "booth", "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "zoomKey" => 1, "zoomSecret" => 1, "adminId" => 1, "boothCommittees" => 1,
                 "boothNumber" => 1, "boothAddress" => 1, "aboutBooth" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |>Enum.to_list
  end


  #get booths list based on zp
  def getAllBoothsTeamsBasedOnZp(groupObjectId, zpObjectId) do
    filter = %{ "groupId" => groupObjectId, "zpId" => zpObjectId, "category" => "booth", "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "zoomKey" => 1, "zoomSecret" => 1, "adminId" => 1, "boothCommittees" => 1,
                 "boothNumber" => 1, "boothAddress" => 1, "aboutBooth" => 1,  "zpId" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |>Enum.to_list
  end


  def getUserProfileLastUpdatedAtEvent(loginUserId) do
    filter = %{
      "_id" => loginUserId
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end



  def getLoginUserLastUpdatedConstituencyTeamTime(teamIdsList, groupObjectId) do
    filter = %{
      "_id" => %{"$in" => teamIdsList},
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
    |> hd
  end


  def getLastConstituencyBoothUpdatedAtEvent(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "category" => "booth", "isActive" => true }
    project = %{"_id" => 0, "updatedAt" => 1}
    list = Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
    if length(list) > 0 do
      hd(list)
    else
      %{"updatedAt" => bson_time()}
    end
  end


  def getLastConstituencySubBoothUpdatedAtEvent(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "category" => "subBooth", "isActive" => true }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
    |> hd
  end


  def getAllBoothTeamIds(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "category" => "booth", "isActive" => true }
    project = %{"_id" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list
  end


  def getTeamLastPostUpdatedAtEvent(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "type" => "teamPost",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def lastCommitteeForBoothUpdatedAtEvent(_groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{"_id" => 0, "committeeUpdatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getLastUpdatedSubBoothTeamEventAtTime(groupObjectId, boothTeamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => boothTeamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getSubBoothTeamIdsForSelectedBooth(groupObjectId, boothTeamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => boothTeamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list
  end


  def getTotalTeamMembersCount(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def getLastGroupPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "groupPost",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getLastGroupPostEventFromEventCol(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 1
    }
    project = %{"_id" => 0, "eventAt" => 1}
    Mongo.find_one(@conn, @group_action_events_col, filter, [projection: project])
  end


  def getLastTeamPostEventFromEventCol(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 2
    }
    project = %{"_id" => 0, "eventAt" => 1}
    Mongo.find_one(@conn, @group_action_events_col, filter, [projection: project])
  end


  def getLastGalleryPostUpdatedAtEventFromEventCol(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 102
    }
    project = %{"_id" => 0, "eventAt" => 1}
    Mongo.find_one(@conn, @group_action_events_col, filter, [projection: project])
  end


  def getLastCalendarEventUpdatedAtFromEventCol(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "eventType" => 103
    }
    project = %{"_id" => 0, "eventAt" => 1}
    Mongo.find_one(@conn, @group_action_events_col, filter, [projection: project])
  end


  def getLastGalleryPostUpdatedAtEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @gallery_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getLastCalendarEventUpdatedAt(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @calendar_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getTotalBoothSubBoothMembersCount123(groupObjectId, boothTeamObjectId) do
    #first get subBooth teamIds belongs to this boothId(teamObjectId)
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => boothTeamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    subBoothTeamIdsList = Mongo.find(@conn, @team_coll, filter, [projection: project])
    |>Enum.to_list
    |>Enum.uniq
    #reduce above list and get subBooth teamIds array
    subBoothTeamIds = Enum.reduce(subBoothTeamIdsList, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #get users count for subBooth ids array
    filterSubBooth = %{
      "groupId" => groupObjectId,
      "teams.teamId" => %{"$in" => subBoothTeamIds},
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filterSubBooth, [projection: project])
  end



  def addCommitteesToBoothTeam(groupObjectId, teamObjectId, changeset) do
    changeset = changeset
    |>update_map_with_key_value(:defaultCommittee, false)
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    update = %{"$push" => %{"boothCommittees" => changeset}, "$set" => %{"committeeUpdatedAt" => bson_time()}}
    Mongo.update_one(@conn, @team_coll, filter, update)
  end



  def updateBoothCommitteeDetails(groupObjectId, teamObjectId, committeeId, changeset) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "boothCommittees.committeeId" => committeeId,
      "isActive" => true
    }
    update = %{"$set" => %{"boothCommittees.$.committeeName" => changeset.committeeName, "committeeUpdatedAt" => bson_time()}}
    Mongo.update_one(@conn, @team_coll, filter, update)
  end



  def removeCommitteeFromBoothTeam(groupObjectId, teamObjectId, committeeId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "boothCommittees.committeeId" => committeeId,
      "isActive" => true
    }
    update = %{"$pull" => %{"boothCommittees" => %{"committeeId" => committeeId}}, "$set" => %{"committeeUpdatedAt" => bson_time()}}
    Mongo.update_one(@conn, @team_coll, filter, update)
  end



  def getCommitteeListForBoothTeam(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "boothCommittees" => 1}
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end




  def addBoothUsersToGroupTeamMembersDoc(user, group, teamObjectId, changeset) do
    group_member_doc = Constituency.insertGroupTeamMemberForBoothMembers(user["_id"], group, teamObjectId, changeset)
    insert = Mongo.insert_one(@conn, @group_team_members_coll, group_member_doc)
    #check changeset map is having teamCategory parameter
    if Map.has_key?(changeset, :teamCategory) do
      if changeset.teamCategory == "booth" do
        #if team category=booth then check is defaultCommittee: true/false to add default team if true
        if changeset.dafaultCommittee == true do
          #to increment SubBootCount in groups table
          incrementSubBooth(group["_id"])
          #to check key exists in teams
          checkWorkersKeyExists = checkWorkerKey(group["_id"], teamObjectId)
          #key does not exists
          if checkWorkersKeyExists  do
            getCountOfBoothWorkers(group["_id"], teamObjectId)
          else
            #key exists
            #to increment workers count
            incrementWorkerCount(group["_id"], teamObjectId)
          end
          #add default sub booth category team to member added
          getCurrentTime = bson_time()
          teamChangeset = %{ name: user["name"]<>" Team", image: user["image"], category: "subBooth",
                            insertedAt: getCurrentTime, updatedAt: getCurrentTime, boothTeamId: teamObjectId }
          TeamRepo.createTeam(user, teamChangeset, group["_id"])
        else
          insert
        end
      else
        insert
      end
    else
      insert
    end
  end


  defp  incrementSubBooth(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalSubBoothsCount" => 1,
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  defp incrementWorkerCount(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "workersCount" => 1
      }
    }
    Mongo.update_one(@conn, @team_coll, filter, update)
  end


  def checkWorkerKey(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "workersCount" => %{
        "$exists" => false,
      },
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end


  defp getCountOfBoothWorkers(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, count } = Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
    filter2 = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "workersCount" => count,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter2, update)
  end



  def addDefaultBoothWorkerTeam(user, group, teamObjectId, changeset) do
    if changeset.dafaultCommittee == true do
      #check subBooth team already added for this booth team
      filter = %{
        "boothTeamId" => teamObjectId,
        "adminId" => user["_id"],
        "category" => "subBooth",
        "isActive" => true
      }
      {:ok, findAlready} = Mongo.count(@conn, @team_coll, filter)
      if findAlready == 0 do
        #add default sub booth category team to member added
        #to increment SubBootCount in groups table
        incrementSubBooth(group["_id"])
        #to check key exists in teams
        checkWorkersKeyExists = checkWorkerKey(group["_id"], teamObjectId)
        #key does not exists
        if checkWorkersKeyExists  do
          getCountOfBoothWorkers(group["_id"], teamObjectId)
        else
          #key exists
          #to increment workers count
          incrementWorkerCount(group["_id"], teamObjectId)
        end
        getCurrentTime = bson_time()
        teamChangeset = %{ name: user["name"]<>" Team", image: user["image"], category: "subBooth",
                          insertedAt: getCurrentTime, updatedAt: getCurrentTime, boothTeamId: teamObjectId }
        TeamRepo.createTeam(user, teamChangeset, group["_id"])
      end
    end
  end


#   # def getAllBoothAdminsId(groupObjectId) do
#   #   filter = %{
#   #     "groupId" => groupObjectId,
#   #     "category" => "booth",
#   #     "isActive" => true
#   #   }
#   #   project = %{"_id" => 0, "adminId" => 1}
#   #   Mongo.find(@conn, @team_coll, filter, [projection: project])
#   #   |> Enum.to_list
#   # end

#   # def getBoothAdminSubBoothAdminIds(groupObjectId, boothAdminIds) do
#   #   filter = %{
#   #     "groupId" => groupObjectId,
#   #     "adminId" => %{"$in" => boothAdminIds},
#   #     "category" => "subBooth",
#   #     "isActive" => true
#   #   }
#   #   project = %{"_id" => 0, "adminId" => 1}
#   #   Mongo.find(@conn, @team_coll, filter, [projection: project])
#   #   |> Enum.to_list
#   # end


  def addSubBoothUsersToGroupTeamMembersDoc(user, group, teamObjectId, _changeset) do
    group_member_doc = Constituency.insertGroupTeamMemberForSubBoothMembers(user["_id"], group, teamObjectId)
    Mongo.insert_one(@conn, @group_team_members_coll, group_member_doc)
  end



  def addTeamForBoothUsers(groupObjectId, teamObjectId, user, changeset) do
    #update into group_team_members doc
    team_members_doc = Constituency.insertNewTeamForAddingUser(teamObjectId, changeset)
    filter = %{ "groupId" => groupObjectId, "userId" => user["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def addBoothMemberToCommittee(groupObjectId, teamObjectId, userObjectId, committeeId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{"$push" => %{"teams.$.committeeIds" => committeeId}}
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end



  def getBoothMembersCount(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def addAdminUserToBooth(user, groupObjectId, teamObjectId) do
    team_members_doc = Constituency.insertGroupTeamMembersForAdminUser(teamObjectId, user)
    filter = %{ "groupId" => groupObjectId, "userId" => user["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
    {:ok, encode_object_id(teamObjectId)}
  end


  #get userId belongs to team from group_team_mem col
  def getTeamUsersList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{"_id" => 0, "userId" => 1, "teams.teamId.$" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1,
                "teams.allowedToAddComment" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list
  end

  def getUserDetailsForTeam(userIds) do
    filter = %{
      "_id" => %{"$in" => userIds}
    }
    projection =  %{ "password_hash" => 0, "insertedAt" => 0, "updatedAt" => 0, "user_secret_otp" => 0 }
    Mongo.find(@conn, @users_col, filter, [projection: projection])
    |> Enum.to_list
  end


  #get userId belongs to team from group_team_mem col
  def getTeamUsersListByCommitteeId(groupObjectId, teamObjectId, committeeId) do
    filter = %{
      "groupId" => groupObjectId,
      "$and" => [
        %{"teams.teamId" => teamObjectId},
        %{"teams.committeeIds" => committeeId}
      ],
      "isActive" => true,
    }
    project = %{"_id" => 0, "userId" => 1, "teams.teamId.$" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1,
                "teams.allowedToAddComment" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list
  end




  def updateBoothMemberInformation(changeset, userObjectId, loginUserId) do
    filter = %{
      "_id" => userObjectId
    }
    changeset = changeset
    |> Map.put(:profileUpdatedBy, loginUserId)
    update = %{"$set" => changeset}
    Mongo.update_one(@conn, @users_col, filter, update)
  end



  def updateRoleBoothCoordinatorForUser(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"teams.$.role" => "boothCoordinator"}}
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end



  def registerUserToVotersList(groupObjectId, teamObjectId, user) do
    #check user is already in constituency_voters list
    filter = %{
      "groupId" => groupObjectId,
      "userId" => user["_id"],
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, count} = Mongo.count(@conn, @constituency_family_db_col, filter, [projection: project])
    if count == 0 do
      #First insert family doc to constituency voters
      currentBsonTime = bson_time()
      #push this updateDoc to "myFamilyMembers" array in insertDoc
      updateDoc = %{
        "userId" => encode_object_id(user["_id"]),
        "name" => user["name"],
        "phone" => user["phone"],
        "relationship" => "self",
        "familyMemberId" => encode_object_id(new_object_id())
        #"userImage" => "",
        #"dob" => "",
        #"address" => "",
        #"voterId" => "",
        #"bloodGroup" => "",
        #"aadharNumber" => "",
        #"gender" => ""
      }
      #insert document
      insertDoc = %{
        "groupId" => groupObjectId,
        "teamId" => teamObjectId,
        "userId" => user["_id"],
        "myFamilyMembers" => [updateDoc],
        "isActive" => true,
        "insertedAt" => currentBsonTime,
        "updatedAt" => currentBsonTime
      }
      Mongo.insert_one(@conn, @constituency_family_db_col, insertDoc)
    else
      {:ok, "user already exist"}
    end
  end


  def addMyFamilyToConstituencyDb(groupObjectId, userObjectId, familyMembers, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    #check this user family is already in constituency_family_db collection
    {:ok, alreadyExist} = Mongo.count(@conn, @constituency_family_db_col, filter, [projection: project])
    if alreadyExist == 0 do
      #insert new
      currentBsonTime = bson_time()
      #firstly get login users doc to update
      loginUserMap = %{
        "userId" => encode_object_id(loginUser["_id"]),
        "name" => loginUser["name"],
        "phone" => loginUser["phone"],
        "relationship" => "self",
        "familyMemberId" => encode_object_id(new_object_id())
      }
      #join with family members added
      familyMembersDoc = [loginUserMap] ++ familyMembers
      #insert Doc
      insertDoc = %{
        "groupId" => groupObjectId,
        #"teamId" => teamObjectId,
        "userId" => loginUser["_id"],
        "myFamilyMembers" => familyMembersDoc,
        "isActive" => true,
        "insertedAt" => currentBsonTime,
        "updatedAt" => currentBsonTime
      }
      Mongo.insert_one(@conn, @constituency_family_db_col, insertDoc)
    else
      #update to existing
      update = %{
        "$set" => %{
          "myFamilyMembers" => familyMembers
        }
      }
      Mongo.update_one(@conn, @constituency_family_db_col, filter, update)
    end
  end


  def getFamilyRegisterList(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "myFamilyMembers" => 1}
    Mongo.find(@conn, @constituency_family_db_col, filter, [projection: project])
    |> Enum.to_list()
    #|> hd()
  end



  def getMyBoothTeams(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "teams.isTeamAdmin" => true,
      #"teamDetails.booth" => true,
      "teamDetails.category" => "booth",
      "teamDetails.isActive" => true,
    }
    project = %{
      "teams.teamId" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1, "teamDetails.adminId" => 1,
      "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.image" => 1, "teamDetails.category" => 1
    }
    pipeline = [%{ "$match" => filter }, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end


  def getLastUpdatedAllBoothTeamEventAtTime(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def getLastUpdatedMyBoothTeamEventAtTime(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  def lastUserToTeamUpdatedAt(_groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "lastUserUpdatedAt" => 1}
    #Mongo.find_one(@conn, @team_coll, filter, [projection: project])
    #|> Enum.to_list
    Mongo.find(@conn, @team_coll, filter, [projection: project, limit: 1])
    |> Enum.to_list
  end



  def getMyBoothTeamIdsForBoothPresident(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "booth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list
  end


  def getLastUpdatedMySubBoothTeamEventAtTime(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end



  def checkUserCanPostInTeam(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @view_group_teams_coll, pipeline)
    |> Enum.to_list
    #Mongo.find_one(@conn, @view_group_teams_coll, filter, [projection: project])
  end



  def getMySubBoothTeamIdsForBoothWorker(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list
  end



  def getMySubBoothTeams(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "teams.isTeamAdmin" => true,
      "teamDetails.category" => "subBooth",
      "teamDetails.isActive" => true,
    }
    project = %{
      "teams.teamId" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1, "teamDetails.adminId" => 1,
      "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.image" => 1, "teamDetails.category" => 1
    }
    pipeline = [%{ "$match" => filter }, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end



  def getBoothMembersTeams(groupObjectId, boothTeamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => boothTeamObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "adminName" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone",
                 "userImage" => "$$CURRENT.userDetails.image", "userId" => "$$CURRENT.userDetails._id",
                 "subjectId" => 1, "ebookId" => 1, "zoomKey" => 1, "zoomSecret" => 1}
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "name" => 1 } }]
    Mongo.aggregate(@conn, @view_teams_details_col, pipeline)
  end




  def constituencyIssuesRegister(changeset, groupObjectId) do
    changeset = changeset
                |> Map.put_new(:groupId, groupObjectId)
    Mongo.insert_one(@conn, @constituency_issues_col, changeset)
  end


  def constituencyIssuesGet(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"insertedAt" => 0, "updatedAt" => 0, "isActive" => 0}
    Mongo.find(@conn, @constituency_issues_col, filter, [projection: project])
    #pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 100}, %{"$sort" => %{"issue" => 1}}]
    #Mongo.aggregate(@conn, @view_constituency_issues_col, pipeline)
    #|> Enum.to_list
  end


  def getTaskForceTeamId(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "constituency",
      "subCategory" => "taskForce",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end



  def getIssuesIdForDepartmentTaskForce(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "departmentUserId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    list = Mongo.find(@conn, @constituency_issues_col, filter, [projection: project])
    #reduce list
    listReduce = Enum.reduce(list, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    listReduce
  end


  def getIssuesIdForPartyTaskForce(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "partyUserId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    list = Mongo.find(@conn, @constituency_issues_col, filter, [projection: project])
    #reduce list
    listReduce = Enum.reduce(list, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    listReduce
  end



  def addUserToUserDoc(changeset) do
    # newUserObjectId = new_object_id()
    generatedPassword = hash_password()
    hashed_password = generatedPassword.password #accessing field from map
    # otp = generatedPassword.otp
    final_user_map = changeset
                      |>update_map_with_key_value("password_hash", hashed_password)
                      |>update_map_with_key_value("insertedAt", bson_time())
                      |>update_map_with_key_value("updatedAt", bson_time())
    case Mongo.insert_one(@conn, @users_col, final_user_map) do
      {:ok, user} ->
        filter = %{ "_id" => user.inserted_id }
        #hd(Enum.to_list(Mongo.find(@conn, @users_col, filter)))
        Mongo.find_one(@conn, @users_col, filter)
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end



  def addUserToGroupTeamMemWithTaskForceTeam(groupObjectId, teamObjectId, userObjectId) do
    group_team_mem_doc = Constituency.insertGroupTeamMemberForTaskForce(userObjectId, groupObjectId, teamObjectId)
    Mongo.insert_one(@conn, @group_team_members_coll, group_team_mem_doc)
  end


  def checkUserIsAlreadyInGroup(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def checkUserAlreadyInTaskForceTeam(userObjectId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def addTaskForceTeamToGroupTeamUser(userObjectId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    updateDoc = %{
      "teamId" => teamObjectId,
      "allowedToAddComment" => true,
      "allowedToAddPost" => true,
      "allowedToAddUser" => false,
      "isTeamAdmin" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      #"role" => "taskForce"
    }
    update = %{"$push" => %{"teams" => updateDoc}}
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end



  def updateDepartmentAndPartyUserIdToConstituencyIssues(departmentUserId, partyUserId, issueObjectId, groupObjectId) do
    filter = %{
      "_id" => issueObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    update_doc = %{
      "departmentUserId" => departmentUserId,
      "partyUserId" => partyUserId
    }
    update = %{"$set" => update_doc}
    Mongo.update_one(@conn, @constituency_issues_col, filter, update)
  end



  def updateConstituencyDesignationToUsersCol(userObjectId, constituencyDesignation) do
    filter = %{
      "_id" => userObjectId
    }
    update = %{"$set" => %{"constituencyDesignation" => constituencyDesignation}}
    Mongo.update_one(@conn, @users_col, filter, update)
  end



  def deleteConstituencyIssue(groupObjectId, issueObjectId) do
    filter = %{
      "_id" => issueObjectId,
      "groupId" => groupObjectId
    }
    update = %{"$set" => %{"isActive" => false}}
    Mongo.update_one(@conn, @constituency_issues_col, filter, update)
  end



  def getBoothOrSubBoothTeamsForLoginUser(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "$or" => [
        %{"teamDetails.category" => "booth"},
        %{"teamDetails.category" => "subBooth"}
      ],
      "teamDetails.isActive" => true
    }
    project = %{"_id" => 0, "teamName" => "$$CURRENT.teamDetails.name", "teamId" => "$$CURRENT.teamDetails._id"}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_teams_coll, pipeline)
    |> Enum.to_list
  end



  def addTicketOnIssueOfConstituency(groupObjectId, boothTeamObjectId, issueObjectId, loginUserId, changeset) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:teamId, boothTeamObjectId)
                |> update_map_with_key_value(:issueId, issueObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
                |> update_map_with_key_value(:type, "constituencyIssue")
    Mongo.insert_one(@conn, @constituency_issues_posts_col, changeset)
  end



  def getTeamsListForBoothCoordinator123(groupObjectId, userObjectId) do
    #first get list of booth teams where role is boothCoordinator
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.role" => "boothCoordinator",
      "teamDetails.isActive" => true,
      "isActive" => true,
    }
    project = %{"_id" => 0, "teamId" => "$$CURRENT.teams.teamId"}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    coordinatorBoothTeamIdList = Mongo.aggregate(@conn, @view_teams_coll, pipeline)
    |>Enum.to_list
    #second, get list of subBooth teams under each booth in above boothList #coordinatorBoothTeamIdList
    #convert above list to only array with teamIds
    boothTeamIds = Enum.reduce(coordinatorBoothTeamIdList, [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    #now get subBooth teams id form above boothTeamIds array/list
    filterSubBooth = %{
      "groupId" => groupObjectId,
      "category" => "subBooth",
      "boothTeamId" => %{"$in" => boothTeamIds},
      "isActive" => true
    }
    projectSubBooth = %{"_id" => 1}
    coordinatorSubBoothTeamIdList = Mongo.find(@conn, @team_coll, filterSubBooth, [projection: projectSubBooth])
    |>Enum.to_list
    #convert above list to only array with teamIds
    subBoothTeamIds = Enum.reduce(coordinatorSubBoothTeamIdList, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #Lastly, merge both coordinator booth and subBooth teamIds
    boothTeamIds ++ subBoothTeamIds
  end


  def getTeamsListForBoothPresident(groupObjectId, userObjectId) do
    #first get list of booth teams where role is admin in booth teams
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "booth" => true,
      "category" => "booth",
      "isActive" => true,
    }
    project = %{"_id" => 1}
    presidentBoothTeamList = Mongo.find(@conn, @team_coll, filter, [projection: project])
    |>Enum.to_list
    #convert above list to only array with teamIds
    boothTeamIds = Enum.reduce(presidentBoothTeamList, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #now get subBooth teams id form above boothTeamIds array/list
    filterSubBooth = %{
      "groupId" => groupObjectId,
      "category" => "subBooth",
      "boothTeamId" => %{"$in" => boothTeamIds},
      "isActive" => true
    }
    projectSubBooth = %{"_id" => 1}
    boothPresidentSubBoothTeamIdList = Mongo.find(@conn, @team_coll, filterSubBooth, [projection: projectSubBooth])
    |>Enum.to_list
    #convert above list to only array with teamIds
    subBoothTeamIds = Enum.reduce(boothPresidentSubBoothTeamIdList, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #Lastly, merge both coordinator booth and subBooth teamIds
    boothTeamIds ++ subBoothTeamIds
  end


  def getTeamsListForBoothMembers(groupObjectId, userObjectId) do
    #first get list of booth teams where role is boothCoordinator
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "subBooth",
      "isActive" => true,
    }
    project = %{"_id" => 1}
    presidentBoothTeamList = Mongo.find(@conn, @team_coll, filter, [projection: project])
    |>Enum.to_list
    #convert above list to only array with teamIds
    boothTeamIds = Enum.reduce(presidentBoothTeamList, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    boothTeamIds
  end


  #option: notApproved/approved/hold/denied
  #def getIssuesTicketsBasedOnOptionSelected123(groupObjectId, teamIdsArray, option, page, limit) do
  #  filter = %{
  #    "issuePostDetails.groupId" => groupObjectId,
  #    "issuePostDetails.teamId" => %{"$in" => teamIdsArray},
  #    "issuePostDetails.coordinatorStatus" => option,
  #    "issuePostDetails.isActive" => true
  #  }
  #  pageNo = String.to_integer(page)
  #  skip = (pageNo - 1) * limit
  #  pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
  #  Mongo.aggregate(@conn, @view_constituency_issue_posts_col, pipeline)
  #  |>Enum.to_list
  #end


  #option: notApproved/approved/hold/denied
  #def getIssuesTicketsBasedOnOptionSelected(groupObjectId, teamIdsArray, option, page, limit) do
  #  filter = %{
  #    "groupId" => groupObjectId,
  #    "teamId" => %{"$in" => teamIdsArray},
  #    "coordinatorStatus" => option,
  #    "isActive" => true
  #  }
  #  pageNo = String.to_integer(page)
  #  skip = (pageNo - 1) * limit
  #  Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{"_id": -1}, skip: skip, limit: limit])
  #  |>Enum.to_list
  #end

  #option: notApproved/approved/hold/denied
  def getConstituencyIssuesTicketsForPartyTaskForce(groupObjectId, issuesIdArray, option, page, limit) do
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issuesIdArray},
      "partyTaskForceStatus" => option,
      "isActive" => true
    }
    pageNo = String.to_integer(page)
    skip = (pageNo - 1) * limit
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
    |>Enum.to_list
  end

  def getPartyTaskForceConstituencyIssuesTicketsEvents(groupObjectId, issuesIdArray, option) do
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issuesIdArray},
      "partyTaskForceStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    #Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{"updatedAt": -1}])
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  #option: notApproved/approved/hold/denied
  def getConstituencyIssuesTicketsForAdmin(groupObjectId, option, page, limit) do
    filter = %{
      "groupId" => groupObjectId,
      "adminStatus" => option,
      "isActive" => true
    }
    pageNo = String.to_integer(page)
    skip = (pageNo - 1) * limit
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
    |>Enum.to_list
  end

  def getAdminConstituencyIssuesTicketsEvents(groupObjectId, option) do
    filter = %{
      "groupId" => groupObjectId,
      "adminStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    #Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{"updatedAt": -1}])
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
    #|> hd
  end


  ##def getConstituencyIssuesTicketsByIssueId123(groupObjectId, issuesIdArray, option, page, limit) do
  ##  #if option is overdue then get list based on date > close date  for issue
  ##  if option == "overdue" do
  ##    #private function redirect
  ##    getFilterForOverDueIssueTickets(groupObjectId, issuesIdArray, option, page, limit)
  ##  else
  ##    filter = %{
  ##      "issuePostDetails.groupId" => groupObjectId,
  ##      "issuePostDetails.issueId" => %{"$in" => issuesIdArray},
  ##      "issuePostDetails.departmentTaskForceStatus" => option,
  ##      "issuePostDetails.isActive" => true
  ##    }
  ##    pageNo = String.to_integer(page)
  ##    skip = (pageNo - 1) * limit
  ##    pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
  ##    Mongo.aggregate(@conn, @view_constituency_issue_posts_col, pipeline)
  ##    |>Enum.to_list
  ##  end
  ##end

  def getConstituencyIssuesTicketsDepartmentTaskForce(groupObjectId, issuesIdArray, option, page, limit) do
    #if option is overdue then get list based on date > close date  for issue
    if option == "overdue" do
      #private function redirect
      getFilterForOverDueIssueTickets(groupObjectId, issuesIdArray, option, page, limit)
    else
      filter = %{
        "groupId" => groupObjectId,
        "issueId" => %{"$in" => issuesIdArray},
        "departmentTaskForceStatus" => option,
        "isActive" => true
      }
      pageNo = String.to_integer(page)
      skip = (pageNo - 1) * limit
      Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
      |>Enum.to_list
    end
  end

  defp getFilterForOverDueIssueTickets(groupObjectId, issuesIdArray, _option, page, limit) do
    #get todays date
    currentDate = Timex.today
    #issue close last date format
    {:ok, currentDateFormat} = Timex.format(currentDate, "%d-%m-%Y", :strftime)
    #convert date to yyyymmdd integer string
    dateStringNumber = String.split(currentDateFormat, "-") |> Enum.reverse() |> Enum.join()
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issuesIdArray},
      "departmentTaskForceStatus" => "open",
      "issueCloseDueDateStringNumber" => %{"$lt" => String.to_integer(dateStringNumber)},
      "isActive" => true
    }
    pageNo = String.to_integer(page)
    skip = (pageNo - 1) * limit
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
    |>Enum.to_list
  end

  def getDepartmentTaskForceConstituencyIssuesTicketsEvents(groupObjectId, issuesIdArray, option) do
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issuesIdArray},
      "departmentTaskForceStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 0, "updatedAt" => 1}
    #Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{"updatedAt": -1}])
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end

#   ##defp getFilterForOverDueIssueTickets123(groupObjectId, issuesIdArray, option, page, limit) do
#   ##  #get todays date
#   ##  currentDate = Timex.today
#   ##  #issue close last date format
#   ##  {:ok, currentDateFormat} = Timex.format(currentDate, "%d-%m-%Y", :strftime)
#   ##  #convert date to yyyymmdd integer string
#   ##  dateStringNumber = String.split(currentDateFormat, "-") |> Enum.reverse() |> Enum.join()
#   ##  filter = %{
#   ##    "issuePostDetails.groupId" => groupObjectId,
#   ##    "issuePostDetails.issueId" => %{"$in" => issuesIdArray},
#   ##    "issuePostDetails.departmentTaskForceStatus" => "open",
#   ##    "issuePostDetails.issueCloseDueDateStringNumber" => %{"$lt" => String.to_integer(dateStringNumber)},
#   ##    "issuePostDetails.isActive" => true
#   ##  }
#   ##  pageNo = String.to_integer(page)
#   ##  skip = (pageNo - 1) * limit
#   ##  pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
#   ##  Mongo.aggregate(@conn, @view_constituency_issue_posts_col, pipeline)
#   ##  |>Enum.to_list
#   ##end


  #option: notApproved/approved/hold/denied
  def getConstituencyIssuesTicketsForBoothPresident(groupObjectId, teamIdsArray, option, page, limit) do
    filter = cond do
      option == "notApproved" || option == "denied" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "approved" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "$and" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "closed" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "departmentTaskForceStatus" => option,
          "isActive" => true
        }
    end
    pageNo = String.to_integer(page)
    skip = (pageNo - 1) * limit
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
    |>Enum.to_list
  end


  def getBoothPresidentConstituencyIssueTicketsEvents(groupObjectId, teamIdsArray, option) do
    filter = cond do
      option == "notApproved" || option == "denied" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "approved" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "$and" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "closed" ->
        %{
          "groupId" => groupObjectId,
          "teamId" => %{"$in" => teamIdsArray},
          "departmentTaskForceStatus" => option,
          "isActive" => true
        }
    end
    project = %{"_id" => 0, "updatedAt" => 1}
    #Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{"updatedAt": -1}])
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end


  #option: open/overdue/hold/closed
  #def getIssuesTicketsBasedOnOptionSelectedForPublic123(groupObjectId, userObjectId, option, page, limit) do
  ##  filter = %{
  ##    "issuePostDetails.groupId" => groupObjectId,
  ##    "issuePostDetails.userId" => userObjectId,
  ##    "issuePostDetails.coordinatorStatus" => option,
  ##    "issuePostDetails.isActive" => true
  ##  }
  ## pageNo = String.to_integer(page)
  ##  skip = (pageNo - 1) * limit
  ## pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
  ##  Mongo.aggregate(@conn, @view_constituency_issue_posts_col, pipeline)
  ##  |>Enum.to_list
  ##end

  #option: open/overdue/hold/closed
  def getIssuesTicketsBasedOnOptionSelectedForPublic(groupObjectId, userObjectId, option, page, limit) do
    filter = cond do
      option == "notApproved" || option == "denied" || option == "hold" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "approved" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "$and" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "closed" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "departmentTaskForceStatus" => option,
          "isActive" => true
        }
    end
    pageNo = String.to_integer(page)
    skip = (pageNo - 1) * limit
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [sort: %{_id: -1}, skip: skip, limit: limit])
    |>Enum.to_list
  end

  def getPublicUserConstituencyIssuesTicketsEvents(groupObjectId, userObjectId, option) do
    filter = cond do
      option == "notApproved" || option == "denied" || option == "hold" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "approved" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "$and" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
          "isActive" => true
        }
      option == "closed" ->
        %{
          "groupId" => groupObjectId,
          "userId" => userObjectId,
          "departmentTaskForceStatus" => option,
          "isActive" => true
        }
    end
    project = %{"_id" => 0, "updatedAt" => 1}
    #Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{"updatedAt": -1}])
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project, sort: %{updatedAt: -1}, limit: 1])
    |> Enum.to_list
  end




  #changeStatusOfNotApprovedIssuesTickets by partyTaskForce/PartyPerson
  def changeStatusOfNotApprovedIssuesTicketsByPartyTaskForce(groupObjectId, issuePostObjectId, statusParams) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    updateDoc = %{"partyTaskForceStatus" => statusParams}
    updateDoc = if statusParams == "approved" do
      ##updateDoc = Map.put(updateDoc, "departmentTaskForceStatus", "open")
      Map.put(updateDoc, "adminStatus", "notApproved")
    else
      updateDoc
    end
    updateDoc = if statusParams == "denied" do
      Map.put(updateDoc, "adminStatus", "")
    else
      updateDoc
    end
    updateDoc = if statusParams == "notApproved" do
      Map.put(updateDoc, "adminStatus", "")
    else
      updateDoc
    end
    updateDoc = Map.put(updateDoc, "updatedAt", bson_time())
    update = %{"$set" => updateDoc}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end



  #changeStatusOfNotApprovedIssuesTickets by admin
  def changeStatusOfNotApprovedIssuesTicketsByAdmin(groupObjectId, issuePostObjectId, statusParams) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    updateDoc = %{"adminStatus" => statusParams}
    updateDoc = cond do
      statusParams == "approved" ->
        updateDoc = Map.put(updateDoc, "departmentTaskForceStatus", "open")
        #update close date for issue based on dueDays for this issueId when issue post is approved
        getDueDateForIssueToClose = updateDueDateForApprovedIssuePosts(filter)
        dueDays = getDueDateForIssueToClose["dueDays"]
        #jump from current/todays date to dueDays length
        #convert to ISO Date and get all parameters of date
        currentDate = Timex.today
        shiftDate = Timex.shift(currentDate, days: dueDays)
        #issue close last date format
        {:ok, closeDateFormat} = Timex.format(shiftDate, "%d-%m-%Y", :strftime)
        updateDoc = Map.put(updateDoc, "issueCloseDueDate", closeDateFormat)
        #convert date to yyyymmdd integer string
        dateStringNumber = String.split(closeDateFormat, "-") |> Enum.reverse() |> Enum.join()
        Map.put(updateDoc, "issueCloseDueDateStringNumber", String.to_integer(dateStringNumber))
      statusParams == "denied" ->
        updateDoc = Map.put(updateDoc, "departmentTaskForceStatus", "")
        updateDoc = Map.put(updateDoc, "issueCloseDueDate", "")
        updateDoc = Map.put(updateDoc, "issueCloseDueDateStringNumber", "")
      statusParams == "notApproved"
        updateDoc = Map.put(updateDoc, "departmentTaskForceStatus", "")
        updateDoc = Map.put(updateDoc, "issueCloseDueDate", "")
        Map.put(updateDoc, "issueCloseDueDateStringNumber", "")
    end
    updateDoc = Map.put(updateDoc, "updatedAt", bson_time())
    update = %{"$set" => updateDoc}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end

  defp updateDueDateForApprovedIssuePosts(filter) do
    project = %{"_id" => 0, "issueId" => 1}
    issuePost = Mongo.find_one(@conn, @constituency_issues_posts_col, filter, [projection: project])
    issueObjectId = issuePost["issueId"]
    #get due days form this issue
    filterIssue = %{
      "_id" => issueObjectId,
      "groupId" => filter["groupId"],
      "isActive" => true
    }
    projectIssue = %{"_id" => 0, "dueDays" => 1}
    Mongo.find_one(@conn, @constituency_issues_col, filterIssue, [projection: projectIssue])
  end



  def closeOrHoldStatusForOpenIssue(groupObjectId, issuePostObjectId, statusParams) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    updateDoc = %{"departmentTaskForceStatus" => statusParams, "updatedAt" => bson_time()}
    update = %{"$set" => updateDoc}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end




  def getTotalIssuesTicketsCountOnOptionSelectedForDepartmentTaskForce(groupObjectId, issueIdsArray, option) do
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issueIdsArray},
      "departmentTaskForceStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end


  def getTotalIssuesTicketsCountOnOptionSelectedForTaskForce(groupObjectId, issueIdsArray, option) do
    filter = %{
      "groupId" => groupObjectId,
      "issueId" => %{"$in" => issueIdsArray},
      "partyTaskForceStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end


  def getTotalIssuesTicketsCountOnOptionSelectedForAdmin(groupObjectId, option) do
    filter = %{
      "groupId" => groupObjectId,
      "adminStatus" => option,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end


  def getTotalIssuesTicketsCountOnOptionSelectedForBoothPresident(groupObjectId, teamIdsArray, option) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => %{"$in" => teamIdsArray},
      "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end



  def getTotalIssuesTicketsCountOnOptionSelectedForPublic(groupObjectId, userObjectId, option) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "$or" => [%{"partyTaskForceStatus" => option}, %{"adminStatus" => option}],
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end



  def checkLoginUserAddedThisIssue(loginUserId, groupObjectId, issueObjectId) do
    filter = %{
      "_id" => issueObjectId,
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      #"issueId" => issueObjectId,
      "type" => "constituencyIssue",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end



  def removeIssueAddedByLoginUser(userObjectId, groupObjectId, issueObjectId) do
    filter = %{
      "_id" => issueObjectId,
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      #"issueId" => issueObjectId,
      "type" => "constituencyIssue"
    }
    update = %{"$set" => %{"isActive" => false}}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end



  def addCoordinatorToGroupTeamMembersDoc(user, group, teamObjectId, _changeset) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    groupTeamMembersInsertDoc = %{
      "userId" => user["_id"],
      "groupId" => group["_id"],
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [%{
         "teamId" => teamObjectId,
         "isTeamAdmin" => false,
         "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
         "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
         "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
         "insertedAt" => bson_time(),
         "updatedAt" => bson_time(),
         "role" => "boothCoordinator"
        }],
    }
    Mongo.insert_one(@conn, @group_team_members_coll, groupTeamMembersInsertDoc)
  end


  def addNewTeamForUserInGroup(groupObjectId, teamObjectId, user, _changeset) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    #update into group_team_members doc
    team_members_update_doc = %{
      "teamId" => teamObjectId,
      "isTeamAdmin" => false,
      "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
      "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
      "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "role" => "boothCoordinator"
    }
    filter = %{ "userId" => user["_id"], "groupId" => groupObjectId }
    update = %{ "$push" => %{ "teams" => team_members_update_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end



  def getListOfBoothCoordinators123(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "teams.role" => "boothCoordinator",
      "isActive" => true
    }
    project = %{"_id" => 0, "userDetails" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_teams_coll, pipeline)
    |>Enum.to_list
  end

  def getListOfBoothCoordinators(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "teams.role" => "boothCoordinator",
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |>Enum.to_list
  end



  def getUserDetailFromUserCol(userId) do
    filter = %{
      "_id" => userId
    }
    project = %{"_id" => 1, "name" => 1, "phone" => 1, "image" => 1, "constituencyDesignation" => 1}
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end



  def getConstituencyIssueDetailsById(issueId) do
    filter = %{
      "_id" => issueId,
      "isActive" => true
    }
    project = %{"issue" => 1, "jurisdiction" => 1, "departmentUserId" => 1, "partyUserId" => 1}
    Mongo.find_one(@conn, @constituency_issues_col, filter, [projection: project])
  end


  def getTeamDetailsById(teamId) do
    filter = %{
      "_id" => teamId,
      "isActive" => true
    }
    project = %{"_id" => 1, "name" => 1, "category" => 1, "adminId" => 1, "boothTeamId" => 1}
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end



  def addCommentToIssueTickets(groupObjectId, loginUserId, issuePostObjectId, changeset) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    changeset = changeset
                |> update_map_with_key_value(:commentId, encode_object_id(new_object_id()))
                |> update_map_with_key_value(:userId, loginUserId)
                |> update_map_with_key_value(:insertedAt, bson_time())
    update = %{"$push" => %{"comments" => changeset}}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end



  def getCommentsOnIssueTickets(groupObjectId, issuePostObjectId) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "comments" => 1}
    Mongo.find(@conn, @constituency_issues_posts_col, filter, [projection: project])
    |>Enum.to_list
    |>hd
  end



  def checkLoginUserAddedCommentForIssueTicket(issuePostObjectId, groupObjectId, userObjectId, commentId) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "comments.commentId" => commentId,
      "comments.userId" => userObjectId,
      "isActive" => true,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end



  def removeCommentAddedForIssueTicket(issuePostObjectId, groupObjectId, commentId) do
    filter = %{
      "_id" => issuePostObjectId,
      "groupId" => groupObjectId,
      "comments.commentId" => commentId,
      "isActive" => true,
    }
    update = %{"$pull" => %{"comments" => %{"commentId" => commentId}}}
    Mongo.update_one(@conn, @constituency_issues_posts_col, filter, update)
  end



  def addUserToConstituencyVotersDatabase(groupObjectId, teamObjectId, userObjectId, changeset) do
    #check this voterId already in constituency_voters_database col
    filterVoterAlreadyExist = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "voterId" => changeset.voterId,
      "isActive" => true
    }
    #filter = %{
    #  "voterId" => changeset.voterId,
    #  "isActive" => true
    #}
    project = %{"_id" => 1}
    {:ok, voterAlreadyExist} = Mongo.count(@conn, @constituency_voters_database_col, filterVoterAlreadyExist, [projection: project])
    if voterAlreadyExist == 0 do
      #not exist. add newly
      changeset = changeset
      |> update_map_with_key_value(:groupId, groupObjectId)
      |> update_map_with_key_value(:teamId, teamObjectId)
      |> update_map_with_key_value(:userId, userObjectId)
      |> update_map_with_key_value(:isActive, true)
      Mongo.insert_one(@conn, @constituency_voters_database_col, changeset)
    else
      #already exist
      {:ok, "already exist"}
    end
  end



  def addUserToConstituencyVotersDatabaseWithoutUserId(groupObjectId, teamObjectId, changeset) do
    #check this voterId already in constituency_voters_database col
    filterVoterAlreadyExist = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "voterId" => changeset.voterId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, voterAlreadyExist} = Mongo.count(@conn, @constituency_voters_database_col, filterVoterAlreadyExist, [projection: project])
    if voterAlreadyExist == 0 do
      #not exist. add newly
      changeset = changeset
      |> update_map_with_key_value(:groupId, groupObjectId)
      |> update_map_with_key_value(:teamId, teamObjectId)
      |> update_map_with_key_value(:isActive, true)
      Mongo.insert_one(@conn, @constituency_voters_database_col, changeset)
    else
      #already exist
      {:ok, "already exist"}
    end
  end



  def getVotersFromMasterList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    Mongo.find(@conn, @constituency_voters_database_col, filter)
    |> Enum.to_list
    |> Enum.uniq
  end



  def removeVoterFromMasterList(groupObjectId, teamObjectId, voterId) do
    filter = %{
      "voterId" => voterId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    Mongo.delete_one(@conn, @constituency_voters_database_col, filter)
  end



  def getTotalOpenIssuesCountOfConstituency(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "departmentTaskForceStatus" => "open",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @constituency_issues_posts_col, filter, [projection: project])
  end


  def getTotalBoothAndDiscussionsCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "booth",
      #"booth" => true,
      "isActive" => true
    }
    project = %{"_id" => 1}
    boothTeamIds = Enum.to_list(Mongo.find(@conn, @team_coll, filter, [projection: project]))
    boothTeamIdsArray = Enum.reduce(boothTeamIds, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #find count of posts done by above booth team Ids array
    filterPostCount = %{
      "groupId" => groupObjectId,
      "teamId" => %{"$in" => boothTeamIdsArray},
      "type" => "teamPost",
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, totalBoothDiscussionCount} = Mongo.count(@conn, @posts_col, filterPostCount, [projection: project])
    totalBoothCount = length(boothTeamIdsArray)
    %{
      "totalBoothDiscussionCount" => totalBoothDiscussionCount,
      "totalBoothCount" => totalBoothCount
    }
  end


  # def getTotalBoothCountInGroup(groupObjectId) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "category" => "booth",
  #     #"booth" => true,
  #     "isActive" => true
  #   }
  #   project = %{"_id" => 1}
  #   Mongo.count(@conn, @team_coll, filter, [projection: project])
  # end



  def getTotalSubBoothAndDiscussionsCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "category" => "subBooth",
      "isActive" => true
    }
    project = %{"_id" => 1}
    subBoothTeamIds = Enum.to_list(Mongo.find(@conn, @team_coll, filter, [projection: project]))
    subBoothTeamIdsArray = Enum.reduce(subBoothTeamIds, [], fn k, acc ->
      acc ++ [k["_id"]]
    end)
    #find count of posts done by above booth team Ids array
    filterPostCount = %{
      "groupId" => groupObjectId,
      "teamId" => %{"$in" => subBoothTeamIdsArray},
      "type" => "teamPost",
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, totalSubBoothDiscussionCount} = Mongo.count(@conn, @posts_col, filterPostCount, [projection: project])
    totalSubBoothCount = length(subBoothTeamIdsArray)
    %{
      "totalSubBoothDiscussionCount" => totalSubBoothDiscussionCount,
      "totalSubBoothCount" => totalSubBoothCount
    }
  end



  def getTotalConstituencyAnnouncementCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "groupPost",
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @posts_col, filter, [projection: project])
  end


  def getUserIdsBelongsToGroup(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list
  end


  def getTotalUsersCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def getTotalTeamsCount(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @team_coll, filter, [projection: project])
  end


  def addTotalBoothCount(groupObjectId, totalBoothsCount) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap.totalBoothsCount" => totalBoothsCount
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def totalSubBoothsDiscussion(groupObjectId, totalSubBoothsDiscussion) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap.totalSubBoothsDiscussion" => totalSubBoothsDiscussion
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def totalSubBoothsCount(groupObjectId, totalSubBoothsCount) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap.totalSubBoothsCount" => totalSubBoothsCount
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def totalBoothDiscussionCount(groupObjectId, totalBoothDiscussionCount) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap.totalBoothDiscussionCount" => totalBoothDiscussionCount
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def totalUsersCount(groupObjectId, totalUsersCount) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap.totalUsersCount" => totalUsersCount
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end

  # def checkFeederMapExistsOrNot(groupObjectId) do
  #   filter = %{
  #     "_id" => groupObjectId,
  #     "isActive" => true,
  #   }
  #   project = %{
  #     "feederMap" => 1,
  #     "_id" => 0,
  #   }
  #   Mongo.find_one(@conn, @groups_coll, filter, [projection: project])
  # end


  def insertFeederMapToGroup(groupObjectId, feederMap) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "feederMap" => feederMap
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def getFeederMap(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "feederMap" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @groups_coll, filter, [projection: project])
  end




  def searchUserInGroup(paramsFilter) do
    searchFilter = paramsFilter["filter"]
    #regex map
    regexMap = %{ "$regex" => searchFilter, "$options" => "i" }
    #check if filter type exist in param or not
    filter = if paramsFilter["filterType"] do
      #search by name/phone/voterId
      cond do
        paramsFilter["filterType"] == "name" ->
          #serch only by name
          %{"$and" => [
            %{"$text" => %{ "$search" => searchFilter }},
            %{"name" => regexMap}
          ]}
        paramsFilter["filterType"] == "phone" ->
          #serch only by phone
          %{"$and" => [
            %{"$text" => %{ "$search" => "+91"<>searchFilter }},
            %{"phone" => regexMap}
          ]}
        paramsFilter["filterType"] == "voterId" ->
          #serch only by voterId
          %{"$and" => [
            %{"$text" => %{ "$search" => searchFilter }},
            %{"voterId" => regexMap}
          ]}
      end
    else
      #serch only by name
      %{"$and" => [
        %{"$text" => %{ "$search" => searchFilter }},
        %{"name" => regexMap}
      ]}
    end
    project = %{"_id" => 1, "name" => 1, "image" => 1, "phone" => 1}
    Mongo.find(@conn, @users_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getUserNotificationPushToken(userObjectId) do
    filter = %{
      "userId" => userObjectId
    }
    project = %{ "_id" => 0, "deviceToken" => 1, "deviceType" => 1 }
    sort = %{"_id" => -1}
    limit = 2
    Mongo.find(@conn, @user_notification_token_col, filter, [projection: project, sort: sort, limit: limit])
    |> Enum.to_list
  end




  #not used############
  def addUserToUsersColWithoutPhone(changeset) do
    #check this voter Id atready in users col
    filter = %{
      "voterId" => changeset.voterId
    }
    alreadyUserExist = Mongo.find_one(@conn, @users_col, filter)
    if !alreadyUserExist do
      Mongo.insert_one(@conn, @users_col, changeset)
    else
      {:ok, alreadyUserExist["_id"]}
    end
  end


  def incrementUsers(group) do
    filter = %{
      "_id" => group["_id"],
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalUsersCount"  => 1,
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
    feederMap =  Mongo.find_one(@conn, @groups_coll, filter, [projection: %{"feederMap" => 1, "_id" => 0}])
    if Map.has_key?(feederMap, "feederMap") do
      totalUserCountShortForm = countHelp(feederMap["feederMap"]["totalUsersCount"])
      filter = %{
        "_id" => group["_id"],
        "isActive" => true,
      }
      update = %{
        "$set" => %{
          "feederMap.totalUsersInWords" => totalUserCountShortForm,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  defp countHelp(totalUsersCount) do
    cond do
      totalUsersCount < 999 ->
        Integer.to_string(totalUsersCount)
      totalUsersCount < 9999 ->
        decimalConversion = Float.floor(totalUsersCount/1000, 2)
        Float.to_string(decimalConversion)<>"k+"
      totalUsersCount < 99999 ->
        decimalConversion = Float.floor(totalUsersCount/10000, 2)
        Float.to_string(decimalConversion)<>"k+"
      totalUsersCount < 999999 ->
        decimalConversion = Float.floor(totalUsersCount/100000, 2)
        Float.to_string(decimalConversion)<>"L+"
      totalUsersCount < 9999999 ->
        decimalConversion = Float.floor(totalUsersCount/1000000, 2)
        Float.to_string(decimalConversion)<>"L+"
    end
  end


  def checkUserKey(groupObjectId, boothTeamId) do
    filter = %{
      "_id" => boothTeamId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "usersCount" => %{
        "$exists" => false,
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  end


  def appendUsersCount(groupObjectId, teamObjectId, boothTeamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, count} = Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
    filter2 = %{
      "_id" => boothTeamId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "usersCount" => count,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter2, update)
  end


  def incrementUsersCount(groupObjectId, boothTeamId, teamObjectId) do
    filter = %{
      "_id" => boothTeamId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "usersCount" => 1,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter, update)
    filter2 = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update2 = %{
      "$inc" => %{
        "membersCount" => 1,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter2, update2)
  end


  def appendWorkersCount(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    {:ok, count} = Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
    filter2 = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "workersCount" => count,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter2, update)
  end


  def incrementWorkersCount(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "workersCount" => 1,
      }
    }
    Mongo.update_one(@conn, @team_coll, filter, update)
  end


  def getTeamsIdUser(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "teams" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def teamNames(groupObjectId, teamsObjectIds) do
    filter = %{
      "_id" => %{
        "$in" => teamsObjectIds
      },
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
    }
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def checkUserCanPost(groupObjectId, loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true
    }
    project = %{
      "canPost" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  end

end
