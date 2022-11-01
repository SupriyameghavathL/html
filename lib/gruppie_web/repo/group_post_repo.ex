defmodule GruppieWeb.Repo.GroupPostRepo do
  import GruppieWeb.Handler.TimeNow


  @conn :mongo

  @group_team_members_col "group_team_members"

  @post_col "posts"

  @view_post_col "VW_POSTS"

  @gallery_col "gallery"

  @vendor_col "vendors"

  @coc_col "code_of_conduct"

  @posts_saved_col "posts_saved"

  # @view_posts_saved_col "VW_POSTS_SAVED"

  # @post_report_col "post_reports"

  # @school_calendar_col "school_calendar"

  # @classSubject_col "class_subjects"

  # @classBooks_col "class_ebooks"

  # @teams_col "teams"

  # @view_teams_ebooks_details_col "VW_TEAMS_EBOOKS_DETAILS"

  @users_col "users"

  @saved_notifications_coll "saved_notifications"




  def getAll(conn, groupObjectId, limit) do
    query_params = conn.query_params
    loginUser = Guardian.Plug.current_resource(conn)
    #filter = %{ "groupId" => groupObjectId, "type" => "groupPost", "isActive" => true }
    filter = %{
      "$or" => [
        %{"groupId" => groupObjectId, "type" => "groupPost", "isActive" => true},
        %{"groupId" => groupObjectId, "bdayUserId" => loginUser["_id"], "type" => "birthdayPost", "isActive" => true},
        ##TEMPORARY
        ##%{"groupId" => groupObjectId, "type" => "birthdayPost", "isActive" => true}
      ]
    }
    project = %{ "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image",
                "_id" => 1, "comments" => 1, "likes" => 1, "text" => 1, "title" => 1, "fileName" => 1, "fileType" => 1, "video" => 1,
                "groupId" => 1, "userId" => 1, "isActive" => 1, "insertedAt" => 1, "updatedAt" => 1, "thumbnailImage" => 1, "type" => 1, "bdayUserId" => 1}
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Enum.to_list(Mongo.aggregate(@conn, @view_post_col, pipeline))
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }}, %{"$limit" => 50} ]
      Enum.to_list(Mongo.aggregate(@conn, @view_post_col, pipeline))
    end
  end


  def findPostIsSaved(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "postId" => postObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @posts_saved_col, filter, [projection: project])
  end


  def getBdayUserDetail(bdayUserId) do
    filter = %{
      "_id" => bdayUserId
    }
    project = %{"_id" => 0, "name" => 1, "image" => 1}
    Mongo.find_one(@conn, @users_col, filter, [projection: project])
  end


  #get total post count of group
  def getTotalPostCount(group_object_id) do
    filter = %{
      "groupId" => group_object_id,
      "isActive" => true,
      "type" => "groupPost"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  #to check login user can post in group or not (for group post add auth)
  def checkLoginUserCanPostInGroup(groupObjectId, login_user_id) do
    filter = %{ "groupId" => groupObjectId, "userId" => login_user_id, "canPost" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_team_members_col, filter, [projection: project])
  end


  #add group post
  def add(changeset, login_user_id, group_object_id) do
    changeset = changeset
    |> Map.put(:groupId, group_object_id)
    |> Map.put(:userId, login_user_id)
    |> Map.put(:type, "groupPost")
    Mongo.insert_one(@conn, @post_col, changeset)
  end


  #add album to gallery
  def addAlbumToGallery(changeset, loginUserId, groupObjectId) do
    changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:userId, loginUserId)
    Mongo.insert_one(@conn, @gallery_col, changeset)
  end


  def getAlbumById(albumObjectId) do
    filter = %{ "_id" => albumObjectId }
    Mongo.find_one(@conn, @gallery_col, filter)
  end


  def addImageToAlbum(groupObjectId, albumObjectId, changeset) do
    filter = %{ "_id" => albumObjectId, "groupId" => groupObjectId }
    Enum.reduce(changeset.fileName, [], fn k, _acc ->
      update = %{ "$push" => %{ "fileName" => k } }
      Mongo.update_one(@conn, @gallery_col, filter, update)
    end)
  end


  def removeAlbumImage(groupObjectId, albumObjectId, fileNameList) do
    filter = %{ "_id" => albumObjectId, "groupId" => groupObjectId }
    Enum.reduce(fileNameList, [], fn k, _acc ->
      update = %{ "$pull" => %{ "fileName" => k } }
      Mongo.update_one(@conn, @gallery_col, filter, update)
    end)
  end


  #add vendors
  def addVendor(changeset, loginUserId, groupObjectId) do
    changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:userId, loginUserId)
    Mongo.insert_one(@conn, @vendor_col, changeset)
  end


  #add code of conduct
  def addCoc(changeset, loginUserId, groupObjectId) do
    changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:userId, loginUserId)
    Mongo.insert_one(@conn, @coc_col, changeset)
  end


  def getGallery(conn, groupObjectId, limit) do
    query_params = conn.query_params
    loginUser = Guardian.Plug.current_resource(conn)
    #update gallery last seen time in group_team_members
    filterUpdate = %{ "groupId" => groupObjectId, "userId" => loginUser["_id"], "isActive" => true }
    update = %{ "$set" => %{ "galleryLastSeen" => bson_time() } }
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      Enum.to_list(Mongo.find(@conn, @gallery_col, filter, [ sort: %{ "_id" => -1 }, limit: limit, skip: skip ]))
    else
      Enum.to_list(Mongo.find(@conn, @gallery_col, filter, [ sort: %{ "_id" => -1 } ]))
    end
  end


  #get total album count in gallery of group
  def getTotalAlbumCount(group_object_id) do
    filter = %{"groupId" => group_object_id, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @gallery_col, filter, [projection: project])
  end


  def getVendors(groupObjectId) do
    filter = %{"groupId" => groupObjectId, "isActive" => true}
    Enum.to_list(Mongo.find(@conn, @vendor_col, filter, [ sort: %{ "_id" => -1 } ]))
  end


  def getCoc(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "isActive" => true}
    Enum.to_list(Mongo.find(@conn, @coc_col, filter, [ sort: %{ "_id" => -1 } ]))
  end

  #find post by _id
  def findPostById(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "$or" => [%{"type" => "groupPost"}, %{"type" => "specialPost"}, %{"type" => "suggestionPost"}, %{"type" => "teamPost"}, %{"type" => "branchPost"}], "isActive" => true }
    hd(Enum.to_list(Mongo.find(@conn, @post_col, filter, [limit: 1])))
  end


  #group post delete
  def deletePost(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "isActive" => true, "$or" => [%{"type" => "groupPost"}, %{"type" => "suggestionPost"}, %{"type" => "branchPost"}]}
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @post_col, filter, update)
  end


  def removeNotificationFromGroup(postObjectId) do
    filter = %{
      "postId" => postObjectId
    }
    Mongo.delete_one(@conn, @saved_notifications_coll, filter)
  end

  def deleteGroupPost(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "$or" => [
        %{"type" => "groupPost"},
        %{"type" => "specialPost"}
      ]
    }
    update = %{
      "$set" => %{
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @post_col, filter, update)
  end


  #gallery album delete
  def deleteAlbum(groupObjectId, albumObjectId) do
    filter = %{ "_id" => albumObjectId, "groupId" => groupObjectId }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @gallery_col, filter, update)
  end


  def deleteVendor(groupObjectId, vendorObjectId) do
    filter = %{ "_id" => vendorObjectId, "groupId" => groupObjectId }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @vendor_col, filter, update)
  end


  def deleteCoc(groupObjectId, cocObjectId) do
    filter = %{ "_id" => cocObjectId, "groupId" => groupObjectId }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @coc_col, filter, update)
  end




end
