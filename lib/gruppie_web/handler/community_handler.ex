defmodule GruppieWeb.Handler.CommunityHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.CommunityRepo
  alias GruppieWeb.Repo.GroupRepo
  import GruppieWeb.Handler.TimeNow


  def addUserToCommunityTeam(changeset, group, team) do
    #check user exist in userDoc and add user to group_team_members
    checkUserExistInUserDocAndAddToCommunityTeam(changeset, group, team)
  end


  defp checkUserExistInUserDocAndAddToCommunityTeam(changeset, group, team) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) == 0 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #incrementing total users community count
      CommunityRepo.incrementTotalUsersCount(group)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      CommunityRepo.addCommunityUsersToGroupTeamMembersDoc(userRegisterToUserDoc, group, team, changeset)
      #append Community Id no for user
      if Map.has_key?(group, "idGenerationNo") do
        if team["defaultTeam"] == true do
          idNo = Kernel.trunc(group["idGenerationNo"]+1)
          idNoForUser = group["appName"]<>String.pad_leading(to_string(idNo), 3, "00")
          CommunityRepo.appendCommunityIdNo(userRegisterToUserDoc["_id"], idNoForUser, group)
        end
      end
      {:ok, userRegisterToUserDoc}
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in this team
        {:ok, teamCount} = GroupRepo.checkUserAlreadyInTeam(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], team["_id"])
        if teamCount == 0 do
          #not exist in this team. So push this team newly
          CommunityRepo.addTeamForCommunityUsers(group["_id"], team["_id"], hd(userAlreadyExistInUserDoc), changeset)
          #check whether default team exists or not
          if team["defaultTeam"] == true do
            {:ok, defaultTeamCount} = CommunityRepo.checkDefaultTeam(group["_id"],  hd(userAlreadyExistInUserDoc)["_id"])
            if defaultTeamCount == 0 do
              CommunityRepo.defaultTeamCreation(hd(userAlreadyExistInUserDoc), group)
              if Map.has_key?(group, "idGenerationNo") do
                idNo = Kernel.trunc(group["idGenerationNo"]+1)
                idNoForUser = group["appName"]<>String.pad_leading(to_string(idNo), 3, "00")
                CommunityRepo.appendCommunityIdNo(hd(userAlreadyExistInUserDoc)["_id"], idNoForUser, group)
              end
            else
              user = hd(userAlreadyExistInUserDoc)
              {:ok, user}
            end
            #teamCreation(hd(userAlreadyExistInUserDoc), group)
          end
        else
          user = hd(userAlreadyExistInUserDoc)
          {:ok, user}
        end
      else
        #add new doc to group_team_members because he is new user to group
        CommunityRepo.addCommunityUsersToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, team, changeset)
      end
      {:ok, hd(userAlreadyExistInUserDoc)}
    end
  end


  def addBranches(groupObjectId, changeset) do
    changeset = changeset
    |> Map.put(:isActive, true)
    |> Map.put(:groupId, groupObjectId)
    CommunityRepo.addBranches(changeset)
  end


  def addPostToBranches(groupObjectId, changeset, loginUserId, branchObjectId) do
    changeset = changeset
    |> Map.put(:userId, loginUserId)
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:uniquePostId, encode_object_id(new_object_id()))
    |> Map.put(:type, "branchPost")
    |> Map.put(:branchId, branchObjectId)
    CommunityRepo.addPostsToBranches(changeset)
  end


  def editBranches(groupObjectId, branchObjectId, changeset) do
    CommunityRepo.editBranches(groupObjectId, branchObjectId, changeset)
  end


  def deleteBranches(groupObjectId, branchObjectId)  do
    CommunityRepo.deleteBranches(groupObjectId, branchObjectId)
  end


  def getBranchPosts(groupObjectId, branchObjectId, params) do
    CommunityRepo.getBranchPosts(groupObjectId, branchObjectId, params)
  end


  def getDefaultTeamId(groupObjectId, userObjectId) do
    CommunityRepo.getDefaultTeamId(groupObjectId, userObjectId)
  end


  def addAdminToUserAndTeamDoc(groupObjectId, changeset) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) == 0 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      groupInsertDoc(groupObjectId, userRegisterToUserDoc["_id"])
      userRegisterToUserDoc["_id"]
      # CommunityRepo.addAdminToTeam(groupObjectId, branchObjectId, userRegisterToUserDoc["_id"])
    else
      #check whether user exists in group team member
      {:ok, groupTeamCount} = CommunityRepo.checkGroupTeamMembers(groupObjectId, hd(userAlreadyExistInUserDoc)["_id"])
      if groupTeamCount == 0 do
        groupInsertDoc(groupObjectId, hd(userAlreadyExistInUserDoc)["_id"])
        hd(userAlreadyExistInUserDoc)["_id"]
        # CommunityRepo.addAdminToTeam(groupObjectId, branchObjectId, userAlreadyExistInUserDoc["_id"])
      else
        # CommunityRepo.addAdminToTeam(groupObjectId, branchObjectId, userAlreadyExistInUserDoc["_id"])
        hd(userAlreadyExistInUserDoc)["_id"]
      end
    end
  end


  defp groupInsertDoc(groupObjectId, userObjectId) do
    #inserting user in group team doc
    insertGroupTeamMemDoc = %{
      "userId" => userObjectId,
      "isActive" => true,
      "canPost" => false,
      "groupId" => groupObjectId,
      "insertedAt" => bson_time(),
      "isAdmin" => false,
      "teams" => [],
      "updatedAt" =>  bson_time(),
    }
    CommunityRepo.addGroupTeamMembers(insertGroupTeamMemDoc)
  end


  def addAdminToTeam(groupObjectId, branchObjectId, userIdsList) do
    adminIdsList = for userObjectId <- userIdsList do
      %{
        "userId" => userObjectId,
        "isActive" => true,
      }
    end
    CommunityRepo.addAdminToTeam(groupObjectId, branchObjectId, adminIdsList)
  end


  def deleteAdminFromTeam(groupObjectId, branchObjectId, userObjectId) do
    CommunityRepo.deleteAdminFromTeam(groupObjectId, branchObjectId, userObjectId)
  end


  def getAdminFromTeam(groupObjectId, branchObjectId) do
    adminIdsList = CommunityRepo.getAdminFromTeam(groupObjectId, branchObjectId)
    userObjectId = for userId <- adminIdsList["adminIds"] do
      userId["userId"]
    end
    #getting user details from user coll
    CommunityRepo.getUserDetails(userObjectId)
  end


  def getListBasedOnSearch(params) do
    page = if !is_nil(params["page"]) do
      String.to_integer(params["page"])
    else
      1
    end
    params = Map.delete(params, "page")
    list = Map.to_list(params)
    filterMap = Enum.reduce(list, %{}, fn k, acc ->
      {key, value} = k
      map = %{
        "$regex" =>  String.downcase(value)
      }
      Map.put(acc, key, map)
    end)
    CommunityRepo.getListBasedOnSearch(filterMap, page)
  end


  def addCommunityIdNo(groupObjectId, _appName) do
    #get userId from userc coll
    getUserId = CommunityRepo.getUserIdFromColl()
    for user <- getUserId do
      CommunityRepo.updateCommunityId(user, groupObjectId)
    end
  end


  def makeAdminToApp(groupObjectId, _user, changeset) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) == 0 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      groupInsertDocAdmin(groupObjectId, userRegisterToUserDoc["_id"])
      {:ok, "success"}
    else
      #check whether user exists in group team member
      {:ok, groupTeamCount} = CommunityRepo.checkGroupTeamMembers(groupObjectId, hd(userAlreadyExistInUserDoc)["_id"])
      if groupTeamCount == 0 do
        groupInsertDocAdmin(groupObjectId, hd(userAlreadyExistInUserDoc)["_id"])
        {:ok, "success"}
      else
        #update canPost true in group_team_doc
        CommunityRepo.updateCanPostTrue(groupObjectId, hd(userAlreadyExistInUserDoc)["_id"])
        {:ok, "success"}
      end
    end
  end


  defp groupInsertDocAdmin(groupObjectId, userObjectId) do
     #inserting user in group team doc
     insertGroupTeamMemDoc = %{
      "userId" => userObjectId,
      "isActive" => true,
      "canPost" => true,
      "groupId" => groupObjectId,
      "insertedAt" => bson_time(),
      "isAdmin" => false,
      "teams" => [],
      "updatedAt" =>  bson_time(),
    }
    CommunityRepo.addGroupTeamMembers(insertGroupTeamMemDoc)
  end


  def getAppAdmins(groupObjectId) do
    userIds = CommunityRepo.getAppAdmins(groupObjectId)
    userList = for user <- userIds do
      user["userId"]
    end
    CommunityRepo.userDetails(userList)
  end


  def deleteAppAdmin(groupObjectId, userObjectId) do
    CommunityRepo.deleteAppAdmin(groupObjectId, userObjectId)
  end


  def addPublicTeam(groupObjectId, changeset) do
    changeset = changeset
    |> Map.put(:isActive, true)
    |> Map.put(:groupId, groupObjectId)
    |> Map.put(:category, "public")
    |> Map.put(:allowTeamPostAll, true)
    |> Map.put(:allowTeamPostCommentAll, true)
    CommunityRepo.addPublicTeam(changeset)
  end
end
