defmodule GruppieWeb.Handler.GroupPostHandler do
  alias GruppieWeb.Post
  alias GruppieWeb.Repo.GroupPostRepo
  import GruppieWeb.Repo.RepoHelper


  def getGroupPostReadMore(groupObjectId, postObjectId) do
    #get post details
    GroupPostRepo.getGroupPostReadMore(groupObjectId, postObjectId)
  end


  def getGroupAlbumReadMore(groupObjectId, albumObjectId) do
    #get album details
    GroupPostRepo.getGroupAlbumReadMore(groupObjectId, albumObjectId)
  end


  def add(changeset, conn, groupObjectId) do
    login_user = Guardian.Plug.current_resource(conn)
    GroupPostRepo.add(changeset, login_user["_id"], groupObjectId)
  end


  def getAll(conn, groupObjectId, limit) do
    GroupPostRepo.getAll(conn, groupObjectId, limit)
  end


  def deletePost(conn, group, post_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    postObjectId = decode_object_id(post_id)
    #check post created by user or group admin only can delete the post
    post = GroupPostRepo.findPostById(group["_id"], postObjectId)
    if group["adminId"] == loginUser["_id"] || post["userId"] == loginUser["_id"] do
      GroupPostRepo.deletePost(group["_id"], postObjectId)
    else
      {:changeset_error, "You Cannot Delete This Post"}
    end
  end


  def deleteNotificationGroupPost(postId) do
    postObjectId = decode_object_id(postId)
    GroupPostRepo.removeNotificationFromGroup(postObjectId)
  end


  def addAlbumToGallery(changeset, conn, group_id) do
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    GroupPostRepo.addAlbumToGallery(changeset, login_user["_id"], groupObjectId)
  end


  def albumImageAdd(groupObjectId, albumObjectId, changeset) do
    GroupPostRepo.addImageToAlbum(groupObjectId, albumObjectId, changeset)
  end


  def removeAlbumImage(group_id, album_id, fileName) do
    groupObjectId = decode_object_id(group_id)
    albumObjectId = decode_object_id(album_id)
    GroupPostRepo.removeAlbumImage(groupObjectId, albumObjectId, fileName)
  end


  def addVendor(changeset, conn, group_id) do
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    GroupPostRepo.addVendor(changeset, login_user["_id"], groupObjectId)
  end


  def addCoc(changeset, conn, group_id) do
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    GroupPostRepo.addCoc(changeset, login_user["_id"], groupObjectId)
  end


  def getGallery(conn, groupObjectId, limit) do
    GroupPostRepo.getGallery(conn, groupObjectId, limit)
  end


  def getVendors(_conn, groupObjectId) do
    GroupPostRepo.getVendors(groupObjectId)
  end


  def getCoc(_conn, groupObjectId) do
    GroupPostRepo.getCoc(groupObjectId)
  end


  def deleteAlbum(group_id, album_id) do
    groupObjectId = decode_object_id(group_id)
    albumObjectId = decode_object_id(album_id)
    GroupPostRepo.deleteAlbum(groupObjectId, albumObjectId)
  end


  def deleteVendor(group_id, vendor_id) do
    groupObjectId = decode_object_id(group_id)
    vendorObjectId = decode_object_id(vendor_id)
    GroupPostRepo.deleteVendor(groupObjectId, vendorObjectId)
  end


  def deleteCoc(group_id, coc_id) do
    groupObjectId = decode_object_id(group_id)
    cocObjectId = decode_object_id(coc_id)
    GroupPostRepo.deleteCoc(groupObjectId, cocObjectId)
  end


  def getSavedPost(conn, groupObjectId, limit) do
    GroupPostRepo.getPostSaved(conn, groupObjectId, limit)
  end


  def addEbooksForClasses(changeset, groupObjectId, loginUserId) do
    GroupPostRepo.addEbooksForClasses(changeset, groupObjectId, loginUserId)
  end


  def getEbooksForSchool(groupId) do
    #loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(groupId)
    GroupPostRepo.getEbooksForSchool(groupObjectId)
  end


  def deleteEbook(groupObjectId, book_id) do
    bookObjectId = decode_object_id(book_id)
    GroupPostRepo.deleteEbook(groupObjectId, bookObjectId)
  end


  def addEbookForClassFromRegister(groupObjectId, teamId, ebookId) do
    teamObjectId = decode_object_id(teamId)
    ebookObjectId = decode_object_id(ebookId)
    GroupPostRepo.addEbookForClassFromRegister(groupObjectId, teamObjectId, ebookObjectId)
  end


  def addEbookForClass(changeset, groupObjectId, teamId) do
    teamObjectId = decode_object_id(teamId)
    GroupPostRepo.addEbookForClass(changeset, groupObjectId, teamObjectId)
  end



  def getEbooksForTeamFromRegister(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    getEbooks = GroupPostRepo.getEbooksForTeamFromRegister(groupObjectId, teamObjectId)
    if length(getEbooks) > 0 do
      hdOfEBooks = hd(getEbooks)
      hdOfEBooks["ebookDetails"]["subjectBooks"]
    else
      []
    end
  end


  def getEbooksForTeam(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    GroupPostRepo.getEbooksForTeam(groupObjectId, teamObjectId)
  end


  def removeEbooksForClass(groupObjectId, team_id, ebook_id) do
    teamObjectId = decode_object_id(team_id)
    ebookObjectId = decode_object_id(ebook_id)
    GroupPostRepo.removeEbooksForClass(groupObjectId, teamObjectId, ebookObjectId)
  end


  def addSubjectForClass(changeset, groupObjectId, loginUserId) do
    GroupPostRepo.addSubjectForClass(changeset, groupObjectId, loginUserId)
  end


  def getClassSubjects(groupObjectId) do
    GroupPostRepo.getClassSubjects(groupObjectId)
  end


  def updateSubjects(changeset, groupObjectId, subjectId) do
    subjectObjectId = decode_object_id(subjectId)
    GroupPostRepo.updateSubjects(changeset, groupObjectId, subjectObjectId)
  end



  def addToSchoolCalendar(conn, groupObjectId, changeset, day, month, year) do
    loginUser = Guardian.Plug.current_resource(conn)
    GroupPostRepo.addToSchoolCalendar(loginUser["_id"], groupObjectId, changeset, day, month, year)
  end



  def getSchoolCalendar(groupObjectId, month, year) do
    GroupPostRepo.getSchoolCalendar(groupObjectId, month, year)
  end


  def getSchoolCalendarEvent(groupObjectId, day, month, year) do
    GroupPostRepo.getSchoolCalendarEvent(groupObjectId, day, month, year)
  end


  def removeEventFromSchoolCalendar(groupObjectId, eventObjectId) do
    GroupPostRepo.removeEventFromSchoolCalendar(groupObjectId, eventObjectId)
  end


  #def addLiveClassTokenToClass(group, team) do
  #  #check jitsi token for team exist or not
  #  {:ok, checkJitsiTokenExist} = GroupPostRepo.checkJitsiTokenExist(group["_id"], team["_id"])
  #  if checkJitsiTokenExist > 0 do
  #    #jitsi token already exist
  #    {:ok, "Already Added"}
  #  else
  #    groupName = String.trim(group["name"], "-")
  #    teamName = team["name"]
  #    randomNumber = :rand.uniform(9999999999)
  #    dateTime = DateTime.utc_now()
  #               |> DateTime.to_iso8601()
      #join/concate all above strings
  #    join = Enum.join([teamName, "-", groupName, "-", randomNumber, "-", dateTime], "")
      #remove white spaces from above contcatenated sring
  #    concateinatedToken = String.replace(join, ~r"[ /]", "")
  #    GroupPostRepo.addLiveClassTokenToClass(group["_id"], team["_id"], concateinatedToken)
  #  end
  #end


  def addLiveClassTokenToClass(group, team) do
    #check secret keys already added
    {:ok, checkZoomKeysExist} = GroupPostRepo.checkZoomKeysExist(group["_id"], team["_id"])
    if checkZoomKeysExist > 0 do
      #jitsi token already exist
      {:ok, "Already Added"}
    else
      zoomKey = "NezBAck80EPh2KCsJ5RiynKm20dznUI2lVIk"
      zoomSecret = "IXvTUJTYKplPT7KNZWhpOAQO328fR6OwEeAB"
      GroupPostRepo.addZoomSecretKeysToClass(group["_id"], team["_id"], zoomKey, zoomSecret)
    end
  end


  #def createZoomHost(groupObjectId, loginUserId, changeset) do
  #  GroupPostRepo.createZoomHost(groupObjectId, loginUserId, changeset)
  #end


  #def getZoomHostsForSchool(groupObjectId) do
  #  GroupPostRepo.getZoomHostsForSchool(groupObjectId)
  #end


  def sharePostToGroup(conn, params, post) do
    #if fileType is image
    if post["fileType"] == "image"  do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "fileName" => fileName, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToGroupPost(conn, post_params, params)
    else
      post
    end
    #if file type is pdf/video
    if post["fileType"] == "pdf" || post["fileType"] == "video" do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "fileName" => fileName, "fileType" => fileType,
                       "thumbnailImage" => post["thumbnailImage"] }
      #calling private func to validate and add
      validateWhenSharingAndAddToGroupPost(conn, post_params, params)
    else
      post
    end
    #if file type is youtube
    if post["fileType"] == "youtube" do
      #making valid youtube link
      video = "https://www.youtube.com/watch?v="<>post["video"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "video" => video, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToGroupPost(conn, post_params, params)
    else
      post
    end
    #if sharing post contains no image or video
    if is_nil(post["fileType"]) do
      post_params = %{ "title" => post["title"], "text" => post["text"]}
      #calling private func to validate and add
      validateWhenSharingAndAddToGroupPost(conn, post_params, params)
    else
      post
    end
  end


  #private function to validate and share when sharing group post
  defp validateWhenSharingAndAddToGroupPost(conn, post_params, params) do
    login_user = Guardian.Plug.current_resource(conn)
    changeset = Post.changeset(%Post{}, post_params)
    if changeset.valid? do
      group_ids = params["groupId"]
      groupIdList = String.split(group_ids, ",")
      Enum.reduce(groupIdList, [], fn group_id, _acc ->
        GroupPostRepo.add(changeset.changes, login_user["_id"], decode_object_id(group_id))
      end)
    else
      {:changesetError, changeset.errors}
    end
  end
end
