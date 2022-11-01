defmodule GruppieWeb.Repo.GroupMembershipRepo do

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



    # def check_my_friend(group_id, login_user_id, adding_user_id) do
    #   filter = %{
    #     "group.group_id" => group_id,
    #     "referrers.referrer_id" => login_user_id,
    #     "user.user_id" => adding_user_id
    #   }
    #   project = %{"_id" => 1}
    #   Mongo.count(@conn, @group_membership, filter, [projection: project, limit: 1])
    # end



    def joinUserToGroup(loginUserId, groupObjectId) do
      insertDoc = GroupMembership.insertGroupMemberWhileJoining(loginUserId, groupObjectId)
      Mongo.insert_one(@conn, @group_team_members_col, insertDoc)
    end




end
