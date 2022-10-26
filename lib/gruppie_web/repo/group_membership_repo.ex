defmodule GruppieWeb.Repo.GroupMembershipRepo do
  # import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.GroupMembership


  @conn :mongo

  @group_team_members_col "group_team_members"


  #from groupAccessAuth
  def findUserBelongsToGroup(user_id, group_id) do
    filter = %{
      "groupId" => group_id,
      "userId" => user_id
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end


  def joinUserToGroup(loginUserId, groupObjectId) do
    insertDoc = GroupMembership.insertGroupMemberWhileJoining(loginUserId, groupObjectId)
    Mongo.insert_one(@conn, @group_team_members_col, insertDoc)
  end
end
