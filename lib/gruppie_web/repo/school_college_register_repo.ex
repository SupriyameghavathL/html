defmodule GruppieWeb.Repo.SchoolCollegeRegisterRepo do
  import GruppieWeb.Handler.TimeNow
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.SchoolCollege

  @conn :mongo

  @board_class_col "boards_class_db"

  @board_db "board_db"

  @group_col "groups"

  @team_col "teams"

  @group_team_members_col "group_team_members"

  @university_col "university_db"

  @medium_col "language_medium_db"

  @typeOfCampus_col "type_Of_Campus_db"

  @new_medium_col "medium_db"

  @staff_data_base "staff_database"


  def addBoardClassToDb(params) do
    Mongo.insert_one(@conn, @board_class_col, params)
  end


  def addBoardToDb(params) do
    Mongo.insert_one(@conn, @board_db, params)
  end


  def createGroup(insertDoc) do
    Mongo.insert_one(@conn, @group_col, insertDoc)
  end


  def getBoardClasses(classTypeId) do
    filter = %{
      "classes.classTypeId" => %{
        "$in" => classTypeId
      }
    }
    arrayFilter = %{
      "board_class" => %{
        "$filter" => %{
          "input" => "$classes",
          "cond" => %{
            "$in" => [
              "$$this.classTypeId" , classTypeId
            ]
          }
        }
      }
    }
    project = %{
      "_id" => 0,
      "board_class" => 1
    }
    pipeline = [%{"$match" => filter}, %{"$addFields" => arrayFilter}, %{"$project" => project}]
    find = Mongo.aggregate(@conn, @board_class_col, pipeline)
    |> Enum.to_list
    |> hd
    find["board_class"]
  end


  def insertTeamsToDb(insertTeamDoc) do
    Mongo.insert_many(@conn, @team_col, insertTeamDoc)
  end


  # def insertTeamsToDbNew(insertTeamDoc) do
  #   Mongo.insert_one(@conn, @team_col, insertTeamDoc)
  # end


  def insertGroupTeamMembers(groupTeamMembersDoc) do
    Mongo.insert_one(@conn, @group_team_members_col, groupTeamMembersDoc)
  end


  def getSchoolClassList(subCategory, board) do
    filter = %{
      "subCategory" => subCategory,
      "board" => board
    }
    project = %{
      "_id" => 0,
    }
    Mongo.find_one(@conn, @board_class_col, filter, [projection: project])
  end


  def getTeamDetailsByClassName(groupObjectId, className) do
    filter = %{
      "groupId" => groupObjectId,
      "gruppieClassName" => className,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "academicStartYear" => 1,
      "academicEndYear" => 1,
      "subCategory" => 1,
      "classTypeId" => 1,
    }
    Mongo.find_one(@conn, @team_col, filter, [projection: project])
  end


  def addNewTeam(inserNewTeam) do
    Mongo.insert_one(@conn, @team_col, inserNewTeam)
  end


  def pushTogroupTeamDoc(groupObjectId, userObjectId, teamDoc) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
    }
    update = %{
      "$push" => %{
        "teams" => teamDoc
      }
    }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end


  def getCreatedClassList(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
    }
    project = %{
      "_id" => 0,
      "gruppieClassName" => 1,
    }
    Mongo.find(@conn, @team_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getMainRepoClass(_conn) do
    filter = %{

    }
    project = %{
      "classes" => 1,
      "_id" => 0,
    }
    classes = Mongo.find(@conn,@board_class_col, filter, [projection: project])
    |> Enum.to_list
    hd(classes)
  end


  def getClassCount(groupObjectId, name) do
    filter = %{
      "groupId" => groupObjectId,
      "gruppieClassName" => name,
      "isActive" => true,
    }
    Mongo.count(@conn, @team_col, filter)
  end


  def checkUserGroupExists(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isAdmin" => true,
      "isActive" => true,
    }
    Mongo.count(@conn, @group_team_members_col, filter)
  end


  def getBoards(_conn, params) do
    filter = %{
      "campusType.type" => params["campusType"]
    }
    project = %{
      "campusType.boards.$" => 1,
    }
   boards = Mongo.find_one(@conn, @board_db, filter, [projection: project])
   hd(boards["campusType"])
  end

  def addUniversity(params) do
    Mongo.insert_one(@conn, @university_col, params)
  end


  def getUniversity(params) do
    filter = %{
      "universities.board" => params["board"]
    }
    project = %{
      "universities.university.$" => 1,
    }
    university = Mongo.find_one(@conn, @university_col, filter, [projection: project])
    hd(university["universities"])
  end


  def addMedium(params) do
    Mongo.insert_one(@conn, @medium_col, params)
  end


  def addMediumNew(params) do
    Mongo.insert_one(@conn, @new_medium_col, params)
  end


  def getMedium(params) do
    list = if Map.has_key?(params, "board") do
      filter = %{
        "medium.board" => params["board"]
      }
      project = %{
        "medium.language.$" => 1,
        "_id" => 0,
      }
      Mongo.find_one(@conn,@new_medium_col, filter, [projection: project])
    else
      filter = %{
        "medium.board" => "OTHERS"
      }
      project = %{
        "medium.language.$" => 1,
        "_id" => 0,
      }
      Mongo.find_one(@conn, @new_medium_col, filter, [projection: project])
    end
    hd(list["medium"])
  end

  def addTypeOfCampus(params) do
    Mongo.insert_one(@conn, @typeOfCampus_col, params)
  end

  def getTypeOfCampus(_params) do
    filter = %{

    }
    Mongo.find_one(@conn, @typeOfCampus_col, filter)
  end


  def deleteClassCreated(groupObjectId, className) do
    filter = %{
      "groupId" => groupObjectId,
      "gruppieClassName" => className,
      "isActive" => true,
    }
    project = %{
      "_id" => 1
    }
    list =  Mongo.find(@conn, @team_col, filter, [projection: project, sort: %{"_id" => -1}, limit: 1])
    |> Enum.to_list
    |> hd()
    filter1 = %{
      "_id" => list["_id"],
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "isActive" => false,
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @team_col, filter1, update)
  end


  def getClassTypeId(className, board, _subCategory) do
    filter = %{
      "board" => board,
      "classes.class" => className,
    }
    project = %{
      "_id" => 0,
      "classes.classTypeId.$" => 1,
    }
    classesTypeId = Mongo.find_one(@conn, @board_class_col, filter, [projection: project])
    #IO.puts "#{classesTypeId}"
    hd(classesTypeId["classes"])
  end


  def getBoardandCategory(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "academicYears.currentYear" => true,
    }
    project = %{
      "academicYears.academicStartYear.$" => 1,
      "academicYears.academicEndYear" => 1,
      "affiliatedBoard" => 1,
      "subCategory" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_col, filter, [projection: project])
  end


  def pushTogroupTeamDocClassRegister(groupObjectId, userObjectId, teams) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
    }
    update = %{
      "$push" => %{
        "teams" => %{
          "$each" => teams,
        }
      },
      "$set" => %{
        "updatedAt" => bson_time(),
      }
    }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end


  def createTeam(loginUser, changeset, groupObjectId) do
    #create new object id as team id
    team_id = new_object_id()
    team_create_doc = SchoolCollege.insert_team(team_id, loginUser["_id"], groupObjectId, changeset)
    Mongo.insert_one(@conn, @team_col, team_create_doc)
    #insert into group_team_members doc
    team_members_doc = SchoolCollege.insertGroupTeamMembersForLoginUser(team_id, loginUser)
    filter = %{
      "groupId" => groupObjectId ,
      "userId" => loginUser["_id"],
    }
    update = %{
      "$push" => %{
        "teams" => team_members_doc ,
        },
        "$set" => %{
          "updateAt" => bson_time(),
        }
      }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
    {:ok, encode_object_id(team_id)}
  end


  def getClassListFromMaster(board, subcategory) do
    filter = %{
      "board" => board,
      "subCategory" => subcategory,
    }
    project = %{
      "classes" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @board_class_col, filter, [projection: project])
  end


  def getClassCountFromTeams(groupObjectId, className) do
    filter = %{
      "groupId" => groupObjectId,
      "gruppieClassName" => className,
      "isActive" =>  true,
    }
    Mongo.count(@conn, @team_col, filter)
  end


  def insertStaff(staffInsertDoc) do
    Mongo.insert_one(@conn, @staff_data_base, staffInsertDoc)
  end


end
