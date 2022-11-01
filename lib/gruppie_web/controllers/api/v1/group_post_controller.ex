defmodule GruppieWeb.Api.V1.GroupPostController do
  use GruppieWeb, :controller
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Handler.GroupPostHandler
  alias GruppieWeb.Post
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Handler.GroupHandler
  alias GruppieWeb.Handler.NotificationHandler
  alias GruppieWeb.Repo.GroupPostRepo
  alias GruppieWeb.User
  alias GruppieWeb.Team
  alias GruppieWeb.Handler.AdminHandler
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Handler.TeamHandler



  #auth to check user is in group or not
  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" } when  action not in [:getGallery]
  #auth to check user can post in group or not
  plug GruppieWeb.Plugs.GroupPostAddAuth, %{ "group_id" => "group_id" } when action in
  [:create, :galleryAdd, :galleryAlbumAdd, :vendorsAdd, :cocAdd, :deletePost, :deleteAlbum,
  :deleteVendor, :deleteCoc, :addClassToSchool, :addBus, :eBooksRegister, :eBooksGet, :deleteEbook,
  :addSubjectForClass, :getSubjectsOfClass, :addStudentToClass, :updateStudentData, :removeStudent,
  :calendarAdd,:addStaffToSchool, :updateStaffData, :removeStaff, :addEbookForClass,
  :addJitsiLiveClassToken, :getStudentFeeListForClass, :getFeeStatusList, :schoolCalendarAdd, :removeEventFromSchoolCalendar]
  #check user already in team
  plug GruppieWeb.Plugs.TeamUserAlreadyExistAuth when action in [:addStudentToBus]




   #add group post
  #post "/groups/:group_id/posts/add"
  def create(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
   group = GroupRepo.get(group_id)
   changeset = Post.changeset(%Post{}, params)
    if changeset.valid? do
     case GroupPostHandler.add(changeset.changes, conn, group["_id"]) do
       {:ok, created}->
         #add groupPost event
         GroupHandler.addGroupPostEvent(created.inserted_id, group["_id"])
         #add notification
         NotificationHandler.groupPostNotification(conn, group, created.inserted_id)
         conn
         |> put_status(201)
         |> json(%{data: [%{"postId" => encode_object_id(created.inserted_id)}]})
       {:error, _error}->
         conn
         |>put_status(500)
         |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
     end
    else
     conn
     |> put_status(400)
     |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #get all group posts
  #get "/groups/:group_id/posts/get"
  def index(conn, %{ "group_id" => group_id  }) do
    # if group_id == "5f06cca74e51ba15f5167b86" do
    #   conn
    #   |>put_status(426)
    #   |>json %JsonErrorResponse{code: 426, title: "Update Available: Please update app from Play Store", message: "Update Available"}
    # else
       group = GroupRepo.get(group_id)
       posts = GroupPostHandler.getAll(conn, group["_id"], resultLimit = 15)
       render(conn, "posts.json", [ posts: posts, group: group, conn: conn, limit: resultLimit ] )
    # end
  end


  #add items to gallery
  #post "/groups/:group_id/gallery/add"
  def galleryAdd(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    changeset = Post.changeset_gallery(%Post{}, params)
    if changeset.valid? do
      case GroupPostHandler.addAlbumToGallery(changeset.changes, conn, group_id) do
        {:ok, created}->
          #add gallery event
          GroupHandler.addGroupGalleryEvent(decode_object_id(group_id))
          #add notification
          NotificationHandler.galleryAddNotification(conn, group_id, created.inserted_id)
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
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #add additional image to gallery album
  #put "/groups/:group_id/album/:album_id/add"
  def galleryAlbumAdd(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id, "album_id" => album_id }) do
    groupObjectId = decode_object_id(group_id)
    albumObjectId = decode_object_id(album_id)
    album = GroupPostRepo.getAlbumById(albumObjectId)
    changeset = Post.changeset_album_add(%Post{}, params)
    if changeset.valid? do
      #check new fileType is same as album fileTypes
      if changeset.changes.fileType == album["fileType"] do
        case GroupPostHandler.albumImageAdd(groupObjectId, albumObjectId, changeset.changes) do
          {:ok, _}->
            conn
            |> put_status(200)
            |> json(%{})
          {:error, _error}->
            conn
            |>put_status(500)
            |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        conn
        |> put_status(400)
        |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: "File Type Not Allowed"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #remove image from album in gallery
  #put, "/groups/:group_id/album/:album_id/remove?fileName=name1,name2
  def removeAlbumImage(%Plug.Conn{ query_params: file_name } = conn, %{ "group_id" => group_id, "album_id" => album_id }) do
    if is_nil(file_name["fileName"]) do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "File Not Found"})
    else
      fileName = String.split(file_name["fileName"], ",")
      case GroupPostHandler.removeAlbumImage(group_id, album_id, fileName) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end


  #vendor add by admin or authorized users
  #post "/groups/:group_id/vendors/add"
  def vendorsAdd(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    changeset = Post.changeset_vendor(%Post{}, params)
    if changeset.valid? do
      case GroupPostHandler.addVendor(changeset.changes, conn, group_id) do
        {:ok, created}->
          #text conn, created
          conn
          |> put_status(201)
          |> json(%{data: %{ vendorId: encode_object_id(created.inserted_id)}})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #code of conduct add by admin or authorized users
  #post "/groups/:group_id/coc/add"
  def cocAdd(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    changeset = Post.changeset_coc(%Post{}, params)
    if changeset.valid? do
      case GroupPostHandler.addCoc(changeset.changes, conn, group_id) do
        {:ok, created}->
          conn
          |> put_status(201)
          |> json(%{data: %{ cocId: encode_object_id(created.inserted_id)}})
        {:error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #get gallery for group
  #get "/groups/:group_id/gallery/get"
  def getGallery(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    gallery = GroupPostHandler.getGallery(conn, group["_id"], resultLimit = 10)
    render(conn, "gallery.json", [ gallery: gallery, limit: resultLimit, conn: conn, group: group ] )
  end


  #get vendors
  #get "/groups/:group_id/vendors/get"
  def getVendors(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    vendors = GroupPostHandler.getVendors(conn, group["_id"])
    render(conn, "vendor.json", [ vendors: vendors, conn: conn, group: group ] )
  end


  #get coc
  #get "/groups/:group_id/coc/get"
  def getCoc(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    coc = GroupPostHandler.getCoc(conn, group["_id"])
    render(conn, "coc.json", [ coc: coc, conn: conn, group: group ] )
  end


  #group post delete by one who created
  #put "/groups/:group_id/posts/:post_id/delete"
  def deletePost(conn, %{ "group_id" => group_id, "post_id" => post_id }) do
    group = GroupRepo.get(group_id)
    case GroupPostHandler.deletePost(conn, group, post_id) do
      {:ok, _}->
        GroupPostRepo.deleteGroupPost(group["_id"])
        #add groupPost event
        GroupHandler.addGroupPostEvent("", group["_id"])
        GroupPostHandler.deleteNotificationGroupPost(post_id)
        conn
        |> put_status(200)
        |> json(%{})
      {:changeset_error, message}->
        conn
        |>put_status(403)
        |>json(%JsonErrorResponse{code: 403, title: "Forbidden", message: message})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #group album by one who created
  #put "/groups/:group_id/album/:album_id/delete"
  def deleteAlbum(conn, %{ "group_id" => group_id, "album_id" => album_id }) do
    case GroupPostHandler.deleteAlbum(group_id, album_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #coc delete by one who created
  #put "/groups/:group_id/vendor/:vendor_id/delete"
  def deleteVendor(conn, %{ "group_id" => group_id, "vendor_id" => vendor_id }) do
    case GroupPostHandler.deleteVendor(group_id, vendor_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


   #vendor delete by one who created
  #put "/groups/:group_id/coc/:coc_id/delete"
  def deleteCoc(conn, %{ "group_id" => group_id, "coc_id" => coc_id }) do
    case GroupPostHandler.deleteCoc(group_id, coc_id) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  ########add class to school by admin or authorized users
  #post "/groups/:id/class/add"
  def addClassToSchool(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      #firstly add class teacher
      parameters = %{ name: conn.params["teacherName"], countryCode: conn.params["countryCode"],
                    phone: conn.params["phone"] }
      changeset = User.changeset_add_friend(%User{}, parameters)
      #secondly create team with this userId as adminId
  #    parameterTeam = %{ name: conn.params["className"], image: conn.params["classImage"], category: conn.params["category"] }
      parameterTeam = %{ name: conn.params["className"], image: conn.params["classImage"],
                         category: conn.params["category"], subjectId: conn.params["subjectId"],
                         ebookId: conn.params["ebookId"]}
      changesetTeam = Team.changeset_class(%Team{}, parameterTeam)
      if changeset.valid? && changesetTeam.valid? do
        #find and add user to user table if not exist else get userId and add team with userId = adminId
        user = AdminHandler.addTeacherToUserTableIfNotExist(changeset.changes, group)
        case TeamRepo.createClassTeam(user, changesetTeam.changes, group["_id"]) do
          {:ok, success} ->
            data = %{ "teamId" => success }
            json conn, %{ data: data }
          {:error, _error}->
            conn
            |>put_status(500)
            |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get staffs list
  #get "/groups/:group_id/staff/get"
  def getSchoolStaff(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    staffGet = TeamHandler.getSchoolStaff(group["_id"])
    render(conn, "staff.json", [staff: staffGet, group: group])
  end

  #get class in student register
  #get "/groups/:id/class/get" ?staffId=:staffId  //to get only selected staff class list
  def getClasses(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    if params["staffId"] do
      #get class list for selected staffId/userId
      myClassTeam = TeamHandler.getMyClassTeams(decode_object_id(params["staffId"]), group["_id"])
      render(conn, "myClassTeams.json", [myClassTeam: myClassTeam, groupObjectId: group["_id"]])
    else
      #get all class list
      classes = AdminHandler.getClasses(group["_id"])
      render(conn, "class.json", [classes: classes, groupObjectId: group["_id"]])
    end
  end


  #get list of students from student db
  #get "/groups/:group_id/team/:team_id/students/get"
  def getStudents(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    studentsList = AdminHandler.getClassStudents(group, team_id)
    render(conn, "studentsList.json", [students: studentsList, groupObjectId: group["_id"], teamId: team_id])
  end





end
