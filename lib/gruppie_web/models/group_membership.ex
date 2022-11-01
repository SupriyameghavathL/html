defmodule GruppieWeb.GroupMembership do
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Repo.RepoHelper


  def insertGroupMemberWhileGroupCreate(_changeset, login_user, groupMap) do
    map = %{
      "userId" => login_user["_id"],
      "groupId" => groupMap._id,
      "isAdmin" => true,
      "canPost" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [],
      "groupPostLastSeen" => bson_time(),
      "messageInboxLastSeen" => bson_time(),
      "notificationLastSeen" => bson_time()
    }
    if groupMap.category == "school" do
      map
      |> Map.put("galleryLastSeen", bson_time())
      |> Map.put("timeTableLastSeen", bson_time())
    else
      map
    end
  end


  def insertGroupTeamMemberWhileAddingStaff(userObjectId, group) do
    map = %{
      "userId" => userObjectId,
      "groupId" => group["_id"],
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [],
      "groupPostLastSeen" => bson_time(),
      "messageInboxLastSeen" => bson_time(),
      "notificationLastSeen" => bson_time()
    }
    if group["category"] == "school" do
      map
      |> Map.put("galleryLastSeen", bson_time())
      |> Map.put("timeTableLastSeen", bson_time())
    else
      map
    end
  end


  def insertGroupTeamMemberWhileAddingUser(userObjectId, group, teamObjectId, userName) do
    #to check team is allowed to post or comment or adding users
    team = TeamRepo.get(encode_object_id(teamObjectId))
    map = %{
      "userId" => userObjectId,
      "groupId" => group["_id"],
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [%{
         "teamId" => teamObjectId,
         "userName" => userName,
         "isTeamAdmin" => false,
         "allowedToAddUser" => if team["allowUserToAddOtherUser"] == true do true else false end,
         "allowedToAddPost" => if team["allowTeamPostAll"] == true do true else false end,
         "allowedToAddComment" => if team["allowTeamPostCommentAll"] == true do true else false end,
         "insertedAt" => bson_time(),
         "updatedAt" => bson_time(),
         "teamPostLastSeen" => bson_time(),
        }],
      "groupPostLastSeen" => bson_time(),
      "messageInboxLastSeen" => bson_time(),
      "notificationLastSeen" => bson_time()
    }
    #IO.puts "#{map}"
    if group["category"] == "school" do
      map
      |> Map.put("galleryLastSeen", bson_time())
      |> Map.put("timeTableLastSeen", bson_time())
    else
      map
    end
  end


  def insertGroupMemberWhileJoining(userObjectId, groupObjectId) do
    %{
      "userId" => userObjectId,
      "groupId" => groupObjectId,
      "isAdmin" => false,
      "canPost" => false,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "isActive" => true,
      "teams" => [],
      "groupPostLastSeen" => bson_time(),
      "messageInboxLastSeen" => bson_time(),
      "notificationLastSeen" => bson_time()
    }
  end

end
