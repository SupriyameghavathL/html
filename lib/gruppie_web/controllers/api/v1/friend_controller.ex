defmodule GruppieWeb.Api.V1.FriendController do
  use GruppieWeb, :controller
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Handler.FriendHandler
  alias GruppieWeb.Handler.NotificationHandler


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }


  #get all my team users added by me to the group contacts for chat contact
  #same api used for my people
  #get "/groups/:groupp_id/my/people"
  def getMyPeople(conn, %{ "group_id" => group_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #get my people (All users added by me to the group in multiple team)
    getPeople = FriendHandler.getMyPeople(loginUser["_id"], groupObjectId)
    render(conn, "myPeopleList.json", [myPeople: getPeople, groupObjectId: groupObjectId])
  end


  #get nested level people
  #get "/groups/:group_id/user/:user_id/people"
  def getNestedPeople(conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    userObjectId = decode_object_id(user_id)
    groupObjectId = decode_object_id(group_id)
    #get my people (All users added by me to the group in multiple team)
    getPeople = FriendHandler.getMyPeople(userObjectId, groupObjectId)
    render(conn, "myPeopleList.json", [myPeople: getPeople, groupObjectId: groupObjectId])
  end


  #get notificatons saved for login user
  #get "/groups/:group_id/notifications/get"
  def getNotifications(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    pageLimit=20
    #get all types of notifications for login user
    notifications = NotificationHandler.getNotifications(conn, group_id, pageLimit, params)
    render(conn, "notifications.json", [notifications: notifications, loginUserId: loginUser["_id"], groupObjectId: decode_object_id(group_id), limit: pageLimit])
  end

end
