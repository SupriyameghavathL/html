defmodule GruppieWeb.Handler.NotificationHandler do
  alias GruppieWeb.Repo.NotificationRepo
  import GruppieWeb.Repo.RepoHelper


  def groupPostNotification(conn, group, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addGroupPostNotification(loginUser, group, postObjectId)
  end



  def galleryAddNotification(conn, groupId, albumId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(groupId)
    #insert into notification coll
    NotificationRepo.galleryAddNotification(loginUser, groupObjectId, albumId)
  end


  def schoolCalendarAddNotification(conn, groupObjectId, day, month, year) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.schoolCalendarAddNotification(loginUser, groupObjectId, day, month, year)
  end


  def teamPostNotification(conn, group_id, team, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #insert into notification coll
    NotificationRepo.addTeamPostNotification(loginUser, groupObjectId, team, postObjectId)
  end


  def removeNotificationFromTeam(postId) do
    postObjectId = decode_object_id(postId)
    NotificationRepo.removeNotificationFromTeam(postObjectId)
  end


  def timeTablePostNotification(conn, group_id, team, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #insert into notification coll
    NotificationRepo.addTimeTablePostNotification(loginUser, groupObjectId, team, postObjectId)
  end


  def individualPostNotification(conn, group_id, friend_id, postObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    friendObjectId = decode_object_id(friend_id)
    #insert into notification coll
    NotificationRepo.addIndividualPostNotification(loginUser, groupObjectId, friendObjectId, postObjectId)
  end


  def attendanceNotification(loginUserId, absentStudentIds, groupObjectId, teamObjectId) do
    #insert into notification coll
    NotificationRepo.attendanceNotification(loginUserId, absentStudentIds, groupObjectId, teamObjectId)
  end


  def marksCardAddNotification(conn, groupObjectId, team_id, user_id, rollNo) do
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #insert into notification col
    NotificationRepo.marksCardAddNotification(loginUser["_id"], groupObjectId, teamObjectId, userObjectId, rollNo)
  end


  def studentINNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, rollNumber) do
    #insert into notification coll
    NotificationRepo.studentINNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, rollNumber)
  end


  def studentOUTNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, rollNumber) do
    #insert into notification coll
    NotificationRepo.studentOUTNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, rollNumber)
  end



  def groupPostCommentNotification(conn, group, commentObjectId, post) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addGroupPostCommentNotification(loginUser, group, commentObjectId, post)
  end



  def groupPostCommentReplyNotification(conn, group, comment) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addGroupPostCommentReplyNotification(loginUser, group, comment)
  end


  def teamPostCommentNotification(conn, groupObjectId, team, commentObjectId, post) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addTeamPostCommentNotification(loginUser, groupObjectId, team, post, commentObjectId)
  end


  def teamPostCommentReplyNotification(conn, group_id, team, comment) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #insert into notification coll
    NotificationRepo.addTeamPostCommentReplyNotification(loginUser, groupObjectId, team, comment)
  end


  def individualPostCommentNotification(conn, groupObjectId, commentObjectId, post) do
    loginUser = Guardian.Plug.current_resource(conn)
    #insert into notification coll
    NotificationRepo.addIndividualPostCommentNotification(loginUser, groupObjectId, post, commentObjectId)
  end


  def individualPostCommentReplyNotification(conn, group_id, comment) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #insert into notification coll
    NotificationRepo.addIndividualPostCommentReplyNotification(loginUser, groupObjectId, comment)
  end


  def getNotifications(conn, group_id, pageLimit, params) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    NotificationRepo.getNotifications(loginUser["_id"], groupObjectId, pageLimit, params)
  end


end
