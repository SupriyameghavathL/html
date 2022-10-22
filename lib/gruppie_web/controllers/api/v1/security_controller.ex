defmodule GruppieWeb.Api.V1.SecurityController do
  use GruppieWeb, :controller
  # alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Handler.SecurityHandler
  alias GruppieWeb.User
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Repo.UserRepo
  # alias GruppieWeb.Repo.GroupMembershipRepo
  alias GruppieWeb.Structs.JsonErrorResponse
  alias GruppieWeb.ChangePassword


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
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
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
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
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
      |> render(GruppieWeb.SecurityView, "error.json", [ error: changeset.errors, status: 400 ])
    end
  end



  #create password for category app
  #put "/create/password/category/app?category="
  def createPasswordCategoryApp(conn, params) do
    if conn.query_params["category"] do
      #create password to category types app
      createPasswordForCategoryApp(conn, params)
    else
      if conn.query_params["constituencyName"] do
        #create password to constituency app
        createPasswordForConstituencyApp(conn, params)
      else
        #not found error
        conn
        |>put_status(400)
        |>json(%JsonErrorResponse{code: 400, title: "Not Found", message: "Page Not Found"})
      end
    end
  end


  #create password to category types app
  defp createPasswordForCategoryApp(conn, params) do
    parameters = %{
      "countryCode" => params["userName"]["countryCode"],
      "phone" => params["userName"]["phone"],
      "otp" => params["otp"],
      "password" => params["password"],
      "confirmPassword" => params["confirmPassword"]
    }
    category = conn.query_params["category"]
    if is_nil(category) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "User Not Found/Registered"})
    else
      changeset = ChangePassword.changeset_create_password(%ChangePassword{}, parameters)
      if changeset.valid? do
        #update password to category app
        case SecurityHandler.createPasswordCategoryApp(changeset.changes, category) do
          {:ok, updated} ->
            login_category_app(conn, params)
          {:error, message} ->
            conn
            |>put_status(400)
            |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
          {:mongo_error, error}->
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
  end


  #create password to constituency types app
  defp createPasswordForConstituencyApp(conn, params) do
    parameters = %{
      "countryCode" => params["userName"]["countryCode"],
      "phone" => params["userName"]["phone"],
      "otp" => params["otp"],
      "password" => params["password"],
      "confirmPassword" => params["confirmPassword"]
    }
    constituencyName = conn.query_params["constituencyName"]
    if is_nil(constituencyName) do
      conn
      |>put_status(404)
      |>json(%JsonErrorResponse{code: 404, title: "Not Found", message: "User Not Found/Registered"})
    end
    changeset = ChangePassword.changeset_create_password(%ChangePassword{}, parameters)
    if changeset.valid? do
      #update password to category app
      case SecurityHandler.createPasswordConstituencyApp(changeset.changes, constituencyName) do
        {:ok, updated} ->
          login_category_app(conn, params)
        {:error, message} ->
          conn
          |>put_status(400)
          |>json(%JsonErrorResponse{code: 400, title: "Bad Request", message: message})
        {:mongo_error, error}->
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


  #post "/login/category/app"?category=school # &appName=RPES/{"appNames" to provide institutional app all in one}
  def login_category_app(conn, params) when is_map(params) do
    if conn.query_params["constituencyName"] do
      #login to constituency app
      loginToConstituencyApp(conn, params)
    else
      category = conn.query_params["category"]
      appName = conn.query_params["appName"]
      #text conn, params
      case validate_params(params, conn) do
        true->
          case SecurityRepo.login_category_app(params, category) do
            {:ok, result}->
              #save device token and device type for user
              if params["deviceToken"] do
                #SecurityHandler.saveDeviceTokenCategoryApp(device_params, result["userId"], category)
                SecurityHandler.saveDeviceTokenCategoryApp(params, result["userId"], category)
              end
              #remove authorizedToAdmin event for login user
              GroupRepo.removeAuthorizedToAdminEventForLoginUser(result["userId"])
              jwt = generate_jwt_token(conn, result)
              countryTelCode = TelCodeRepo.countryTelCode(params["userName"]["countryCode"])
              token_map = %{
                "userId" => BSON.ObjectId.encode!(result["userId"]),
                "token" => jwt["jwt"],
                "countryAlpha2Code" => params["userName"]["countryCode"],
                "counryTelephoneCode" => countryTelCode,
                "voterId" => result["voterId"]
              }

              id_deleted_map = Map.delete(result, "_id")
              merged_map = Map.merge(id_deleted_map, token_map)
              delete_pwd_map = Map.delete(merged_map, "password")
              #get total number of groups for user with this category
              case SecurityHandler.getCategoryGroupsCountForUser(result["userId"], category, appName) do
                {:ok, map}->
                  #return map
                  json conn, Map.merge(delete_pwd_map, map)
                {:error, message}->
                  conn
                  |>put_status(403)
                  |>json(%JsonErrorResponse{ code: 403, title: "Forbidden", message: message })
              end
            {:error, _error}->
              conn
              |>put_status(400)
              |>json(%JsonErrorResponse{ code: 400, title: "Invalid Data", message: "Invalid UserName" })
            {:not_found, _error}->
              conn
              |>put_status(401)
              |>json(%JsonErrorResponse{ code: 401, title: "Invalid Credentials", message: "Invalid UserName Or Password" })
          end
        false->
          conn
          |>put_status(401)
          |>json(%JsonErrorResponse{ code: 401, title: "Invalid Credentials", message: "Enter Username And Password" })
      end
    end
  end


  #login to constituency app
  defp loginToConstituencyApp(conn, params) do
    constituencyName = conn.query_params["constituencyName"]
    case validate_params(params, conn) do
      true ->
        case SecurityRepo.login_constituency_app(params, constituencyName) do
          {:ok, result}->
            #save device token and device type for user
            if params["deviceToken"] do
              #SecurityHandler.saveDeviceTokenCategoryApp(device_params, result["userId"], category)
              SecurityHandler.saveDeviceTokenConstituencyApp(params, result["userId"], constituencyName)
            end
            #remove authorizedToAdmin event for login user
            GroupRepo.removeAuthorizedToAdminEventForLoginUser(result["userId"])
            jwt = generate_jwt_token(conn, result)
            countryTelCode = TelCodeRepo.countryTelCode(params["userName"]["countryCode"])
            token_map = %{
              "userId" => BSON.ObjectId.encode!(result["userId"]),
              "token" => jwt["jwt"],
              "countryAlpha2Code" => params["userName"]["countryCode"],
              "counryTelephoneCode" => countryTelCode,
              "voterId" => result["voterId"]
            }
            id_deleted_map = Map.delete(result, "_id")
            merged_map = Map.merge(id_deleted_map, token_map)
            delete_pwd_map = Map.delete(merged_map, "password")
            #get total number of groups for user with this category
            case SecurityHandler.getConstituencyGroupsCountForUser(result["userId"], constituencyName) do
              {:ok, map}->
                #return map
                json conn, Map.merge(delete_pwd_map, map)
              {:error, message}->
                conn
                |>put_status(403)
                |>json(%JsonErrorResponse{ code: 403, title: "Forbidden", message: message })
            end
          {:error, _error}->
            conn
            |>put_status(400)
            |>json(%JsonErrorResponse{ code: 400, title: "Invalid Data", message: "Invalid UserName" })
          {:not_found, _error}->
            conn
            |>put_status(401)
            |>json(%JsonErrorResponse{ code: 401, title: "Invalid Credentials", message: "Invalid UserName Or Password" })
        end
      false ->
        conn
        |>put_status(401)
        |>json(%JsonErrorResponse{ code: 401, title: "Invalid Credentials", message: "Enter Username And Password" })
    end
  end


   #generate jwt token for login and change password
   defp generate_jwt_token(conn, result) do
    new_conn = Guardian.Plug.api_sign_in(conn, result)
    jwt = Guardian.Plug.current_token(new_conn)
    {:ok, claims } = Guardian.Plug.claims(new_conn)
    exp  = Map.get(claims, "exp")
    jwt = %{
      "jwt" => jwt,
      "exp" => exp
    }
  end
end
