defmodule GruppieWeb.Handler.SchoolCollegeRegisterHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.SchoolCollegeRegisterRepo
  import GruppieWeb.Handler.TimeNow


  def addBoardToDb(params) do
    SchoolCollegeRegisterRepo.addBoardToDb(params)
  end


  def addBoardClassToDb(params) do
    createId = for createId <- params["classes"] do
      createId
      |> Map.put("classTypeId", encode_object_id(new_object_id()))
    end
    insertDoc = %{
      "board" => params["board"],
      "subCategory" => params["subCategory"],
      "classes" => createId
    }
    SchoolCollegeRegisterRepo.addBoardClassToDb(insertDoc)
  end


  def getSchoolClassList(subCategory, board) do
    SchoolCollegeRegisterRepo.getSchoolClassList(subCategory, board)
  end


  def getCreatedClassList(conn, groupId) do
    groupObjectId = decode_object_id(groupId)
    classList = SchoolCollegeRegisterRepo.getCreatedClassList(groupObjectId)
    listOfClassName = for className <- classList do
      className["gruppieClassName"]
    end
    listOfClassName = listOfClassName
    |> Enum.uniq()
    mainRepoClassNames = SchoolCollegeRegisterRepo.getMainRepoClass(conn)
    listOfClass = Enum.reduce(mainRepoClassNames["classes"], [], fn k, acc ->
      acc ++ k["class"]
    end)
    listOfClass -- listOfClassName
  end


  def createGroup(changeset, params, name) do
    currentTime = NaiveDateTime.utc_now
    userObjectId = decode_object_id(params["user_id"])
    insertDocs = %{
      "adminId" => userObjectId,
      "allowPostAll" => false,
      "isAdminChangeAllowed" => true,
      "isPostShareAllowed" => false,
      "name" => changeset.name,
      "category" => "school",
      "subCategory" => changeset.subCategory,
      "affiliatedBoard" => changeset.board,
      "type" => "private",
      "isActive" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "trialStartPeriod" => "#{currentTime}",
      "trialEndPeriod" => "#{NaiveDateTime.add(currentTime, 30*24*60*60)}",
      "academicYears" => [
        %{
          "academicStartYear" => changeset.academicStartYear,
          "academicEndYear" => changeset.academicEndYear,
          "currentYear" => true
        }
      ],
      "medium" => changeset.medium,
      "university" => changeset.university,
    }
    insertDocs = if Map.has_key?(changeset, :appName) do
      Map.put_new(insertDocs, "appName", changeset.appName)
    else
      insertDocs
    end
    insertDocs = if Map.has_key?(changeset, :logo) do
      Map.put_new(insertDocs, "logo", changeset.logo)
    else
      insertDocs
    end
    insertDocs = if Map.has_key?(changeset, :address) do
      Map.put_new(insertDocs, "address", changeset.address)
    else
      insertDocs
    end
    insertDocs = if Map.has_key?(changeset, :location) do
      Map.put_new(insertDocs, "location", changeset.location)
    else
      insertDocs
    end
    {:ok , newInsertedId} = SchoolCollegeRegisterRepo.createGroup(insertDocs)
    groupObjectId = newInsertedId.inserted_id
    createTeams(userObjectId, groupObjectId, changeset)
     #get name from user table for staff register
     insertToStaffDb(userObjectId, groupObjectId, name)
  end


  defp createTeams(userObjectId, groupObjectId, changeset) do
    # to create section based on users
    sections = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
                "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    insertTeamDoc = Enum.reduce(changeset.classSection, [], fn k , acc ->
      list = if k["noOfSection"] > 0 do
        classTypeId = SchoolCollegeRegisterRepo.getClassTypeId(k["className"], changeset.board, changeset.subCategory)
        for x <- 1..k["noOfSection"] do
          %{
            "adminId" => userObjectId,
            "allowTeamPostAll" => false,
            "allowTeamPostCommentAll" => false,
            "allowUserToAddOtherUser" => false,
            "class" => true,
            "enableAttendance" => true,
            "enableGps" => false,
            "groupId" => groupObjectId,
            "insertedAt" => bson_time(),
            "isActive" => true,
            "name" => k["className"]<>"-"<>Enum.at(sections, x-1),
            "updatedAt" => bson_time(),
            "gruppieClassName" => k["className"],
            "academicStartYear" => changeset.academicStartYear,
            "academicEndYear" => changeset.academicEndYear,
            "subCategory" => changeset.subCategory,
            "classTypeId" => classTypeId["classTypeId"]
          }
        end
      else
        []
      end
      acc ++ list
    end)
    {:ok, newTeamInsertedIds} = SchoolCollegeRegisterRepo.insertTeamsToDb(insertTeamDoc)
    newTeamIds =  Map.values(newTeamInsertedIds.inserted_ids)
    groupTeamMembers(userObjectId, groupObjectId, newTeamIds)
  end


  defp groupTeamMembers(userObjectId, groupObjectId, newTeamIds) do
    teams = for teamId <- newTeamIds do
      %{
        "allowedToAddComment" => true,
        "allowedToAddPost" => true,
        "allowedToAddUser" => true,
        "insertedAt" => bson_time(),
        "isTeamAdmin" => true,
        "teamId" => teamId,
        "updatedAt" => bson_time(),
      }
    end
    insertGroupTeamMembersDoc =  %{
      "userId" => userObjectId,
      "groupId" => groupObjectId,
      "canPost" => true,
      "isAdmin" => true,
      "isActive" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
      "teams" => teams
    }
    SchoolCollegeRegisterRepo.insertGroupTeamMembers(insertGroupTeamMembersDoc)
  end


  defp insertToStaffDb(userObjectId, groupObjectId, name) do
    staffInsertDoc = %{
      "name" => name,
      "userId" => userObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "insertedAt" => bson_time(),
      "updatedAt" => bson_time(),
    }
    SchoolCollegeRegisterRepo.insertStaff(staffInsertDoc)
  end


  def getTeamDetails(groupObjectId, userObjectId, params) do
    className = SchoolCollegeRegisterRepo.getTeamDetailsByClassName(groupObjectId, params["className"])
    #to insert section for the class
    {:ok, count} = SchoolCollegeRegisterRepo.getClassCount(groupObjectId, params["className"])
    sections = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    #to insert new section for same class with same gruppie name
    if count > 0 do
      insertNewTeam = %{
        "adminId" => userObjectId,
        "allowTeamPostAll" => false,
        "allowTeamPostCommentAll" => false,
        "allowUserToAddOtherUser" => false,
        "class" => true,
        "enableAttendance" => true,
        "enableGps" => false,
        "groupId" => groupObjectId,
        "insertedAt" => bson_time(),
        "isActive" => true,
        "classTypeId" => className["classTypeId"],
        "name" => params["className"]<>"-"<>Enum.at(sections, count),
        "updatedAt" => bson_time(),
        "gruppieClassName" => params["className"],
        "academicStartYear" => className["academicStartYear"],
        "academicEndYear" => className["academicEndYear"],
        "subCategory" => className["subCategory"],
      }
      {:ok, newTeamInsertedIds} = SchoolCollegeRegisterRepo.addNewTeam(insertNewTeam)
      # to check whether group team created for user id
      {:ok, count} = SchoolCollegeRegisterRepo.checkUserGroupExists(groupObjectId, userObjectId)
      if count > 0 do
        teamDoc = %{
          "allowedToAddComment" => true,
          "allowedToAddPost" => true,
          "allowedToAddUser" => true,
          "insertedAt" => bson_time(),
          "isTeamAdmin" => true,
          "teamId" => newTeamInsertedIds.inserted_id,
          "updatedAt" => bson_time(),
        }
        SchoolCollegeRegisterRepo.pushTogroupTeamDoc(groupObjectId, userObjectId, teamDoc)
      end
    else
      boardandCategory = SchoolCollegeRegisterRepo.getBoardandCategory(groupObjectId)
      # to create new teams
      insertTeamDoc = if params["noOfSection"] > 0 do
            map = %{
              "adminId" => userObjectId,
              "allowTeamPostAll" => false,
              "allowTeamPostCommentAll" => false,
              "allowUserToAddOtherUser" => false,
              "class" => true,
              "enableAttendance" => true,
              "enableGps" => false,
              "groupId" => groupObjectId,
              "insertedAt" => bson_time(),
              "isActive" => true,
              "name" => params["className"]<>"-"<>Enum.at(sections, params["noOfSection"]-1),
              "updatedAt" => bson_time(),
              "gruppieClassName" => params["className"],
              "subCategory" => boardandCategory["subCategory"],
              "classTypeId" => params["classTypeId"]
              }
              Enum.reduce(boardandCategory["academicYears"], [], fn k, _acc ->
                map
                |> Map.put("academicStartYear", k["academicStartYear"])
                |> Map.put("academicEndYear", k["academicEndYear"])
              end)
        else
          []
        end
      {:ok, newTeamInsertedIds} = SchoolCollegeRegisterRepo.addNewTeam(insertTeamDoc)
      newTeamId = newTeamInsertedIds.inserted_id
      teamDoc = %{
        "allowedToAddComment" => true,
        "allowedToAddPost" => true,
        "allowedToAddUser" => true,
        "insertedAt" => bson_time(),
        "isTeamAdmin" => true,
        "teamId" => newTeamId,
        "updatedAt" => bson_time(),
      }
      SchoolCollegeRegisterRepo.pushTogroupTeamDoc(groupObjectId, userObjectId, teamDoc)
    end
  end



  def getboards(conn, params) do
    SchoolCollegeRegisterRepo.getBoards(conn,params)
  end


  def addUniversity(params) do
    SchoolCollegeRegisterRepo.addUniversity(params)
  end


  def getUniversity(_conn, params) do
    SchoolCollegeRegisterRepo.getUniversity(params)
  end


  def addMedium(params) do
    SchoolCollegeRegisterRepo.addMedium(params)
  end


  def addMediumNew(params) do
    SchoolCollegeRegisterRepo.addMediumNew(params)
  end


  def getMedium(_conn, params) do
    SchoolCollegeRegisterRepo.getMedium(params)
  end


  def addTypeOfCampus(_conn, params) do
    SchoolCollegeRegisterRepo.addTypeOfCampus(params)
  end

  def getTypeOfCampus(_conn, params) do
    SchoolCollegeRegisterRepo.getTypeOfCampus(params)
  end


  def deleteClassCreated(groupObjectId, className) do
    SchoolCollegeRegisterRepo.deleteClassCreated(groupObjectId, className)
  end


  def createTeam(conn, changeset, group_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    SchoolCollegeRegisterRepo.createTeam(loginUser, changeset, groupObjectId)
  end


  def getClassListWithSections(groupObjectId, board, subCategory) do
    #to get classList from master repo
    masterClasslist = SchoolCollegeRegisterRepo.getClassListFromMaster(board, subCategory)
    Enum.reduce(masterClasslist["classes"], [], fn k, acc ->
      map = %{
        "classTypeId" => k["classTypeId"],
        "type" => k["type"],
      }
      #check no of section of each class
      sectionList = for class <- k["class"] do
        {:ok, sectionCount} = SchoolCollegeRegisterRepo.getClassCountFromTeams(groupObjectId, class)
        %{
          "className" => class,
          "noOfSections" => sectionCount
        }
      end
      map = map
      |> Map.put("class", sectionList)
      acc ++ [map]
    end)
  end


  def getTrailPeriodRemainingDays(trialEndPeriod) do
    navieTrailEndPeriodConversion = NaiveDateTime.from_iso8601!(trialEndPeriod)
    dateCompare = NaiveDateTime.diff(navieTrailEndPeriodConversion, NaiveDateTime.utc_now)
    Kernel.trunc(dateCompare/ 86400)
  end
end
