defmodule GruppieWeb.Repo.FriendRepo do

  @conn :mongo

  @view_teams_col "VW_TEAMS"

  @user_col "users"



  def getMyPeople(teamAdminId, groupObjectId) do
    #get all the teams of login user
    filter = %{ "groupId" => groupObjectId, "teamDetails.adminId" => teamAdminId, "teams.isTeamAdmin" => false, "isActive" => true }
    project = %{ "_id" => 0, "userId" => 1 }
    Mongo.distinct(@conn, @view_teams_col, "userId", filter, [projection: project])
  end


  def getMyPeopleDetails(peopleId) do
    filter = %{ "_id" => %{ "$in" => peopleId } }
    projection = %{ "_id" => 1, "name" => 1, "phone" => 1, "image" => 1 }
    Enum.to_list(Mongo.find(@conn, @user_col, filter, [projection: projection]))
  end


  def getMyPeopleCount(teamAdminId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamDetails.adminId" => teamAdminId, "teams.isTeamAdmin" => false, "isActive" => true }
    {:ok, peopleId} = Mongo.distinct(@conn, @view_teams_col, "userId", filter)
    length(peopleId)
  end




end
