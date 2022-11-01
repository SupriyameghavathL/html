defmodule GruppieWeb.Handler.VoterAnalysisHandler do
  alias GruppieWeb.Repo.VoterAnalysisRepo
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  import GruppieWeb.Handler.TimeNow


  def checkVoterListCreated(groupObjectId, teamObjectId) do
    {:ok, existed} = VoterAnalysisRepo.checkVoterListCreated(groupObjectId, teamObjectId)
    if existed == 0 do
      insertDoc = %{
        "groupId" => groupObjectId,
        "teamId" => teamObjectId,
        "isActive" => true,
        "insertedAt" => bson_time(),
        "updatedAt" => bson_time(),
        "voterDetails" => []
      }
      VoterAnalysisRepo.insertDoc(insertDoc)
    end
  end


  def pushToArray(groupObjectId, teamObjectId, voterDetailsMap) do
    VoterAnalysisRepo.pushToArray(groupObjectId, teamObjectId, voterDetailsMap)
  end


  # def voterDetails(voterDoc) do
  #   VoterAnalysisRepo.insertDoc(voterDoc)
  # end


  def getVotersDetailsBooth(groupObjectId, teamObjectId) do
    VoterAnalysisRepo.getVotersDetailsBooth(groupObjectId, teamObjectId)
  end


  def deleteVotersFromList(groupObjectId, teamObjectId, deletedUsersIds) do
    VoterAnalysisRepo.deleteVotersFromList(groupObjectId, teamObjectId, deletedUsersIds)
  end


  def getBoothPost(groupObjectId, pageNo) do
    #getting team id beloging to booths
    VoterAnalysisRepo.getBoothsIds(groupObjectId, pageNo)
  end


  def getWorkers(groupObjectId, params) do
    boothWorkersUsersIdList = ConstituencyCategoryRepo.getIdsBoothWorkers(groupObjectId)
    boothWorkersIds = for userId <- boothWorkersUsersIdList do
      userId["adminId"]
    end
    VoterAnalysisRepo.getUserDetails(boothWorkersIds, params)
  end


  def getUsers(groupObjectId, filter) do
    boothWorkersUsersIdList = ConstituencyCategoryRepo.getIdsBoothWorkers(groupObjectId)
    boothWorkersIds = for userId <- boothWorkersUsersIdList do
      userId["adminId"]
    end
    VoterAnalysisRepo.getUserDetailsBasedOnFilter(boothWorkersIds, filter)
  end


  def getTeamUsers(groupObjectId, teamObjectId, filter) do
    teamUsersList = VoterAnalysisRepo.getTeamUsersList(groupObjectId, teamObjectId)
    teamUserIdList = for user <- teamUsersList do
      user["userId"]
    end
    VoterAnalysisRepo.getUserDetailsBasedOnFilter(teamUserIdList, filter)
  end
end
