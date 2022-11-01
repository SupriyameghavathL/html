defmodule GruppieWeb.GroupMembership do
  import GruppieWeb.Handler.TimeNow


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
