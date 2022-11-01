defmodule GruppieWeb.Repo.VoterAnalysisRepo do


  @conn :mongo

  @voter_coll "voters_details_db"

  @teams_coll "teams"

  @posts_coll "posts"

  @users_coll "users"

  @group_team_coll "group_team_members"


  def checkVoterListCreated(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @voter_coll, filter, [projection: project])
  end


  def insertDoc(insertDoc) do
    Mongo.insert_one(@conn, @voter_coll, insertDoc)
  end


  def pushToArray(groupObjectId, teamObjectId, voterDetailsMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "voterDetails" => voterDetailsMap
      }
    }
    Mongo.update_one(@conn, @voter_coll, filter, update)
  end


  def getVotersDetailsBooth(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "voterDetails" => 1,
    }
    Mongo.find_one(@conn, @voter_coll, filter, [projection: project])
  end


  def deleteVotersFromList(groupObjectId, teamObjectId, deletedUsersIds) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$pull" => %{
        "voterDetails" => %{
          "uniqueId" => %{
            "$in" => deletedUsersIds
          }
        }
      }
    }
    Mongo.update_many(@conn, @voter_coll, filter, update)
  end


  def getBoothsIds(groupObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "category" => "booth"
    }
    project = %{
      "_id" => 1,
    }
    list = Mongo.find(@conn, @teams_coll, filter, [projection: project])
    |> Enum.to_list()
    teamIdsList = for teamId <- list do
      teamId["_id"]
    end
    getBoothsDiscussion(groupObjectId, teamIdsList, params)
  end


  def getBoothsDiscussion(groupObjectId, teamIdsList, params) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => %{
        "$in" => teamIdsList
      },
      "isActive" => true,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      {:ok, pageCount} = pageCountBoothsPost(groupObjectId, teamIdsList)
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @posts_coll, filter, [sort: %{"_id" => -1}, skip: skip, limit: 15, ])
      |> Enum.to_list()
      [%{"pageCount" => pageCount}] ++ list
    else
      list = Mongo.find(@conn, @posts_coll, filter)
      |> Enum.to_list()
      [%{"pageCount" => 1}] ++ list
    end
  end


  def  pageCountBoothsPost(groupObjectId, teamIdsList) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => %{
        "$in" => teamIdsList
      },
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @posts_coll, filter, [projection: project])
  end


  def getUserDetails(boothWorkersIds, params) do
    filter = %{
      "_id" => %{
        "$in" => boothWorkersIds
      }
    }
    project = %{
      "name" => 1,
      "phone" => 1,
      "image" => 1,
      "_id" => 1,
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      {:ok, pageCount} = pageCountUsers(boothWorkersIds)
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @users_coll, filter, [projection: project, sort: %{"name" => 1}, skip: skip, limit: 15, ])
      |> Enum.to_list()
      [%{"pageCount" => pageCount}] ++ list
    else
      list = Mongo.find(@conn, @users_coll, filter)
      |> Enum.to_list()
      [%{"pageCount" => 1}] ++ list
    end
  end


  def  pageCountUsers(boothWorkersIds) do
    filter = %{
      "_id" => %{
        "$in" => boothWorkersIds
      }
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @users_coll, filter, [projection: project])
  end


  def getUserDetailsBasedOnFilter(boothWorkersIds, filter) do
    regexMap = %{ "$regex" => filter }
    filter = %{
      "searchName" => regexMap,
      "_id" => %{
        "$in" => boothWorkersIds
      }
    }
    project = %{
      "name" => 1,
      "phone" => 1,
      "image" => 1,
      "_id" => 1,
    }
    Mongo.find(@conn, @users_coll, filter, [projection: project, sort: %{"name" => 1}])
    |> Enum.to_list()
  end


  def getTeamUsersList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "userId" => 1,
      "_id" => 0,
    }
    Mongo.find(@conn, @group_team_coll, filter, [projection: project])
    |> Enum.to_list()
  end
end
