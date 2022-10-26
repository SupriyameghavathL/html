defmodule GruppieWeb.Handler.NotificationHandler do
  alias GruppieWeb.Repo.NotificationRepo
  import GruppieWeb.Repo.RepoHelper


  def groupPostNotification(conn, group, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addGroupPostNotification(loginUser, group, postObjectId)
  end

  def getNotifications(conn, group_id, pageLimit, params) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    NotificationRepo.getNotifications(loginUser["_id"], groupObjectId, pageLimit, params)
  end


  def galleryAddNotification(conn, groupId, albumId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(groupId)
    #insert into notification coll
    NotificationRepo.galleryAddNotification(loginUser, groupObjectId, albumId)
  end

  def teamPostNotification(conn, group_id, team, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #insert into notification coll
    NotificationRepo.addTeamPostNotification(loginUser, groupObjectId, team, postObjectId)
  end



end
