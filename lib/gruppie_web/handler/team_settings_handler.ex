defmodule GruppieWeb.Handler.TeamSettingsHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.TeamSettingsRepo
  alias GruppieWeb.Repo.GroupRepo

  def allowTeamPostAll(conn, group_id, team_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.allowTeamPostAll(groupObjectId, teamObjectId, loginUser["_id"])
  end


  def allowTeamPostCommentAll(conn, group_id, team_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.allowTeamPostCommentAll(groupObjectId, teamObjectId, loginUser["_id"])
  end


  def getTeamSettingList(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.getTeamSettingDetails(groupObjectId, teamObjectId)
  end


  def removeTeamUser(group, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #get number of teams for this user (if team is 0 remmove from group except group admin and public group)
    ####{:ok, teamCount} = TeamRepo.getTeamsCountForUser(userObjectId, group["_id"])
    ####if group["adminId"] == userObjectId || group["category"] == "public" do
      #remove only from team
      TeamSettingsRepo.removeUserFromTeam(group["_id"], teamObjectId, userObjectId)
    ####else
      ####if teamCount > 1 do
        #remove only from team
    ####    TeamSettingsRepo.removeUserFromTeam(group["_id"], teamObjectId, userObjectId)
      ####else
        #remove from group itself
      ####  AdminRepo.removeUserFromGroupByAdmin(group["_id"], userObjectId)
    ####  end
    ####end
  end


  def leaveTeam(conn, group_id, team_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    #leave only from team
    TeamSettingsRepo.removeUserFromTeam(groupObjectId, teamObjectId, loginUser["_id"])
  end


  def editTeam(conn, changeset, group_id, team_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.updateTeamDetails(changeset, groupObjectId, teamObjectId, loginUser["_id"])
  end


  def deleteTeam(conn, group_id, team_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    #find there is no users in the team except login user(teamAdmin)
    # {:ok, count} = TeamRepo.getCreatedTeamMembersCount(groupObjectId, teamObjectId)
    # if count > 1 do
    #   #cannot delete when users exist
    #   {:error1, "cannot delete when user exist"}
    # else
      #delete team permanently (when deleting team remove loginUser from team members)
      TeamSettingsRepo.deleteTeamPermanently(loginUser["_id"], groupObjectId, teamObjectId)
    #end
  end


  def archiveTeam(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.archiveTeam(groupObjectId, teamObjectId)
  end


  def getArchiveTeam(conn, group_id) do
    groupObjectId = decode_object_id(group_id)
    loginUser = Guardian.Plug.current_resource(conn)
    TeamSettingsRepo.getArchiveTeams(loginUser["_id"], groupObjectId)
  end


  def restoreArchiveTeam(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.restoreArchiveTeam(groupObjectId, teamObjectId)
  end


  def gpsEnableOrDisable(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.findEnableOrDisableGps(groupObjectId, teamObjectId)
  end


  def attendanceEnableOrDisable(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamSettingsRepo.findEnableOrDisableAttendance(groupObjectId, teamObjectId)
  end


  def findAndDisAllowUserToAddOtherUsers(conn, groupId, teamId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(groupId)
    teamObjectId = decode_object_id(teamId)
    TeamSettingsRepo.disallowUserToAddOtherUsers(loginUser["_id"], groupObjectId, teamObjectId)
  end


  def findAndAllowUserToAddOtherUsers(conn, groupId, teamId) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(groupId)
    teamObjectId = decode_object_id(teamId)
    TeamSettingsRepo.allowUserToAddOtherUsers(loginUser["_id"], groupObjectId, teamObjectId)
  end


  def findIndividuallyAndDisAllowUserToAddOtherUsers(group, team_id, user_id) do
    groupObjectId = group["_id"]
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamSettingsRepo.findIndividuallyAndDisAllowUserToAddOtherUsers(groupObjectId, teamObjectId, userObjectId)
  end


  def findIndividuallyAndAllowUserToAddTeamPost(group, team_id, user_id) do
    groupObjectId = group["_id"]
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    update = TeamSettingsRepo.findIndividuallyAndAllowUserToAddTeamPost(groupObjectId, teamObjectId, userObjectId)
    #I have implemented like this for event in school group so update this for only school group
    if group["category"] == "school" do
      #check authorizedToAdmin event is already exist
      {:ok, authorizedToAdminEvent} = GroupRepo.checkAuthorizedToAdminEvent(groupObjectId, userObjectId)
      if authorizedToAdminEvent > 0 do
        #already exist. So, update
        GroupRepo.updateAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
      else
        #add authorizedToAdmin event for this user
        GroupRepo.addAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
      end
    else
      update
    end
  end


  def findIndividuallyAndAllowUserToAddTeamPostComment(group, team_id, user_id) do
    groupObjectId = group["_id"]
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    update = TeamSettingsRepo.findIndividuallyAndAllowUserToAddTeamPostComment(groupObjectId, teamObjectId, userObjectId)
    #I have implemented like this for event in school group so update this for only school group
    if group["category"] == "school" do
      #check authorizedToAdmin event is already exist
      {:ok, authorizedToAdminEvent} = GroupRepo.checkAuthorizedToAdminEvent(groupObjectId, userObjectId)
      if authorizedToAdminEvent > 0 do
        #already exist. So, update
        GroupRepo.updateAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
      else
        #add authorizedToAdmin event for this user
        GroupRepo.addAuthorizedToAdminEventForUser(groupObjectId, userObjectId)
      end
    else
      update
    end
  end



  def changeTeamAdmin(conn, group_id, team_id, user_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamSettingsRepo.changeTeamAdmin(loginUser["_id"], groupObjectId, teamObjectId, userObjectId)
  end



end
