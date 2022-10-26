defmodule GruppieWeb.Handler.GroupPostHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupPostRepo



  def add(changeset, conn, groupObjectId) do
    login_user = Guardian.Plug.current_resource(conn)
    GroupPostRepo.add(changeset, login_user["_id"], groupObjectId)
  end


  def getAll(conn, groupObjectId, limit) do
    GroupPostRepo.getAll(conn, groupObjectId, limit)
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





end
