defmodule GruppieWeb.Repo.MessageRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @group_team_members_col "group_team_members"

  @message_last_seen_col "message_last_seen"

  @message_inbox_col "message_inbox"

  @view_message_inbox_col "VW_MESSAGE_INBOX"

  @message_col "messages"

  @view_teams_col "VW_TEAMS"

  @view_messages_col "VW_MESSAGES"

  @notification_token_col "notification_tokens"


  def getIndividualPostReadMore(groupObjectId, _userObjectId, postObjectId) do
    filter = %{"_id" => postObjectId, "groupId" => groupObjectId, "isActive" => true}
    pipeline = [%{ "$match" => filter }]
    hd(Enum.to_list(Mongo.aggregate(@conn, @view_messages_col, pipeline)))
  end


  def checkUserAlreadyInMessageLastSeen(loginUserId, userObjectId, groupObjectId) do
    filter = %{"groupId" => groupObjectId, "loginUserId" => loginUserId, "userId" => userObjectId}
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_last_seen_col, filter, [projection: project])
  end



  def addMessageLastSeen(loginUserId, userObjectId, groupObjectId) do
    insertDoc1 = %{ "groupId" => groupObjectId, "userId" => userObjectId, "loginUserId" => loginUserId, "individualPostLastSeen" => bson_time() }
    Mongo.insert_one(@conn, @message_last_seen_col, insertDoc1)

    insertDoc2 = %{ "groupId" => groupObjectId, "userId" => loginUserId, "loginUserId" => userObjectId, "individualPostLastSeen" => bson_time() }
    Mongo.insert_one(@conn, @message_last_seen_col, insertDoc2)
  end



  def checkUserInMessageInboxList(loginUserId, userObjectId, groupObjectId) do
    filter = %{
      "$or" => [%{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true },
      %{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true }]
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_inbox_col, filter, [projection: project])
  end



  def addUserToMessageInbox(loginUserId, userObjectId, groupObjectId) do
    insertMap = %{"senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true,
                  "updated_at" => bson_time(), "allowPostReply" => true, "allowPostComment" => true }
    Mongo.insert_one(@conn, @message_inbox_col, insertMap)
  end



  def updateTimeInMessageInbox(loginUserId, userObjectId, groupObjectId) do
    filter = %{
      "$or" => [%{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true },
                %{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true}]
    }
    update = %{ "$set" => %{ "updated_at" => bson_time() } }
    Mongo.update_one(@conn, @message_inbox_col, filter, update)
  end


  def getMessageUnseenCount(groupObjectId, loginUserId, userObjectId) do
    filter = %{"groupId" => groupObjectId, "loginUserId" => loginUserId, "userId" => userObjectId}
    projection = %{ "_id" => 0, "individualPostLastSeen" => 1 }
    lastSeenTime = hd(Enum.to_list(Mongo.find(@conn, @message_last_seen_col, filter, [projection: projection])))
    #get post count greater the last seen count
    filterPost = %{
      "$or" => [%{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
                %{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true} ],
      "insertedAt" => %{ "$gt" => lastSeenTime["individualPostLastSeen"] }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_col, filterPost, [projection: project])
  end


  def getAllMessageInboxUnseenCount(loginUserId, groupObjectId) do
    filter = %{"groupId" => groupObjectId, "userId" => loginUserId}
    projection = %{ "_id" => 0, "messageInboxLastSeen" => 1 }
    lastSeenTime = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filter, [projection: projection])))
    #get post count greater the last seen count
    filterPost = %{
      "$or" => [%{ "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
                %{ "senderId" => loginUserId, "groupId" => groupObjectId, "isActive" => true} ],
      "insertedAt" => %{ "$gt" => lastSeenTime["messageInboxLastSeen"] }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_col, filterPost, [projection: project])
  end



  def addTeamIndividualMessage(changeset, loginUserId, groupObjectId, teamObjectId, userObjectId) do
    #add doc for team users individual post
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:teamId, teamObjectId)
                |> update_map_with_key_value(:receiverId, userObjectId)
                |> update_map_with_key_value(:senderId, loginUserId)

    Mongo.insert_one(@conn, @message_col, changeset)
  end



  def addIndividualMessageDirect(changeset, loginUserId, groupObjectId, userObjectId) do
    #add doc for team users individual post
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:receiverId, userObjectId)
                |> update_map_with_key_value(:senderId, loginUserId)

    Mongo.insert_one(@conn, @message_col, changeset)
  end



  def getMessageInboxForLoginUser(loginUserId, groupObjectId) do
    #update message inbox last seen time in group_team_members
    filterUpdate = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    update = %{ "$set" => %{ "messageInboxLastSeen" => bson_time() } }
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    #get message inbox for login user
    filter = %{
      "$or" => [%{ "senderId" => loginUserId, "groupId" => groupObjectId, "isActive" => true},
      %{"receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true} ]
    }
    projection = %{
      "_id" => 0, "senderId" => 1, "receiverId" => 1, "updated_at" => 1
    }
    pipeline = [%{"$match" => filter},%{"$project" => projection}, %{"$sort" => %{"updated_at" => -1}}]
    cursor = Mongo.aggregate(@conn, @message_inbox_col, pipeline)
    result = Enum.reduce(cursor, [], fn k, acc ->
      pipelineDoc = if k["receiverId"] == loginUserId do
        #provide sender details
        %{
          filter: %{ "senderId" => k["senderId"], "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
          project: %{
            "_id" => 0, "userId" => k["senderId"], "updated_at" => 1, "allowPostReply" => 1, "allowPostComment" => 1,
            "name" => "$$CURRENT.senderDetails.name", "phone" => "$$CURRENT.senderDetails.phone", "image" => "$$CURRENT.senderDetails.image"
          }
        }
      else
        %{
          filter: %{ "senderId" => loginUserId, "receiverId" => k["receiverId"], "groupId" => groupObjectId, "isActive" => true },
          project: %{
            "_id" => 0, "userId" => k["receiverId"], "updated_at" => 1, "allowPostReply" => 1, "allowPostComment" => 1,
            "name" => "$$CURRENT.receiverDetails.name", "phone" => "$$CURRENT.receiverDetails.phone", "image" => "$$CURRENT.receiverDetails.image"
          }
        }
      end
      pipelineDoc = [%{"$match" => pipelineDoc.filter},%{"$project" => pipelineDoc.projection}]
      find = Mongo.aggregate(@conn, @view_message_inbox_col, pipelineDoc)
      acc ++ Enum.to_list(find)
    end)
    result
  end


  # def updateIndividualPostSeenForLoginUser(group_id, loginUser, user_id) do
  #   loginUserId = loginUser["_id"]
  #   userObjectId = decode_object_id(user_id)
  #   groupObjectId = decode_object_id(group_id)
  #   filter = %{
  #     "loginUserId" => loginUserId,
  #     "userId" => userObjectId,
  #     "groupId" => groupObjectId
  #   }
  #   #get current time to update
  #   getCurrentTime = Gruppie.Handler.TimeNow.bson_time()
  #   update = %{
  #     "$set" => %{ "individualPostLastSeen" => getCurrentTime }
  #   }
  #   Mongo.update_one(@conn, @individual_posts_seen, filter, update)
  # end



  #get individual message count to
  def getIndividualMessageCount(loginUserId, userObjectId, groupObjectId) do
    filter = %{
       "$or" => [%{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
                 %{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true} ]
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_col, filter, [projection: project])
  end



  def getMyPeople(loginUserId, groupObjectId) do
    filter = %{ "teamDetails.adminId" => loginUserId, "groupId" => groupObjectId,
                "userId" => %{"$nin" => [loginUserId]}}
    project = %{ "_id" => 0, "userId" => 1 }
    Mongo.distinct(@conn, @view_teams_col, "userId", filter, [projection: project])
  end



  def getMessageList(query_params, loginUserId, userObjectId, groupObjectId, limit) do
    #update current time for message_last_seen
    filterUpdate  = %{"groupId" => groupObjectId,"loginUserId" => loginUserId,"userId" => userObjectId}
    update = %{"$set" => %{ "individualPostLastSeen" => bson_time() }}
    Mongo.update_one(@conn, @message_last_seen_col, filterUpdate, update)

    filter = %{
      "$or" => [%{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
                %{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true} ]
    }
    pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }} ]
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_messages_col, pipeline)
    else
      Mongo.aggregate(@conn, @view_messages_col, pipeline)
    end
  end



  def getTotalMessageCount(loginUserId, userObjectId, groupObjectId) do
    filter = %{
      "$or" => [%{ "senderId" => userObjectId, "receiverId" => loginUserId, "groupId" => groupObjectId, "isActive" => true },
                %{ "senderId" => loginUserId, "receiverId" => userObjectId, "groupId" => groupObjectId, "isActive" => true} ]
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_col, filter, [projection: project])
  end


  def findMessageById(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId }
    hd(Enum.to_list(Mongo.find(@conn, @message_col, filter)))
  end


#  def findMessageById(groupObjectId, postObjectid) do
#    filter = %{ "_id" => postObjectid, "groupId" => groupObjectId }
#    update = %{ "$set" => %{ "isActive" => false } }
#    Mongo.update_one(@conn, @message_col, filter, update)
#  end


  def deleteIndividualMessage(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @message_col, filter, update)
  end


  def getDeviceTokenList(userObjectIdList, appObjectId) do
    filter = %{"userId" => %{ "$in" => userObjectIdList },"appId" => appObjectId}
    projection = %{"deviceToken" => 1, "deviceType" => 1, "_id" => 0}
    Enum.to_list(Mongo.find(@conn, @notification_token_col, filter, [projection: projection]))
  end


  def getDeviceToken(userObjectId, appObjectId) do
    filter = %{"userId" => userObjectId, "appId" => appObjectId}
    projection = %{ "deviceToken" => 1, "deviceType" => 1, "_id" => 0 }
    Enum.to_list(Mongo.find(@conn, @notification_token_col, filter, [projection: projection]))
  end


  def findMessageIsLiked(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "likedUsers.userId" => loginUserId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @message_col, filter, [projection: project])
  end


  def messageLike(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId }
    update = %{ "$push" => %{ "likedUsers" => %{ "userId" => loginUserId, "insertedAt" => bson_time() } } }
    Mongo.update_one(@conn, @message_col, filter, update)
    #increament likes count
    updateLikeCount = %{ "$inc" => %{ "likes" =>  1 } }
    Mongo.update_one(@conn, @message_col, filter, updateLikeCount)
  end


  def messageUnLike(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId }
    update = %{ "$pull" => %{ "likedUsers" => %{ "userId" => loginUserId } } }
    Mongo.update_one(@conn, @message_col, filter, update)
    #increament likes count
    updateLikeCount = %{ "$inc" => %{ "likes" =>  -1 } }
    Mongo.update_one(@conn, @message_col, filter, updateLikeCount)
  end



end
