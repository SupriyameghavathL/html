defmodule GruppieWeb.Api.V1.SchoolCollegeRegisterController do
  use GruppieWeb, :controller
  alias GruppieWeb.Handler.SchoolCollegeRegisterHandler
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.SchoolCollege



  #post "/add/board/to/db"
  def addBoardToDb(conn, params) do
    case SchoolCollegeRegisterHandler.addBoardToDb(params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #get "/get/board/db"
  def getboards(conn, params) do
   boardList = SchoolCollegeRegisterHandler.getboards(conn, params)
   render(conn, "getBoard.json", [getBoardList: boardList])
  end


  # post "/add/university/to/db"
  def addUniversity(conn, params) do
    case SchoolCollegeRegisterHandler.addUniversity(params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  # get "/get/universty/from/db"
  def getUniversity(conn, params) do
    universityList = SchoolCollegeRegisterHandler.getUniversity(conn, params)
    render(conn, "getUniversity.json", [getUniversityList: universityList])
  end


  # post "/add/medium/to/db"
  def addMedium(conn, params) do
    case SchoolCollegeRegisterHandler.addMedium(params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  # post "/add/medium/to/db/new"
  def addMediumNew(conn, params) do
    case SchoolCollegeRegisterHandler.addMediumNew(params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #get "/get/medium/from/db"
  def getMedium(conn, params) do
    mediumList = SchoolCollegeRegisterHandler.getMedium(conn,params)
    render(conn, "getMedium.json", [getMediumList: mediumList])
  end


  # post "/add/board/class/to/db"
  def addBoardClassToDb(conn, params) do
    case SchoolCollegeRegisterHandler.addBoardClassToDb(params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  # post "/add/type/of/campus"
  def addTypeOfCampus(conn, params) do
    case SchoolCollegeRegisterHandler.addTypeOfCampus(conn, params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  def getTypeOfCampus(conn, params) do
    campusList = SchoolCollegeRegisterHandler.getTypeOfCampus(conn, params)
    render(conn, "getCampus.json", [getCampusList: campusList])
  end


  #get "/get/board/class/list/school"
  def getSchoolClassList(conn, params) do
    classList = SchoolCollegeRegisterHandler.getSchoolClassList(params["subCategory"], params["board"])
    render(conn, "getClassList.json", [getClassList: classList])
  end


  # post "user/:user_id/new/register"
  def createGroupTeams(%Plug.Conn{params: params} = conn, %{ "user_id" => _user_id }) do
    changeset = SchoolCollege.school_college_register(%SchoolCollege{}, params)
    loginUserId = Guardian.Plug.current_resource(conn)
    if changeset.valid? do
      case SchoolCollegeRegisterHandler.createGroup(changeset.changes, params, loginUserId["name"]) do
        {:ok, _success} ->
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


  #  get "/groups/:group_id/get/created/class/list"
  def getCreatedClassList(conn, params) do
    classList = SchoolCollegeRegisterHandler.getCreatedClassList(conn, params["group_id"])
    |> Enum.to_list()
    render(conn, "getCreatedClassList.json", [getCreatedClassList: classList])
  end



  #post "/groups/:group_id/add/classes"
  def addClassToSchool(%Plug.Conn{params: params} = conn, %{ "group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    end
    loginUserId = Guardian.Plug.current_resource(conn)
    case SchoolCollegeRegisterHandler.getTeamDetails(group["_id"], loginUserId["_id"], params) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #put "/groups/:group_id/delete/class"
  def deleteClassCreated(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    end
    case  SchoolCollegeRegisterHandler.deleteClassCreated(group["_id"], params["className"]) do
      {:ok, _success} ->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _error}->
        conn
        |>put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
    end
  end


  #post "/groups/:group_id/class/add/extra"
  def createExtraClass(%Plug.Conn{ body_params: team_params } = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    end
    changeset = SchoolCollege.changeset(%SchoolCollege{}, team_params)
    if changeset.valid? do
      changesetChange = Map.put_new(changeset.changes, :category, group["category"])
      case SchoolCollegeRegisterHandler.createTeam(conn, changesetChange, group_id) do
        {:ok, _success} ->
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


  #get  "/groups/:group_id/get/class/list"
  def getClassListWithSections(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    end
   classListToAddClass = SchoolCollegeRegisterHandler.getClassListWithSections(group["_id"], group["affiliatedBoard"], group["subCategory"])
   render(conn, "getClassListToCreate.json", [getClassListToCreate: classListToAddClass])
  end

  #get "/groups/:group_id/trail/period"
  def getTrailPeriodRemainingDays(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |> put_status(404)
      |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    end
    getTrailPeriodRemainingDays = SchoolCollegeRegisterHandler.getTrailPeriodRemainingDays(group["trialEndPeriod"])
    render(conn, "getRemainingDays.json", [getRemainingDays: getTrailPeriodRemainingDays])
  end
end
