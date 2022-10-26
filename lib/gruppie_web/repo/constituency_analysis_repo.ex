defmodule  GruppieWeb.Repo.ConstituencyAnalysisRepo  do
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @panchayat_db "panchayat_database"

  @teams_coll "teams"

  @group_team_members "group_team_members"

  @users_coll "users"


  def getUserId(phone)  do
    filter = %{
      "phone" => phone,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
    }
    Mongo.find_one(@conn, @users_coll, filter, [projection: project])
  end


  def groupTeamCheck(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "userId" => userObjectId
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @group_team_members, filter, [projection: project])
  end


  def insertGroupTeamDoc(groupTeamDoc) do
    Mongo.insert_one(@conn, @group_team_members, groupTeamDoc)
  end


  def addZpTpToDb(changeSet) do
    Mongo.insert_one(@conn,  @panchayat_db, changeSet)
  end


  def getZpWardFromDb(groupObjectId, type1, type2) do
    filter = %{
      "groupId" => groupObjectId,
      "$and" => [
        %{
          "$or" => [
            %{"type" => type1},
            %{"type" => type2},
          ]
        },
      ],
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 1,
      "name" => 1,
      "type" => 1,
      "image" => 1,
      "adminId" => 1,
      "phone" => 1,
    }
    Mongo.find(@conn, @panchayat_db, filter, [projection: project])
    |> Enum.to_list()
  end


  def getTpFromDbByZpId(groupObjectId, zpObjectId, type) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => type,
      "zillaPanchayatId" => zpObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "type" => 1,
      "zillaPanchayatId" => 1,
    }
    Mongo.find(@conn, @panchayat_db, filter, [projection: project])
    |> Enum.to_list()
  end


  def getTpFromDb(groupObjectId, type) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => type,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "type" => 1,
      "zillaPanchayatId" => 1,
    }
    Mongo.find(@conn, @panchayat_db, filter, [projection: project])
    |> Enum.to_list()
  end


  def getZpName(panchayatObjectId) do
    filter = %{
      "_id" => panchayatObjectId,
      "isActive" => true,
    }
    project = %{
      "name" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn,  @panchayat_db, filter, [projection: project])
  end


  def editZpTpWard(groupObjectId, changeset, panchayatObjectId) do
    filter = %{
      "_id" => panchayatObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => changeset,
    }
    Mongo.update_one(@conn, @panchayat_db, filter, update)
  end


  def deleteZpTpWard(groupObjectId, panchayatObjectId) do
    filter = %{
      "_id" => panchayatObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "isActive" => false,
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @panchayat_db, filter, update)
  end


  def getCommitteeMapAndTeam(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "booth",
      "isActive" => true,
      "boothCommittees.defaultCommittee" => true,
    }
    project = %{
      "_id" => 1,
      "category" => 1,
      "boothCommittees.$" => 1,
    }
    Mongo.find_one(@conn, @teams_coll, filter, [projection: project])
  end


  def getTeamDetails(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "category" => "subBooth",
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 1,
      "category" => 1,
      "boothTeamId" => 1,
    }
    Mongo.find_one(@conn, @teams_coll, filter, [projection: project])
  end


  def getTeamIdAndBoothAdminId(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "category" => "booth",
    }
    project = %{
      "_id" => 1,
      "adminId" => 1,
      "name" => 1,
    }
    Mongo.find(@conn, @teams_coll, filter, [projection: project])
    |>Enum.to_list()
  end


  def checkSubBoothExists(groupObjectId, adminObjectId, boothTeamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "boothTeamId" => boothTeamObjectId,
      "adminId" => adminObjectId,
      "category" => "subBooth",
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 1,
    }
    Mongo.find(@conn, @teams_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def checkGroupTeamExists(groupObjectId, adminObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "userId" => adminObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @group_team_members, filter, [projection: project])
  end


  def pushToGroupTeamRepo(groupTeamMap, groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "teams" => groupTeamMap
      }
    }
    Mongo.update_one(@conn, @group_team_members, filter, update)
  end


  def getPanchayatDetails(panchayatObjectId) do
    filter = %{
      "_id" => panchayatObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "adminId" => 1,
    }
    Mongo.find_one(@conn, @panchayat_db, filter, [projection: project])
  end


  def getName(userId) do
    filter = %{
      "_id" => userId,
    }
    project = %{
      "name" => 1,
      "_id" => 1,
    }
    Mongo.find_one(@conn, @users_coll, filter, [projection: project])
  end


  def updateName(name, userId) do
    filter = %{
      "_id" => userId
    }
    update = %{
      "$set" => %{
        "name" => name,
        "searchName" => String.downcase(name),
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @users_coll, filter, update)
  end
end
