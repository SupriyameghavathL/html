defmodule GruppieWeb.Handler.SuggestionBoxHandler do
  alias GruppieWeb.Repo.SuggestionBoxRepo


  def postSuggestionByParents(changeset, groupObjectId, userObjectId) do
    SuggestionBoxRepo.postSuggestionByParents(changeset, groupObjectId, userObjectId)
  end


  def checkCanPostTrue(groupObjectId, userObjectId) do
    SuggestionBoxRepo.checkCanPostTrue(groupObjectId, userObjectId)
  end


  def getAllSuggestionPost(groupObjectId, params) do
    SuggestionBoxRepo.getAllSuggestionPost(groupObjectId, params)
  end


  def getPostPostedByUser(groupObjectId, userObjectId) do
    SuggestionBoxRepo.getPostPostedByUser(groupObjectId, userObjectId)
  end


  def getNotesFeedTopic(groupObjectId, teamObjectId, topicId) do
    SuggestionBoxRepo.getNotesFeedTopic(groupObjectId, teamObjectId, topicId)

  end


  def getNotesFeed(groupObjectId, teamObjectId, postObjectId) do
    SuggestionBoxRepo.getNotesFeed(groupObjectId, teamObjectId, postObjectId)
  end


  def getHomeWorksFeed(groupObjectId, teamObjectId, postObjectId) do
    SuggestionBoxRepo.getHomeWorksFeed(groupObjectId, teamObjectId, postObjectId)
  end

  def getSuggestionBoxPostForAdmin(groupObjectId) do
    SuggestionBoxRepo.getSuggestionBoxPostForAdmin(groupObjectId)
  end

  def getSuggestionBoxPostForUser(groupObjectId, loginUserId) do
    SuggestionBoxRepo.getSuggestionBoxPostForUser(groupObjectId, loginUserId)
  end


end
