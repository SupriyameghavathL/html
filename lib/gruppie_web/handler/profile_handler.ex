defmodule GruppieWeb.Handler.ProfileHandler do
  alias GruppieWeb.Repo.UserRepo
  import GruppieWeb.Handler.TimeNow


  def addProfession(professions) do
    UserRepo.addProfession(professions)
  end


  def addEducation(educationList) do
    UserRepo.addEducation(educationList)
  end


  def addInfluencerList(influencerList) do
    UserRepo.addInfluencerList(influencerList)
  end


  def addConstituency(constituencyList) do
    UserRepo.addConstituency(constituencyList)
  end


  def getGroupId(birthDayDate) do
    group = UserRepo.getGroupId()
    #get uses list based on dob
    todayBirthdayList = UserRepo.getUserBirthday(birthDayDate)
    bdayImages = [
			"https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Birthday/WhatsApp%20Image%202022-05-06%20at%204.50.16%20PM.jpeg",
			"https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Birthday/WhatsApp%20Image%202022-05-06%20at%205.41.32%20PM.jpeg",
			"https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Birthday/WhatsApp%20Image%202022-05-06%20at%206.00.12%20PM.jpeg",
			"https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Birthday/WhatsApp%20Image%202022-05-06%20at%206.00.12%20PM%20%281%29.jpeg",
			"https://gruppiemedia.sgp1.cdn.digitaloceanspaces.com/Birthday/WhatsApp%20Image%202022-05-06%20at%206.00.12%20PM%20%282%29.jpeg"
		]
    birthdayPostInsertDoc = for userList <- todayBirthdayList do
      #insert birthday post in group_post
      %{
        "bdayUserId" => userList["_id"],
        "groupId" => group["_id"],
        "userId" =>  group["adminId"],
        "type" => "birthdayPost",
        "fileName" =>  [Enum.random(bdayImages)],
        "fileType" =>  "image",
        "isActive" => true,
        "insertedAt" =>  bson_time(),
        "updatedAt" =>  bson_time()
      }
    end
    UserRepo.birthdayPost(birthdayPostInsertDoc)

    # #2 post to user teams
    # birthdayPostInsertDoc = for userList <- todayBirthdayList do
    #   teamsArrayUser = UserRepo.getUsersTeamsList(group["_id"], userList["_id"])
    #   # IO.puts "#{teamsArrayUser}"
    #   teamPostBirthday = for teamId <- teamsArrayUser["teams"] do
    #     %{
    #       "bdayUserId" => userList["_id"],
    #       "groupId" => group["_id"],
    #       "userId" =>  group["adminId"],
    #       "teamId" => teamId["teamId"]
    #       "type" => "birthdayPost",
    #       "fileName" =>  [Enum.random(bdayImages)],
    #       "fileType" =>  "image",
    #       "isActive" => true,
    #       "insertedAt" =>  Gruppie.Handler.TimeNow.bson_time(),
    #       "updatedAt" =>  Gruppie.Handler.TimeNow.bson_time()
    #     }
    #   end
    #   UserRepo.birthdayPost(teamPostBirthday)
    # end
  end

  def addStates(params) do
    UserRepo.addStates(params)
  end

  def getStates(country) do
    UserRepo.getStates(country)
  end

  def addDistricts(params) do
    UserRepo.addDistricts(params)
  end

  def getDistricts(state) do
    UserRepo.getDistricts(state)
  end

  def addTaluks(params) do
    UserRepo.addTaluks(params)
  end

  def getTaluks(district) do
    UserRepo.getTaluks(district)
  end


  def addReminder(params) do
    UserRepo.addReminder(params)
  end

  def getReminder() do
    UserRepo.getReminder()
  end


  def addRelatives(params) do
    UserRepo.addRelatives(params)
  end


  def getRelatives() do
    UserRepo.getRelatives()
  end


  def updateProfileWithAddress(user_changeset, address_changeset, logged_in_user) do
    merged_map = Map.merge(user_changeset.changes,%{ address: address_changeset.changes})
    UserRepo.update_logged_in_user(merged_map, logged_in_user)
  end


  def updateProfile(user_changeset, logged_in_user) do
    state = if Map.has_key?(user_changeset.changes, :state) do
      String.downcase(user_changeset.changes.state)
    end
    district = if Map.has_key?(user_changeset.changes, :district) do
      String.downcase(user_changeset.changes.district)
    end
    taluk = if Map.has_key?(user_changeset.changes, :taluk) do
      String.downcase(user_changeset.changes.taluk)
    end
    place = if Map.has_key?(user_changeset.changes, :place) do
      String.downcase(user_changeset.changes.place)
    end
    user_changeset = user_changeset.changes
    |>  Map.put(:searchName, String.downcase(user_changeset.changes.name))
    |>  Map.put(:state, state)
    |>  Map.put(:district, district)
    |>  Map.put(:taluk, taluk)
    |>  Map.put(:place, place)
    UserRepo.update_logged_in_user(user_changeset, logged_in_user)
  end


  def removeUserProfilePic(conn) do
    loginUser = Guardian.Plug.current_resource(conn)
    UserRepo.removeUserProfilePic(loginUser)
  end



end
