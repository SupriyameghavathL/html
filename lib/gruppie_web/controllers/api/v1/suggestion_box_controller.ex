defmodule GruppieWeb.Api.V1.SuggestionBoxController  do
  use GruppieWeb, :controller
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Handler.SuggestionBoxHandler
  alias GruppieWeb.SuggestionBox


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }


  #post "/groups/:group_id/suggestion/add"
  def postSuggestionByParents(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    changeset = SuggestionBox.suggestionPost(%SuggestionBox{}, params)
    if changeset.valid? do
      case SuggestionBoxHandler.postSuggestionByParents(changeset.changes, group["_id"], loginUser["_id"]) do
        {:ok, _} ->
          conn
          |> put_status(201)
          |> json(%{})
        {:error, _error} ->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #get "groups/:group_id/suggestion/get"
  def getSuggestionToLoginUserAndAdmin(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUser = Guardian.Plug.current_resource(conn)
    #checking login user canPost true or not
    canPost = SuggestionBoxHandler.checkCanPostTrue(group["_id"], loginUser["_id"])
    suggestionPostList = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
      #to get all the post of that group from collection
      SuggestionBoxHandler.getAllSuggestionPost(group["_id"], params)
    else
      #to get only the post posted by the user
      SuggestionBoxHandler.getPostPostedByUser(group["_id"], loginUser["_id"])
    end
    render(conn, "get_suggestion_post.json", [getSuggestionPost: suggestionPostList, group: group, login_user: loginUser])
  end


  #get events for suggestion box post get
  #get "groups/:group_id/suggestion/events"
  def getEventsForSuggestionBoxPost(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      loginUser = Guardian.Plug.current_resource(conn)
      #checking login user canPost true or not
      canPost = SuggestionBoxHandler.checkCanPostTrue(group["_id"], loginUser["_id"])
      eventAt = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
        #admin, so get last suggestion post event at for admin
        SuggestionBoxHandler.getSuggestionBoxPostForAdmin(group["_id"])
      else
        #other users, so get last suggestion post event at for users
        SuggestionBoxHandler.getSuggestionBoxPostForUser(group["_id"], loginUser["_id"])
      end
      render(conn, "suggestion_events.json", [eventAt: eventAt])
    end
  end


  #get "groups/:groups_id/team/:team_id/post/:post_id/notes/read"?topicId=""
  def getNotesFeed(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "post_id" => post_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      postObjectId = decode_object_id(post_id)
      getNotesBasedOnId = if params["topicId"] do
        SuggestionBoxHandler.getNotesFeedTopic(group["_id"], teamObjectId, params["topicId"])
      else
        SuggestionBoxHandler.getNotesFeed(group["_id"], teamObjectId, postObjectId)
      end
      render(conn, "notes.json", [getNotesPost: getNotesBasedOnId])
    end
  end


  #get "groups/:group_id/team/:team_id/post/:post_id/homework/read"
  def getHomeWorkFeed(%Plug.Conn{params: _params} = conn, %{"group_id" => group_id, "team_id" => team_id, "post_id" => post_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      postObjectId = decode_object_id(post_id)
      getHomeWorkPostBasedOnId = SuggestionBoxHandler.getHomeWorksFeed(group["_id"], teamObjectId, postObjectId)
      # IO.puts "#{getHomeWorkPostBasedOnId}"
      render(conn, "homeWork.json", [getHomeWorkPost: getHomeWorkPostBasedOnId])
    end
  end
end
