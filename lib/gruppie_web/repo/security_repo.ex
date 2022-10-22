defmodule GruppieWeb.Repo.SecurityRepo do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.UserCategoryApp

  @conn :mongo

  @user_col "users"

  @user_individual_col "user_individual_apps"

  @user_category_app_col "user_category_apps"

  @view_group_team_members_col "VW_GROUP_TEAM_MEMBERS"

  @notification_token_col "notification_tokens"


  def findUserExistByPhoneNumber(phone) do
    filter = %{ "phone" => phone }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_col, filter, [projection: project])
  end



  def find_user_exists_individual_app(changeset, appId) do
    filter = %{ "phone" => changeset.phone, "appId" => decode_object_id(appId) }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_individual_col, filter, [projection: project])
  end



  def findUserRegisteredToCategoryApp(conn, changeset) do
    filter = %{ "phone" =>  changeset.phone, "category" => conn.query_params["category"] }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end

  def findUserRegisteredToConstituencyApp(conn, changeset) do
    filter = %{ "phone" =>  changeset.phone, "constituencyName" => conn.query_params["constituencyName"] }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def getCategoryGroupsCountForUser(userObjectId, category) do
    filter = %{
      "userId" => userObjectId,
      "groupDetails.category" => category,
      "groupDetails.isActive" => true,
      "isActive" => true
    }
    projection = %{ "_id" => 0, "groupId" => 1, "groupDetails.category" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => projection }]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_col, pipeline))
  end


  def register(changeset) do
    generatedPassword = hash_password()
    hashed_password = generatedPassword.password #accessing field from map
    otp = generatedPassword.otp
    changeset = Map.put_new(changeset, :password_hash, hashed_password) #hash_password[private function]
    case Mongo.insert_one(@conn, @user_col, changeset) do
      {:ok, _ok} ->
        {:ok, otp}
      {:mongo_error, _err} ->
        {:mongo_error, "Something went wrong"}
    end
  end



  def register_user_category_app(conn, changeset, user) do
    generatedPassword = hash_password()
    # hashed_password = generatedPassword.password
    otp = generatedPassword.otp
    user_doc = UserCategoryApp.register_category(conn, changeset, user["_id"], otp)
    case Mongo.insert_one(@conn, @user_category_app_col, user_doc) do
      {:ok, _ok}->
        {:ok, otp}
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end



  def register_user_constituency_app(conn, changeset, user) do
    generatedPassword = hash_password()
    # hashed_password = generatedPassword.password
    otp = generatedPassword.otp
    user_doc = UserCategoryApp.register_constituency_app(conn, changeset, user["_id"], otp)
    case Mongo.insert_one(@conn, @user_category_app_col, user_doc) do
      {:ok, _ok}->
        {:ok, otp}
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end


  def upate_user_profile_while_register(updadteChangesetDoc, user) do
    filter = %{
      "_id" => user["_id"]
    }
    update = %{"$set" => updadteChangesetDoc}
    Mongo.update_one(@conn, @user_col, filter, update)
  end


  def verifyOtpCategoryApp(changeset, category) do
    filter = %{
      "phone" => changeset.phone,
      "category" => category,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end


  def verifyOtpConstituencyApp(changeset, constituencyName) do
    filter = %{
      "phone" => changeset.phone,
      "constituencyName" => constituencyName,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
  end



  def createPasswordCategoryApp(changeset, category) do
    filter = %{
      "phone" => changeset.phone,
      "category" => category,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    {:ok, count} = Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
    if count > 0 do
      new_password_hash = Bcrypt.hash_pwd_salt(changeset.password)
      update_doc = %{ "$set" => %{ "password_hash_individual" => new_password_hash, "user_secret_otp" => changeset.password }  }
      Mongo.update_one(@conn, @user_category_app_col, filter, update_doc)
    else
      {:error, "Invalid OTP"}
    end
  end

  def createPasswordConstituencyApp(changeset, constituencyName) do
    filter = %{
      "phone" => changeset.phone,
      "constituencyName" => constituencyName,
      "otp_verify_individual" => changeset.otp
    }
    project = %{"_id" => 1}
    {:ok, count} = Mongo.count(@conn, @user_category_app_col, filter, [projection: project])
    if count > 0 do
      new_password_hash = Bcrypt.hash_pwd_salt(changeset.password)
      update_doc = %{ "$set" => %{ "password_hash_individual" => new_password_hash, "user_secret_otp" => changeset.password }  }
      Mongo.update_one(@conn, @user_category_app_col, filter, update_doc)
    else
      {:error, "Invalid OTP"}
    end
  end


  def login_category_app(params, category) do
    userCountry = params["userName"]["countryCode"]
    userPhone = params["userName"]["phone"]
    password = params["password"]
    case ExPhoneNumber.parse(userPhone, userCountry) do
      {:ok, phone_number}->
      #  if ExPhoneNumber.is_valid_number?(phone_number) do
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          filter = %{ phone: e164_number, category: category }
          user_cursor = Mongo.find(@conn, @user_category_app_col, filter, [ limit: 1 ])
          list = Enum.to_list(user_cursor)
          if length(list) == 1 do
            #user detail returns user_individual_apps model details
            userDetail = hd(list)
            user_password = userDetail["password_hash_individual"]
            #get user details from user model
            user = hd(Gruppie.Repo.UserRepo.find_user_by_phone(e164_number))
            ##IO.puts "#{userDetail}"
            if Bcrypt.verify_pass(password, user_password) do
              final_result_map = %{
                  "_id" => userDetail["_id"],
                  "name" => user["name"],
                  "phone" => userDetail["phone"],
                  "password" => userDetail["password_hash_individual"],
                  "image" => user["image"],
                  "userId" => user["_id"],
                  "voterId" => user["voterId"]
                }
              if userDetail["role"] do
                final_result_map = Map.put_new(final_result_map, "role", userDetail["role"])
              end
              {:ok, final_result_map}
            else
              {:not_found, "Invalid Credentials"}
            end
          else
            {:not_found, "Invalid Credentials"}
          end
      {:error, error}->
        {:error, error}
    end
  end


  def checkAlreadyAddedWithSameDeviceCategoryApp(map, userId, category) do
    filter = %{
      "userId" => userId,
      "category" => category,
      "deviceToken" => map["deviceToken"],
      "deviceType" => map["deviceType"]
    }
    if !is_nil(map["appVersion"]) do
      filter = Map.put_new(filter, "appVersion", map["appVersion"])
    end
    if !is_nil(map["osVersion"]) do
      filter = Map.put_new(filter, "osVersion", map["osVersion"])
    end
    if !is_nil(map["deviceModel"]) do
      filter = Map.put_new(filter, "deviceModel", map["deviceModel"])
    end
    project = %{"_id" => 1}
    Mongo.count(@conn, @notification_token_col, filter, [projection: project])
  end

end
