defmodule GruppieWeb.Handler.SecurityHandler do
  alias GruppieWeb.Repo.SecurityRepo
  alias GruppieWeb.Repo.UserRepo

  def findUserExistByPhoneNumber(changeset) do
    SecurityRepo.findUserExistByPhoneNumber(changeset.phone)
  end

  def register(changeset) do
    SecurityRepo.register(changeset)
  end

  def registerCategoryApp(conn, changeset) do
    #check user already in user table or not
    checkUserExistInUserModel = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExistInUserModel) > 0 do
      #check user in  user school app table
      checkUserExistInSchoolAppModel = UserRepo.check_user_exist_category_app(conn, hd(checkUserExistInUserModel), changeset)
      if length(checkUserExistInSchoolAppModel) > 0 do
        {:user_already_error, "user already registered"}
      else
        registerUserToCategoryApp(conn, changeset, hd(checkUserExistInUserModel))
      end
    else
      {:new_user, "register"}
    end
  end

  defp registerUserToCategoryApp(conn, changeset, user) do
    SecurityRepo.register_user_category_app(conn, changeset, user)
  end

  def registerUserToConstituencyApp(conn, changeset, constituencyName) do
    #check user already in user table or not
    checkUserExistInUserModel = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExistInUserModel) > 0 do
      #check user in  constituency app
      checkUserExistInConstituencyApp = UserRepo.check_user_exist_constituency_app(conn, hd(checkUserExistInUserModel), changeset)
      if length(checkUserExistInConstituencyApp) > 0 do
        {:user_already_error, "user already registered"}
      else
        #register user to constituency app
        user = hd(checkUserExistInUserModel)
        SecurityRepo.register_user_constituency_app(conn, changeset, user)
        #to incrementDownloadCount
        #  get groupId from groups coll
        groupId = SecurityRepo.getGroupId(constituencyName)
        #user Logged to app
        SecurityRepo.checkInGroupTeamMembers(groupId["_id"], user, constituencyName)
        # set user_col with :caste, :subcaste, :category, :designation, :education, :image
        changeset = changeset
        |> Map.delete(:phone)
        SecurityRepo.upate_user_profile_while_register(changeset, user)
      end
    else
      {:new_user, "register"}
    end
  end


  def registerUserToCommunityApp(conn, changeset) do
    #check user already in user table or not
    checkUserExistInUserModel = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExistInUserModel) > 0 do
      #check user in  community app
      checkUserExistInConstituencyApp = UserRepo.check_user_exist_category_app(conn, hd(checkUserExistInUserModel), changeset)
      if length(checkUserExistInConstituencyApp) > 0 do
        {:user_already_error, "user already registered"}
      else
        #register user to constituency app
        user = hd(checkUserExistInUserModel)
        SecurityRepo.register_user_category_app(conn, changeset, user)
        #to incrementDownloadCount
        #  get groupId from groups coll
        groupId = SecurityRepo.getGroupIdByAppName(changeset.category, changeset.appName)
        #user Logged to app
        SecurityRepo.checkInGroupTeamMembers(groupId["_id"], user, "")
        # set user_col with :caste, :subcaste, :category, :designation, :education, :image
        changeset = changeset
        |> Map.delete(:phone)
        SecurityRepo.upate_user_profile_while_register(changeset, user)
      end
    else
      {:new_user, "register"}
    end
  end

  def createPasswordCategoryApp(changeset, category) do
    # update password for the user in individual app
    SecurityRepo.createPasswordCategoryApp(changeset, category)
  end


  def createPasswordConstituencyApp(changeset, constituencyName) do
    #update password for the user in individual app
    SecurityRepo.createPasswordConstituencyApp(changeset, constituencyName)
  end


  def saveDeviceTokenCategoryApp(device_params, userId, category) do
    map = %{
      "deviceToken" => device_params["deviceToken"],
      "deviceType" => device_params["deviceType"],
      "appVersion" => device_params["appVersion"],
      "osVersion" => device_params["osVersion"],
      "deviceModel" => device_params["deviceModel"],
    }
    #check whether same deviceToken to deviceModel is added for the same user
    {:ok, checkAlreadyAddedWithSameDevice} = SecurityRepo.checkAlreadyAddedWithSameDeviceCategoryApp(map, userId, category)
    if checkAlreadyAddedWithSameDevice == 0 do
      #add new device
      SecurityRepo.insertNotificationDeviceTokenCategoryApp(map, userId, category)
    else
      #already added
      {:ok, "alreadyAdded"}
    end
  end


  def getCategoryGroupsCountForUser(userId, category, appName) do
    #if category and appName exist (for individual institutional app all school and college app in one )
    if !is_nil(appName) do
      #get groups count for category and appName
      groupDetails = SecurityRepo.getCategoryWithAppNameGroupsCountForUser(userId, category, appName)
      #IO.puts "#{groupDetails}"
      if length(groupDetails) == 1 do
        #direct land in groups index page of that one group (provide group id)
        map = %{
              "groupCount" => length(groupDetails),
              "groupId" => GruppieWeb.Repo.RepoHelper.encode_object_id(hd(groupDetails)["groupId"]),
              "groupCategory" => hd(groupDetails)["groupDetails"]["category"]
            }
        {:ok, map}
      else
        if length(groupDetails) > 1 do
          #land in to app index page where with the same category list of groups
          map = %{
                "groupCount" => length(groupDetails)
              }
          {:ok, map}
        else
          if length(groupDetails) == 0 do
            #not allowed to access app
            { :error, "You Are Not Allowed To Access This App" }
          end
        end
      end
    else
      # common gruppieCampus connect app
      #get groups count for only category
      groupDetails = SecurityRepo.getCategoryGroupsCountForUser(userId, category)
      #IO.puts "#{groupDetails}"
      if length(groupDetails) == 1 do
        #direct land in groups index page of that one group (provide group id)
        map = %{
              "groupCount" => length(groupDetails),
              "groupId" => GruppieWeb.Repo.RepoHelper.encode_object_id(hd(groupDetails)["groupId"]),
              "groupCategory" => hd(groupDetails)["groupDetails"]["category"]
            }
        {:ok, map}
      else
        if length(groupDetails) > 1 do
          #land in to app index page where with the same category list of groups
          map = %{
                "groupCount" => length(groupDetails)
              }
          {:ok, map}
        else
          if length(groupDetails) == 0 do
            # #not allowed to access app
            # { :error, "You Are Not Allowed To Access This App" }
            map = %{}
            {:ok, map}
          end
        end
      end
    end
  end


  def saveDeviceTokenConstituencyApp(device_params, userId, constituencyName) do
    map = %{
      "deviceToken" => device_params["deviceToken"],
      "deviceType" => device_params["deviceType"],
      "appVersion" => device_params["appVersion"],
      "osVersion" => device_params["osVersion"],
      "deviceModel" => device_params["deviceModel"],
    }
    #check whether same deviceToken to deviceModel is added for the same user
    {:ok, checkAlreadyAddedWithSameDevice} = SecurityRepo.checkAlreadyAddedWithSameDeviceConstituencyApp(map, userId, constituencyName)
    if checkAlreadyAddedWithSameDevice == 0 do
      #add new device
      SecurityRepo.insertNotificationDeviceTokenConstituencyApp(map, userId, constituencyName)
    else
      #already added
      {:ok, "alreadyAdded"}
    end
  end


  def getConstituencyGroupsCountForUser(userId, constituencyName) do
    #if constituencyName exist
    if !is_nil(constituencyName) do
      #get groups count for constituencyName
      groupDetails = SecurityRepo.getConstituencyGroupsCountForUser(userId, constituencyName)
      #IO.puts "#{groupDetails}"
      if length(groupDetails) == 1 do
        #direct land in groups index page of that one group (provide group id)
        map = %{
              "groupCount" => length(groupDetails),
              "groupId" => GruppieWeb.Repo.RepoHelper.encode_object_id(hd(groupDetails)["groupId"]),
              "groupCategory" => hd(groupDetails)["groupDetails"]["category"]
            }
        {:ok, map}
      else
        if length(groupDetails) > 1 do
          #land in to app index page where with the same category list of groups
          map = %{
                "groupCount" => length(groupDetails)
              }
          {:ok, map}
        else
          if length(groupDetails) == 0 do
            #not allowed to access app
            { :error, "You Are Not Allowed To Access This App" }
          end
        end
      end
    end
  end


  def saveDeviceToken(device_params, userId) do
    deviceToken = device_params["deviceToken"]
    deviceType = device_params["deviceType"]
    #check user already inserted with same device token
    #  {:ok, find} = SecurityRepo.findDeviceTokenAlready(userId, appObjectId)
    #  if find > 0 do
    #update device token for user
    #    SecurityRepo.updateNotificationDeviceToken(deviceToken, deviceType, userId, appObjectId)
    #  else
    {:ok, checkAlready} = SecurityRepo.checkDeviceTokenAlreadyExist(deviceToken, deviceType, userId)
    if checkAlready < 1 do
      SecurityRepo.insertNotificationDeviceToken(deviceToken, deviceType, userId)
    end
    #  end
  end


  def forgot_password(changeset) do
    SecurityRepo.forgot_password(changeset.phone)
  end


  def forgot_password_category_app(category, appName, changeset, params) do
    SecurityRepo.forgot_password_category_app(category, appName, changeset.phone, params)
  end

  def forgot_password_constituency_app(constituencyName, changeset) do
    SecurityRepo.forgot_password_constituency_app(constituencyName, changeset.phone)
  end

   #change user password
   def change_password(conn, params) do
    loginUser = Guardian.Plug.current_resource(conn)
    newPassword = params.newPasswordFirst
    #checking the old password and current password of user match or not
    if Bcrypt.verify_pass(params.oldPassword, loginUser["password_hash"]) do
      SecurityRepo.change_password(loginUser["_id"], newPassword)
    else
      {:error, "Old Password Is Incorrect"}
    end
  end


  #change user password individual
  def change_password_individual(conn, params, appId) do
    loginUser = Guardian.Plug.current_resource(conn)
    loginUserIndividual = UserRepo.findUserIndividualApp(loginUser["_id"], appId)
    newPassword = params.newPasswordFirst
    #checking the old password and current password of user match or not
    if Bcrypt.check_pass(params.oldPassword, loginUserIndividual["password_hash_individual"]) do
      SecurityRepo.change_password_individual(loginUser["_id"], newPassword, appId)
    else
      {:error, "Old Password Is Incorrect"}
    end
  end


  def change_password_category_app(conn, params, category, appName) do
    loginUser = Guardian.Plug.current_resource(conn)
    loginUserIndividual = UserRepo.findUserCategoryApp(loginUser["_id"], category, appName)
    newPassword = params.newPasswordFirst
    #checking the old password and current password of user match or not
    if Bcrypt.check_pass(params.oldPassword, loginUserIndividual["password_hash_individual"]) do
      SecurityRepo.change_password_category_app(loginUser["_id"], newPassword, category, appName)
    else
      {:error, "Old Password Is Incorrect"}
    end
  end


  def change_password_constituency_app(conn, params, constituencyName) do
    loginUser = Guardian.Plug.current_resource(conn)
    loginUserIndividual = UserRepo.findUserConstituencyApp(loginUser["_id"], constituencyName)
    newPassword = params.newPasswordFirst
    #checking the old password and current password of user match or not
    if Bcrypt.check_pass(params.oldPassword, loginUserIndividual["password_hash_individual"]) do
      SecurityRepo.change_password_constituency_app(loginUser["_id"], newPassword, constituencyName)
    else
      {:error, "Old Password Is Incorrect"}
    end
  end




end
