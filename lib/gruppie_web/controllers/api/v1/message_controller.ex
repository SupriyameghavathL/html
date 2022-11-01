defmodule GruppieWeb.Api.V1.MessageController do
  use GruppieWeb, :controller
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Post
  alias GruppieWeb.Handler.MessageHandler
  alias GruppieWeb.Structs.JsonErrorResponse

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }
  #plug Gruppie.Plugs.TeamAuth, when action in [:addTeamIndividualPost]

  #add individual post for team individual users
  #/groups/:group_id/team/:team_id/user/:user_id/post/add
  def addMessageToTeamUser(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    changeset = Post.changeset(%Post{}, params)
    if changeset.valid? do
      case MessageHandler.addMessageToTeamUser(changeset.changes, conn, group_id, team_id, user_id) do
        {:ok, _created}->
          #add notification
    #      NotificationHandler.individualPostNotification(conn, group_id, user_id, created.inserted_id)
          #get device token for this user_id
    #      getDeviceToken = MessageHandler.getDeviceToken(decode_object_id(user_id), decode_object_id(group_id))
    #      render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: decode_object_id(user_id), loginUser: Guardian.Plug.current_resource(conn)] )
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #add individidual post directly
  #/groups/:group_id/user/:user_id/post/add
  def addMessage(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    changeset = Post.changeset(%Post{}, params)
    if changeset.valid? do
      case MessageHandler.addMessageDirect(changeset.changes, conn, group_id, user_id) do
        {:ok, _created}->
          #add notification
      #    NotificationHandler.individualPostNotification(conn, group_id, user_id, created.inserted_id)
          #get device token for this user_id
      #    getDeviceToken = MessageHandler.getDeviceToken(decode_object_id(user_id), decode_object_id(group_id))
      #    render(conn, "deviceToken.json", [deviceToken: getDeviceToken, userObjectId: decode_object_id(user_id), loginUser: Guardian.Plug.current_resource(conn)] )
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #add individidual message to multiple parents
  #/groups/:group_id/multipleuser/post/add?userId=Id1,id2....
  def addMultipleIndividualMessage(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    if !is_nil(params["userIds"]) do
      params = params
               |> Map.put_new("text", params["title"])
               |> Map.delete("title")
      changeset = Post.changeset(%Post{}, params)
      if changeset.valid? do
        ##text conn, params["userIds"]
        splitUserIds = String.split(params["userIds"], ",")
        case MessageHandler.addMultipleIndividualMessage(changeset.changes, conn, group_id, splitUserIds) do
          {:ok, _created}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _error}->
            conn
            |>put_status(500)
            |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        conn
        |> put_status(400)
        |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      conn
      |>put_status(400)
      |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get individual post inbox list
  #/groups/:group_id/chat/inbox
  def getChatInbox(conn, %{"group_id" => group_id}) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #get individual chat inbox
    chatInbox = MessageHandler.getMessageInbox(loginUser["_id"], groupObjectId)
    render(conn, "chatInboxList.json", [chatInbox: chatInbox, groupObjectId: groupObjectId, loginUserId: loginUser["_id"]])
  end


  #get all my team users added by me to the group contacts for chat contact
  #same api used for my people
  #get "/groups/:group_id/chat/contacts"
  def getChatContacts(conn, %{ "group_id" => group_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    #get my people (All users added by me to the group in multiple team)
    chatContacts = MessageHandler.getMyPeople(loginUser["_id"], groupObjectId)
    render(conn, "chatContactsList.json", [chatContacts: chatContacts])
  end



  #get individual post list
  #/groups/:group_id/user/:user_id/posts/get
  def getMessages(conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    userObjectId = decode_object_id(user_id)
    #get individual post list
    messageList = MessageHandler.getMessages(conn, userObjectId, groupObjectId, resultLimit = 15)
    render(conn, "MessageList.json", [messageList: messageList, loginUserId: loginUser["_id"], limit: resultLimit, userObjectId: userObjectId, groupObjectId: groupObjectId])
  end


  #individual_post_delete
  #PUT"/groups/:group_id/user/:user_id/post/:post_id/delete"
  def deleteIndividualMessage(conn, %{ "group_id" => group_id, "user_id" => user_id, "post_id" => post_id }) do
    case MessageHandler.deleteIndividualMessage(conn, group_id, user_id, post_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:changesetError, "error"}->
        conn
        |>put_status(403)
        |>json(%JsonErrorResponse{code: 403, title: "Forbidden", message: "You cannot delete this post"})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end




end
