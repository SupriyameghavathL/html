defmodule GruppieWeb.Repo.GroupPostRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  @conn :mongo

  @group_team_members_col "group_team_members"

  @post_col "posts"

  @view_post_col "VW_POSTS"

  @gallery_col "gallery"

  @vendor_col "vendors"

  @coc_col "code_of_conduct"

  @posts_saved_col "posts_saved"

  @view_posts_saved_col "VW_POSTS_SAVED"

  @post_report_col "post_reports"

  @school_calendar_col "school_calendar"

  @classSubject_col "class_subjects"

  @classBooks_col "class_ebooks"

  @teams_col "teams"

  @view_teams_ebooks_details_col "VW_TEAMS_EBOOKS_DETAILS"

  @users_col "users"

  @saved_notifications_coll "saved_notifications"

  #@zoom_hosts_col "zoom_hosts"


  def getGroupPostReadMore(groupObjectId, postObjectId) do
    filter = %{"_id" => postObjectId,"groupId" => groupObjectId,"isActive" => true}
    pipeline = [%{ "$match" => filter }]
    hd(Enum.to_list(Mongo.aggregate(@conn, @view_post_col, pipeline)))
  end


  def getGroupAlbumReadMore(groupObjectId, albumObjectId) do
    filter = %{"_id" => albumObjectId, "groupId" => groupObjectId, "isActive" => true }
    hd(Enum.to_list(Mongo.find(@conn, @gallery_col, filter)))
  end

  #find gallery album exist or not
  def findAlbumExistById(groupObjectId, albumObjectId) do
    filter = %{"_id" => albumObjectId, "groupId" => groupObjectId, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @gallery_col, filter, [projection: project])
  end

  #find post by _id
  def findPostById(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "$or" => [%{"type" => "groupPost"}, %{"type" => "specialPost"}, %{"type" => "suggestionPost"}, %{"type" => "teamPost"}, %{"type" => "branchPost"}], "isActive" => true }
    hd(Enum.to_list(Mongo.find(@conn, @post_col, filter, [limit: 1])))
  end

  #find post exit "isActive=true" by _id
  def findPostExistById(groupObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "type" => "groupPost", "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  #add group post
  def add(changeset, login_user_id, group_object_id) do
    changeset = changeset
    |> update_map_with_key_value(:groupId, group_object_id)
    |> update_map_with_key_value(:userId, login_user_id)
    |> update_map_with_key_value(:type, "groupPost")
    Mongo.insert_one(@conn, @post_col, changeset)
  end


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



  #get posts unseen count / UP
  def getGroupPostUnseenCount(login_user_id, group_object_id) do
    lastSeenTime = getUserLastSeenTime(login_user_id, group_object_id)
    filter = %{
      "groupId" => group_object_id,
      "type" => "groupPost",
      "insertedAt" => %{ "$gt" => lastSeenTime["groupPostLastSeen"] }
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


  #add/register eBooks for class/teams
  def addEbooksForClasses(changeset, groupObjectId, loginUserId) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
    Mongo.insert_one(@conn, @classBooks_col, changeset)
  end


  #get list of class-books registered forschool - with all classes
  def getEbooksForSchool(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1, "className" => 1, "subjectBooks" => 1}
    Enum.to_list(Mongo.find(@conn, @classBooks_col, filter, [projection: project, sort: %{"_id" => -1}]))
  end


  def getEbooksForTeamFromRegister(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    project = %{"_id" => 0, "ebookDetails.subjectBooks" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_ebooks_details_col, pipeline))
  end

  def addEbookForClass(changeset, groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    #add manual ebookdId for changeset
    changeset = changeset
                |> Map.put_new(:ebookId, new_object_id())
    update = %{"$push" => %{"eBooks" => changeset}}
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def getEbooksForTeam(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    project = %{"_id" => 0, "eBooks" => 1}
    hd(Enum.to_list(Mongo.find(@conn, @teams_col, filter, [projection: project])))
  end


  def removeEbooksForClass(groupObjectId, teamObjectId, ebookObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "eBooks.ebookId" => ebookObjectId
    }
    #update = %{"$pull" => %{"eBooks.$.ebookId" => ebookObjectId}}
    update = %{"$pull" => %{"eBooks" => %{"ebookId" => ebookObjectId}}}
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  #delete/remove ebook from register/list
  def deleteEbook(groupObjectId, bookObjectId) do
    #set isActive = false in class_ebooks coll
    filter = %{
      "groupId" => groupObjectId,
      "_id" => bookObjectId,
      "isActive" => true
    }
    update = %{ "$set" => %{"isActive" => false} }
    Mongo.update_one(@conn, @classBooks_col, filter, update)

    #remove ebooks from teams where this is used
    filter = %{
      "groupId" => groupObjectId,
      "ebookId" => bookObjectId
    }
    #IO.puts "#{filter}"
    update = %{"$unset" => %{"ebookId" => bookObjectId}}
    Mongo.update_many(@conn, @teams_col, filter, update)
  end

  ###****OLDER VERSION****####
  #add eBook for already created team without ebook
  def addEbookForClassFromRegister(groupObjectId, teamObjectId, ebookObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"ebookId" => ebookObjectId}}
    Mongo.update_one(@conn, @teams_col, filter, update)
  end



  #add subject for class
  def addSubjectForClass(changeset, groupObjectId, loginUserId) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
    Mongo.insert_one(@conn, @classSubject_col, changeset)
  end


  #get class subjects list
  def getClassSubjects(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "isActive" => true }
    Mongo.find(@conn, @classSubject_col, filter)
  end


  def updateSubjects(changeset, groupObjectId, subjectObjectId) do
    filter = %{ "_id" => subjectObjectId, "groupId" => groupObjectId, "isActive" => true }
    update = %{ "$set" => %{ "name" => changeset.name, "classSubjects" => changeset.classSubjects, "updatedAt" => bson_time() } }
    Mongo.update_one(@conn, @classSubject_col, filter, update)
  end


  def deleteSubject(groupObjectId, subjectObjectId) do
    filter = %{ "_id" => subjectObjectId, "groupId" => groupObjectId, "isActive" => true }
    Mongo.delete_one(@conn, @classSubject_col, filter)
  end



  #add album to gallery
  def addAlbumToGallery(changeset, loginUserId, groupObjectId) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
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
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
    Mongo.insert_one(@conn, @vendor_col, changeset)
  end


  #add code of conduct
  def addCoc(changeset, loginUserId, groupObjectId) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:userId, loginUserId)
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


  def getGalleryUnseenCount(loginUserId, groupObjectId) do
    filter = %{"groupId" => groupObjectId, "userId" => loginUserId}
    projection = %{ "_id" => 0, "galleryLastSeen" => 1 }
    lastSeenTime = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filter, [projection: projection])))
    #get gallery post count greater the last seen count
    filterPost = %{
      "groupId" => groupObjectId,
      "insertedAt" => %{ "$gt" => lastSeenTime["galleryLastSeen"] },
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @gallery_col, filterPost, [projection: project])
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



  def getPostSaved(conn, groupObjectId, limit) do
    query_params = conn.query_params
    loginUser = Guardian.Plug.current_resource(conn)
    filter = %{ "groupId" => groupObjectId, "userId" => loginUser["_id"] }
    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_posts_saved_col, pipeline)
      |> Enum.to_list()
    else
      pipeline = [ %{"$match" => filter}, %{"$sort" => %{ "_id" => -1 }} ]
      Mongo.aggregate(@conn, @view_posts_saved_col, pipeline)
      |> Enum.to_list()
    end
    # filter = %{ "groupId" => groupObjectId, "userId" => loginUser["_id"] }
    # pipeline = [%{"$match" => filter}]
    # Mongo.aggregate(@conn, @view_posts_saved_col, pipeline)
  end


  def findPostIsSaved(loginUserId, groupObjectId, postObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "postId" => postObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @posts_saved_col, filter, [projection: project])
  end


  def getTotalPostsSavedCount(groupObjectId, loginUserId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @posts_saved_col, filter, [projection: project])
  end


  def getTotalPostsCount(groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "isActive" =>  true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def checkUserAlreadyReportedPost(loginUser, group_id, post_id) do
    loginUserId = loginUser["_id"]
    groupObjectId = decode_object_id(group_id)
    postObjectId = decode_object_id(post_id)
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "postId" => postObjectId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_report_col, filter, [projection: project])
  end


  def addPostReport(loginUser, reportType, group_id, post_id) do
    loginUserId = loginUser["_id"]
    groupObjectId = decode_object_id(group_id)
    postObjectId = decode_object_id(post_id)
    insertMap = %{ "userId" => loginUserId, "groupId" => groupObjectId, "postId" => postObjectId, "reportType" => String.to_integer(reportType) }
    Mongo.insert_one(@conn, @post_report_col, insertMap)
  end



  def addToSchoolCalendar(loginUserId, groupObjectId, changeset, day, month, year) do
    insert_doc = changeset
                  |> update_map_with_key_value(:day, day)
                  |> update_map_with_key_value(:month, month)
                  |> update_map_with_key_value(:year, year)
                  |> update_map_with_key_value(:userId, loginUserId)
                  |> update_map_with_key_value(:groupId, groupObjectId)
    Mongo.insert_one(@conn, @school_calendar_col, insert_doc)
  end



  def getSchoolCalendar(groupObjectId, month, year) do
    filter = %{
      "groupId" => groupObjectId,
      "month" => month,
      "year" => year,
      "isActive" => true
    }
    Mongo.find(@conn, @school_calendar_col, filter)
  end


  def getSchoolCalendarEvent(groupObjectId, day, month, year) do
    filter = %{
      "groupId" => groupObjectId,
      "day" => day,
      "month" => month,
      "year" => year,
      "isActive" => true
    }
    Mongo.find(@conn, @school_calendar_col, filter)
  end



  def checkEventCreatedByLoginUser(loginUserId, groupObjectId, eventObjectId) do
    filter = %{
      "_id" => eventObjectId,
      "groupId" => groupObjectId,
      "userId" => loginUserId,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_calendar_col, filter, [projection: project])
  end



  def removeEventFromSchoolCalendar(groupObjectId, eventObjectId) do
    filter = %{
      "_id" => eventObjectId,
      "groupId" => groupObjectId,
    }
    Mongo.delete_one(@conn, @school_calendar_col, filter)
  end



  def checkZoomKeysExist(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "class" => true,
      "isActive" => true,
      "zoomKey" => %{
        "$exists" => true
      },
      "zoomSecret" => %{
        "$exists" => true
      }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @teams_col, filter, [projection: project])
  end



  def addZoomSecretKeysToClass(groupObjectId, teamObjectId, zoomKey, zoomSecret) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      #"class" => true,
      "isActive" => true
    }
    update = %{"$set" => %{"zoomKey" => zoomKey, "zoomSecret" => zoomSecret, "alreadyOnZoomLive" => false}}
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  # / UP
  defp getUserLastSeenTime(login_user_id, group_object_id) do
    filter = %{
      "groupId" => group_object_id,
      "userId" => login_user_id,
    }
    project = %{ "_id" => 0, "groupPostLastSeen" => 1 }
    find = Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
    hd(Enum.to_list(find))
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




end
