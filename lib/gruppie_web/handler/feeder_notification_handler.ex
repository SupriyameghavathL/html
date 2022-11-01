defmodule GruppieWeb.Handler.FeederNotificationHandler do
  alias GruppieWeb.Repo.FeederNotificationRepo
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.ConstituencyCategoryRepo


  def getAllPostForAdmin(groupObjectId, params) do
    FeederNotificationRepo.getAllPostForAdmin(groupObjectId, params)
  end


  def getAllPostForUser(groupObjectId, loginUser, params)  do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamIds = for teamId <- getTeamIds["teams"] do
      encode_object_id(teamId["teamId"])
    end
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    checkBoothPresident =  ConstituencyCategoryRepo.checkBoothPresident(groupObjectId, loginUser["_id"])
    checkBoothWorker = ConstituencyCategoryRepo.checkBoothWorker(groupObjectId, loginUser["_id"])
    checkCitizen = ConstituencyCategoryRepo.checkCitizen(groupObjectId, loginUser["_id"])
    cond do
      #checking whether loginUser is president, worker, citizen
      checkBoothPresident && checkBoothWorker && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesALL(groupObjectId, loginUser, params, teamIds, teamObjectIds)
      #checking whether loginUser is president,citizen
      checkBoothPresident && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllPresident(groupObjectId, loginUser, params, teamIds, teamObjectIds)
      #checking whether loginUser is worker,citizen
      checkBoothWorker && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllBoothWorker(groupObjectId, loginUser, params, teamIds, teamObjectIds)
      #checking whether loginUser is citizen
      true ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllCitizen(groupObjectId, loginUser, params, teamIds, teamObjectIds)
     end
  end


  def getAllPostForAdminSchool(groupObjectId, params) do
    FeederNotificationRepo.getAllPostForAdminSchool(groupObjectId, params)
  end


  def getAllHomeWorkPostAdmin(groupObjectId, params) do
    FeederNotificationRepo.getAllHomeWorkPostAdmin(groupObjectId, params)
  end


  def getAllNotesAndVideosPostAdmin(groupObjectId, params) do
    FeederNotificationRepo.getAllNotesAndVideosPostAdmin(groupObjectId, params)
  end

  def getAllPostForUserSchool(groupObjectId, loginUser, params) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllPostForUserSchool(groupObjectId, teamObjectIds, params, loginUser["_id"])
  end


  def getAllHomeWorkPostUser(groupObjectId, loginUser, params) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllHomeWorkPostUser(groupObjectId, teamObjectIds, params)
  end


  def getAllNotesAndVideosPostUser(groupObjectId, loginUser, params) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllNotesAndVideosPostUser(groupObjectId, teamObjectIds, params)
  end


  #events api function
  def getAllPostForAdminEvents(groupObjectId) do
    FeederNotificationRepo.getAllPostForAdminEvents(groupObjectId)
  end


  def getAllPostForUserEvent(groupObjectId, loginUser)  do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamIds = for teamId <- getTeamIds["teams"] do
      encode_object_id(teamId["teamId"])
    end
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      if !Map.has_key?(teamId, "blocked") do
        teamId["teamId"]
      end
    end
    |> Enum.reject(&is_nil/1)
    checkBoothPresident =  ConstituencyCategoryRepo.checkBoothPresident(groupObjectId, loginUser["_id"])
    checkBoothWorker = ConstituencyCategoryRepo.checkBoothWorker(groupObjectId, loginUser["_id"])
    checkCitizen = ConstituencyCategoryRepo.checkCitizen(groupObjectId, loginUser["_id"])
    cond do
      #checking whether loginUser is president, worker, citizen
      checkBoothPresident && checkBoothWorker && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesALLEvent(groupObjectId, loginUser, teamIds, teamObjectIds)
      #checking whether loginUser is president,citizen
      checkBoothPresident && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllPresidentEvents(groupObjectId, loginUser, teamIds, teamObjectIds)
      #checking whether loginUser is worker,citizen
      checkBoothWorker && checkCitizen ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllBoothWorkerEvents(groupObjectId, loginUser, teamIds, teamObjectIds)
      #checking whether loginUser is citizen
      true ->
        FeederNotificationRepo.getAllPostBasedOnAllTypesAllCitizenEvents(groupObjectId, loginUser, teamIds, teamObjectIds)
     end
  end


  def getAllPostForAdminSchoolEvents(groupObjectId) do
    FeederNotificationRepo.getAllPostForAdminSchoolEvents(groupObjectId)
  end


  def getAllHomeWorkPostAdminEvents(groupObjectId) do
    FeederNotificationRepo.getAllHomeWorkPostAdminEvents(groupObjectId)
  end


  def getAllNotesAndVideosPostAdminEvents(groupObjectId) do
    FeederNotificationRepo.getAllNotesAndVideosPostAdminEvents(groupObjectId)
  end


  def getAllPostForUserSchoolEvents(groupObjectId, loginUser) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllPostForUserSchoolEvents(groupObjectId, teamObjectIds)
  end


  def getAllHomeWorkPostUserEvents(groupObjectId, loginUser) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllHomeWorkPostUserEvents(groupObjectId, teamObjectIds)
  end


  def getAllNotesAndVideosPostUserEvents(groupObjectId, loginUser) do
    getTeamIds = ConstituencyCategoryRepo.getTeamIds(groupObjectId, loginUser["_id"])
    teamObjectIds = for teamId <- getTeamIds["teams"] do
      teamId["teamId"]
    end
    FeederNotificationRepo.getAllNotesAndVideosPostUserEvents(groupObjectId, teamObjectIds)
  end


  def addReportsListToDb(reports) do
    FeederNotificationRepo.addReportsListToDb(reports)
  end


  def getReportsListToDb() do
    FeederNotificationRepo.getReportsListToDb()
  end


  def getTeamsArrayConstituencyAdmin(groupObjectId, userObjectId, params) do
    teamsList = FeederNotificationRepo.getTeamsArray(groupObjectId, userObjectId)
    teamIdList = for teamMap <- teamsList["teams"] do
      teamMap["teamId"]
    end
    FeederNotificationRepo.getTeamsConstituencyAdmin(groupObjectId, teamIdList, params)
  end


  def getTeamsArrayUser(groupObjectId, userObjectId, params) do
    teamsList = FeederNotificationRepo.getTeamsArray(groupObjectId, userObjectId)
    teamIdList = for teamMap <- teamsList["teams"] do
      if teamMap["allowedToAddPost"] == true do
        teamMap["teamId"]
      end
    end
    |> Enum.reject(&is_nil/1)
    FeederNotificationRepo.getTeamsUserId(groupObjectId, teamIdList, params)
  end


  def getTeamsArraySchoolAdmin(groupObjectId, userObjectId, params) do
    teamsList = FeederNotificationRepo.getTeamsArray(groupObjectId, userObjectId)
    teamIdList = for teamMap <- teamsList["teams"] do
      teamMap["teamId"]
    end
    FeederNotificationRepo.getTeamsSchoolAdmin(groupObjectId, teamIdList, params)
  end

  def getTeamsArrayCommunityAdmin(groupObjectId, userObjectId, params) do
    teamsList = FeederNotificationRepo.getTeamsArray(groupObjectId, userObjectId)
    teamIdList = for teamMap <- teamsList["teams"] do
      teamMap["teamId"]
    end
    FeederNotificationRepo.getTeamsArrayCommunityAdmin(groupObjectId, teamIdList, params)
  end


  def getPostDetails(postObjectId) do
    FeederNotificationRepo. getPostDetails(postObjectId)
  end


  def getLanguageListClass(groupObjectId, teamObjectId) do
    FeederNotificationRepo.getLanguageListClass(groupObjectId, teamObjectId)
  end

  def getLanguages() do
    FeederNotificationRepo.getLanguages()
  end

  def postLanguages(params) do
    FeederNotificationRepo.postLanguages(params["languages"])
  end


  def getPostForUniqueId(groupObjectId) do
    postList = FeederNotificationRepo.getPostForUniqueId(groupObjectId)
    for post <- postList do
      post = post
      |> Map.put("uniquePostId", encode_object_id(new_object_id()))
      FeederNotificationRepo.updatePost(groupObjectId, post, post["_id"])
    end
  end
end
