defmodule GruppieWeb.Handler.UserBlockHandler do
  alias GruppieWeb.Repo.UserBlockRepo


  def blockUser(groupObjectId, userObjectId, teamObjectId) do
    UserBlockRepo.blockUser(groupObjectId, userObjectId, teamObjectId)
  end


  def leaveTeam(groupObjectId, userObjectId, teamObjectId) do
    UserBlockRepo.leaveTeam(groupObjectId, userObjectId, teamObjectId)
  end


  def unblockUser(groupObjectId, teamObjectId, userObjectId) do
    UserBlockRepo.unblockUser(groupObjectId, teamObjectId, userObjectId)
  end


  def changeAdmin(groupObjectId, userObjectId, teamObjectId) do
    UserBlockRepo.changeAdmin(groupObjectId, teamObjectId, userObjectId)
  end

end
