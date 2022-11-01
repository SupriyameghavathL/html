defmodule GruppieWeb.Api.V1.SchoolFeeController do
  use GruppieWeb, :controller
  alias GruppieWeb.Structs.JsonErrorResponse
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.SchoolFees
  alias GruppieWeb.Handler.SchoolFeeHandler

  plug GruppieWeb.Plugs.GroupAccessAuth, %{ "group_id" => "group_id", "user_id" => "login_user_id" }


  #get "/groups/:group_id/class/get/fee"
  def getClassFees(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
     conn
     |> put_status(404)
     |> json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page not found"})
    else
      loginUserId = Guardian.Plug.current_resource(conn)
      accountantUserId = if Map.has_key?(group, "accountantIds") do
          Enum.find(group["accountantIds"], fn map ->
          map["userId"] ==  loginUserId["_id"]
        end)
      end
      canPostTrue = SchoolFeeHandler.canPostTrue(group["_id"], loginUserId["_id"])
      classList = cond do
        group["adminId"] == loginUserId["_id"] || accountantUserId["userId"] == loginUserId["_id"] || canPostTrue["userId"] == loginUserId["_id"]  ->
          SchoolFeeHandler.getClassFees(group["_id"])
        true ->
          SchoolFeeHandler.getClassFeesStudent(group["_id"], loginUserId["_id"])
      end
      render(conn, "getFeeClassList.json", [getClassFeesList: classList])
    end
  end

  #post "/groups/:group_id/team/:team_id/student/:user_id/fee/paid"
  def addFeePaidDetailsByStudent(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    end
    loginUserId = Guardian.Plug.current_resource(conn)
    userObjectId = decode_object_id(user_id)
    accountantUserId = if Map.has_key?(group, "accountantIds") do
      Enum.find(group["accountantIds"], fn map ->
      map["userId"] ==  loginUserId["_id"]
      end)
    end
    cond do
      #pay by accountant or admin
      group["adminId"] == loginUserId["_id"] || accountantUserId["userId"] == loginUserId["_id"]  ->
      #pay fee changeset
      changeset = SchoolFees.changeset_student_fee_paid(%SchoolFees{}, params)
      if changeset.valid? do
        case SchoolFeeHandler.addFeePaidDetailsByAccountant(changeset.changes, group["_id"], team_id, loginUserId["_id"], userObjectId, params, loginUserId["name"]) do
          {:ok, _success}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
          {:invalidCheque, error} ->
            conn
            |> put_status(400)
            |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: error})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
      #pay by student/parent
      loginUserId["_id"] == userObjectId ->
      #pay fee changeset
      changeset = SchoolFees.changeset_student_fee_paid(%SchoolFees{}, params)
      if changeset.valid? do
        case SchoolFeeHandler.addFeePaidDetailsByStudent(changeset.changes, group["_id"], team_id, loginUserId["_id"], params) do
          {:ok, _success}->
            conn
            |> put_status(201)
            |> json(%{})
          {:error, _error}->
            conn
            |> put_status(500)
            |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
          {:invalidCheque, error} ->
            conn
            |> put_status(400)
            |> json(%JsonErrorResponse{code: 400, title: "Bad Request", message: error})
        end
      else
        conn
        |> put_status(400)
        |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
      end
    end
  end


  #get "/groups/:group_id/team/:team_id/student/:user_id/fee/due/fine"
  def addFeeFinesToStudent(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      userObjectId = decode_object_id(user_id)
      if params["date"] do
        reverseDateArray = String.split(params["date"], "-")
        reverseDate = Enum.at(reverseDateArray, 2)<>"-"<>Enum.at(reverseDateArray, 1)<>"-"<>Enum.at(reverseDateArray, 0)
        fineAmount = SchoolFeeHandler.addFeeFinesToStudent(group["_id"], teamObjectId, userObjectId, reverseDate)
        render(conn, "getFineAmountUser.json", [getFineAmount: fineAmount])
      end
    end
  end


  #get "/groups/:group_id/total/fee/amount"
  def getTotalFeeOfSchool(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      getTotalFeeAndPaidAmount = if params["teamId"] do
        teamObjectId = decode_object_id(params["teamId"])
        SchoolFeeHandler.getTotalFeeAmountClassWise(group["_id"], teamObjectId)
      else
        SchoolFeeHandler.getTotalFeeAmountAndPaid(group["_id"])
      end
      render(conn, "totalFeeSchool.json", [getTotalFeeSchool: getTotalFeeAndPaidAmount, params: params])
    end
  end


  #get "/groups/:group_id/team/:team_id/school/fee/report/get"
  def getInstallmentSchool(%Plug.Conn{params: _params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      feeReportList = SchoolFeeHandler.getClassStudentFee(group["_id"], teamObjectId)
      render(conn, "feeReport.json",[getFeeReportList: feeReportList, groupObjectId: group["_id"], teamObjectId: teamObjectId])
    end
  end


  #get "/groups/:group_id/class/fee/report"
  def getClassesFeeReport(conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      classFeeReportList = SchoolFeeHandler.getClassFeeReportList(group["_id"])
      render(conn, "classWiseFeeReport.json", [getClassWiseFeeReport: classFeeReportList])
    end
  end

  #get "/groups/:group_id/fee/reminder/get"?date="30-05-2022"/dueReminder=true/
  def getFeeReminderList(%Plug.Conn{params: params} = conn, %{"group_id" => group_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      cond do
        params["date"] ->
          reverseDateArray = String.split(params["date"], "-")
          reverseDate = Enum.at(reverseDateArray, 2)<>"-"<>Enum.at(reverseDateArray, 1)<>"-"<>Enum.at(reverseDateArray, 0)
          #selecting date get student list who have due
          dueStudentList = SchoolFeeHandler.getStudentsListForReminder(group["_id"], reverseDate)
          render(conn, "schoolClassInstallmentStudentDueList.json", [getInstallmentStudentDueList: dueStudentList])
        true ->
          conn
          |>put_status(404)
          |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #post "/groups/:group_id/team/:team_id/fee/reminder/add"
  def postFeeReminder(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      case SchoolFeeHandler.postFeeReminder(group["_id"], teamObjectId, params["userIds"]) do
        {:ok, _success}->
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


  #get "/groups/:group_id/team/:team_id/user/:user_id/due/get"
  def getDue(%Plug.Conn{params: params} = conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      userObjectId = decode_object_id(user_id)
      dueMap = SchoolFeeHandler.getDue(group["_id"], teamObjectId, userObjectId, params["date"])
      render(conn, "dueMap.json", [getDueMap: dueMap])
    end
  end


  #put "/groups/:group_id/team/:team_id/user/:user_id/payment/:payment_id/fee/revert"
  def feeRevert(conn, %{"group_id" => group_id, "team_id" => team_id, "user_id" => user_id, "payment_id" => payment_id}) do
    group = GroupRepo.get(group_id)
    if group["category"] != "school" do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "Page Not Found"})
    else
      teamObjectId = decode_object_id(team_id)
      userObjectId = decode_object_id(user_id)
      case SchoolFeeHandler.feeRevert(group["_id"], teamObjectId, userObjectId, payment_id) do
        {:ok, _success}->
          conn
          |> put_status(200)
          |> json(%{})
        {:error, _error}->
          conn
          |> put_status(500)
          |> json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    end
  end
end
