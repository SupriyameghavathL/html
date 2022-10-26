defmodule GruppieWeb.Api.V1.ProfileController do
  use GruppieWeb, :controller
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Handler.ProfileHandler
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.User
  alias GruppieWeb.Handler.AdminHandler
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow



  #get list of religion for caste in karnataka
  #get "/caste/religions"
  def constituencyReligionGet(conn, _) do
    religionList = UserRepo.getCasteReligionList()
    render conn, "casteReligion.json", religion: religionList
  end


  #get "/caste/get" ?religion=Hindu&casteId="" to get list of caste of religion or subcaste for selected caste
  def constituencyCasteGet(%Plug.Conn{params: params} = conn, _) do
    #get main caste names ;list
    casteList = UserRepo.getCasteList(params)
    if params["religion"] do
      #get main caste list for selected religion
      render conn, "mainCasteForReligion.json", caste: casteList
    else
      if params["casteId"] do
        #subCaste list
        render conn, "subCaste.json", caste: casteList
      else
        #get all main caste list
        render conn, "mainCaste.json", caste: casteList
      end
    end
  end


  #add profession to profile for selection
  #post "/profession/add"
  def addProfession(%Plug.Conn{params: params} = conn, _) do
    case ProfileHandler.addProfession(params["professions"]) do
      {:ok, _success}->
        conn
        |> put_status(200)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |>json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end


  #post "/education/add"
  def addEducation(conn, params) do
    case ProfileHandler.addEducation(params["educationList"]) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end


  #post "/constituency/add"
  def addConstituency(conn, params) do
    case ProfileHandler.addConstituency(params["constituencyList"]) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end

  #get "/constituency/get"
  def getConstituency(conn, _) do
    constituencyList = UserRepo.getConstituency()
    render conn, "constituency.json", constituencyList: constituencyList
  end


  #get list of professions
  #get "/profession/get"
  def getProfession(conn, _) do
    professionList = UserRepo.getProfession()
    render conn, "profession.json", professionList: professionList
  end


  #get "/education/get"
  def getEducation(conn, _) do
    educationList = UserRepo.getEducation()
    render conn, "education.json", educationList: educationList
  end

  #to add influencer list
  def addInfluencerList(conn, params) do
    case ProfileHandler.addInfluencerList(params["influencerList"]) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
    end
  end

  #get influencer list
  def getInfluencerList(conn, _) do
    influencerList = UserRepo.getInfluencerList()
    render conn, "influencer.json", influencerList: influencerList
  end

  #get "/birthday/post/add"
  def addBirthdayPost(conn, _) do
    currentTime =  bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    # time = DateTime.to_time(datetime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour
                    }
      #to get date string
      day = String.slice("0"<>""<>to_string(dateTimeMap["day"]), -2, 2)
      month = String.slice("0"<>""<>to_string(dateTimeMap["month"]), -2, 2)
      birthDayDate = day<>"-"<>month
      case ProfileHandler.getGroupId(birthDayDate) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end


  # post "/gruppie/states/add"
  def addStates(conn, params) do
    case ProfileHandler.addStates(params) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end


  #get "/gruppie/states/get"
  def getStates(conn, params)  do
    statesList = if params["country"] do
      ProfileHandler.getStates(params["country"])
    else
      ProfileHandler.getStates("INDIA")
    end
    render(conn, "statesList.json", [getStatesList: statesList])
  end


  #post "/gruppie/districts/add"
  def addDistricts(conn, params) do
    case ProfileHandler.addDistricts(params) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end


  # get "/gruppie/districts/get"
  def getDistricts(conn, params)  do
    districtsList = ProfileHandler.getDistricts(params["state"])
    render(conn, "districtsList.json", [getDistrictsList: districtsList])
  end


  # post "/gruppie/taluks/add"
  def addTaluks(conn, params) do
    case ProfileHandler.addTaluks(params) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end


  #get "/gruppie/taluks/get"
  def getTaluks(conn, params) do
    taluksList = ProfileHandler.getTaluks(params["district"])
    render(conn, "taluksList.json", [getTaluksList: taluksList])
  end


  #post "/gruppie/reminder/add"
  def addReminder(conn, params) do
    case ProfileHandler.addReminder(params) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end

  #get "/gruppie/reminder/get"
  def getReminder(conn, _params) do
    reminderList = ProfileHandler.getReminder()
    render(conn, "reminderList.json", [getreminderList: reminderList])
  end


  #"/gruppie/relatives/add"
  def addRelatives(conn, params) do
    case ProfileHandler.addRelatives(params) do
      {:ok, _success}->
        conn
        |> put_status(201)
        |> json(%{})
      {:error, _mongo_error}->
        conn
        |> put_status(500)
        |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
      end
  end

  #"/gruppie/relatives/get"
  def getRelatives(conn, _params) do
    relativesList = ProfileHandler.getRelatives()
    render(conn, "relativesList.json", [getrelativesList: relativesList])
  end


  #get post report reasons
  #"/post/report/reasons"
  def getPostReportReasons(conn, _param) do
    getPostReportReasons = UserRepo.getPostReportReasons()
    render(conn, "post_report_reasons.json", [postReportReasons: getPostReportReasons])
  end



  #user profile show
  #get "/api/v1/profile/show"
  def show(conn, _) do
    logged_in_user = Guardian.Plug.current_resource(conn)
    {:ok, country} = Phone.parse(logged_in_user["phone"])
    login_in_user = Map.to_list(logged_in_user)
    login_in_user = Enum.reduce(login_in_user, %{}, fn {k, v}, acc ->
      if k not in ["_id", "password_hash", "image", "email", "searchName" ] do
        Map.put(acc, k, Recase.to_title(v))
      else
        Map.put(acc, k, v)
      end
    end)
    # IO.puts "#{login_in_user}"
    login_in_user = login_in_user
    |> Map.put("country", String.upcase(country.country))
    render conn, "show.json", user: login_in_user
  end


  #user profile update
  #put "/api/v1/profile/edit"
  def edit(%Plug.Conn{ params: params } = conn, _) do
    #if Map.has_key?(params, "address") do
    #  if is_map(params["address"]) do
    #    address_changeset = Address.changeset(%Address{}, params["address"])
    #  else
    #    conn
    #    |> put_status(400)
    #    |> json%JsonErrorResponse{code: 400, title: "Invalid Params", message: "Invalid Address Parameters"}
    #  end
    #end
    user_changeset = User.changeset_user_update(%User{}, params)
    logged_id_user = Guardian.Plug.current_resource(conn)
    if user_changeset.valid? do
      #if Map.has_key?(params, "address") do
      #  if address_changeset.valid? do
      #    updateProfileWithAddress(user_changeset, address_changeset, logged_id_user, conn)
      #  else
      #    conn
      #    |> put_status(400)
      #    |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: address_changeset.errors, status: 400 ])
      #  end
      #end
      updateUserProfile(user_changeset, logged_id_user, conn)
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.Api.V1.SecurityView, "error.json", [ error: user_changeset.errors, status: 400 ])
    end
  end



  defp updateUserProfile(user_changeset, logged_id_user, conn) do
    case ProfileHandler.updateProfile(user_changeset, logged_id_user ) do
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


  # defp updateProfileWithAddress(user_changeset, address_changeset, logged_id_user, conn) do
  #   case ProfileHandler.updateProfileWithAddress(user_changeset, address_changeset, logged_id_user ) do
  #     {:ok, _success}->
  #       conn
  #       |> put_status(200)
  #       |> json(%{})
  #     {:error, _mongo_error}->
  #       conn
  #       |> put_status(500)
  #       |> json(%JsonErrorResponse{code: 500, title: "System Error", message: "Something went wrong we are working on it"})
  #   end
  # end


  #change mobile number
  #put "/number/change", ProfileController, :changeMobileNumber
  def changeMobileNumber(%Plug.Conn{body_params: body_params} = conn, _params) do
    changeset = User.updateStudentStaffPhoneNumber(%User{}, body_params)
    loginUser = Guardian.Plug.current_resource(conn)
    #update staff phone number in users_col
    case AdminHandler.updateStudentStaffPhoneNumber(changeset.changes, encode_object_id(loginUser["_id"])) do
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


  #api to remove user profile picture
  #put "/profile/pic/remove"
  def removeUserProfilePic(conn, _) do
    case ProfileHandler.removeUserProfilePic(conn) do
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



end
