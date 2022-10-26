defmodule GruppieWeb.Repo.SecurityRepo do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.UserCategoryApp
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @user_col "users"

  @user_individual_col "user_individual_apps"

  @user_category_app_col "user_category_apps"

  @view_group_team_members_col "VW_GROUP_TEAM_MEMBERS"

  @notification_token_col "notification_tokens"

  @group_team_members_col "group_team_members"

  @groups_col "groups"

  @teams_col "teams"


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


  def getGroupId(constituencyName) do
    filter = %{
      "constituencyName" => constituencyName,
      "category" => "constituency",
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @groups_col, filter, [projection: project])
  end


  def getGroupIdByAppName(category, appName) do
    filter = %{
      "category" => category,
      "appName" => String.trim(appName),
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @groups_col, filter, [projection: project])
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
          user = hd(GruppieWeb.Repo.UserRepo.find_user_by_phone(e164_number))
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
            final_result_map = if userDetail["role"] do
              Map.put_new(final_result_map, "role", userDetail["role"])
            else
              final_result_map
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
    filter = if !is_nil(map["appVersion"]) do
      Map.put_new(filter, "appVersion", map["appVersion"])
    else
      filter
    end
    filter = if !is_nil(map["osVersion"]) do
      Map.put_new(filter, "osVersion", map["osVersion"])
    else
      filter
    end
    filter = if !is_nil(map["deviceModel"]) do
      Map.put_new(filter, "deviceModel", map["deviceModel"])
    else
      filter
    end
    project = %{"_id" => 1}
    Mongo.count(@conn, @notification_token_col, filter, [projection: project])
  end


  def insertNotificationDeviceTokenCategoryApp(map, userId, category) do
    insertMap = %{
      "userId" => userId,
      "category" => category,
      "deviceToken" => map["deviceToken"],
      "deviceType" => map["deviceType"],
      "insertedAt" => GruppieWeb.Handler.TimeNow.bson_time(),
    }
    insertMap = if !is_nil(map["appVersion"]) do
      Map.put_new(insertMap, "appVersion", map["appVersion"])
    else
      insertMap
    end
    insertMap =  if !is_nil(map["osVersion"]) do
      Map.put_new(insertMap, "osVersion", map["osVersion"])
    else
      insertMap
    end
    insertMap = if !is_nil(map["deviceModel"]) do
      Map.put_new(insertMap, "deviceModel", map["deviceModel"])
    else
      insertMap
    end
    Mongo.insert_one(@conn, @notification_token_col, insertMap)
  end


  def getCategoryWithAppNameGroupsCountForUser(userObjectId, category, appName) do
    filter = %{
      "userId" => userObjectId,
      "groupDetails.category" => category,
      "groupDetails.appName" => appName,
      "groupDetails.isActive" => true,
      "isActive" => true
    }
    projection = %{ "_id" => 0, "groupId" => 1, "groupDetails.category" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => projection }]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_col, pipeline))
  end



  def login_constituency_app(params, constituencyName) do
    userCountry = params["userName"]["countryCode"]
    userPhone = params["userName"]["phone"]
    password = params["password"]
    case ExPhoneNumber.parse(userPhone, userCountry) do
      {:ok, phone_number}->
      #  if ExPhoneNumber.is_valid_number?(phone_number) do
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          filter = %{ phone: e164_number, constituencyName: constituencyName }
          user_cursor = Mongo.find(@conn, @user_category_app_col, filter, [ limit: 1 ])
          list = Enum.to_list(user_cursor)
          if length(list) == 1 do
            #user detail returns user_individual_apps model details
            userDetail = hd(list)
            user_password = userDetail["password_hash_individual"]
            #get user details from user model
            user = hd(GruppieWeb.Repo.UserRepo.find_user_by_phone(e164_number))
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
                final_result_map = if userDetail["role"] do
                  Map.put_new(final_result_map, "role", userDetail["role"])
                else
                  final_result_map
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


  def checkAlreadyAddedWithSameDeviceConstituencyApp(map, userId, constituencyName) do
    #IO.puts "#{map}"
    filter = %{
      "userId" => userId,
      "constituencyName" => constituencyName,
      "deviceToken" => map["deviceToken"],
      "deviceType" => map["deviceType"]
    }
    filter = if !is_nil(map["appVersion"]) do
      Map.put_new(filter, "appVersion", map["appVersion"])
    else
      filter
    end
    filter = if !is_nil(map["osVersion"]) do
      Map.put_new(filter, "osVersion", map["osVersion"])
    else
      filter
    end
    filter = if !is_nil(map["deviceModel"]) do
      Map.put_new(filter, "deviceModel", map["deviceModel"])
    else
      filter
    end
    project = %{"_id" => 1}
   # IO.puts "#{filter}"
    Mongo.count(@conn, @notification_token_col, filter, [projection: project])
  end



  def insertNotificationDeviceTokenConstituencyApp(map, userId, constituencyName) do
    insertMap = %{
      "userId" => userId,
      "constituencyName" => constituencyName,
      "deviceToken" => map["deviceToken"],
      "deviceType" => map["deviceType"],
      "insertedAt" => bson_time(),
    }
    insertMap = if !is_nil(map["appVersion"]) do
      Map.put_new(insertMap, "appVersion", map["appVersion"])
    else
      insertMap
    end
    insertMap = if !is_nil(map["osVersion"]) do
      Map.put_new(insertMap, "osVersion", map["osVersion"])
    else
      insertMap
    end
    insertMap = if !is_nil(map["deviceModel"]) do
      Map.put_new(insertMap, "deviceModel", map["deviceModel"])
    else
      insertMap
    end
    Mongo.insert_one(@conn, @notification_token_col, insertMap)
  end


  def getConstituencyGroupsCountForUser(userObjectId, constituencyName) do
    filter = %{
      "userId" => userObjectId,
      "groupDetails.constituencyName" => constituencyName,
      "groupDetails.isActive" => true,
      "isActive" => true
    }
    projection = %{ "_id" => 0, "groupId" => 1, "groupDetails.category" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => projection }]
    Enum.to_list(Mongo.aggregate(@conn, @view_group_team_members_col, pipeline))
  end


  def login(params) do
    userCountry = params["userName"]["countryCode"]
    userPhone = params["userName"]["phone"]
    password = params["password"]
    case ExPhoneNumber.parse(userPhone, userCountry) do
      {:ok, phone_number}->
        #if ExPhoneNumber.is_valid_number?(phone_number) do
          e164_number = ExPhoneNumber.format(phone_number, :e164)
          filter = %{ phone: e164_number }
          user_cursor = Mongo.find(@conn, @user_col, filter, [ limit: 1 ])
          list = Enum.to_list(user_cursor)
          if length(list) == 1 do
            userDetail = hd(list)
            user_password = userDetail["password_hash"]
            if Bcrypt.verify_pass(password, user_password) do
              final_result_map = %{
                "_id" => userDetail["_id"],
                "name" => userDetail["name"],
                "phone" => userDetail["phone"],
                "password" => userDetail["password_hash"],
                "image" => userDetail["image"]
                }
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


  def checkDeviceTokenAlreadyExist(deviceToken, deviceType, userId) do
    filter = %{
      "userId" => userId,
      "appId" => %{ "$exist" => false },
      "deviceToken" => deviceToken,
      "deviceType" => deviceType,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @notification_token_col, filter, [projection: project])
  end


  def insertNotificationDeviceToken(deviceToken, deviceType, userId) do
    insertMap = %{
      "userId" => userId,
      "deviceToken" => deviceToken,
      "deviceType" => deviceType,
      "insertedAt" => bson_time(),
    }
    Mongo.insert_one(@conn, @notification_token_col, insertMap)
  end


  def forgot_password(phone) do
    filter = %{ "phone" => phone }
    new_password = hash_password()
    update_doc = %{ "$set" => %{ "password_hash" => new_password.password, "user_secret_otp" => new_password.otp }  }
    case Mongo.update_one(@conn, @user_col, filter, update_doc) do
      {:ok, _res}->
        otp_map = %{ phone: phone, otp: new_password.otp }
        {:ok, otp_map}
      {:error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end


  def forgot_password_category_app(category, appName, phone_number, _params) do
    currentTime =  NaiveDateTime.utc_now
    otpExpireTime = "#{NaiveDateTime.add(currentTime, 300, :second)}"
    filter = %{ "phone" => phone_number, "category" => category, "appName" => appName }
    {:ok, list} = Mongo.count(@conn, @user_category_app_col, filter, [limit: 1])
    if list == 1 do
      new_password = hash_password()
      # update_doc = if params["appName"] in ["GC2123"] || !params["appName"] do
      #   %{ "$set" => %{ "otp_verify_individual" => "123456" } }
      # else
        #update_doc = %{ "$set" => %{ "otp_verify_individual" => new_password.otp } }
      # end
      #finding optExpire Time key
      {:ok, count }= otpExpireTime(filter)
      update_doc = if count > 0 do
        %{ "$set" => %{ "otp_verify_individual" => new_password.otp, "otpExpireTime" => otpExpireTime} }
      else
        otpExpireTimeMap = oldOtpMap(filter)
        navieOtpConversion = NaiveDateTime.from_iso8601!(otpExpireTimeMap["otpExpireTime"])
        check = NaiveDateTime.compare(navieOtpConversion, currentTime)
        if check == :gt do
          ^new_password = %{ otp: otpExpireTimeMap["otp_verify_individual"]}
          %{ "$set" => %{ "otp_verify_individual" => otpExpireTimeMap["otp_verify_individual"] } }
        else
          %{ "$set" => %{ "otp_verify_individual" => new_password.otp, "otpExpireTime" => otpExpireTime}}
        end
      end
      case Mongo.update_one(@conn, @user_category_app_col, filter, update_doc) do
        {:ok, _result}->
          otp_map = %{ phone: phone_number, otp: new_password.otp }
          {:ok, otp_map}
        {:error, _err}->
          {:mongo_error, "Something went wrong"}
      end
    else
      {:error, "Phone Number Not Exists"}
    end
  end


  def forgot_password_constituency_app(constituencyName, phone_number) do
    currentTime =  NaiveDateTime.utc_now
    otpExpireTime = "#{NaiveDateTime.add(currentTime, 300, :second)}"
    filter = %{ "phone" => phone_number, "constituencyName" => constituencyName }
    {:ok, list} = Mongo.count(@conn, @user_category_app_col, filter, [limit: 1])
    if list == 1 do
      new_password = hash_password()
      update_doc = if constituencyName in ["Gruppie Constituency Management"] do
        %{ "$set" => %{ "otp_verify_individual" => "123456" } }
      else
        #finding optExpire Time key
        {:ok, count }= otpExpireTime(filter)
        if count > 0 do
          %{ "$set" => %{ "otp_verify_individual" => new_password.otp, "otpExpireTime" => otpExpireTime} }
        else
          otpExpireTimeMap = oldOtpMap(filter)
          navieOtpConversion = NaiveDateTime.from_iso8601!(otpExpireTimeMap["otpExpireTime"])
          check = NaiveDateTime.compare(navieOtpConversion, currentTime)
          if check == :gt do
            ^new_password = %{ otp: otpExpireTimeMap["otp_verify_individual"]}
            %{ "$set" => %{ "otp_verify_individual" => otpExpireTimeMap["otp_verify_individual"] } }
          else
            %{ "$set" => %{ "otp_verify_individual" => new_password.otp, "otpExpireTime" => otpExpireTime}}
          end
        end
      end
      case Mongo.update_one(@conn, @user_category_app_col, filter, update_doc) do
        {:ok, _result}->
          otp_map = %{ phone: phone_number, otp: new_password.otp }
          {:ok, otp_map}
        {:error, _err}->
          {:mongo_error, "Something went wrong"}
      end
    else
      {:error, "Phone Number Not Exists"}
    end
  end


  defp  oldOtpMap(filter) do
    project = %{
      "_id" => 0,
      "otp_verify_individual" => 1,
      "otpExpireTime" => 1,
    }
    Mongo.find_one(@conn, @user_category_app_col, filter, [projection: project])
  end


  defp otpExpireTime(filter) do
    filter = Map.put(filter, "otpExpireTime", %{"$exists" => false})
    Mongo.count(@conn, @user_category_app_col, filter)
  end




  def checkInGroupTeamMembers(groupObjectId, user) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => user["_id"],
      "isActive" => true,
    }
    project = %{
      "teams" => 1,
    }
    userTeamMap = Mongo.find_one(@conn, @group_team_members_col, filter, [projection: project])
    checkTeamListExists(user, userTeamMap, groupObjectId)
  end


  defp checkTeamListExists(user, userTeamMap, groupObjectId) do
    userObjectId = user["_id"]
    if userTeamMap do
      if userTeamMap["teams"] != [] do
        teamIdList = for teamId <- userTeamMap["teams"] do
          teamId["teamId"]
        end
        incrementDownloadedUserCount(userObjectId, teamIdList)
      end
    else
      insert_doc = %{
        "canPost" => false,
        "groupId" => groupObjectId,
        "isActive" => true,
        "isAdmin" => false,
        "teams" => [],
        "userId" => userObjectId,
        "insertedAt" => bson_time(),
        "updatedAt" => bson_time(),
      }
      teamChangeset = %{
        name: user["name"]<>" Team",
        insertedAt: bson_time(),
        updatedAt: bson_time(),
      }
      Mongo.insert_one(@conn, @group_team_members_col, insert_doc)
      TeamRepo.createTeam(user, teamChangeset, groupObjectId)
    end
  end


  defp incrementDownloadedUserCount(userObjectId, teamIdList) do
    for teamId <- teamIdList do
      incrementingDownloadedUserCountInTable(teamId, userObjectId)
    end
  end


  defp incrementingDownloadedUserCountInTable(teamId, userObjectId) do
    team = TeamRepo.get(encode_object_id(teamId))
    if team["category"] == "subBooth" do
      #1) increment userDownloadedCount in category= booth
      incrementDownloadedUserInBooth(team["boothTeamId"])
      #2) increment userDownloadedCount in category= subBooth
      incrementDownloadedUserInSubBooth(team["_id"])
    else
      if team["category"] == "booth" do
        if !team["adminId"] == userObjectId do
          incrementDownloadedUserInBooth(team["_id"])
        end
      end
    end
  end


  defp incrementDownloadedUserInBooth(teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "downloadedUserCount" => 1,
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  defp incrementDownloadedUserInSubBooth(teamObjectId) do
    filter =  %{
      "_id" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "downloadedUserCount" => 1,
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def change_password(loginUserId, newPassword) do
    filter = %{ "_id" => loginUserId }
    #encrypting password to hash_password
    new_password_hash = Bcrypt.hash_pwd_salt(newPassword)
    update_doc = %{ "$set" => %{ "password_hash" => new_password_hash, "user_secret_otp"  => newPassword }  }
    insert_result = Mongo.update_one(@conn, @user_col, filter, update_doc)
    user_map = hd(Enum.to_list(Mongo.find(@conn, @user_col, filter)))
    case insert_result do
      {:ok, _res}->
         {:ok, user_map}
      {:error, _err}->
         {:mongo_error, "Something went wrong"}
    end
  end


  def change_password_individual(loginUserId, newPassword, appId) do
    filter = %{ "userId" => loginUserId, "appId" => decode_object_id(appId) }
    #encrypting password to hash_password
    new_password_hash = Bcrypt.hash_pwd_salt(newPassword)
    update_doc = %{ "$set" => %{ "password_hash_individual" => new_password_hash, "user_secret_otp"  => newPassword}  }
    insert_result = Mongo.update_one(@conn, @user_individual_col, filter, update_doc)
    #to get user name and phone from user col
    filterUser = %{ "_id" => loginUserId }
    user = Mongo.find(@conn, @user_col, filterUser)
    list = Enum.to_list(user)
    user_map = hd(list)
    #to get user individual app from user_individual
    userIndividual = hd(Enum.to_list(Mongo.find(@conn, @user_individual_col, filter)))
    #merge user info and password for individual app
    mergeMap = %{ "_id" => userIndividual["_id"], "userId" => userIndividual["userId"], "name" => user_map["name"], "phone" => user_map["phone"], "password_hash_individual" => userIndividual["password_hash_individual"] }
    case insert_result do
      {:ok, _res}->
         {:ok, mergeMap}
      {:error, _err}->
         {:mongo_error, "Something went wrong"}
    end
  end


  def change_password_category_app(loginUserId, newPassword, category, appName) do
    filter = %{ "userId" => loginUserId, "category" => category, "appName" => appName }
    #encrypting password to hash_password
    new_password_hash = Bcrypt.hash_pwd_salt(newPassword)
    update_doc = %{ "$set" => %{ "password_hash_individual" => new_password_hash, "user_secret_otp"  => newPassword }  }
    insert_result = Mongo.update_one(@conn, @user_category_app_col, filter, update_doc)
    #to get user name and phone from user col
    filterUser = %{ "_id" => loginUserId }
    user = Mongo.find(@conn, @user_col, filterUser)
    list = Enum.to_list(user)
    user_map = hd(list)
    #to get user individual app from user_category_app
    userIndividual = hd(Enum.to_list(Mongo.find(@conn, @user_category_app_col, filter)))
    #merge user info and password for individual app
    mergeMap = %{ "_id" => userIndividual["_id"], "userId" => userIndividual["userId"], "name" => user_map["name"], "phone" => user_map["phone"], "password_hash_individual" => userIndividual["password_hash_individual"] }
    case insert_result do
      {:ok, _res}->
         {:ok, mergeMap}
      {:error, _err}->
         {:mongo_error, "Something went wrong"}
    end
  end


  def change_password_constituency_app(loginUserId, newPassword, constituencyName) do
    filter = %{ "userId" => loginUserId, "constituencyName" => constituencyName }
    #encrypting password to hash_password
    new_password_hash = Comeonin.Bcrypt.hashpwsalt(newPassword)
    update_doc = %{ "$set" => %{ "password_hash_individual" => new_password_hash, "user_secret_otp"  => newPassword }  }
    insert_result = Mongo.update_one(@conn, @user_category_app_col, filter, update_doc)
    #to get user name and phone from user col
    filterUser = %{ "_id" => loginUserId }
    user = Mongo.find(@conn, @user_col, filterUser)
    list = Enum.to_list(user)
    user_map = hd(list)
    #to get user individual app from user_category_app
    userIndividual = hd(Enum.to_list(Mongo.find(@conn, @user_category_app_col, filter)))
    #merge user info and password for individual app
    mergeMap = %{ "_id" => userIndividual["_id"], "userId" => userIndividual["userId"], "name" => user_map["name"], "phone" => user_map["phone"], "password_hash_individual" => userIndividual["password_hash_individual"] }
    case insert_result do
      {:ok, _res}->
         {:ok, mergeMap}
      {:error, _err}->
         {:mongo_error, "Something went wrong"}
    end
  end




end
