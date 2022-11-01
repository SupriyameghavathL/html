defmodule GruppieWeb.Api.V1.MessageView do
  use GruppieWeb, :view
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.MessageRepo
  alias GruppieWeb.Repo.MessageCommentsRepo

  def render("chatInboxList.json", %{chatInbox: chatInbox, groupObjectId: groupObjectId, loginUserId: loginUserId}) do
  resultList = Enum.reduce(chatInbox, [], fn k, acc ->
    #get individual post count to decide to show in chat inbox list (if count = 0 then don't show that in inbox list)
    {:ok, individualPostCount} = MessageRepo.getIndividualMessageCount(loginUserId, k["userId"], groupObjectId)
    if individualPostCount > 0 do
      #allow post reply setting
      allowPost = if k["allowPostReply"] == false do
        if k["senderId"] == loginUserId do
          true
        else
          false
        end
      else
        true
      end
      #allow post comment setting
      allowPostComment = if k["allowPostComment"] == false do
        if k["senderId"] == loginUserId do
          true
        else
          false
        end
      else
        true
      end
      #check sender id is login user id to provide individual settings
      provideSettings = if k["senderId"] == loginUserId do
        true
      else
        false
      end
      #get individual post unseen count
      {:ok, messageUnseenCount} = MessageRepo.getMessageUnseenCount(groupObjectId, loginUserId, k["userId"])
      map = %{
        userId: encode_object_id(k["userId"]),
        name: k["name"],
        phone: k["phone"],
        image: k["image"],
        postUnreadCount: messageUnseenCount,
        updatedAtTime: k["updated_at"],
        allowToPost: allowPost,
        allowPostComment: allowPostComment,
        provideSettings: provideSettings,
      }
      acc ++ [map]
    else
      acc
    end
  end)
  %{ data: resultList }
  end




  def render("chatContactsList.json", %{ chatContacts: chatContacts }) do
    list = Enum.reduce(chatContacts, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "phone" => k["phone"],
        "image" => k["image"]
      }
      acc ++ [map]
    end)
    %{ data: list }
  end



  def render("MessageList.json", %{messageList: messageList, loginUserId: loginUserId, limit: limit, userObjectId: userObjectId, groupObjectId: groupObjectId}) do
    resultList = Enum.reduce(messageList, [], fn k, acc ->
      #if sender id is equal to login user  id then change name to "you"
      #check login user liked this post or not
      {:ok ,isLikedPostCount} = MessageRepo.findMessageIsLiked(loginUserId, groupObjectId, k["_id"])
      isLiked = if isLikedPostCount == 0 do
        false
      else
        true
      end
      #get total comments count for this post
      {:ok, commentsCount} = MessageCommentsRepo.getTotalCommentsCountForMessage(groupObjectId, k["_id"])
      map = %{
        id: encode_object_id(k["_id"]),
        senderId: encode_object_id(k["senderId"]),
        senderPhone: k["senderDetails"]["phone"],
        senderImage: k["senderDetails"]["image"],
        text: k["text"],
        comments: commentsCount,
        likes: k["likes"],
        isLiked: isLiked,
        updatedAt: k["updatedAt"]
      }

      if k["senderId"] == loginUserId  do
        map
        |> Map.put_new("senderName", "You")
        |> Map.put_new("canEdit", true)
      else
        map
        |> Map.put_new("senderName", k["senderDetails"]["name"])
        |> Map.put_new("canEdit", false)
      end

      map = if !is_nil(k["fileName"]) do
        map
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        map
      end

      map = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          map
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          map
        end
      else
        map
      end

      #if thumbnailImage for video and pdf is not nil then display
      map = if !is_nil(k["thumbnailImage"]) do
        map
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        map
      end

      acc ++ [map]
    end)
    #get total number of pages
    {:ok, postCount} = MessageRepo.getTotalMessageCount(loginUserId, userObjectId, groupObjectId)
    pageCount = Float.ceil(postCount / limit)
    totalPages = round(pageCount)

    %{ data: resultList, totalNumberOfPages: totalPages }
  end


  #get all replies of comments along with parent comments
  def render("deviceToken.json", %{ deviceToken: deviceToken, userObjectId: userObjectId, loginUser: loginUser }) do
    list = Enum.reduce(deviceToken, [], fn k, acc ->
      map = %{
        "deviceToken" => k["deviceToken"],
        "deviceType" => k["deviceType"],
        "userId" => encode_object_id(userObjectId),
        "loginUserId" => encode_object_id(loginUser["_id"])
      }
      acc ++ [map]
    end)
    %{ data: list }
  end


end
