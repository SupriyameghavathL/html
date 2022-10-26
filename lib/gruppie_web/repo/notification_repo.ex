defmodule GruppieWeb.Repo.NotificationRepo do
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @saved_notifications_coll "saved_notifications"

  @group_team_members_coll "group_team_members"



  def getNotifications(loginUserId, groupObjectId, limit, params) do
    #update notification last seen time in group_team_members
    ##filterUpdate = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    ##update = %{ "$set" => %{ "notificationLastSeen" => bson_time() } }
    ##Mongo.update_one(@conn, @group_team_members_coll, filterUpdate, update)
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList}, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ]
    }
    pipeline = if params["page"] do
      #get results based on pagination
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * limit
      [ %{"$match" => filterNotification}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      ##Mongo.find(@conn, @saved_notifications_coll, filterNotification, [sort: %{_id: -1}, skip: skip, limit: limit])
    else
      [%{ "$match" => filterNotification }, %{"$sort" => %{"_id" => -1}}, %{ "$limit" => limit }]
      ##Mongo.find(@conn, @saved_notifications_coll, filterNotification, [sort: %{_id: -1}, limit: limit])
    end
    ##Mongo.aggregate(@conn, @view_saved_notifications_coll, pipeline)
    Mongo.aggregate(@conn, @saved_notifications_coll, pipeline)
  end


  def getTotalNotificationsCount(loginUserId, groupObjectId) do
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList}, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ]
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @saved_notifications_coll, filterNotification, [projection: project])
  end


  ############## group notifications #######################################

  def addGroupPostNotification(loginUser, group, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => group["_id"],
      "postId" => postObjectId,
      "insertedAt" => bson_time(),
      "type" => "groupPost",
      "notification" => 1
    }
    message = if group["category"] == "school" do
      loginUser["name"]<>" has posted in Notice Board"
    else
      if group["category"] == "corporate" do
        loginUser["name"]<>" has posted in Broadcast"
      else
        loginUser["name"]<>" has posted in "<>group["name"]
      end
    end
    insertMap = insertMap
    |> Map.put_new("message", message)

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def galleryAddNotification(loginUser, groupObjectId, albumObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "albumId" => albumObjectId,
      "insertedAt" => bson_time(),
      "type" => "gallery",
      "message" => loginUser["name"]<>" added a new Album in Gallery",
      "notification" => 1
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


   ############################### team notifications ####################################


   def addTeamPostNotification(loginUser, groupObjectId, team, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "postId" => postObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "teamPost",
      "message" => loginUser["name"]<>" has posted in "<>team["name"],
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end

end
