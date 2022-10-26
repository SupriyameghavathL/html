defmodule GruppieWeb.Handler.GroupHandler do
  alias GruppieWeb.Repo.GroupRepo
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


  def getEventsListForSchoolGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getEventsListForSchoolGroup(groupObjectId, loginUserId)
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


  def getLiveClassEventsListForGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getLiveClassEventsListForGroup(groupObjectId, loginUserId)
  end


  def getLiveTestExamEventsListForGroup(loginUserId, groupObjectId) do
    #get event list for groupPost, teamPost...etc
    GroupRepo.getLiveTestExamEventsListForGroup(groupObjectId, loginUserId)
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


end
