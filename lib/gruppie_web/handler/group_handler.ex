defmodule GruppieWeb.Handler.GroupHandler do
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamPostRepo
  alias GruppieWeb.Repo.GroupSettingsRepo
  alias GruppieWeb.Repo.GroupMembershipRepo
  import GruppieWeb.Repo.RepoHelper


  #create group UP
  def insert(conn, changeset) do
    logged_in_user = Guardian.Plug.current_resource(conn)
    GroupRepo.insert(changeset, logged_in_user)
  end


  #returns all the groups belongs to user
  def getAll(conn) do
    logged_in_user = Guardian.Plug.current_resource(conn)
    GroupRepo.getAll(logged_in_user)
  end


  def getCategoryGroups(conn, category, appName, talukName, constituency_CategoryName) do
    #IO.puts "#{appName}"
    logged_in_user = Guardian.Plug.current_resource(conn)
    if !is_nil(appName) do
      #IO.puts "#{"appName exist"}"
      GroupRepo.getCategoryGroupsByAppName(logged_in_user, category, appName)
    else
      #check talukName is exist
      if !is_nil(talukName) do
        #get groups belongs to taluk
        GroupRepo.getCategoryGroupsByTalukName(logged_in_user, category, talukName)
      else
        #get groups belongs to constituency categoryName
        if !is_nil(constituency_CategoryName) do
          #get groups belongs to taluk
          GroupRepo.getCategoryGroupsByConstituencyCategoryName(logged_in_user, category, constituency_CategoryName)
        else
          #IO.puts "#{"appName does not exist"}"
          GroupRepo.getCategoryGroups(logged_in_user, category)
        end
      end
    end
  end


  def update(changeset, groupId) do
    groupObjectId = decode_object_id(groupId)
    GroupRepo.update(changeset, groupObjectId)
  end


  def delete(_conn, group_id) do
    groupObjectId = decode_object_id(group_id)
    #get group users count
    {:ok, count} = GroupRepo.getTotalUsersCount(groupObjectId)
    if count > 1 do
       {:notAllowed, count}
    else
       GroupRepo.delete(groupObjectId)
    end
  end


  def allowAdminChangeSetting(group) do
    if group["isAdminChangeAllowed"] == false do
      #update to true
      GroupSettingsRepo.changeAdminAllow(group["_id"], true)
    else
      #update to false
      GroupSettingsRepo.changeAdminAllow(group["_id"], false)
    end
  end


  def postShareAllowSetting(group) do
    if group["isPostShareAllowed"] == false do
      #update to true
      GroupSettingsRepo.postShareAllow(group["_id"], true)
    else
      #update to false
      GroupSettingsRepo.postShareAllow(group["_id"], false)
    end
  end


  def allowPostAllSetting(group) do
    if group["allowPostAll"] == false do
      #update to true
      GroupSettingsRepo.allowPostAll(group["_id"], true)
    else
      #update to false
      GroupSettingsRepo.allowPostAll(group["_id"], false)
    end
  end


  def joinUserToPublicGroupDirectly(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    #find user already a group member
    {:ok, checkUserAlreadyInGroup} = GroupRepo.checkUserAlreadyInGroup(loginUser["_id"], groupObjectId)
    if checkUserAlreadyInGroup > 0 do
      #user alreday in group
      {:error, "already exist"}
    else
      #join user to group directly
      GroupMembershipRepo.joinUserToGroup(loginUser["_id"], groupObjectId)
    end
  end


  def addLiveTestExamEvent(loginUser, groupObjectId, team_id, subject_id, testexam_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    testexamObjectId = decode_object_id(testexam_id)
    #check this testexam event for this team is already exist
    {:ok, count} = GroupRepo.checkLiveTestExamEvent(groupObjectId, teamObjectId, subjectObjectId, testexamObjectId)
    if count == 0 do
      GroupRepo.addLiveTestExamEvent(loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId)
    else
      #update time for the existing event
      GroupRepo.updateLiveTestExamEvent(loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId)
    end
    #secondly create live class event for this meetingId
    #check this liveCalss event for this team is already exist
    {:ok, count} = GroupRepo.checkLiveClassEvent(groupObjectId, teamObjectId)
    if count == 0 do
      GroupRepo.addLiveClassEvent(loginUser, groupObjectId, teamObjectId, new_object_id())
    else
      #update time for the existing event
      GroupRepo.updateLiveClassEvent(loginUser, groupObjectId, teamObjectId, new_object_id())
    end
  end


  def removeLiveTestExamEvent(loginUser, groupObjectId, team_id, subject_id, testexam_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    testexamObjectId = decode_object_id(testexam_id)
    #first, remove live test event
    GroupRepo.removeLiveTestExamEvent(loginUser, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId)
    #secondly remove live class event
    TeamPostRepo.endLiveClassEvent(loginUser["_id"], groupObjectId, teamObjectId)
  end


  def getEventsListForSchoolGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getEventsListForSchoolGroup(groupObjectId, loginUserId)
  end



  def getLiveClassEventsListForGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getLiveClassEventsListForGroup(groupObjectId, loginUserId)
  end


  def getLiveTestExamEventsListForGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getLiveTestExamEventsListForGroup(groupObjectId, loginUserId)
  end



  def addGroupPostEvent(insertedPostId, groupObjectId) do
    #check this group post event is already exist
    {:ok, count} = GroupRepo.checkGroupPostEvent(groupObjectId)
    if count == 0 do
      GroupRepo.addGroupPostEvent(insertedPostId, groupObjectId)
    else
      #update time for the existing event
      GroupRepo.updateGroupPostEvent(insertedPostId, groupObjectId)
    end
  end


  def addGroupGalleryEvent(groupObjectId) do
    #check this group gallery event is already exist
    {:ok, count} = GroupRepo.checkGroupGalleryEvent(groupObjectId)
    if count == 0 do
      GroupRepo.addGroupGalleryPostEvent(groupObjectId)
    else
      #update time for the existing event
      GroupRepo.updateGroupGalleryPostEvent(groupObjectId)
    end
  end


  def addGroupCalendarEvent(groupObjectId) do
    #check this group calendar event is already exist
    {:ok, count} = GroupRepo.checkGroupCalendarEvent(groupObjectId)
    if count == 0 do
      GroupRepo.addGroupCalendarPostEvent(groupObjectId)
    else
      #update time for the existing event
      GroupRepo.updateGroupCalendarPostEvent(groupObjectId)
    end
  end


  def addTeamPostEvent(insertedPostId, groupId, teamId) do
    groupObjectId = decode_object_id(groupId)
    teamObjectId = decode_object_id(teamId)
    #check this group post event is already exist
    {:ok, count} = GroupRepo.checkTeamPostEvent(groupObjectId, teamObjectId)
    if count == 0 do
      GroupRepo.addTeamPostEvent(insertedPostId, groupObjectId, teamObjectId)
    else
      #update time for the existing event
      GroupRepo.updateTeamPostEvent(insertedPostId, groupObjectId, teamObjectId)
    end
  end


  def addAssignmentEvent(insertedAssignmentId, groupObjectId, teamObjectId, subjectObjectId) do
    #check this assignment event is already exist
    {:ok, count} = GroupRepo.checkAssignmentEvent(groupObjectId, teamObjectId, subjectObjectId)
    if count == 0 do
      GroupRepo.addAssignmentEvent(insertedAssignmentId, groupObjectId, teamObjectId, subjectObjectId)
    else
      #update time for the existing event
      GroupRepo.updateAssignmentEvent(insertedAssignmentId, groupObjectId, teamObjectId, subjectObjectId)
    end
  end


  def addTestExamEvent(insertedTestExamId, groupObjectId, teamObjectId, subjectObjectId) do
    #check this testexam event is already exist
    {:ok, count} = GroupRepo.checkTestExamEvent(groupObjectId, teamObjectId, subjectObjectId)
    if count == 0 do
      GroupRepo.addTestExamEvent(insertedTestExamId, groupObjectId, teamObjectId, subjectObjectId)
    else
      #update time for the existing event
      GroupRepo.updateTestExamEvent(insertedTestExamId, groupObjectId, teamObjectId, subjectObjectId)
    end
  end


  def addNotesAndVideosEvent(insertedNotesId, groupObjectId, teamObjectId, subjectObjectId) do
    #check this notes and videos event is already exist
    {:ok, count} = GroupRepo.checkNotesAndVideosEvent(groupObjectId, teamObjectId, subjectObjectId)
    if count == 0 do
      GroupRepo.addNotesAndVideosEvent(insertedNotesId, groupObjectId, teamObjectId, subjectObjectId)
    else
      #update time for the existing event
      GroupRepo.updateNotesAndVideosEvent(insertedNotesId, groupObjectId, teamObjectId, subjectObjectId)
    end
  end



  def getListOfTaluks(loginUserId) do
    #first get list of groupIds for login user
    groupIds = GroupRepo.getListOfGroupIdsForLoginUser(loginUserId)
    groupIdList = Enum.reduce(groupIds, [], fn k, acc ->
      [k["groupId"]] ++ acc
    end)
    #now find taluks for the grupIds
    GroupRepo.getTaluksListForSchoolGroup(groupIdList)
  end


  def getConstituencyGroupsCategoryList(loginUserId, constituencyName) do
    #first get list of groupIds for login user
    groupIds = GroupRepo.getListOfGroupIdsForLoginUser(loginUserId)
    groupIdList = Enum.reduce(groupIds, [], fn k, acc ->
      [k["groupId"]] ++ acc
    end)
    #now find constituency group category for the grupIds
    getConstituencyCategories = GroupRepo.getConstituencyGroupsCategoryList(groupIdList, constituencyName)
    #now check on each constituency category how many groups are there for login user
    Enum.reduce(getConstituencyCategories, [], fn k, acc ->
      #get groups count belongs to same constituency and category name
      getCategoryGroupCount = GroupRepo.getGroupsCountForConstituencyCategory(k, groupIdList, loginUserId)
      #check group count is more than one, if equal to 1 then provide that groupId, groupName and groupImage
      if length(getCategoryGroupCount) == 1 do
        k
        |> Map.put_new("groupId", hd(getCategoryGroupCount)["groupId"])
        |> Map.put_new("groupName", hd(getCategoryGroupCount)["groupDetails"]["name"])
        |> Map.put_new("groupImage", hd(getCategoryGroupCount)["groupDetails"]["avatar"])
        |> Map.put_new("isAdmin", hd(getCategoryGroupCount)["isAdmin"])
        |> Map.put_new("canPost", hd(getCategoryGroupCount)["canPost"])
        |> Map.put_new("groupCount", 1)
      else
        k
        |> Map.put_new("groupCount", length(getCategoryGroupCount))
      end
      [k] ++ acc
    end)
    #IO.puts "#{constituencyCategoryList}"
  end


end
