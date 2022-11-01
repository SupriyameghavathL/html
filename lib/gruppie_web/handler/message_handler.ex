defmodule GruppieWeb.Handler.MessageHandler do
  alias GruppieWeb.Repo.MessageRepo
  alias GruppieWeb.Repo.FriendRepo
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Post


  def getIndividualPostReadMore(groupObjectId, userObjectId, post_id) do
    postObjectId = decode_object_id(post_id)
    MessageRepo.getIndividualPostReadMore(groupObjectId, userObjectId, postObjectId)
  end



  def addMessageToTeamUser(changeset, conn, group_id, team_id, user_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #check Already in individual_posts_seen doc
    {:ok, checkUserAlreadyInIndividualPostSeen} = MessageRepo.checkUserAlreadyInMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
    if checkUserAlreadyInIndividualPostSeen == 0 do
      #add to individual_post_seen
      MessageRepo.addMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
    end
    #before adding team individual post 1st check this user is in individual_post_inbox doc
    {:ok, checkIsInInboxPostList} = MessageRepo.checkUserInMessageInboxList(loginUser["_id"], userObjectId, groupObjectId)
    if checkIsInInboxPostList == 0 do
      #insert to inbox doc
      MessageRepo.addUserToMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
      MessageRepo.addTeamIndividualMessage(changeset, loginUser["_id"], groupObjectId, teamObjectId, userObjectId)
    else
      #update updated_at time formindividualPostInbox
      MessageRepo.updateTimeInMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
      MessageRepo.addTeamIndividualMessage(changeset, loginUser["_id"], groupObjectId, teamObjectId, userObjectId)
    end
  end



  def addMessageDirect(changeset, conn, group_id, user_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    #check Already in individual_posts_seen doc
    {:ok, checkUserAlreadyInIndividualPostSeen} = MessageRepo.checkUserAlreadyInMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
    if checkUserAlreadyInIndividualPostSeen == 0 do
      #add to individual_post_seen
      MessageRepo.addMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
    end
    #before adding team individual post 1st check this user is in individual_post_inbox doc
    {:ok, checkIsInInboxPostList} = MessageRepo.checkUserInMessageInboxList(loginUser["_id"], userObjectId, groupObjectId)
    if checkIsInInboxPostList > 0 do
      #update updated_at time formindividualPostInbox
      MessageRepo.updateTimeInMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
      MessageRepo.addIndividualMessageDirect(changeset, loginUser["_id"], groupObjectId, userObjectId)
    else
      #insert to inbox doc
      MessageRepo.addUserToMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
      MessageRepo.addIndividualMessageDirect(changeset, loginUser["_id"], groupObjectId, userObjectId)
    end
  end


  def addMultipleIndividualMessage(changeset, conn, group_id, userIds) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    Enum.reduce(userIds, [], fn k, _acc ->
      userObjectId = decode_object_id(k)
      #check Already in individual_posts_seen doc
      {:ok, checkUserAlreadyInIndividualPostSeen} = MessageRepo.checkUserAlreadyInMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
      if checkUserAlreadyInIndividualPostSeen == 0 do
        #add to individual_post_seen
        MessageRepo.addMessageLastSeen(loginUser["_id"], userObjectId, groupObjectId)
      end
      #before adding team individual post 1st check this user is in individual_post_inbox doc
      {:ok, checkIsInInboxPostList} = MessageRepo.checkUserInMessageInboxList(loginUser["_id"], userObjectId, groupObjectId)
      if checkIsInInboxPostList > 0 do
        #update updated_at time formindividualPostInbox
        MessageRepo.updateTimeInMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
        MessageRepo.addIndividualMessageDirect(changeset, loginUser["_id"], groupObjectId, userObjectId)
      else
        #insert to inbox doc
        MessageRepo.addUserToMessageInbox(loginUser["_id"], userObjectId, groupObjectId)
        MessageRepo.addIndividualMessageDirect(changeset, loginUser["_id"], groupObjectId, userObjectId)
      end
    end)
  end


  def getMessageInbox(loginUserId, groupObjectId) do
    #get chat inbox list for login user as both sender  and receiver
    MessageRepo.getMessageInboxForLoginUser(loginUserId, groupObjectId)
  end


  def getMyPeople(loginUserId, groupObjectId) do
    {:ok, peopleId} = MessageRepo.getMyPeople(loginUserId, groupObjectId)
    #get details of userId
    userList = FriendRepo.getMyPeopleDetails(peopleId)
    userList
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def getMessages(conn, userObjectId, groupObjectId, limit) do
    query_params = conn.query_params
    loginUser = Guardian.Plug.current_resource(conn)
    MessageRepo.getMessageList(query_params, loginUser["_id"], userObjectId, groupObjectId, limit)
  end


  def deleteIndividualMessage(conn, group_id, _user_id, post_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    postObjectid = decode_object_id(post_id)
    getIndividualPost = MessageRepo.findMessageById(groupObjectId, postObjectid)
    if loginUser["_id"] == getIndividualPost["senderId"] do
      MessageRepo.deleteIndividualMessage(groupObjectId, postObjectid)
    else
      {:changesetError, "error"}
    end
  end


  def getDeviceToken(userObjectId, groupObjectId) do
    MessageRepo.getDeviceToken(userObjectId, groupObjectId)
  end


  def getDeviceTokenList(user, group_id) do
    groupObjectId = decode_object_id(group_id)
    #userObjectId = decode_object_id(user_id)
    MessageRepo.getDeviceTokenList(user, groupObjectId)
  end


  def sharePostToFriends(conn, params, post) do
    title = if post["title"] do
      post["title"]
    else
      ""
    end
    text = if post["text"] do
     post["text"]
    else
      ""
    end
    body = title<>". "<>text
    #if fileType is image
    if post["fileType"] == "image"  do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "text" => body, "fileName" => fileName, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToIndividualPost(conn, post_params, params)
    else
      post
    end
    #if file type is pdf/video
    if post["fileType"] == "pdf" || post["fileType"] == "video" do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "text" => body, "fileName" => fileName, "fileType" => fileType, "thumbnailImage" => post["thumbnailImage"] }
      #calling private func to validate and add
      validateWhenSharingAndAddToIndividualPost(conn, post_params, params)
    else
      post
    end
    #if file type is youtube
    if post["fileType"] == "youtube" do
      #making valid youtube link
      video = "https://www.youtube.com/watch?v="<>post["video"]
      fileType = post["fileType"]
      post_params = %{ "text" => body, "video" => video, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToIndividualPost(conn, post_params, params)
    else
      post
    end
    #if sharing post contains no image or video
    if is_nil(post["fileType"]) do
       post_params = %{ "text" => body }
       #calling private func to validate and add
       validateWhenSharingAndAddToIndividualPost(conn, post_params, params)
    else
      post
    end
  end


  def messageLike(loginUserId, groupObjectId, postObjectId) do
    #get login user liked this post or not
    {:ok, isLikedCount} = MessageRepo.findMessageIsLiked(loginUserId, groupObjectId, postObjectId)
    if isLikedCount == 0 do
      case MessageRepo.messageLike(loginUserId, groupObjectId, postObjectId) do
        {:ok, _}->
          {:ok, "liked"}
      end
    else
      case MessageRepo.messageUnLike(loginUserId, groupObjectId, postObjectId) do
        {:ok, _}->
          {:ok, "unliked"}
      end
    end
  end


  #private function to validate and share when sharing post
  defp validateWhenSharingAndAddToIndividualPost(conn, post_params, params) do
    loginUser = Guardian.Plug.current_resource(conn)
    changeset = Post.changeset(%Post{}, post_params)
    if changeset.valid? do
      group_id = params["groupId"]
      friend_ids = params["friendsId"]
      friendsIdList = String.split(friend_ids, ",")
      Enum.reduce(friendsIdList, [], fn friend_id, _acc ->
        #check Already in individual_posts_seen doc
        {:ok, checkUserAlreadyInIndividualPostSeen} = MessageRepo.checkUserAlreadyInMessageLastSeen(loginUser["_id"], decode_object_id(friend_id), decode_object_id(group_id))
        if checkUserAlreadyInIndividualPostSeen == 0 do
          #add to individual_post_seen
          MessageRepo.addMessageLastSeen(loginUser["_id"], decode_object_id(friend_id), decode_object_id(group_id))
        end
        #before adding team individual post 1st check this user is in individual_post_inbox doc
        {:ok, checkIsInInboxPostList} = MessageRepo.checkUserInMessageInboxList(loginUser["_id"], decode_object_id(friend_id), decode_object_id(group_id))
        if checkIsInInboxPostList > 0 do
          #update updated_at time formindividualPostInbox
          MessageRepo.updateTimeInMessageInbox(loginUser["_id"], decode_object_id(friend_id), decode_object_id(group_id))
          MessageRepo.addIndividualMessageDirect(changeset.changes, loginUser["_id"], decode_object_id(group_id), decode_object_id(friend_id))
        else
          #insert to inbox doc
          MessageRepo.addUserToMessageInbox(loginUser["_id"], decode_object_id(friend_id), decode_object_id(group_id))
          MessageRepo.addIndividualMessageDirect(changeset.changes, loginUser["_id"], decode_object_id(group_id), decode_object_id(friend_id))
        end
      end)
    else
      {:changesetError, changeset.errors}
    end
  end
end
