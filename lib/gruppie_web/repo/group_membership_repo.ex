defmodule GruppieWeb.Repo.GroupMembershipRepo do
  # import GruppieWeb.Repo.RepoHelper


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
end
