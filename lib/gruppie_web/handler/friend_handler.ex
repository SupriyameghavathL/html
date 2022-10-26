defmodule GruppieWeb.Handler.FriendHandler do
  alias GruppieWeb.Repo.FriendRepo

  def getMyPeople(loginUserId, groupObjectId) do
    #get my people in all teams
    {:ok, peopleId} = FriendRepo.getMyPeople(loginUserId, groupObjectId)
    #get details of userId
    userList = FriendRepo.getMyPeopleDetails(peopleId)
    userList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end

end
