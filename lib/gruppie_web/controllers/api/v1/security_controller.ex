defmodule GruppieWeb.Api.V1.SecurityController do
  use GruppieWeb, :controller
  # alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Handler.SecurityHandler
  alias GruppieWeb.User
  # alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Repo.UserRepo
  # alias GruppieWeb.Repo.GroupMembershipRepo
  alias GruppieWeb.Structs.JsonErrorResponse


  #to check whether user exist in gruppie or not
  #post "/user/exist"
  def userExist(conn, params) do
    changeset = User.changeset_user_exist(%User{}, params)
    if changeset.valid? do
      {:ok, result} = SecurityHandler.findUserExistByPhoneNumber(changeset.changes)
      data = if result > 0 do
        %{
          "countryCode" => params["countryCode"],
          "phone" => params["phone"],
          "isUserExist" => true,
        }
      else
        %{
          "countryCode" => params["countryCode"],
          "phone" => params["phone"],
          "isUserExist" => false,
        }
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(Gruppie.Api.V1.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #to check whether user exist in school app or not
  #post "/user/exist/category/app?category=school/constituency" OR constituencyName=Namma Gundlupet
  def userExistCategoryApp(conn, params) do
    if conn.query_params["category"] do
      #check user exist for category app
      checkUserExistInCategoryApp(conn, params)
    else
      if conn.query_params["constituencyName"] do
        #check user exit for constituency app
        checkUserExistInConstituencyApp(conn, params)
      else
        #not found error
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #check user exist for category app
  #post "/user/exist/category/app?category=school/constituency"
  defp checkUserExistInCategoryApp(conn, params) do
    category = conn.query_params["category"]
    changeset = User.changeset_user_exist(%User{}, params)
    if changeset.valid? do
      #check user registered to school app
      {:ok, userRegistered} = SecurityRepo.findUserRegisteredToCategoryApp(conn, changeset.changes)
      data =  if userRegistered > 0 do
        #user already registered to school app
        #allowedToAccessApp = true
        %{
          "countryCode" => conn.params["countryCode"],
          "phone" => conn.params["phone"],
          "isUserExist" => true,
          "isAllowedToAccessApp" => true,
          #digitalocea access keys
          "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
          "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
        }
      else
        #not exist in any school app.
        #Find user exist in user table (get user by phone)
        getUser = UserRepo.find_user_by_phone(changeset.changes.phone)
        if length(getUser) > 0 do
          #user exist in user collection. So, check user is in any school category group
          getSchoolCategoryAppCount = SecurityRepo.getCategoryGroupsCountForUser(hd(getUser)["_id"], category)
          if length(getSchoolCategoryAppCount) > 0 do
            #user is in school category app
            #allowedToAccessApp = true
            %{
              "countryCode" => conn.params["countryCode"],
              "phone" => conn.params["phone"],
              "isUserExist" => false,
              "isAllowedToAccessApp" => true,
              #digitalocea access keys
              "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
              "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
            }
          else
            #user not in any school category app so don't provide access
            #allowedToAccessApp = false
            %{
              "countryCode" => conn.params["countryCode"],
              "phone" => conn.params["phone"],
              "isUserExist" => false,
              "isAllowedToAccessApp" => false,
              #digitalocea access keys
              "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
              "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
            }
          end
        else
          #user not exist. so, don't allow access to app
          #allowedToAccessApp = false
          %{
            "countryCode" => conn.params["countryCode"],
            "phone" => conn.params["phone"],
            "isUserExist" => false,
            "isAllowedToAccessApp" => false,
            #digitalocea access keys
            "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
            "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
          }
        end
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #check user exit for constituency app
  #post "/user/exist/category/app?constituencyName=Namma Gundlupet"
  defp checkUserExistInConstituencyApp(conn, params) do
    # constituencyName = conn.query_params["constituencyName"]
    changeset = User.changeset_user_exist(%User{}, params)
    if changeset.valid? do
      #check user registered to school app
      {:ok, userRegistered} = SecurityRepo.findUserRegisteredToConstituencyApp(conn, changeset.changes)
      data = if userRegistered > 0 do
        #user already registered to constituency app
        #allowedToAccessApp = true
        %{
          "countryCode" => conn.params["countryCode"],
          "phone" => conn.params["phone"],
          "isUserExist" => true,
          "isAllowedToAccessApp" => true,
          #digitalocea access keys
          "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
          "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
        }
      else
        #not exist in any constituency app.
        #allowedToAccessApp = false
         %{
          "countryCode" => conn.params["countryCode"],
          "phone" => conn.params["phone"],
          "isUserExist" => false,
          "isAllowedToAccessApp" => true,
          #digitalocea access keys
          "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
          "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
        }
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #user register to gruppie app
  #post "/register"
  def register(conn, params) do
    changeset = User.changeset_user_register(%User{}, params)
    if changeset.valid? do
      case SecurityHandler.register(changeset.changes) do
        {:ok, _otp}->
          #if params["countryCode"] == "IN" do
          #  SmsHandler.register(changeset.changes, otp)
          #else
          #  text conn, "send email"
          #end
          conn
          |> put_status(201)
          |> json(%{})
        {:mongo_error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #register to category or constituwcy app
  #post "/register/category/app"?category=school,  OR constituencyName=Namma Gundlupet
  def registerIndividualCategory(conn, params) do
    if conn.query_params["category"] do
      #register to category types app
      registerToCategoryApp(conn, params)
    else
      if conn.query_params["constituencyName"] do
        #register to constituency app
        registerToConstituencyApp(conn, params)
      else
        #not found error
        conn
        |>put_status(404)
        |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "User Not Found/Registered"})
      end
    end
  end

  #register to category types app
  #post "/register/category/app"?category=school"
  defp registerToCategoryApp(conn, params) do
    # category = conn.query_params["category"]
    changeset = User.changeset_user_register_individual(%User{}, params)
    if changeset.valid? do
      #check user registered to user school app collection
      case SecurityHandler.registerCategoryApp(conn, changeset.changes) do
        {:ok, _otp} ->
          if params["countryCode"] == "IN" do
            #SmsHandler.register(changeset.changes, otp)
            conn
            |> put_status(201)
            |> json(%{})
          else
            text conn, "send email"
          end
        {:new_user, _} ->
          #calling above register function for new users
          register(conn, params)
          registerIndividualCategory(conn, params)
        {:user_already_error, _message}->
          conn
          |>put_status(400)
          |>json(%JsonErrorResponse{ code: 400, title: "Duplicate User", message: "User Already Registered" })
        {:mongo_error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


  #post "/register/category/app"?constituencyName=Namma Gundlupet"
  defp registerToConstituencyApp(conn, params) do
    # constituencyName = conn.query_params["constituencyName"]
    changeset = User.changeset_user_register_individual(%User{}, params)
    if changeset.valid? do
      #check user ristered to user school app collection
      case SecurityHandler.registerUserToConstituencyApp(conn, changeset.changes) do
        {:ok, _otp}->
          if params["countryCode"] == "IN" do
            #SmsHandler.register(changeset.changes, otp)
            conn
            |> put_status(201)
            |> json(%{})
          else
            text conn, "send email"
          end
        {:new_user, _}->
          #calling above register function for new users
          register(conn, params)
          registerIndividualCategory(conn, params)
        {:user_already_error, _message}->
          conn
          |>put_status(400)
          |>json(%JsonErrorResponse{ code: 400, title: "Duplicate User", message: "User Already Registered" })
        {:mongo_error, _error}->
          conn
          |>put_status(500)
          |>json(%JsonErrorResponse{code: 500, title: "DB Error", message: "Something went wrong"})
      end
    else
      conn
      |> put_status(400)
      |> render(Gruppie.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end


   #verify otp
  #post "/verify/otp/category/app?category=school" OR constituencyName=Namma Gundlupet
  def verifyOtpCategoryApp(conn, params) do
    if conn.query_params["category"] do
      #verify otp to category types app
      verifyOtpForCategoryApp(conn, params)
    else
      if conn.query_params["constituencyName"] do
        #verify otp to constituency app
        verifyOtpForConstituencyApp(conn, params)
      else
        #not found error
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #verify otp to category types app
  #post "/verify/otp/category/app?category=school"
  defp verifyOtpForCategoryApp(conn, params) do
    category = conn.query_params["category"]
    changeset = User.changeset_verify_otp_individual(%User{}, params)
    if changeset.valid? do
      #check entered otp is right
      {:ok, count} = SecurityRepo.verifyOtpCategoryApp(changeset.changes, category)
      data = if count > 0 do
        #otp is correct
        %{"otpVerified" => true}
      else
        #wrong otp
        %{"otpVerified" => false}
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(Gruppie.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #verify otp to constituency app
  #post "/verify/otp/category/app?constituencyName=Namma Gundlupet"
  defp verifyOtpForConstituencyApp(conn, params) do
    constituencyName = conn.query_params["constituencyName"]
    changeset = User.changeset_verify_otp_individual(%User{}, params)
    if changeset.valid? do
      #check entered otp is right
      {:ok, count} = SecurityRepo.verifyOtpConstituencyApp(changeset.changes, constituencyName)
      data = if count > 0 do
        #otp is correct
        %{"otpVerified" => true}
      else
        #wrong otp
       %{"otpVerified" => false}
      end
      json conn, %{ data: data }
    else
      conn
      |> put_status(400)
      |> render(Gruppie.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end





end
