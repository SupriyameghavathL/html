defmodule GruppieWeb.Handler.ConstituencyCategoryHandler do
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow


  def addCategoriesToDb(groupObjectId, categories) do
    ConstituencyCategoryRepo.addCategoriesToDb(groupObjectId, categories)
  end


  def getCategoriesFromDb(groupObjectId) do
    ConstituencyCategoryRepo.getCategoriesFromDb(groupObjectId)
  end


  def addCategoriesTypeToDb(groupObjectId, categoryTypes) do
    ConstituencyCategoryRepo.addCategoriesTypeToDb(groupObjectId, categoryTypes)
  end


  def getCategoriesTypeFromDb(groupObjectId) do
    ConstituencyCategoryRepo.getCategoriesTypeFromDb(groupObjectId)
  end


  def userListBasedOnFilter(groupObjectId, params) do
    cond do
      params["categoryType"] == "1" ->
      boothPresidentUsersIdList = ConstituencyCategoryRepo.getIdsBoothPresident(groupObjectId)
      boothPresidentIds = for userId <- boothPresidentUsersIdList do
        userId["adminId"]
      end
      ConstituencyCategoryRepo.getUserListBasedOnFilter(params, boothPresidentIds)
      params["categoryType"] == "2" ->
      boothWorkersUsersIdList = ConstituencyCategoryRepo.getIdsBoothWorkers(groupObjectId)
      boothWorkersIds = for userId <- boothWorkersUsersIdList do
        userId["adminId"]
      end
      ConstituencyCategoryRepo.getUserListBasedOnFilter(params, boothWorkersIds)
      true ->
      ConstituencyCategoryRepo.getUserListBasedOnFilter(params, "")
    end
  end


  def addSpecialPostBasedOnFilter(changeset, groupObjectId, userObjectId) do
    ConstituencyCategoryRepo.addSpecialPostBasedOnFilter(changeset, groupObjectId, userObjectId)
  end


  def checkCanPost(groupObjectId, userObjectId) do
    ConstituencyCategoryRepo.checkCanPost(groupObjectId, userObjectId)
  end


  def getSpecialPostBasedOnFilter(groupObjectId, loginUser, params) do
    #getting teams Ids from groupTeamMembers db
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamIds = for teamId <- getTeamIds["teams"] do
      encode_object_id(teamId["teamId"])
    end
    checkBoothPresident =  ConstituencyCategoryRepo.checkBoothPresident(groupObjectId, loginUser["_id"])
    checkBoothWorker = ConstituencyCategoryRepo.checkBoothWorker(groupObjectId, loginUser["_id"])
    checkCitizen = ConstituencyCategoryRepo.checkCitizen(groupObjectId, loginUser["_id"])
    cond do
      #checking whether loginUser is president, worker, citizen
      checkBoothPresident && checkBoothWorker && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesALL(groupObjectId, loginUser, params, teamIds)
      #checking whether loginUser is president,citizen
      checkBoothPresident && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllPresident(groupObjectId, loginUser, params, teamIds)
      #checking whether loginUser is worker,citizen
      checkBoothWorker && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllBoothWorker(groupObjectId, loginUser, params, teamIds)
      #checking whether loginUser is citizen
      true ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllCitizen(groupObjectId, loginUser, params, teamIds)
   end
  end


  def getSpecialPostBasedForAdmin(groupObjectId) do
    ConstituencyCategoryRepo.getSpecialPostBasedForAdmin(groupObjectId)
  end


  def addLikesToSpecialPost(groupObjectId, postObjectId, userObjectId) do
    {:ok , count} = ConstituencyCategoryRepo.getUserLikeThePost(groupObjectId, postObjectId, userObjectId)
    if count == 0  do
      likedUserDoc = %{
        "userId" => userObjectId,
        "insertedAt" => bson_time(),
      }
      ConstituencyCategoryRepo.addLikesToSpecialPost(groupObjectId, postObjectId, userObjectId, likedUserDoc)
    else
      ConstituencyCategoryRepo.addDisLikeToSpecialPost(groupObjectId, postObjectId, userObjectId)
    end
  end


  def deleteSpecialPost(groupObjectId, postId) do
    postObjectId = decode_object_id(postId)
    ConstituencyCategoryRepo.deleteSpecialPost(groupObjectId, postObjectId)
  end


  #events api queries
  def getSpecialPostBasedForAdminEvents(groupObjectId) do
    ConstituencyCategoryRepo.getSpecialPostBasedForAdminEvents(groupObjectId)
  end

  def getSpecialPostBasedOnFilterEvents(groupObjectId, loginUser) do
    #getting teams Ids from groupTeamMembers db
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamIds = for teamId <- getTeamIds["teams"] do
      encode_object_id(teamId["teamId"])
    end
    checkBoothPresident =  ConstituencyCategoryRepo.checkBoothPresident(groupObjectId, loginUser["_id"])
    checkBoothWorker = ConstituencyCategoryRepo.checkBoothWorker(groupObjectId, loginUser["_id"])
    checkCitizen = ConstituencyCategoryRepo.checkCitizen(groupObjectId, loginUser["_id"])
    cond do
      #checking whether loginUser is president, worker, citizen
      checkBoothPresident && checkBoothWorker && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesALLEvents(groupObjectId, loginUser, teamIds)
      #checking whether loginUser is president,citizen
      checkBoothPresident && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllPresidentEvents(groupObjectId, loginUser, teamIds)
      #checking whether loginUser is worker,citizen
      checkBoothWorker && checkCitizen ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllBoothWorkerEvents(groupObjectId, loginUser, teamIds)
      #checking whether loginUser is citizen
      true ->
        ConstituencyCategoryRepo.getSpecialPostBasedOnAllTypesAllCitizenEvents(groupObjectId, loginUser, teamIds)
   end
  end


  def getInstalledAndVoterUsers(feederMap) do
    # feederMap = group["feederMap"]
    #get total no of user installed app
    {:ok, userInstalledApp} = ConstituencyCategoryRepo.getTotalUsersInstalledApp()
    #get voter updated users
    # {:ok, votersCount} = ConstituencyCategoryRepo.getTotalVoters()
    %{
      "totalUserInstalledApp" => userInstalledApp,
      # "totalVotersCount" => votersCount,
      "totalUsers" => feederMap["totalUsersCount"]
    }
  end


  def addProfileExtraFields(groupObjectId, voterAnalysisFields) do
    #to check whether document is created or not
    {:ok, existed} = ConstituencyCategoryRepo.checkExtraFieldCreated(groupObjectId)
    if existed == 0 do
      insertDoc = %{
        "groupId" => groupObjectId,
        "isActive" => true,
        "voterAnalysisFields" => voterAnalysisFields
      }
      ConstituencyCategoryRepo.insertDocToDb(insertDoc)
    else
      ConstituencyCategoryRepo.pushToExistingArray(groupObjectId, voterAnalysisFields)
    end
  end


  def getAnalysisFields(groupObjectId) do
    ConstituencyCategoryRepo.getAnalysisFields(groupObjectId)
  end


  def getUserListBasedOnSearch(groupObjectId, params) do
    cond do
      params["categoryType"] == "1" ->
      boothPresidentUsersIdList = ConstituencyCategoryRepo.getIdsBoothPresident(groupObjectId)
      boothPresidentIds = for userId <- boothPresidentUsersIdList do
        userId["adminId"]
      end
      ConstituencyCategoryRepo.getUserListBasedOnSearch(params, boothPresidentIds)
      params["categoryType"] == "2" ->
      boothWorkersUsersIdList = ConstituencyCategoryRepo.getIdsBoothWorkers(groupObjectId)
      boothWorkersIds = for userId <- boothWorkersUsersIdList do
        userId["adminId"]
      end
      ConstituencyCategoryRepo.getUserListBasedOnSearch(params, boothWorkersIds)
      true ->
      ConstituencyCategoryRepo.getUserListBasedOnSearch(params, "")
    end
  end


  def getActiveUsers(groupObjectId, getUserOnSearchList) do
    userIdsList = for userId <- tl(getUserOnSearchList) do
      userId["_id"]
    end
    activeUserList = ConstituencyCategoryRepo.getActiveUsers(groupObjectId, userIdsList)
    Enum.map(activeUserList, fn k ->
      userWithTeamMap = Enum.find(tl(getUserOnSearchList), fn v -> v["_id"] == k["userId"] end)
      if userWithTeamMap do
        Map.merge(k, userWithTeamMap)
      end
    end)
  end


  def getUserList() do
    ConstituencyCategoryRepo.getUserList()
  end


  def updateNames(name) do
    ConstituencyCategoryRepo.updateNames(name)
  end


  def getBoothMembersTeams(groupObjectId, params) do
    ConstituencyCategoryRepo.getBoothMembersTeams(groupObjectId, params)
  end


  def getTeamUsersList(groupObjectId, teamObjectId, params) do
    ConstituencyCategoryRepo.getTeamUsersList(groupObjectId, teamObjectId, params)
  end


  def getBoothTeamMembersList(groupObjectId, teamObjectId, params) do
     # 1. Get all the userIds belongs to this team from group_team_mem
     usersWithTeam = ConstituencyCategoryRepo.getTeamUsersListGroup(groupObjectId, teamObjectId, params)
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
     userDetailsList = ConstituencyRepo.getUserDetailsForTeam(userIds)
     # Now merge two lists based on _id and userId
      Enum.map(usersWithTeamList, fn k ->
       userWithTeamMap = Enum.find(userDetailsList, fn v -> v["_id"] == k["userId"] end)
       if userWithTeamMap do
         Map.merge(k, userWithTeamMap)
       end
     end)
  end


  def getBoothTeamMembersCommitteeList(groupObjectId, teamObjectId, params) do
    # 1. Get all the userIds belongs to this team from group_team_mem
    usersWithTeam = ConstituencyCategoryRepo.getTeamUsersListByCommitteeIdList(groupObjectId, teamObjectId, params)
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
    userDetailsList = ConstituencyRepo.getUserDetailsForTeam(userIds)
    # Now merge two lists based on _id and userId
    Enum.map(usersWithTeamList, fn k ->
      userWithTeamMap = Enum.find(userDetailsList, fn v -> v["_id"] == k["userId"] end)
      if userWithTeamMap do
        Map.merge(k, userWithTeamMap)
      end
    end)
  end
end
