defmodule GruppieWeb.Repo.UserBlockRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @group_team_coll "group_team_members"

  @teams_col "teams"


  def blockUser(groupObjectId, userObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "teams.$.blocked" => true,
        "teams.$.updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @group_team_coll, filter, update)
    updateTeam(groupObjectId, userObjectId, teamObjectId)
  end


  defp updateTeam(groupObjectId, userObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
      "blockedUsers" => %{
        "$exists" => true
      }
    }
    {:ok, count} =  Mongo.count(@conn, @teams_col, filter)
    # IO.puts "#{count}"
    if count == 0 do
      filter = %{
        "_id" => teamObjectId,
        "groupId" => groupObjectId,
        "isActive" => true,
      }
      update = %{
        "$set" =>   %{
          "blockedUsers" => [
            encode_object_id(userObjectId)
          ],
          "updatedAt" =>  bson_time()
        }
      }
      Mongo.update_one(@conn, @teams_col, filter, update)
    else
      filter = %{
        "_id" => teamObjectId,
        "groupId" => groupObjectId,
        "isActive" => true,
      }
      update = %{
        "$push" => %{
         "blockedUsers" =>
         encode_object_id(userObjectId)
        },
        "$set" => %{
          "updatedAt" =>  bson_time()
        }
      }
      Mongo.update_one(@conn, @teams_col, filter, update)
    end

  end


  def leaveTeam(groupObjectId, userObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
      "teams.teamId" => teamObjectId,
    }
    # IO.puts "#{filter}"
    update = %{
      "$pull" => %{
        "teams" => %{
          "teamId" => teamObjectId
        }
      }
    }
    Mongo.update_one(@conn, @group_team_coll, filter, update)
  end


  def unblockUser(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$unset" => %{
        "teams.$.blocked" => 1
      }
    }
    Mongo.update_one(@conn, @group_team_coll, filter, update)
    #delete user id from blocked list
    pullUserFromBlockedList(groupObjectId, teamObjectId, userObjectId)
  end


  defp pullUserFromBlockedList(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$pull" => %{
        "blockedUsers" => encode_object_id(userObjectId)
      }
    }
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def changeAdmin(groupObjectId, userObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    # IO.puts "#{filter}"
    project = %{
      "_id" => 1,
    }
    {:ok, count} = Mongo.count(@conn, @group_team_coll, filter, [projection: project])
    if count == 0 do
      {:adminChange, "User Does Not Exists In Team Please Add And Change Admin"}
    else
      filter1 = %{
        "_id" => teamObjectId,
        "groupId" => groupObjectId,
        "isActive" => true,
      }
      project = %{
        "adminId" => 1,
        "_id" => 0,
      }
      adminId = Mongo.find_one(@conn, @teams_col, filter1, [projection: project])
      #change permission of old admin
      changePermissionForOldUser(groupObjectId, teamObjectId, adminId["adminId"])
      #change permission of new admin
      changePermissionForNewAdmin(filter1, filter, userObjectId)
    end
  end


  defp changePermissionForOldUser(groupObjectId, teamObjectId, adminObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => adminObjectId,
      "isActive" => true,
      "teams.teamId" => teamObjectId,
    }
    update = %{
      "$set" => %{
        "teams.$.allowedToAddComment" => true,
        "teams.$.allowedToAddPost" => true,
        "teams.$.allowedToAddUser" => false,
        "teams.$.isTeamAdmin" => false,
      }
    }
    Mongo.update_one(@conn, @group_team_coll, filter, update)
  end


  defp changePermissionForNewAdmin(filter1, filter, userObjectId) do
    update = %{
      "$set" => %{
        "adminId" => userObjectId
      }
    }
    Mongo.update_one(@conn, @teams_col, filter1, update)
    update = %{
      "$set" => %{
        "teams.$.allowedToAddComment" => true,
        "teams.$.allowedToAddPost" => true,
        "teams.$.allowedToAddUser" => true,
        "teams.$.isTeamAdmin" => true,
      }
    }
    Mongo.update_one(@conn, @group_team_coll, filter, update)
  end
end
