defmodule GruppieWeb.Api.V1.FeederNotificationController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.FeederNotificationHandler
  alias GruppieWeb.Repo.ConstituencyCategoryRepo
  alias GruppieWeb.Post
  alias GruppieWeb.Handler.TeamPostHandler
  alias GruppieWeb.Repo.TeamPostRepo
  alias GruppieWeb.Handler.GroupHandler
  alias GruppieWeb.Handler.NotificationHandler
  alias GruppieWeb.Handler.GroupPostHandler
  alias GruppieWeb.Repo.TeamRepo


  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" } when action not  in [:addReportsToDb, :getReportsListToDb, :postLanguages, :getLanguages]


  #get "groups/:group_id/all/post/get"
  def getAllPost(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    canPost = ConstituencyCategoryRepo.checkCanPost(group["_id"], loginUser["_id"])
    if group["category"] == "constituency" || group["category"] == "community" do
      allPostList = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
        FeederNotificationHandler.getAllPostForAdmin(group["_id"], params)
      else
        FeederNotificationHandler.getAllPostForUser(group["_id"], loginUser, params)
      end
      render(conn, "postListAll.json", [getAllPostList: allPostList, group: group, loginUser: loginUser])
    else
      allPostSchool = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
       cond do
        params["type"] == "noticeBoard" ->
          FeederNotificationHandler. getAllPostForAdminSchool(group["_id"], params)
        params["type"] == "homeWork" ->
          FeederNotificationHandler.getAllHomeWorkPostAdmin(group["_id"], params)
        params["type"] == "notesVideos" ->
          FeederNotificationHandler.getAllNotesAndVideosPostAdmin(group["_id"], params)
        true ->
          FeederNotificationHandler. getAllPostForAdminSchool(group["_id"], params)
       end
      else
        cond do
          params["type"] == "noticeBoard" ->
            FeederNotificationHandler.getAllPostForUserSchool(group["_id"], loginUser, params)
          params["type"] == "homeWork" ->
            FeederNotificationHandler.getAllHomeWorkPostUser(group["_id"], loginUser, params)
          params["type"] == "notesVideos" ->
            FeederNotificationHandler.getAllNotesAndVideosPostUser(group["_id"], loginUser, params)
          true ->
            FeederNotificationHandler.getAllPostForUserSchool(group["_id"], loginUser, params)
        end
      end
      render(conn, "allPostSchool.json", [getAllPostList: allPostSchool,  group: group,
                                          loginUser: loginUser, params: params])
    end
  end


  #events api
  #get "groups/:group_id/all/post/get/events"
  def getAllPostEvent(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    canPost = ConstituencyCategoryRepo.checkCanPost(group["_id"], loginUser["_id"])
    if group["category"] == "constituency" do
      allPostListEvents = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
        FeederNotificationHandler.getAllPostForAdminEvents(group["_id"])
      else
        FeederNotificationHandler.getAllPostForUserEvent(group["_id"], loginUser)
      end
      render(conn, "postListAllEvents.json", [getAllPostListEvents: allPostListEvents])
    else
      allPostListEvents = if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
        cond do
         params["type"] == "noticeBoard" ->
           FeederNotificationHandler. getAllPostForAdminSchoolEvents(group["_id"])
         params["type"] == "homeWork" ->
           FeederNotificationHandler.getAllHomeWorkPostAdminEvents(group["_id"])
         params["type"] == "notesVideos" ->
           FeederNotificationHandler.getAllNotesAndVideosPostAdminEvents(group["_id"])
         true ->
          FeederNotificationHandler. getAllPostForAdminSchoolEvents(group["_id"])
        end
      else
        cond do
          params["type"] == "noticeBoard" ->
            FeederNotificationHandler.getAllPostForUserSchoolEvents(group["_id"], loginUser)
          params["type"] == "homeWork" ->
            FeederNotificationHandler.getAllHomeWorkPostUserEvents(group["_id"], loginUser)
          params["type"] == "notesVideos" ->
            FeederNotificationHandler.getAllNotesAndVideosPostUserEvents(group["_id"], loginUser)
          true ->
            FeederNotificationHandler.getAllPostForUserSchoolEvents(group["_id"], loginUser)
        end
      end
      render(conn, "postListAllEvents.json", [getAllPostListEvents: allPostListEvents])
    end
  end


  #post "gruppie/reports/list/add"
  def addReportsToDb(conn, params)  do
    case FeederNotificationHandler.addReportsListToDb(params["reports"]) do
      {:ok, _}  ->
        conn
        |> put_status(201)
        |> json(%{})
    end
  end


  def getReportsListToDb(conn, _params) do
    reportList = FeederNotificationHandler.getReportsListToDb()
    render(conn, "reportList.json", [getReportList: reportList])
  end


  # get "groups/:group_id/feeder/teams/get"
  def getTeamToPost(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    canPost = ConstituencyCategoryRepo.checkCanPost(group["_id"], loginUser["_id"])
    cond do
      group["category"] == "constituency" ->
        if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
          #getting teams Array from group_team_doc
          allTeamsList = FeederNotificationHandler.getTeamsArrayConstituencyAdmin(group["_id"], loginUser["_id"], params)
          render(conn, "canPostTeamList.json", [teamsList: allTeamsList, group: group, params: params])
        else
          allTeamListUser = FeederNotificationHandler.getTeamsArrayUser(group["_id"], loginUser["_id"], params)
          render(conn, "teamListUserConstituency.json", [teamsList: allTeamListUser])
        end
      group["category"] == "school" ->
        if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
          #getting teams Array from group_team_doc
          allTeamsList = FeederNotificationHandler.getTeamsArraySchoolAdmin(group["_id"], loginUser["_id"], params)
          render(conn, "canPostTeamList.json", [teamsList: allTeamsList, group: group, params: params])
        else
          allTeamListUser = FeederNotificationHandler.getTeamsArrayUser(group["_id"], loginUser["_id"], params)
          render(conn, "teamListUser.json", [teamsList: allTeamListUser])
        end
      group["category"] == "community" ->
        if loginUser["_id"] == group["adminId"] || canPost["canPost"] == true do
          #getting teams Array from group_team_doc
          allTeamsList = FeederNotificationHandler.getTeamsArrayCommunityAdmin(group["_id"], loginUser["_id"], params)
          render(conn, "canPostTeamList.json", [teamsList: allTeamsList, group: group, params: params])
        else
          allTeamListUser = FeederNotificationHandler.getTeamsArrayUser(group["_id"], loginUser["_id"], params)
          render(conn, "teamListUser.json", [teamsList: allTeamListUser])
        end
      true ->
        conn
        |> put_status(400 )
        |> json(%{})
    end
  end


  #post "groups/:group_id/feeder/post/add"
  def postFromFeeder(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if !params["postId"] do
      changeset = Post.changeset(%Post{}, params)
      if changeset.valid? do
        if params["selectedArray"] do
          for postType <- params["selectedArray"] do
            cond do
              postType["type"] == "groupPost" ->
                  case GroupPostHandler.add(changeset.changes, conn, group["_id"]) do
                    {:ok, created}->
                      #add groupPost event
                      GroupHandler.addGroupPostEvent(created.inserted_id, group["_id"])
                      #add notification
                      NotificationHandler.groupPostNotification(conn, group, created.inserted_id)
                      conn
                      |> put_status(201)
                      |> json(%{})
                    {:error, _error}->
                      conn
                      |>put_status(500)
                      |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
                  end
              postType["type"] == "teamPost" ->
                team = TeamRepo.get(postType["id"])
                case TeamPostHandler.add(changeset.changes, conn, group_id, team["_id"]) do
                  {:ok, created}->
                    #check team is subbooth or booth
                    if Map.has_key?(team, "category") do
                      if  team["category"] == "booth"  do
                        TeamPostRepo.incrementBoothDiscussionCount(group["_id"])
                      else
                        if  team["category"] == "subBooth" do
                          TeamPostRepo.incrementSubBoothDiscussionCount(group["_id"])
                        end
                      end
                    end
                    #add teamPost event for school
                    GroupHandler.addTeamPostEvent(created.inserted_id, group_id, postType["id"])
                    #add notification
                    NotificationHandler.teamPostNotification(conn, group_id, team, created.inserted_id)
                    conn
                    |> put_status(201)
                    |> json(%{})
                  {:error, _error}->
                    conn
                    |> put_status(500)
                    |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
                end
            end
          end
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      getPostDetails = FeederNotificationHandler.getPostDetails(decode_object_id(params["postId"]))
      if params["selectedArray"] do
        for postType <- params["selectedArray"] do
          cond do
            postType["type"] == "groupPost" ->
                case GroupPostHandler.add(getPostDetails, conn, group["_id"]) do
                  {:ok, created}->
                    #add groupPost event
                    GroupHandler.addGroupPostEvent(created.inserted_id, group["_id"])
                    #add notification
                    NotificationHandler.groupPostNotification(conn, group, created.inserted_id)
                    conn
                    |> put_status(201)
                    |> json(%{})
                  {:error, _error}->
                    conn
                    |>put_status(500)
                    |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
                end
            postType["type"] == "teamPost" ->
              team = TeamRepo.get(postType["id"])
              case TeamPostHandler.add(getPostDetails, conn, group_id, team["_id"]) do
                {:ok, created}->
                  #check team is subbooth or booth
                  if Map.has_key?(team, "category") do
                    if  team["category"] == "booth"  do
                      TeamPostRepo.incrementBoothDiscussionCount(group["_id"])
                    else
                      if  team["category"] == "subBooth" do
                        TeamPostRepo.incrementSubBoothDiscussionCount(group["_id"])
                      end
                    end
                  end
                  #add teamPost event for school
                  GroupHandler.addTeamPostEvent(created.inserted_id, group_id, postType["id"])
                  #add notification
                  NotificationHandler.teamPostNotification(conn, group_id, team, created.inserted_id)
                  conn
                  |> put_status(201)
                  |> json(%{})
                {:error, _error}->
                  conn
                  |> put_status(500)
                  |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
              end
          end
        end
      end
    end
  end


  # get "groups/:group_id/team/:team_id/language/get"
  def getLanguageList(%Plug.Conn{params: _params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      getLanguageList = FeederNotificationHandler.getLanguageListClass(group["_id"], teamObjectId)
      render(conn, "languageList.json", [getLanguageList: getLanguageList])
    end
  end


  #get "gruppie/languages/get"
  def getLanguages(conn, _params) do
    languageMap = FeederNotificationHandler.getLanguages()
    render(conn, "gruppieLanguage.json", [getLanguageMap: languageMap])
  end


  #post "gruppie/languages/add"
  def postLanguages(conn, params) do
    case FeederNotificationHandler.postLanguages(params) do
      {:ok, _}  ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end

  #post "groups/:group_id/post/uniqueid"
  def addUniquePostId(conn,  %{"group_id" => group_id}) do
    groupObjectId = decode_object_id(group_id)
    case hd(FeederNotificationHandler.getPostForUniqueId(groupObjectId)) do
      {:ok, _}  ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end
end
