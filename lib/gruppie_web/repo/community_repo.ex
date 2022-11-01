defmodule GruppieWeb.Repo.CommunityRepo do
  alias GruppieWeb.Community
  alias GruppieWeb.Repo.TeamRepo
  import GruppieWeb.Handler.TimeNow


  @conn :mongo

  @group_team_members_coll "group_team_members"

  @groups_coll "groups"

  @users_coll "users"

  @community_coll "community_branches_db"

  @post_coll "posts"

  @teams_coll "teams"

  # @user_category_app "user_category_apps"


  def addCommunityUsersToGroupTeamMembersDoc(user, group, team, _changeset) do
    #IO.puts "#{changeset}"
    group_member_doc = Community.insertGroupTeamMemberForSubBoothMembers(user["_id"], group, team["_id"])
    Mongo.insert_one(@conn, @group_team_members_coll, group_member_doc)
    #add default team for new user
    if team["defaultTeam"] == true do
      defaultTeamCreation(user, group)
      # teamCreation(user, group)
    end
  end


  def checkDefaultTeam(groupObjectId,  userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "defaultTeam" => true,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @teams_coll, filter, [projection: project])
  end


  def defaultTeamCreation(user, group) do
    teamChangeset = %{
      name: user["name"]<>" Team",
      image: user["image"],
      insertedAt: bson_time(),
      updatedAt:  bson_time(),
      defaultTeam: true,
    }
    TeamRepo.createTeam(user, teamChangeset, group["_id"])
    #incrementing Total Teams Count
    incrementTotalTeamsCount(group)
  end


  # def teamCreation(user, group) do
  #   teamChangeset = %{
  #     name: user["name"]<>" Team",
  #     insertedAt: bson_time(),
  #     updatedAt:  bson_time(),
  #   }
  #   TeamRepo.createTeam(user, teamChangeset, group["_id"])
  #   #incrementing Total Teams Count
  #   incrementTotalTeamsCount(group)
  # end


  def addTeamForCommunityUsers(groupObjectId, teamObjectId, user, changeset) do
    #update into group_team_members doc
    team_members_doc = Community.insertNewTeamForAddingUser(teamObjectId, changeset)
    filter = %{ "groupId" => groupObjectId, "userId" => user["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def appendCommunityIdNo(userObjectId, idNo, group) do
    filter = %{
      "groupId" => group["_id"],
      "userId" => userObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "userCommunityId" => idNo
      }
    }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
    filter = %{
      "_id" => group["_id"],
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "idGenerationNo"  => 1,
      }
    }
    Mongo.update_one(@conn, @groups_coll, filter, update)
  end


  def incrementTotalTeamsCount(group) do
    if Map.has_key?(group, "feederMap") do
      filter = %{
        "_id" => group["_id"],
        "isActive" => true,
      }
      update = %{
        "$inc" => %{
          "feederMap.totalTeamsCount"  => 1,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  def incrementTotalUsersCount(group)  do
    if Map.has_key?(group, "feederMap") do
      filter = %{
        "_id" => group["_id"],
        "isActive" => true,
      }
      update = %{
        "$inc" => %{
          "feederMap.totalUsersCommunityCount" => 1,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  def decrementTotalUserCountCommunity(group) do
    if Map.has_key?(group, "feederMap") do
      filter = %{
        "_id" => group["_id"],
        "isActive" => true,
      }
      update = %{
        "$inc" => %{
          "feederMap.totalUsersCommunityCount" => -1,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  def decrementTotalTeamsCount(group) do
    if Map.has_key?(group, "feederMap") do
      filter = %{
        "_id" => group["_id"],
        "isActive" => true,
      }
      update = %{
        "$inc" => %{
          "feederMap.totalTeamsCount"  => -1,
        }
      }
      Mongo.update_one(@conn, @groups_coll, filter, update)
    end
  end


  def addBranches(branchDocument) do
    Mongo.insert_one(@conn, @community_coll, branchDocument)
  end


  def addPostsToBranches(insertDoc) do
    Mongo.insert_one(@conn, @post_coll, insertDoc)
  end


  def editBranches(groupObjectId, branchObjectId, changeset) do
    filter = %{
      "_id" => branchObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => changeset
    }
    Mongo.update_one(@conn, @community_coll, filter, update)
  end


  def deleteBranches(groupObjectId, branchObjectId) do
    filter = %{
      "_id" => branchObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "isActive" => false
      }
    }
    Mongo.update_one(@conn, @community_coll, filter, update)
  end


  def getBranchPosts(groupObjectId, branchObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "branchId" => branchObjectId,
      "isActive" => true,
      "type" => "branchPost"
    }
    if !is_nil(params["page"]) do
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * 15
      list = Mongo.find(@conn, @post_coll, filter, [skip: skip, limit: 15])
      |> Enum.to_list()
      {:ok, pageCount} = pageCountBranchPost(groupObjectId, branchObjectId)
     [%{"pageCount" => pageCount } | list]
    else
      [ %{"pageCount" => 0} | [] ]
    end
  end


  defp pageCountBranchPost(groupObjectId, branchObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "branchId" => branchObjectId,
      "isActive" => true,
      "type" => "branchPost"
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @post_coll, filter, [projection: project])
  end


  def getDefaultTeamId(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "adminId" => userObjectId,
      "isActive" => true,
      "defaultTeam" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.find_one(@conn, @teams_coll, filter, [projection: project])
  end

  def addGroupTeamMembers(insertGroupTeamMemDoc) do
    Mongo.insert_one(@conn, @group_team_members_coll, insertGroupTeamMemDoc)
  end


  def checkGroupTeamMembers(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" =>1,
    }
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def addAdminToTeam(groupObjectId, branchObjectId, adminIdsList) do
    filter = %{
      "_id" => branchObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "adminIds" => adminIdsList
      }
    }
    Mongo.update_one(@conn, @community_coll, filter, update)
  end


  def deleteAdminFromTeam(groupObjectId, branchObjectId, userObjectId) do
    filter = %{
      "_id" => branchObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$pull" => %{
        "adminIds" => %{
          "userId" => userObjectId
        }
      }
    }
    Mongo.update_one(@conn, @community_coll, filter, update)
  end


  def getAdminFromTeam(groupObjectId, branchObjectId) do
    filter = %{
      "_id" => branchObjectId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "adminIds" =>1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @community_coll, filter, [projection: project])
  end


  def getUserDetails(userObjectIds) do
    filter = %{
      "_id" => %{
        "$in" => userObjectIds
      }
    }
    project = %{
      "name" => 1,
      "_id" => 1,
      "phone" => 1,
      "image" => 1,
    }
    Mongo.find(@conn, @users_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def getListBasedOnSearch(filterMap, page) do
    filter = filterMap
    project = %{
      "name" => 1,
      "phone" => 1,
      "image" => 1,
      "_id" => 1,
    }
    skip = (page - 1) * 25
    {:ok, pageCount} = pageCountTotalUsers(filterMap)
    list = Mongo.find(@conn, @users_coll, filter, [projection: project, sort: %{"name" => 1}, limit: 25, skip: skip])
    |> Enum.to_list()
    [%{"pageCount" => pageCount}] ++ list
  end

  defp pageCountTotalUsers(filterMap) do
    filter = filterMap
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @users_coll, filter, [projection: project])
  end


  def getUserIdFromColl() do
    filter = %{
      "userCommunityId" => %{
        "$exists" => true
      }
    }
    project = %{
      "_id" => 1,
      "userCommunityId" => 1,
    }
    Mongo.find(@conn, @users_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def updateCommunityId(user, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => user["_id"],
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "userCommunityId" => user["userCommunityId"]
      }
    }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def  updateCanPostTrue(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "canPost" => true
      }
    }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def getAppAdmins(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "canPost" => true,
    }
    project = %{
      "userId" => 1,
      "_id" => 1,
    }
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def userDetails(userList) do
    filter = %{
      "_id" => %{
        "$in" => userList
      }
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "phone" => 1,
      "image" => 1,
    }
    Mongo.find(@conn, @users_coll, filter, [projection: project])
    |> Enum.to_list()
  end


  def deleteAppAdmin(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "canPost" => false,
      }
    }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
  end


  def addPublicTeam(changeset) do
    Mongo.insert_one(@conn, @teams_coll, changeset)
  end
end
