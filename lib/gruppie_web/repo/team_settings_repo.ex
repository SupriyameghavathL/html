defmodule GruppieWeb.Repo.TeamSettingsRepo do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @group_team_members_col "group_team_members"

  @team_col "teams"

  @groups_coll "groups"


  def allowTeamPostAll(groupObjectId, teamObjectId, loginUserId) do
    team = TeamRepo.get(encode_object_id(teamObjectId))
    filterTeam = %{ "_id" => teamObjectId }
    #get all team users
    ##filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    ##project = %{ "_id" => 0, "userId" => 1 }
    ##pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$limit" => 100} ]
    ##cursor = Mongo.aggregate(@conn, @view_teams_col, pipeline)
    #get all team users
    filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    project = %{ "_id" => 0, "userId" => 1 }
    cursor = Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
    if length(Enum.to_list(cursor)) > 0 do
      Enum.reduce(cursor, [], fn k, _acc ->
        #update team setting for the user from above
        filterUpdate = %{ "userId" => k["userId"], "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
        {updateTeam, update} = if team["allowTeamPostAll"] == true do
          %{ "$set" => %{ "allowTeamPostAll" => false, "updatedAt" => bson_time() } }
          #update to false
          %{ "$set" => %{ "teams.$.allowedToAddPost" => false, "teams.$.updatedAt" => bson_time() } }
        else
          if team["allowTeamPostAll"] == false do   ## !team["allowTeamPostAll"] because in constituency i am not setting allowTeamPostAll
            %{ "$set" => %{ "allowTeamPostAll" => true, "updatedAt" => bson_time() } }
            #update to true
            %{ "$set" => %{ "teams.$.allowedToAddPost" => true, "teams.$.updatedAt" => bson_time() } }
          end
        end
        Mongo.update_one(@conn, @team_col, filterTeam, updateTeam)
        Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
      end)
    end
  end


  def allowTeamPostCommentAll(groupObjectId, teamObjectId, loginUserId) do
    team = TeamRepo.get(encode_object_id(teamObjectId))
    filterTeam = %{ "_id" => teamObjectId }
    #get all team users
    ##filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    ##project = %{ "_id" => 0, "userId" => 1 }
    ##pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
    ##cursor = Mongo.aggregate(@conn, @view_teams_col, pipeline)
    #get all team users
    filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    project = %{ "_id" => 0, "userId" => 1 }
    cursor = Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
    if length(Enum.to_list(cursor)) > 0 do
      Enum.reduce(cursor, [], fn k, _acc ->
        #update team setting for the user from above
        filterUpdate = %{ "userId" => k["userId"], "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
        {updateTeam, update} = if team["allowTeamPostCommentAll"] == true do
          %{ "$set" => %{ "allowTeamPostCommentAll" => false, "updatedAt" => bson_time() } }
          #update to false
          %{ "$set" => %{ "teams.$.allowedToAddComment" => false, "teams.$.updatedAt" => bson_time() } }
        else
          if team["allowTeamPostCommentAll"] == false do
            %{ "$set" => %{ "allowTeamPostCommentAll" => true, "updatedAt" => bson_time() } }
            #update to true
            %{ "$set" => %{ "teams.$.allowedToAddComment" => true, "teams.$.updatedAt" => bson_time() } }
          end
        end
        Mongo.update_one(@conn, @team_col, filterTeam, updateTeam)
        Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
      end)
    else
      {:ok, "No other users in this team"}
    end
  end


  def disallowUserToAddOtherUsers(loginUserId, groupObjectId, teamObjectId) do
    filterTeam = %{ "groupId" => groupObjectId, "_id" => teamObjectId, "isActive" => true }
    #get all team users
    ##filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    ##project = %{ "_id" => 0, "userId" => 1 }
    ##pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
    ##cursor = Mongo.aggregate(@conn, @view_teams_col, pipeline)
    #get all team users
    filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    project = %{ "_id" => 0, "userId" => 1 }
    cursor = Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
    Enum.reduce(cursor, [], fn k, _acc ->
      updateTeam = %{ "$set" => %{ "allowUserToAddOtherUser" => false, "updatedAt" => bson_time() } }
      #update team setting for the user from above
      filterUpdate = %{ "userId" => k["userId"], "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
      #update to false
      update = %{ "$set" => %{ "teams.$.allowedToAddUser" => false, "teams.$.updatedAt" => bson_time() } }
      Mongo.update_one(@conn, @team_col, filterTeam, updateTeam)
      Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    end)
  end


  def allowUserToAddOtherUsers(loginUserId, groupObjectId, teamObjectId) do
    filterTeam = %{ "groupId" => groupObjectId, "_id" => teamObjectId, "isActive" => true }
    #get all team users
    ##filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    ##project = %{ "_id" => 0, "userId" => 1 }
    ##pipeline = [ %{"$match" => filter}, %{"$project" => project} ]
    ##cursor = Mongo.aggregate(@conn, @view_teams_col, pipeline)
    #get all team users
    filter = %{ "groupId" => groupObjectId, "teams.teamId" => teamObjectId, "userId" => %{ "$nin" => [loginUserId] } }
    project = %{ "_id" => 0, "userId" => 1 }
    cursor = Mongo.find(@conn, @group_team_members_col, filter, [projection: project])
    Enum.reduce(cursor, [], fn k, _acc ->
      updateTeam = %{ "$set" => %{ "allowUserToAddOtherUser" => true, "updatedAt" => bson_time() } }
      #update team setting for the user from above
      filterUpdate = %{ "userId" => k["userId"], "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
      #update to false
      update = %{ "$set" => %{ "teams.$.allowedToAddUser" => true, "teams.$.updatedAt" => bson_time() } }
      Mongo.update_one(@conn, @team_col, filterTeam, updateTeam)
      Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    end)
  end


  def findIndividuallyAndDisAllowUserToAddOtherUsers(groupObjectId, teamObjectId, userObjectId) do
    #update team setting for the user from above
    filterUpdate = %{ "userId" => userObjectId, "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
    project = %{ "teams.$" => 1, "_id" => 0 }
    find = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filterUpdate, [projection: project])))
    cursor = hd(find["teams"])
    update = if cursor["allowedToAddUser"] == true do
      #update to false
      %{ "$set" => %{ "teams.$.allowedToAddUser" => false, "teams.$.updatedAt" => bson_time() } }
    else
      #update to true
      %{ "$set" => %{ "teams.$.allowedToAddUser" => true, "teams.$.updatedAt" => bson_time() } }
    end
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
  end


  def findIndividuallyAndAllowUserToAddTeamPost(groupObjectId, teamObjectId, userObjectId) do
    #update team setting for the user from above
    filterUpdate = %{ "userId" => userObjectId, "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
    project = %{ "teams.$" => 1, "_id" => 0 }
    find = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filterUpdate, [projection: project])))
    cursor = hd(find["teams"])
    update = if cursor["allowedToAddPost"] == true do
      #update to false
      %{ "$set" => %{ "teams.$.allowedToAddPost" => false, "teams.$.updatedAt" => bson_time() } }
    else
      #update to true
      %{ "$set" => %{ "teams.$.allowedToAddPost" => true, "teams.$.updatedAt" => bson_time() } }
    end
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
  end


  def findIndividuallyAndAllowUserToAddTeamPostComment(groupObjectId, teamObjectId, userObjectId) do
    #update team setting for the user from above
    filterUpdate = %{ "userId" => userObjectId, "groupId" => groupObjectId, "teams.teamId" => teamObjectId }
    project = %{ "teams.$" => 1, "_id" => 0 }
    find = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filterUpdate, [projection: project])))
    cursor = hd(find["teams"])
    update = if cursor["allowedToAddComment"] == true do
      #update to false
      %{ "$set" => %{ "teams.$.allowedToAddComment" => false, "teams.$.updatedAt" => bson_time() } }
    else
      #update to true
      %{ "$set" => %{ "teams.$.allowedToAddComment" => true, "teams.$.updatedAt" => bson_time() } }
    end
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
  end



  def getTeamSettingDetails(groupObjectId, teamObjectId) do
    filter = %{"_id" => teamObjectId, "groupId" => groupObjectId, "isActive" => true}
    hd(Enum.to_list(Mongo.find(@conn, @team_col, filter)))
  end


  def removeUserFromTeam(groupObjectId, teamObjectId, userObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => userObjectId }
    update = %{ "$pull" => %{ "teams" => %{ "teamId" => teamObjectId } } }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
  end


  def updateTeamDetails(changeset, _groupObjectId, teamObjectId, _loginUserId) do
    filter = %{ "_id" => teamObjectId }
    # if Map.has_key?(changeset, :image) do
    #   update = %{"$set" => %{"name" => changeset.name, "image" => changeset.image, "updatedAt" => bson_time()}}
    # else
    #   update = %{"$set" => %{"name" => changeset.name, "updatedAt" => bson_time()}, "$unset" =>%{"image" => ""}}
    # end
    update = %{"$set" => changeset}
    Mongo.update_one(@conn, @team_col, filter, update)
  end



  def deleteTeamPermanently(_loginUserId, _groupObjectId, teamObjectId) do
    #first delete from group_team_members
    ##removeUserFromTeam(groupObjectId, teamObjectId, loginUserId)
    #delete team from teams collection
    ##filter = %{ "_id" => teamObjectId, "groupId" => groupObjectId, "adminId" => loginUserId }
    ##Mongo.delete_one(@conn, @team_col, filter)
    filter = %{ "_id" => teamObjectId }
    update = %{ "$set" => %{ "isActive" => false, "isArchivedTeam" => "", "updatedAt" => bson_time() } }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def archiveTeam(groupObjectId, teamObjectId) do
    filter = %{ "_id" => teamObjectId, "groupId" => groupObjectId, "isActive" => true }
    update = %{ "$set" => %{ "isActive" => false, "isArchivedTeam" => true, "updatedAt" => bson_time() } }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def getArchiveTeams(loginUserId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "adminId" => loginUserId, "isActive" => false, "isArchivedTeam" => true }
    Enum.to_list(Mongo.find(@conn, @team_col, filter))
  end


  def restoreArchiveTeam(_groupObjectId, teamObjectId) do
    filter = %{ "_id" => teamObjectId }
    update = %{ "$set" => %{ "isActive" => true, "isArchivedTeam" => false, "updatedAt" => bson_time() } }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def findEnableOrDisableGps(_groupObjectId, teamObjectId) do
    filter = %{ "_id" => teamObjectId}
    project = %{ "_id" => 0, "enableGps" => 1 }
    cursor = hd(Enum.to_list(Mongo.find(@conn, @team_col, filter, [projection: project])))
    update = if cursor["enableGps"] == false do
      %{ "$set" => %{"enableGps" => true} }
    else
      %{ "$set" => %{"enableGps" => false} }
    end
    Mongo.update_one(@conn, @team_col, filter, update)
    enable = hd(Enum.to_list(Mongo.find(@conn, @team_col, filter, [projection: project])))
    {:ok, enable["enableGps"]}
  end


  def findEnableOrDisableAttendance(_groupObjectId, teamObjectId) do
    filter = %{"_id" => teamObjectId}
    project = %{ "_id" => 0, "enableAttendance" => 1 }
    cursor = hd(Enum.to_list(Mongo.find(@conn, @team_col, filter, [projection: project])))
    update = if cursor["enableAttendance"] == false do
      %{ "$set" => %{"enableAttendance" => true} }
    else
      %{ "$set" => %{"enableAttendance" => false} }
    end
    Mongo.update_one(@conn, @team_col, filter, update)
    enable = hd(Enum.to_list(Mongo.find(@conn, @team_col, filter, [projection: project])))
    {:ok, enable["enableAttendance"]}
  end



  def changeTeamAdmin(loginUserId, groupObjectId, teamObjectId, userObjectId) do
    #update isTeamAdmin false for login user in group_team_members
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "teams.teamId" => teamObjectId
    }
    update = %{ "$set" => %{ "teams.$.isTeamAdmin" => false, "teams.$.allowedToAddComment" => false,
                "teams.$.allowedToAddPost" => false } }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
    #update isTeamAdmin true for the new user
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teams.teamId" => teamObjectId
    }
    update = %{ "$set" => %{ "teams.$.isTeamAdmin" => true, "teams.$.allowedToAddComment" => true,
                "teams.$.allowedToAddPost" => true, "teams.$.allowedToAddUser" => true } }
    Mongo.update_one(@conn, @group_team_members_col, filter, update)
    #update adminId in teams collection
    filter = %{
      "_id" => teamObjectId
    }
    update = %{ "$set" => %{ "adminId" => userObjectId } }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def decrementWorkersCount(groupObjectId, boothTeamId) do
    filter = %{
      "_id" => boothTeamId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "workersCount" => -1
      }
    }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def decrementTotalUserCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalUsersCount"  => -1,
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
    feederMap =  Mongo.find_one(@conn, @groups_coll, filter, [projection: %{"feederMap" => 1, "_id" => 0}])
    if Map.has_key?(feederMap, "feederMap") do
      totalUserCountShortForm = countHelp(feederMap["feederMap"]["totalUsersCount"])
      filter = %{
        "_id" => groupObjectId,
        "isActive" => true,
      }
      update = %{
        "$set" => %{
          "feederMap.totalUsersInWords" => totalUserCountShortForm,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  defp countHelp(totalUsersCount) do
    cond do
      totalUsersCount < 999 ->
        Integer.to_string(totalUsersCount)
      totalUsersCount < 9999 ->
        decimalConversion = Float.floor(totalUsersCount/1000, 2)
        Float.to_string(decimalConversion)<>"k+"
      totalUsersCount < 99999 ->
        decimalConversion = Float.floor(totalUsersCount/10000, 2)
        Float.to_string(decimalConversion)<>"k+"
      totalUsersCount < 999999 ->
        decimalConversion = Float.floor(totalUsersCount/100000, 2)
        Float.to_string(decimalConversion)<>"L+"
      totalUsersCount < 9999999 ->
        decimalConversion = Float.floor(totalUsersCount/1000000, 2)
        Float.to_string(decimalConversion)<>"L+"
    end
  end


  def decrementUserCount(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "isActive" => true,
      "groupId" => groupObjectId,
    }
    update = %{
      "$inc" => %{
        "usersCount" => -1
      }
    }
    Mongo.update_one(@conn, @team_col, filter, update)
  end


  def decrementBoothCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
   update = %{
    "$inc" => %{
      "feederMap.totalBoothsCount" => -1
    }
   }
   Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def decrementSubBoothCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
   update = %{
    "$inc" => %{
      "feederMap.totalSubBoothsCount" => -1
    }
   }
   Mongo.update_one(@conn, @groups_coll, filter, update)
  end
end
