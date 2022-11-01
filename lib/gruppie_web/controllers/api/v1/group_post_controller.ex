defmodule GruppieWeb.Api.V1.GroupPostController do
  use GruppieWeb, :controller
  alias GruppieWeb.Post
  alias GruppieWeb.Handler.GroupPostHandler
  alias GruppieWeb.Handler.GroupHandler
  alias GruppieWeb.Handler.NotificationHandler
  alias GruppieWeb.Repo.GroupPostRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Handler.AdminHandler
  alias GruppieWeb.Handler.TeamHandler
  alias GruppieWeb.Handler.TeamPostHandler
  alias GruppieWeb.Handler.TeamSettingsHandler
  alias GruppieWeb.User
  alias GruppieWeb.Team
  alias GruppieWeb.Post


  #auth to check user is in group or not
  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" } when action not in [:getGallery]
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



  #get saved post for loin user
  #get "/groups/:group_id/posts/saved"?page=1/2/3...
  def getPostSaved(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    posts = GroupPostHandler.getSavedPost(conn, group["_id"], pageLimit = 15)
    render(conn, "saved_posts.json", [ posts: posts, group: group, conn: conn, limit: pageLimit ] )
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



  ########add bus to school by admin or authorized users
  #post "/groups/:id/bus/add"
  def addBus(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      #firstly add class teacher
      parameters = %{ name: conn.params["driverName"], countryCode: conn.params["countryCode"],
                    phone: conn.params["phone"] }
      changeset = User.changeset_add_friend(%User{}, parameters)
      #secondly create team with this userId
      parameterTeam = %{ name: conn.params["routeName"], image: conn.params["image"] }
      changesetTeam = Team.changeset(%Team{}, parameterTeam)
      if changeset.valid? && changesetTeam.valid? do
        #find and add user to user table if not exist else get userId and add team with userId = adminId
        user = AdminHandler.addDriverToUserTableIfNotExist(changeset.changes, group)
        case TeamRepo.createBusTeam(user, changesetTeam.changes, group["_id"]) do
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


  #add books to school-class
  #post "/groups/:group_id/ebooks/register"
  def eBooksRegister(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    if group["category"] == "school" do
      #add subject to class
      changeset = Team.changeset_ebook_register(%Team{}, params)
      if changeset.valid? do
        case GroupPostHandler.addEbooksForClasses(changeset.changes, group["_id"], loginUser["_id"]) do
          {:ok, _}->
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
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get eBooks list foir admin/authorized user
  #/groups/:group_id/ebooks/get
  def eBooksGet(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      getBooks = GroupPostHandler.getEbooksForSchool(group_id)
      render(conn, "class_ebooks.json", [ ebooks: getBooks ])
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #delete ebooks from school/list
  #put "/groups/:group_id/ebook/:book_id/delete"
  def deleteEbook(conn, %{"group_id" => group_id, "book_id" => book_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      case GroupPostHandler.deleteEbook(group["_id"], book_id) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end



  #select or add ebook for already created classes without eBook
  #put "/groups/:group_id/team/:team_id/ebook/add?ebookId=121"
  def addEbookForClassFromRegister(%Plug.Conn{ params: params } = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case GroupPostHandler.addEbookForClassFromRegister(group["_id"], team_id, params["ebookId"]) do
      {:ok, _}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #select or add ebook for already created classes without eBook
  #post "/groups/:group_id/team/:team_id/ebooks/add"
  def addEbookForClass(%Plug.Conn{ params: params } = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #add ebooks for class
    changeset = Post.changeset_ebook_register(%Post{}, params)
    if changeset.valid? do
      #add ebooks to class
      case GroupPostHandler.addEbookForClass(changeset.changes, group["_id"], team_id) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
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



  #get ebooks for selected class
  #get "/groups/:group_id/team/:team_id/ebooks/get"
  def getEbooksForTeamFromRegister(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      getEbooksForTeam = GroupPostHandler.getEbooksForTeamFromRegister(group["_id"], team_id)
      render(conn, "get_Ebooks_teams_register.json", [ getEbooksForTeam: getEbooksForTeam ])
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #get ebooks for selected class
  #get "/groups/:group_id/team/:team_id/ebooks/get"
  def getEbooksForTeam(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      getEbooksForTeam = GroupPostHandler.getEbooksForTeam(group["_id"], team_id)
      ##text conn, getEbooksForTeam
      render(conn, "get_Ebooks_teams.json", [ getEbooksForTeam: getEbooksForTeam ])
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  #remove ebook added for class
  #put "/groups/:group_id/team/:team_id/ebook/:ebook_id/remove"
  def removeEbooksForTeam(conn, %{"group_id" => group_id, "team_id" => team_id, "ebook_id" => ebook_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] == "school" do
      #remove ebooks
      case GroupPostHandler.removeEbooksForClass(group["_id"], team_id, ebook_id) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
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




  #get bus in bus register
  #get "/groups/:id/bus/get"
  def getBuses(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    buses = AdminHandler.getBuses(group["_id"])
    render(conn, "bus.json", [buses: buses, groupObjectId: group["_id"]])
  end


  #add students to class
  #post "/groups/:id/staff/add"
  def addStaffToSchool(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.changeset_add_staff(%User{}, user_params)
    addStaffToSchool(conn, changeset, group)
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



  #add students to class
  #post "/groups/:id/team/:team_id/student/add"
  def addStudentToClass(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.changeset_add_student(%User{}, user_params)
    addStudentToTeam(conn, changeset, group, team_id)
  end



  #add students to bus
  #post "/groups/:id/team/:team_id/student/add/bus"
  def addStudentToBus(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      #not found error
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.changeset_add_friend(%User{}, user_params)
    addStudentToTeamBus(conn, changeset, group, team_id)
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



  #get list of students from student db
  #get "/groups/:group_id/team/:team_id/bus/students/get"
  def getBusStudents(conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    studentsList = AdminHandler.getBusStudents(group, team_id)
    render(conn, "busStudentsList.json", [students: studentsList, groupObjectId: group["_id"], teamId: team_id])
  end

  #update staff data in staff_database
  #put "/groups/:group_id/staff/:user_id/edit"
  def updateStaffData(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.addStaffToDB(%User{}, user_params)
    if changeset.valid? do
      case AdminHandler.updateStaffDetailsInDB(changeset.changes, group["_id"], user_id) do
        {:ok, _success}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #update staff phone details
  #put "/groups/:group_id/staff/:user_id/phone/edit"
  def updateStaffPhoneNumber(%Plug.Conn{body_params: body_params} = conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.updateStudentStaffPhoneNumber(%User{}, body_params)
    #update staff phone number in users_col
    case AdminHandler.updateStudentStaffPhoneNumber(changeset.changes, user_id) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end



  #update student data
  #put "/groups/:group_id/team/:team_id/student/:user_id/edit"
  def updateStudentData(%Plug.Conn{ body_params: user_params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.addStudentToDB(%User{}, user_params)
    if changeset.valid? do
      #update
      case AdminHandler.updateStudentDetailsInDB(changeset.changes, group["_id"], team_id, user_id) do
        {:ok, _success}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _mongo_error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end

  #update student phone details
  #put "/groups/:group_id/student/:user_id/phone/edit"
  def updateStudentPhoneNumber(%Plug.Conn{body_params: body_params} = conn, %{"group_id" => group_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = User.updateStudentStaffPhoneNumber(%User{}, body_params)
    #update staff phone number in users_col
    case AdminHandler.updateStudentStaffPhoneNumber(changeset.changes, user_id) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end


  #remove staff from staff database
  #delete, "/groups/:group_id/staff/:user_id/delete"
  def removeStaff(conn, %{ "group_id" => group_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case AdminHandler.removeStaffFromDB(group["_id"], user_id) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end



  #remove student from student database
  #delete, "/groups/:group_id/team/:team_id/student/:user_id/delete"
  def removeStudent(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #remove student from db (Student removed from db should get removed from group)
    case AdminHandler.removeStudentFromDB(group, team_id, user_id) do
      {:ok, _success}->
        AdminHandler.removeStudentFromFeeDB(group["_id"], team_id, user_id)
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end






  #remove student from bus register
  #delete, "/groups/:group_id/team/:team_id/student/:user_id/delete/bus"
  def removeBusStudent(conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id }) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case TeamSettingsHandler.removeTeamUser(group, team_id, user_id) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end




  ############ATTENDANCE

  #get class students with attendance present count for month
  #get "/groups/:group_id/team/:team_id/attendance/report/get?month=2&year=2019"
  def getAttendanceReport(%Plug.Conn{ query_params: month_params } = conn, %{ "group_id" => group_id, "team_id" => team_id }) do
    group = GroupRepo.get(group_id)
    # team = TeamRepo.get(team_id)
    # loginUser = Guardian.Plug.current_resource(conn)
    month = month_params["month"]
    year = month_params["year"]
    #check login user can post in group
    ###{:ok, userCanPost} = GroupPostRepo.checkLoginUserCanPostInGroup(group["_id"], loginUser["_id"])
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #get Attendance list
    attendanceList = TeamHandler.getAttendanceList(conn, group_id, team_id)
    render(conn, "attendanceReport.json", [ attendance: attendanceList, month: month, year: year, groupId: group_id, teamId: team_id ] )
  end




  #get attendance report of individual student
  #get "/groups/:group_id/team/:team_id/user/:user_id/attendance/report/get?rollNumber=100&month=2&year=2019"
  def getIndividualStudentAttendanceReport(%Plug.Conn{ query_params: query_params } = conn, %{ "group_id" => group_id, "team_id" => team_id, "user_id" => user_id } ) do
    group = GroupRepo.get(group_id)
    # loginUser = Guardian.Plug.current_resource(conn)
    month = query_params["month"]
    year = query_params["year"]
    rollNumber = query_params["rollNumber"]
    #check login user can post in group
    ###{:ok, userCanPost} = GroupPostRepo.checkLoginUserCanPostInGroup(group["_id"], loginUser["_id"])
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #get Attendance list
    individualAttendanceList = TeamHandler.getIndividualStudentAttendanceReport(conn, group_id, team_id, user_id, rollNumber, month, year)
    render(conn, "attendanceReportIndividual.json", [ attendance: individualAttendanceList ] )
  end



  #add holidays or events in calendar by admin
  #post "/groups/:group_id/school/calendar/add?day=12&month=3&year=2019"
  def schoolCalendarAdd(%Plug.Conn{ params: params } = conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    day = conn.query_params["day"]
    month = conn.query_params["month"]
    year = conn.query_params["year"]
    #if group["category"] != "school" && group["category"] != "corporate" || is_nil(day) || is_nil(month) || is_nil(year) do
    #  conn
    #  |>put_status(404)
    #  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    #end
    if is_nil(day) || is_nil(month) || is_nil(year) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    changeset = Post.changeset_calendar_add(%Post{}, params)
    if changeset.valid? do
      case GroupPostHandler.addToSchoolCalendar(conn, group["_id"], changeset.changes, String.to_integer(day), String.to_integer(month), String.to_integer(year)) do
        {:ok, _created}->
          #add gallery event
          GroupHandler.addGroupCalendarEvent(group["_id"])
          #add notification
          NotificationHandler.schoolCalendarAddNotification(conn, group["_id"], String.to_integer(day), String.to_integer(month), String.to_integer(year))
          conn
          |> put_status(201)
          |> json(%{})
        {:changeset_error, message}->
          conn
          |>put_status(400)
          |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: message})
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


  #get calendar events list
  #get "/groups/:group_id/school/calendar/get?month=3&year=2019"
  def getSchoolCalendar(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    month = conn.query_params["month"]
    year = conn.query_params["year"]
    if is_nil(month) || is_nil(year) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getCalendarList = GroupPostHandler.getSchoolCalendar(group["_id"], String.to_integer(month), String.to_integer(year))
    render(conn, "school_calendar.json", [ calendarList: getCalendarList ] )
  end



  #get event/holiday for the particular selected date
  #get "/groups/:group_id/school/callendar/event/get?day=13&month=3&year=2019"
  def getSchoolCalendarEvent(conn, %{ "group_id" => group_id }) do
    group = GroupRepo.get(group_id)
    day = conn.query_params["day"]
    month = conn.query_params["month"]
    year = conn.query_params["year"]
    if is_nil(day) || is_nil(month) || is_nil(year) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getCalendarEventList = GroupPostHandler.getSchoolCalendarEvent(group["_id"], String.to_integer(day), String.to_integer(month), String.to_integer(year))
    render(conn, "school_calendar_event.json", [ conn: conn, group: group, calendarEventList: getCalendarEventList ] )
  end



  #remove event/holiday from calendar
  #delete "/groups/:group_id/event/:event_id/delete"
  def removeEventFromSchoolCalendar(conn, %{ "group_id" => group_id, "event_id" => event_id }) do
    group = GroupRepo.get(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    #check this event created by login User
    {:ok, checkCount} = GroupPostRepo.checkEventCreatedByLoginUser(loginUser["_id"], group["_id"], decode_object_id(event_id))
    #if group["category"] != "school" && group["category"] != "corporate" do
    #  conn
    #  |>put_status(404)
    #  |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    #end
    if checkCount == 0 do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    case GroupPostHandler.removeEventFromSchoolCalendar(group["_id"], decode_object_id(event_id)) do
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


  #add token for the classes/teams where video class is required
  #post "/groups/:group_id/team/:team_id/jitsi/token/add"
  def addJitsiLiveClassToken(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    team = TeamRepo.get(team_id)
    if group["category"] == "school" do
      case GroupPostHandler.addLiveClassTokenToClass(group, team) do
        {:ok, _}->
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
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end


  defp addStaffToSchool(conn, changeset, group) do
    if changeset.valid? do
      #add staff to school without any team
      addedStaffId = TeamHandler.addStaffToSchoolManually(changeset.changes, group)
      #add staff to staff database
      case AdminHandler.addStaffToDatabase(conn, addedStaffId, group) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:staffError, message}->
          conn
          |> put_status(400)
          |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
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



  defp addStudentToTeam(conn, changeset, group, team_id) do
    if changeset.valid? do
      #first add user to team
      addedStudentId = TeamHandler.addStudentsToTeamManually(changeset.changes, group, team_id)
      #add student to student database
      case AdminHandler.addStudentToDatabase(conn, addedStudentId, group, team_id) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:changesetError, changeset}->
          conn
          |> put_status(400)
          |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
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



  defp addStudentToTeamBus(conn, changeset, group, team_id) do
    if changeset.valid? do
      #add student to bus team
      case TeamHandler.addStudentsToBusTeamManually(changeset.changes, group, team_id) do
        {:ok, _}->
          conn
          |> put_status(200)
          |> json(%{})
        {:changesetError, changeset}->
          conn
          |> put_status(400)
          |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
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



  #get student fee list, class wise fee details (Paid/pending report)
  #get "/groups/:group_id/team/:team_id/student/fee/get"
  def getStudentFeeListForClass(conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    getStudentsFeeDetails = TeamPostHandler.getStudentsFeeDetails(group["_id"], team_id)
    render(conn, "get_student_fees_details.json", [getStudentsFeeDetails: getStudentsFeeDetails])
  end



  #get not approved/hold fees list for admin/fee management staff ##From TeamPostController
  #get "groups/:group_id/fee/status/list"?status=approved/notApproved/onHold &teamId=team_id (if they want list team wise)
  def getFeeStatusList(%Plug.Conn{query_params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    #check query_param exist
    if params["status"] do
      getStudentFeeStatusDetails = if params["teamId"] do
        #get student fees status based on teamId
        TeamPostHandler.getStudentFeeStatusListBasedOnTeam(group["_id"], params["teamId"], params["status"])
      else
        #get student fee list based on the status
        TeamPostHandler.getStudentFeeStatusList(group["_id"], params["status"])
      end
      render(conn, "get_student_fees_status_details.json", [getStudentFeeStatusDetails: getStudentFeeStatusDetails])
    else
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
  end






end
