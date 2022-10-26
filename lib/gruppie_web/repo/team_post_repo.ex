defmodule GruppieWeb.Repo.TeamPostRepo do

  @conn :mongo

  @post_col "posts"

  @groups_col "groups"


  def add(changeset, loginUserId, groupObjectId, teamObjectId) do
    changeset = changeset
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:teamId, teamObjectId)
    |> Map.put(:userId, loginUserId)
    |> Map.put(:type, "teamPost")
    Mongo.insert_one(@conn, @post_col, changeset)
  end


  def incrementSubBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalSubBoothDiscussion" => 1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end


  def incrementBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalBoothsDiscussion" => 1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end
end
