defmodule GruppieWeb.Repo.UserRepo do
  # alias GruppieWeb.User
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @user_col "users"

  @group_col "groups"

  @caste_db_col "caste_database"

  @user_individual_col "user_individual_apps"

  @user_category_app_col "user_category_apps"

  # @group_team_members_col "group_team_members"

  # @view_staff_db "VW_STAFF_DB"

  @staff_db_col "staff_database"

  @teams_col "teams"

  # @student_db_col "student_database"

  @profession_col "professions"

  @education_col "education_db"

  @constituency_col "constituency_db"

  @influencer_col "influencer_db"

  @post_col  "posts"

  @state_col "states_db"

  @district_col "district_db"

  @taluk_col "taluk_db"

  @reminder_col "reminder_list_db"

  @releatives_coll "releatives_db"

  @post_report_reasons "post_report_reasons"


  def find_user_by_phone(phone) do
    filter = %{
      "phone" => phone
    }
    projection =  %{
      "password_hash" => 0
    }
    Enum.to_list(Mongo.find(@conn, @user_col, filter, [ projection: projection, limit: 1]))
  end


  def find_user_by_id(id) do
    filter = %{ "_id" => id }
    projection =  %{ "password_hash" => 0 }
    hd(Enum.to_list(Mongo.find(@conn, @user_col, filter, [ projection: projection, limit: 1 ])))
    #Mongo.find_one(@conn, @user_col, filter, [ projection: projection ])
  end


  def check_user_exist_category_app(conn, user, _changeset) do
    category = conn.query_params["category"]
    # loginUser = Guardian.Plug.current_resource(conn)
    filter = %{ "userId" => user["_id"], "category" => category }
    cursor = Mongo.find(@conn, @user_category_app_col, filter)
    Enum.to_list(cursor)
  end


  def check_user_exist_constituency_app(conn, user, _changeset) do
    constituencyName = conn.query_params["constituencyName"]
    # loginUser = Guardian.Plug.current_resource(conn)
    filter = %{ "userId" => user["_id"], "constituencyName" => constituencyName }
    cursor = Mongo.find(@conn, @user_category_app_col, filter)
    Enum.to_list(cursor)
  end


   #find user by id stored in session
   def find_by_id(id, password)  do
    object_id = id
    # object_id = BSON.ObjectId.decode!(id)
    filter = %{"_id" => object_id, "password_hash" => password }
    # IO.puts "#{filter}"
    cursor = Mongo.find(@conn, @user_col, filter, [ limit: 1 ])
    list = Enum.to_list(cursor)
    if length(list) == 1 do
      {:ok, hd(list)}
    else
      filter1 = %{"_id" => object_id, "password_hash_individual" => password}
      cursor1 = Mongo.find(@conn, @user_individual_col, filter1, [ limit: 1 ])
      list1 = Enum.to_list(cursor1)
      if length(list1) == 1 do
        userIndividualList = hd(list1)
        #get user id from individual list and fetch all user details using id
        userId = userIndividualList["userId"]
        filter2 = %{"_id" => userId }
        cursor2 = Mongo.find(@conn, @user_col, filter2, [ limit: 1 ])
        list2 = Enum.to_list(cursor2)
        if length(list2) == 1 do
           {:ok, hd(list2)}
        else
           {:error, "not found"}
        end
      else
        filter3 = %{"_id" => object_id, "password_hash_individual" => password}
        cursor3 = Mongo.find(@conn, @user_category_app_col, filter3, [ limit: 1 ])
        list3 = Enum.to_list(cursor3)
        if length(list3) == 1 do
          userCategoryList = hd(list3)
          #get user id from individual list and fetch all user details using id
          userId = userCategoryList["userId"]
          filter4 = %{"_id" => userId }
          cursor4 = Mongo.find(@conn, @user_col, filter4, [ limit: 1 ])
          list4 = Enum.to_list(cursor4)
          if length(list4) == 1 do
             {:ok, hd(list4)}
          else
             {:error, "not found"}
          end
        else
          {:error, "not found"}
        end
      end
    end
  end


  def getCasteReligionList() do
    filter = %{}
    # project = %{"_id" => 0, "religion" => 1}
    {:ok, religion} = Mongo.distinct(@conn, @caste_db_col, "religion", filter)
    religion
  end


  def getCasteList(params) do
    if params["religion"] do
      #get main castes base on religion
      filter = %{
        "religion" => params["religion"]
      }
      project = %{"_id" => 1, "casteName" => 1, "categoryName" => 1, "religion" => 1}
      Mongo.find(@conn, @caste_db_col, filter, [projection: project, sort: %{casteName: 1}])
      |> Enum.to_list
    else
      if params["casteId"] do
        #get sub caste name for selected caste
        casteObjectId = decode_object_id(params["casteId"])
        #get sub caste list for selected casteId
        filter = %{
          "_id" => casteObjectId
        }
        project = %{"_id" => 0, "subCaste" => 1}
        subCasteFind = Mongo.find_one(@conn, @caste_db_col, filter, [projection: project])
        subCasteFind["subCaste"]
      else
        #get all main caste list
        filter = %{}
        project = %{"_id" => 1, "casteName" => 1, "categoryName" => 1, "religion" => 1}
        Mongo.find(@conn, @caste_db_col, filter, [projection: project, sort: %{casteName: 1}])
        |> Enum.to_list
      end
    end
  end


  def addProfession(professions) do
    filter = %{}
    {:ok, professionCount} = Mongo.count(@conn, @profession_col, filter)
    if professionCount == 0 do
      #insert newly
      insertDoc = %{"professionList" => professions}
      Mongo.insert_one(@conn, @profession_col, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"professionList" => %{"$each" => professions}}}
      Mongo.update_one(@conn, @profession_col, filter, update)
    end
  end


  def addEducation(educationList) do
    filter = %{}
    {:ok, education_count} = Mongo.count(@conn, @education_col, filter)
    if education_count == 0 do
      #insert newly
      insertDoc = %{"educationList" => educationList}
      Mongo.insert_one(@conn, @education_col, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"educationList" => %{"$each" => educationList}}}
      Mongo.update_one(@conn, @education_col, filter, update)
    end
  end


  def addInfluencerList(influencerList) do
    filter = %{}
    {:ok, influencer_count} = Mongo.count(@conn, @influencer_col, filter)
    if influencer_count == 0 do
      #insert newly
      insertDoc = %{"influencerList" => influencerList}
      Mongo.insert_one(@conn, @influencer_col, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"influencerList" => %{"$each" => influencerList}}}
      Mongo.update_one(@conn, @influencer_col, filter, update)
    end
  end


  def addConstituency(constituencyList) do
    filter = %{}
    {:ok, constituency_count} = Mongo.count(@conn, @constituency_col, filter)
    if constituency_count == 0 do
      #insert newly
      insertDoc = %{"constituencyList" => constituencyList}
      Mongo.insert_one(@conn, @constituency_col, insertDoc)
    else
      #update profession to existing
      update = %{"$push" => %{"constituencyList" => %{"$each" => constituencyList}}}
      Mongo.update_one(@conn, @constituency_col, filter, update)
    end
  end


  def getGroupId() do
    filter = %{
      "category" => "constituency",
      "isActive" => true,
    }
    project = %{
      "adminId" => 1,
      "_id" => 1,
    }
    Mongo.find_one(@conn, @group_col, filter, [projection: project])
  end


  def getUserBirthday(birthDayDate) do
    filter = %{
      "dob" => %{
        "$regex" => birthDayDate
      }
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 1,
    }
    Mongo.find(@conn, @user_col, filter, [projection: project])
    |> Enum.to_list()
    # IO.puts "#{list}"
  end


  def birthdayPost(birthdayPostInsertDoc) do
    Mongo.insert_many(@conn, @post_col, birthdayPostInsertDoc)
  end

  # def getUsersTeamsList(groupObjectId, userId) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "userId" => userId,
  #     "isActive" => true,
  #   }
  #   project = %{
  #     "teams.teamId" => 1,
  #     "_id" => 0,
  #   }
  #   Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
  #   |> Enum.to_list()
  # end



  def getProfession() do
    filter = %{}
    project = %{"_id" => 0}
    Mongo.find_one(@conn, @profession_col, filter, [projection: project, limit: 1])
  end


  def getEducation() do
    filter = %{}
    project = %{"_id" => 0}
    Mongo.find_one(@conn, @education_col, filter, [projection: project, limit: 1])
  end

  def getInfluencerList() do
    filter = %{}
    project = %{"_id" => 0}
    Mongo.find_one(@conn, @influencer_col, filter, [projection: project, limit: 1])
  end

  def getConstituency() do
    filter = %{}
    project = %{"_id" => 0}
    Mongo.find_one(@conn, @constituency_col, filter, [projection: project, limit: 1])
  end

  def addStates(params) do
    filter = %{
      "country" => params["country"]
    }
    {:ok, country_count} = Mongo.count(@conn, @state_col, filter)
    if country_count == 0 do
      #insert newly
      Mongo.insert_one(@conn, @state_col, params)
    else
      #update states to existing
      update = %{"$push" => %{"states" => %{"$each" => params["states"]}}}
      Mongo.update_one(@conn, @state_col, filter, update)
    end
  end


  def getStates(country) do
    filter = %{
      "country" => country
    }
    project = %{
      "states" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @state_col, filter, [projection: project])
  end


  def addDistricts(params) do
    filter = %{}
    {:ok, state_count} = Mongo.count(@conn, @district_col, filter)
    if state_count == 0 do
      #insert newly
      Mongo.insert_one(@conn, @district_col, params)
    else
      #update states to existing
      update = %{"$push" => %{"districtsList" => %{"$each" => params["districtsList"]}}}
      Mongo.update_one(@conn, @district_col, filter, update)
    end
  end


  def getDistricts(state) do
    filter = %{
      "districtsList.state" => state
    }
    project = %{
      "districtsList.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @district_col, filter, [projection: project])
  end


  def addTaluks(params) do
    filter = %{}
    {:ok, district_count} = Mongo.count(@conn, @taluk_col, filter)
    if district_count == 0 do
      #insert newly
      Mongo.insert_one(@conn, @taluk_col, params)
    else
      #update states to existing
      update = %{"$push" => %{"taluksList" => %{"$each" => params["taluksList"]}}}
      Mongo.update_one(@conn, @taluk_col, filter, update)
    end
  end


  def getTaluks(district) do
    filter = %{
      "taluksList.district" => district
    }
    project = %{
      "taluksList.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @taluk_col, filter, [projection: project])
  end


  def addReminder(params) do
    filter = %{
      "reminderList" => params["reminderList"]
    }
    {:ok, reminder_count} = Mongo.count(@conn, @reminder_col, filter)
    if reminder_count == 0 do
      #insert newly
      Mongo.insert_one(@conn, @reminder_col, params)
    else
      #update states to existing
      update = %{"$push" => %{"reminderList" => %{"$each" => params["reminderList"]}}}
      Mongo.update_one(@conn, @reminder_col, filter, update)
    end
  end


  def getReminder() do
    Mongo.find_one(@conn, @reminder_col, %{}, [projection: %{"_id" => 0}])
  end


  def addRelatives(params) do
    filter = %{
      "relativesList" => params["relativesList"]
    }
    {:ok, relative_count} = Mongo.count(@conn, @releatives_coll, filter)
    if relative_count == 0 do
      #insert newly
      Mongo.insert_one(@conn, @releatives_coll, params)
    else
      #update releatives to existing
      update = %{"$push" => %{"relativesList" => %{"$each" => params["relativesList"]}}}
      Mongo.update_one(@conn, @releatives_coll, filter, update)
    end
  end


  def getRelatives() do
    Mongo.find_one(@conn, @releatives_coll, %{}, [projection: %{"_id" => 0}])
  end

  def getPostReportReasons() do
    filter = %{ "isActive" => true }
    projection = %{ "_id" => 0, "isActive" => 0 }
    Mongo.find(@conn, @post_report_reasons, filter, [projection: projection])
  end


  def update_logged_in_user(merged_map, logged_in_user) do
    #merged_map = Map.delete(merged_map, :image)
    filter = %{ "_id" => logged_in_user["_id"] }
    update = %{ "$set" =>  merged_map }
    Mongo.update_one(@conn, @user_col, filter, update)
  end

  def removeUserProfilePic(loginUser) do
    filter = %{ "_id" =>  loginUser["_id"] }
    update = %{ "$unset" => %{ "image" => loginUser["image"] } }
    Mongo.update_one(@conn, @user_col, filter, update)
  end


  def findUserIndividualApp(loginUserId, appId) do
    appObjectId = decode_object_id(appId)
    filter = %{
      "userId" => loginUserId,
      "appId" => appObjectId,
      "isActive" => true
    }
    hd(Enum.to_list(Mongo.find(@conn, @user_individual_col, filter)))
  end


  def findUserCategoryApp(loginUserId, category, appName) do
    filter = %{
      "userId" => loginUserId,
      "category" => category,
      "appName" => appName,
      "isActive" => true
    }
    hd(Enum.to_list(Mongo.find(@conn, @user_category_app_col, filter)))
  end


  def findUserConstituencyApp(loginUserId, constituencyName) do
    filter = %{
      "userId" => loginUserId,
      "constituencyName" => constituencyName,
      "isActive" => true
    }
    hd(Enum.to_list(Mongo.find(@conn, @user_category_app_col, filter)))
  end


  def addUserToUserDoc(changeset) do
    newUserObjectId = new_object_id()
    generatedPassword = hash_password()
    hashed_password = generatedPassword.password #accessing field from map
    # otp = generatedPassword.otp
    final_user_map = changeset
                      |>update_map_with_key_value(:_id, newUserObjectId)
                      |>update_map_with_key_value(:password_hash, hashed_password)
                      |>update_map_with_key_value(:searchName, String.downcase(changeset.name))
                      |>Map.delete(:teamCategory)
                      |>Map.delete(:isActive)
    case Mongo.insert_one(@conn, @user_col, final_user_map) do
      {:ok, user} ->
        filter = %{ "_id" => user.inserted_id }
        hd(Enum.to_list(Mongo.find(@conn, @user_col, filter)))
      {:mongo_error, _err}->
        {:mongo_error, "Something went wrong"}
    end
  end


  def lastUserForTeamUpdatedAt(teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"lastUserUpdatedAt" => bson_time()}}
    Mongo.update_one(@conn, @teams_col, filter, update)
  end

  def getSchoolStaff(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true
    }
    ##pipeline = [%{"$match" => filter}]
    ##Mongo.aggregate(@conn, @view_staff_db, pipeline)
    Mongo.find(@conn, @staff_db_col, filter)
  end



end
