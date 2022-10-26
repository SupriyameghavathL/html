defmodule GruppieWeb.Handler.ConstituencyHandler do
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.ConstituencyRepo
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.User
  alias GruppieWeb.Constituency
  alias GruppieWeb.Repo.TeamRepo

  def addBoothsToConstituency(params, group, loginUser) do
    #check booth is creating by login user to login user
    #slice1 = loginUser["phone"].slice(0,10)
    loginUserPhone = String.slice(loginUser["phone"], 3..13)
    if params["phone"] == loginUserPhone do
      #just create one booth/team and add login user to that booth/team
      addBoothForBoothPresident(params, group)
    else
      #check that other user is already in group and add to booth/team
      #add booth/team with booth president and add login user to that team as authorized user
      {:ok, _boothOrTeamId} = addBoothForBoothPresident(params, group)
      #now add login user to that boothOrTeamId
      #####addToBooth = ConstituencyRepo.addAdminUserToBooth(loginUser, group["_id"], decode_object_id(boothOrTeamId)) #don't add admin to booth created
    end
  end

  #add booth/team to booth president
  defp addBoothForBoothPresident(params, group) do
    #firstly add class teacher
    parameters = %{ name: params["boothPresidentName"], countryCode: params["countryCode"], phone: params["phone"] }
    changesetUser = User.changeset_add_friend(%User{}, parameters)
    #secondly create team with this userId as adminId
    parameterBooth = boothTeamAddDoc(params)
    ####changesetBoothTeam = Team.changeset_class(%Team{}, parameterBooth)
    changesetBoothTeam = Constituency.changeset_booth_add(%Constituency{}, parameterBooth)
    if changesetUser.valid? && changesetBoothTeam.valid? do
      #find and add user to user table if not exist else get userId and add team with userId = adminId
      user = addBoothPresidentToUserTableIfNotExist(changesetUser.changes, group)
      #add team/booth to user
      ConstituencyRepo.createBoothTeam(user, changesetBoothTeam.changes, group["_id"])
    else
      {:changeset_error, changesetUser}
    end
  end

  defp boothTeamAddDoc(params) do
    if params["zpId"] do
      %{
        name: params["boothName"],
        image: params["boothImage"],
        category: params["category"],
        boothNumber: params["boothNumber"],
        boothAddress: params["boothAddress"],
        aboutBooth: params["aboutBooth"],
        zpId: params["zpId"]
      }
    else
      map = %{
        name: params["boothName"],
        image: params["boothImage"],
        category: params["category"],
        boothNumber: params["boothNumber"],
        boothAddress: params["boothAddress"],
        aboutBooth: params["aboutBooth"]
      }
      #add booth workers committee
      boothWorkerCommitteeMap = %{
        committeeName: "Booth Workers",
        committeeId: encode_object_id(new_object_id()),
        defaultCommittee: true
      }
      Map.put_new(map, :boothCommittees, [boothWorkerCommitteeMap])
    end
  end

  defp addBoothPresidentToUserTableIfNotExist(changeset, group) do
    #check user exist in user doc by phone
    checkUserExist = UserRepo.find_user_by_phone(changeset.phone)
    if length(checkUserExist) > 0 do
      #check user already in group/constituency but not in this team/booth
      {:ok, count} = ConstituencyRepo.checkUserAlreadyInConstituency(hd(checkUserExist)["_id"], group["_id"])
      if count < 1 do
        #insert to group_team_members
        ConstituencyRepo.joinUserToConstituency(hd(checkUserExist)["_id"], group["_id"])
        hd(checkUserExist)
      else
        hd(checkUserExist)
      end
    else
      #add user to uer doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #increment  user count
      ConstituencyRepo.incrementUsers(group)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      ConstituencyRepo.joinUserToConstituency(userRegisterToUserDoc["_id"], group["_id"])
      userRegisterToUserDoc
    end
  end



  def getAllBoothsTeams(groupObjectId) do
    #get all booths teams of this constituency
    booths = ConstituencyRepo.getAllBoothsTeams(groupObjectId)
    booths
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end


  def getAllBoothsTeamsBasedOnZp(groupObjectId, zpObjectId) do
    booths = ConstituencyRepo.getAllBoothsTeamsBasedOnZp(groupObjectId, zpObjectId)
    booths
    |> Enum.sort_by(& String.downcase(&1["name"]))
  end



  def addCommitteesToBoothTeam(groupObjectId, team_id, changeset, params) do
    teamObjectId = decode_object_id(team_id)
    if params["committeeId"] do
      #update already exist committee detail
      ConstituencyRepo.updateBoothCommitteeDetails(groupObjectId, teamObjectId, params["committeeId"], changeset)
    else
      #add new committee
      ConstituencyRepo.addCommitteesToBoothTeam(groupObjectId, teamObjectId, changeset)
    end
  end



  def getCommitteeListForBoothTeam(groupObjectId, teamId) do
    teamObjectId = decode_object_id(teamId)
    ConstituencyRepo.getCommitteeListForBoothTeam(groupObjectId, teamObjectId)
  end



  def updateBoothMemberInformation(changeset, user_id, loginUserId) do
    userObjectId = decode_object_id(user_id)
    #update user information to users col
    ConstituencyRepo.updateBoothMemberInformation(changeset, userObjectId, loginUserId)
  end




  # def addUserToBoothTeam123(changeset, group, teamId) do
  #   teamObjectId = decode_object_id(teamId)
  #   #check user exist in userDoc and add user to group_team_members
  #   checkUserExistInUserDocAndAddToBooth(changeset, group, teamObjectId)
  # end


  def addUserToBoothTeam(changeset, group, teamObjectId) do
    # teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc and add user to group_team_members
    checkUserExistInUserDocAndAddToBooth(changeset, group, teamObjectId)
  end


  defp checkUserExistInUserDocAndAddToBooth(changeset, group, teamObjectId) do
    #IO.puts "#{changeset}"
    ###check member adding to booth teams to add default teams
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) == 0 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      ConstituencyRepo.addBoothUsersToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
      {:ok, userRegisterToUserDoc}
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in this team
        {:ok, teamCount} = GroupRepo.checkUserAlreadyInTeam(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamCount == 0 do
          #not exist in this team. So push this team newly
          ConstituencyRepo.addTeamForBoothUsers(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
          #add default subBooth team for this user
          ConstituencyRepo.addDefaultBoothWorkerTeam(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
        else
          #already exist in this team so add to committee // push committeeId inside teams array in grp_team_mem
          ConstituencyRepo.addBoothMemberToCommittee(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc)["_id"], changeset.committeeId)
          #add default subBooth team for this user
          ConstituencyRepo.addDefaultBoothWorkerTeam(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
        end
        {:noIncrement, hd(userAlreadyExistInUserDoc)}
      else
        #add new doc to group_team_members because he is new user to group
        ConstituencyRepo.addBoothUsersToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
        {:ok, hd(userAlreadyExistInUserDoc)}
      end
    end
  end


  def addUserToSubBoothTeam(changeset, group, teamObjectId) do
    # teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc and add user to group_team_members
    checkUserExistInUserDocAndAddToSubBooth(changeset, group, teamObjectId)
  end

  defp checkUserExistInUserDocAndAddToSubBooth(changeset, group, teamObjectId) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) == 0 do
      #uses does not exist in user doc/ So, add user to user doc/group_team_members doc
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc / userRegisterToUserDoc = user (inserted user details)
      ConstituencyRepo.addSubBoothUsersToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
      {:ok, userRegisterToUserDoc}
    else
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in this team
        {:ok, teamCount} = GroupRepo.checkUserAlreadyInTeam(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamCount == 0 do
          #not exist in this team. So push this team newly
          ConstituencyRepo.addTeamForBoothUsers(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
        else
          {:ok, ""}
        end
        {:noIncrement, hd(userAlreadyExistInUserDoc)}
      else
        #add new doc to group_team_members because he is new user to group
        ConstituencyRepo.addSubBoothUsersToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
        {:ok, hd(userAlreadyExistInUserDoc)}
      end
    end
  end



  def addCoordinatorsToBoothTeam(changeset, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    #check user exist in userDoc and add user to group_team_members
    checkUserExistInUserDocForBoothCoordinator(changeset, group, teamObjectId)
  end

  defp checkUserExistInUserDocForBoothCoordinator(changeset, group, teamObjectId) do
    #check user exist in user doc by phone
    userAlreadyExistInUserDoc = UserRepo.find_user_by_phone(changeset.phone)
    if length(userAlreadyExistInUserDoc) < 1 do
      #user does not exist so add to users, group_team_members
      userRegisterToUserDoc = UserRepo.addUserToUserDoc(changeset)
      #add user to  group_team_members doc
      ConstituencyRepo.addCoordinatorToGroupTeamMembersDoc(userRegisterToUserDoc, group, teamObjectId, changeset)
      {:ok, userRegisterToUserDoc}
    else
      #user already in users table
      #check user already in group but not in this team
      {:ok, count} = GroupRepo.checkUserAlreadyInGroup(hd(userAlreadyExistInUserDoc)["_id"], group["_id"])
      if count > 0 do
        #check user already in this team
        {:ok, teamCount} = GroupRepo.checkUserAlreadyInTeam(hd(userAlreadyExistInUserDoc)["_id"], group["_id"], teamObjectId)
        if teamCount == 0 do
          #user already in group / Just push new team for the user
          ConstituencyRepo.addNewTeamForUserInGroup(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc), changeset)
        else
          #update role: "boothCoordinator" for this user
          ConstituencyRepo.updateRoleBoothCoordinatorForUser(group["_id"], teamObjectId, hd(userAlreadyExistInUserDoc)["_id"])
          {:ok, hd(userAlreadyExistInUserDoc)}
        end
      else
        #add new doc to group_team_members because he is new user to group
        ConstituencyRepo.addCoordinatorToGroupTeamMembersDoc(hd(userAlreadyExistInUserDoc), group, teamObjectId, changeset)
      end
    end
  end



  # def getBoothTeamMembers123(groupObjectId, teamObjectId) do
  #   users = ConstituencyRepo.getBoothTeamMembersList(groupObjectId, teamObjectId)
  #   #IO.puts "#{Enum.to_list(users)}"
  #   usersList = Enum.reduce(users, [], fn k, acc ->
  #     #get user team details from team_view col
  #     getUserTeamDetails = ConstituencyRepo.getBoothTeamMemberDetails(groupObjectId, teamObjectId, k["userId"])
  #     #IO.puts "#{Enum.to_list(getUserTeamDetails)}"
  #     acc = Enum.to_list(getUserTeamDetails) ++ acc
  #   end)
  #   #IO.puts "#{usersList}"
  #   usersList
  #   |> Enum.sort_by(& String.downcase(&1["name"]))
  # end


  def getBoothTeamMembers(groupObjectId, teamObjectId) do
    team = TeamRepo.get(encode_object_id(teamObjectId))
    # 1. Get all the userIds belongs to this team from group_team_mem
    usersWithTeam = ConstituencyRepo.getTeamUsersList(groupObjectId, teamObjectId)
    #checking for Blocked User
    usersWithTeam = if Map.has_key?(team, "blockedUsers") do
      for userId <- usersWithTeam do
        if encode_object_id(userId["userId"]) in team["blockedUsers"] do
          Map.put(userId, "blocked", true)
        else
          Map.put(userId, "blocked", false)
        end
      end
    else
      usersWithTeam
    end
    # convert teamList to map
    usersWithTeamList = for teams <- usersWithTeam do
      #IO.puts "#{hd(teams["teams"])}"
      Map.put(teams, "teams", hd(teams["teams"]))
    end
    # get all userIds in list
    userIds = for userId <- usersWithTeamList do
      [] ++ userId["userId"]
    end
    # 2. Now get user details from user_col
    userDetailsList = ConstituencyRepo.getUserDetailsForTeam(userIds)
    # Now merge two lists based on _id and userId
    Enum.map(usersWithTeamList, fn k ->
      userWithTeamMap = Enum.find(userDetailsList, fn v -> v["_id"] == k["userId"] end)
      if userWithTeamMap do
        Map.merge(k, userWithTeamMap)
      end
    end)
  end


  def getBoothTeamMembersByCommitteeId(groupObjectId, teamObjectId, committeeId) do
    # 1. Get all the userIds belongs to this team from group_team_mem
    usersWithTeam = ConstituencyRepo.getTeamUsersListByCommitteeId(groupObjectId, teamObjectId, committeeId)
    # convert teamList to map
    usersWithTeamList = for teams <- usersWithTeam do
      #IO.puts "#{hd(teams["teams"])}"
      Map.put(teams, "teams", hd(teams["teams"]))
    end
    # get all userIds in list
    userIds = for userId <- usersWithTeamList do
      [] ++ userId["userId"]
    end
    # 2. Now get user details from user_col
    userDetailsList = ConstituencyRepo.getUserDetailsForTeam(userIds)
    # Now merge two lists based on _id and userId
    Enum.map(usersWithTeamList, fn k ->
      userWithTeamMap = Enum.find(userDetailsList, fn v -> v["_id"] == k["userId"] end)
      if userWithTeamMap do
        Map.merge(k, userWithTeamMap)
      end
    end)
  end


  # def getBoothTeamMembersByCommitteeId123(groupObjectId, teamObjectId, committeeId) do
  #   users = ConstituencyRepo.getBoothTeamMembersListByCommitteeId(groupObjectId, teamObjectId, committeeId)
  #   #IO.puts "#{Enum.to_list(users)}"
  #   usersList = Enum.reduce(users, [], fn k, acc ->
  #     #get user team details from team_view col
  #     getUserTeamDetails = ConstituencyRepo.getBoothTeamMemberDetails(groupObjectId, teamObjectId, k["userId"])
  #     #IO.puts "#{Enum.to_list(getUserTeamDetails)}"
  #     acc = Enum.to_list(getUserTeamDetails) ++ acc
  #   end)
  #   #IO.puts "#{usersList}"
  #   usersList
  #   |> Enum.sort_by(& String.downcase(&1["name"]))
  # end



  def getListOfBoothCoordinators(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    ConstituencyRepo.getListOfBoothCoordinators(groupObjectId, teamObjectId)
  end



  ##def registerUserToVotersList(groupObjectId, team_id, user) do
  ##  teamObjectId = decode_object_id(team_id)
  ##  #add user to voters register
  ##  ConstituencyRepo.registerUserToVotersList(groupObjectId, teamObjectId, user)
  ##end


  def addMyFamilyToConstituencyDb(groupObjectId, user_id, familyMembers, loginUser) do
    userObjectId = decode_object_id(user_id)
    #add familyMember Id if not exist
    familyList = Enum.reduce(familyMembers, [], fn k, acc ->
      #IO.puts "#{k}"
      k = if !k["familyMemberId"] do
        Map.put_new(k, "familyMemberId", encode_object_id(new_object_id()))
      else
        k
      end
      acc ++ [k]
    end)
    #IO.puts "#{familyList}"
    #add family to constituency_voters list
    ConstituencyRepo.addMyFamilyToConstituencyDb(groupObjectId, userObjectId, familyList, loginUser)
  end


  def getFamilyRegisterList(groupObjectId, user_id) do
    userObjectId = decode_object_id(user_id)
    familyVotersList = ConstituencyRepo.getFamilyRegisterList(groupObjectId, userObjectId)
    if length(familyVotersList) > 0 do
      #IO.puts "#{familyVotersList}"
      hd(familyVotersList)["myFamilyMembers"]
    else
      []
    end
  end



  def getMyBoothTeams(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    ConstituencyRepo.getMyBoothTeams(loginUser["_id"], groupObjectId)
  end



  def getMySubBoothTeams(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    ConstituencyRepo.getMySubBoothTeams(loginUser["_id"], groupObjectId)
  end



  def getBoothMembersTeams(groupObjectId, boothTeamId) do
    boothTeamObjectId = decode_object_id(boothTeamId)
    #get teams under
    ConstituencyRepo.getBoothMembersTeams(groupObjectId, boothTeamObjectId)
  end



  def constituencyIssuesRegister(changeset, groupObjectId) do
    ConstituencyRepo.constituencyIssuesRegister(changeset, groupObjectId)
  end



  def constituencyIssuesGet(groupObjectId) do
    ConstituencyRepo.constituencyIssuesGet(groupObjectId)
  end



  def addDepartmentAndPartyUserToConstituencyIssues(changeset, groupObjectId, issue_id) do
    issueObjectId = decode_object_id(issue_id)
    departmentUserChangeset = changeset.departmentUser
    partyUserChangeset = changeset.partyUser
    #check and add both departmentUser and partyUser to users, group_team_mem, constituency_issues col
    insertedDepartmentUserId = addDepartmentUser(departmentUserChangeset, groupObjectId, issueObjectId)
    insertedPartyUserId = addPartyUser(partyUserChangeset, groupObjectId, issueObjectId)
    #now update both department and party userId to constituency_issues
    ConstituencyRepo.updateDepartmentAndPartyUserIdToConstituencyIssues(insertedDepartmentUserId, insertedPartyUserId, issueObjectId, groupObjectId)
  end

  defp addDepartmentUser(departmentUserChangeset, groupObjectId, _issueObjectId) do
    #first check department user id already in users col
    deptUserCheck = UserRepo.find_user_by_phone(departmentUserChangeset["phone"])
    if length(deptUserCheck) > 0 do
      #user exist in user col, so update constituencyDesignation to this user if it is coming in changeset
      if Map.has_key?(departmentUserChangeset, "constituencyDesignation") do
        #update constituency designation in users col
        ConstituencyRepo.updateConstituencyDesignationToUsersCol(hd(deptUserCheck)["_id"], departmentUserChangeset["constituencyDesignation"])
      end
      #first check user is in group
      {:ok, checkUserAlreadyInGroup} = ConstituencyRepo.checkUserIsAlreadyInGroup(hd(deptUserCheck)["_id"], groupObjectId)
      if checkUserAlreadyInGroup > 0 do
        #user already in group so check user already in task force team
        #get task force team id
        taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
        {:ok, checkUserInTaskForceTeam} = ConstituencyRepo.checkUserAlreadyInTaskForceTeam(hd(deptUserCheck)["_id"], groupObjectId, taskForceTeamId["_id"])
        if checkUserInTaskForceTeam > 0 do
          #already in task force team, so just return userId
          hd(deptUserCheck)["_id"]
        else
          #add task force team to this user
          ConstituencyRepo.addTaskForceTeamToGroupTeamUser(hd(deptUserCheck)["_id"], groupObjectId, taskForceTeamId["_id"])
          hd(deptUserCheck)["_id"]
        end
      else
        #user not in group so add to group_team_mem col
        #get task force team id
        taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
        ConstituencyRepo.addUserToGroupTeamMemWithTaskForceTeam(groupObjectId, taskForceTeamId["_id"], hd(deptUserCheck)["_id"])
        #add to constituency_issues col, so here im just returning inserted userId
        hd(deptUserCheck)["_id"]
      end
    else
      #user not exist so add newly to user_col, add to task force team and add userId to constituency_issues col
      #first add to user_col
      userRegisterToUserDoc = ConstituencyRepo.addUserToUserDoc(departmentUserChangeset)
      #secondly add user to group_team_members with taskForce team
      #get task force team id
      taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
      ConstituencyRepo.addUserToGroupTeamMemWithTaskForceTeam(groupObjectId, taskForceTeamId["_id"], userRegisterToUserDoc["_id"])
      #third add to constituency_issues col, so here im just returning inserted userId
      userRegisterToUserDoc["_id"]
    end
  end

  defp addPartyUser(partyUserChangeset, groupObjectId, _issueObjectId) do
    #first check department user id already in users col
    partyUserCheck = UserRepo.find_user_by_phone(partyUserChangeset["phone"])
    if length(partyUserCheck) > 0 do
      #user exist in user col, so update constituencyDesignation to this user if it is coming in changeset
      if Map.has_key?(partyUserChangeset, "constituencyDesignation") do
        #update constituency designation in users col
        ConstituencyRepo.updateConstituencyDesignationToUsersCol(hd(partyUserCheck)["_id"], partyUserChangeset["constituencyDesignation"])
      end
      #first check user is in group
      {:ok, checkUserAlreadyInGroup} = ConstituencyRepo.checkUserIsAlreadyInGroup(hd(partyUserCheck)["_id"], groupObjectId)
      if checkUserAlreadyInGroup > 0 do
        #user already in group so check user already in task force team
        #get task force team id
        taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
        {:ok, checkUserInTaskForceTeam} = ConstituencyRepo.checkUserAlreadyInTaskForceTeam(hd(partyUserCheck)["_id"], groupObjectId, taskForceTeamId["_id"])
        if checkUserInTaskForceTeam > 0 do
          #already in task force team, so just return userId
          hd(partyUserCheck)["_id"]
        else
          #add task force team to this user
          ConstituencyRepo.addTaskForceTeamToGroupTeamUser(hd(partyUserCheck)["_id"], groupObjectId, taskForceTeamId["_id"])
          hd(partyUserCheck)["_id"]
        end
      else
        #user not in group so add to group_team_mem col
        #get task force team id
        taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
        ConstituencyRepo.addUserToGroupTeamMemWithTaskForceTeam(groupObjectId, taskForceTeamId["_id"], hd(partyUserCheck)["_id"])
        #add to constituency_issues col, so here im just returning inserted userId
        hd(partyUserCheck)["_id"]
      end
    else
      #user not exist so add newly to user_col, add to task force team and add userId to constituency_issues col
      #first add to user_col
      userRegisterToUserDoc = ConstituencyRepo.addUserToUserDoc(partyUserChangeset)
      #secondly add user to group_team_members with taskForce team
      #get task force team id
      taskForceTeamId = ConstituencyRepo.getTaskForceTeamId(groupObjectId)
      ConstituencyRepo.addUserToGroupTeamMemWithTaskForceTeam(groupObjectId, taskForceTeamId["_id"], userRegisterToUserDoc["_id"])
      #third add to constituency_issues col, so here im just returning inserted userId
      userRegisterToUserDoc["_id"]
      #addDeptUserToIssues = ConstituencyRepo.addDepartmentUserIdToIssue
    end
  end




  def deleteConstituencyIssue(groupObjectId, issueId) do
    issueObjectId = decode_object_id(issueId)
    ConstituencyRepo.deleteConstituencyIssue(groupObjectId, issueObjectId)
  end



  def getBoothOrSubBoothTeamsForLoginUser(loginUserId, groupObjectId) do
    ConstituencyRepo.getBoothOrSubBoothTeamsForLoginUser(loginUserId, groupObjectId)
  end



  def addTicketOnIssueOfConstituency(groupObjectId, boothId, issueId, loginUserId, changeset) do
    boothTeamObjectId = decode_object_id(boothId)
    issueObjectId = decode_object_id(issueId)
    #add/raise ticket for issue
    ConstituencyRepo.addTicketOnIssueOfConstituency(groupObjectId, boothTeamObjectId, issueObjectId, loginUserId, changeset)
  end



  def removeIssueAddedByLoginUser(loginUserId, groupObjectId, issuePostId) do
    issuePostObjectId = decode_object_id(issuePostId)
    #first check loginUser raised this issue
    {:ok, checkloginUserIssue} = ConstituencyRepo.checkLoginUserAddedThisIssue(loginUserId, groupObjectId, issuePostObjectId)
    if checkloginUserIssue > 0 do
      #allow to delete/remove
      ConstituencyRepo.removeIssueAddedByLoginUser(loginUserId, groupObjectId, issuePostObjectId)
    else
      #not found error
      {:not_found, "error"}
    end
  end



  ##def getConstituencyIssuesTickets(groupObjectId, coordinatorTeamsIdArray, params, pageLimit) do
  ##  #get issues list based on option approved/notApproved/hold/denied for his booth/subBooth teams Ids
  ##  ConstituencyRepo.getIssuesTicketsBasedOnOptionSelected(groupObjectId, coordinatorTeamsIdArray, params["option"], params["page"], pageLimit)
  ##end

  def getConstituencyIssuesTicketsForPartyTaskForce(groupObjectId, issuesIdArray, params, pageLimit) do
    #get issues list based on option approved/notApproved/hold/denied for his issue Ids
    ConstituencyRepo.getConstituencyIssuesTicketsForPartyTaskForce(groupObjectId, issuesIdArray, params["option"], params["page"], pageLimit)
  end

  #event
  def getPartyTaskForceConstituencyIssuesTicketsEvents(groupObjectId, loginUserId, option) do
    #get issues list where he is allocated as party task force for the issue. So first get list of issues id where login user is party task force
    partyTaskForceIssuesId = ConstituencyRepo.getIssuesIdForPartyTaskForce(groupObjectId, loginUserId)
    #get last updatedAt event time for list
    ConstituencyRepo.getPartyTaskForceConstituencyIssuesTicketsEvents(groupObjectId, partyTaskForceIssuesId, option)
  end


  def getConstituencyIssuesTicketsForAdmin(groupObjectId, params, pageLimit) do
     #get issues list based on option approved/notApproved/hold/denied
     ConstituencyRepo.getConstituencyIssuesTicketsForAdmin(groupObjectId, params["option"], params["page"], pageLimit)
  end

  #events
  def getAdminConstituencyIssuesTicketsEvents(groupObjectId, option) do
    ConstituencyRepo.getAdminConstituencyIssuesTicketsEvents(groupObjectId, option)
  end


  def getConstituencyIssuesTicketsDepartmentTaskForce(groupObjectId, issuesIdArray, params, pageLimit) do
    #get issues list based on option overdue/open/closed/hold for his booth/subBooth teams Ids
    ConstituencyRepo.getConstituencyIssuesTicketsDepartmentTaskForce(groupObjectId, issuesIdArray, params["option"], params["page"], pageLimit)
  end

  #events
  def getDepartmentTaskForceConstituencyIssuesTicketsEvents(groupObjectId, loginUserId, option) do
    #get issues list where he is allocated as department task force for the issue. So first get list of issues id where login user is department task force
    deptTaskForceIssuesId = ConstituencyRepo.getIssuesIdForDepartmentTaskForce(groupObjectId, loginUserId)
    #get last updatedAt event time for list
    ConstituencyRepo.getDepartmentTaskForceConstituencyIssuesTicketsEvents(groupObjectId, deptTaskForceIssuesId, option)
  end


  def getConstituencyIssuesTicketsForBoothPresident(groupObjectId, boothPresidentTeamsIdArray, params, pageLimit) do
    #get issues list based on option approved/notApproved/hold/denied for his booth/subBooth teams Ids
    ConstituencyRepo.getConstituencyIssuesTicketsForBoothPresident(groupObjectId, boothPresidentTeamsIdArray, params["option"], params["page"], pageLimit)
  end

  #events
  def getBoothPresidentConstituencyIssueTicketsEvents(groupObjectId, loginUserId, option) do
    #get issues of only his booth teams and subBooth teams. So get list of all team Ids belongs to this boothCoordinator (booth and under subBooths)
    boothPresidentTeamsIdArray = ConstituencyRepo.getTeamsListForBoothPresident(groupObjectId, loginUserId)
    #get last updatedAt event time for list
    ConstituencyRepo.getBoothPresidentConstituencyIssueTicketsEvents(groupObjectId, boothPresidentTeamsIdArray, option)
  end

  #events boothMember
  def getBoothMembersConstituencyIssueTicketsEvents(groupObjectId, loginUserId, option) do
    #get issues of only his booth teams and subBooth teams. So get list of all team Ids belongs to this boothCoordinator (booth and under subBooths)
    boothMembersTeamsIdArray = ConstituencyRepo.getTeamsListForBoothMembers(groupObjectId, loginUserId)
    #get last updatedAt event time for list
    ConstituencyRepo.getBoothPresidentConstituencyIssueTicketsEvents(groupObjectId, boothMembersTeamsIdArray, option)
  end


  def getConstituencyIssuesTicketsForPublic(groupObjectId, loginUserId, params, pageLimit) do
    #get issues list based on option approved/notApproved/hold/denied
    ConstituencyRepo.getIssuesTicketsBasedOnOptionSelectedForPublic(groupObjectId, loginUserId, params["option"], params["page"], pageLimit)
  end

  #events
  def getPublicUserConstituencyIssuesTicketsEvents(groupObjectId, loginUserId, option) do
    ConstituencyRepo.getPublicUserConstituencyIssuesTicketsEvents(groupObjectId, loginUserId, option)
  end


  def changeStatusOfNotApprovedIssuesTicketsByPartyTaskForce(groupObjectId, issuePostId, statusParams) do
    issuePostObjectId = decode_object_id(issuePostId)
    ConstituencyRepo.changeStatusOfNotApprovedIssuesTicketsByPartyTaskForce(groupObjectId, issuePostObjectId, statusParams)
  end

  def changeStatusOfNotApprovedIssuesTicketsByAdmin(groupObjectId, issuePostId, statusParams) do
    issuePostObjectId = decode_object_id(issuePostId)
    ConstituencyRepo.changeStatusOfNotApprovedIssuesTicketsByAdmin(groupObjectId, issuePostObjectId, statusParams)
  end


  def closeOrHoldStatusForOpenIssue(groupObjectId, issuePostId, statusParams) do
    issuePostObjectId = decode_object_id(issuePostId)
    ConstituencyRepo.closeOrHoldStatusForOpenIssue(groupObjectId, issuePostObjectId, statusParams)
  end



  def addCommentToIssueTickets(groupObjectId, loginUserId, issuePostId, changeset) do
    issuePostObjectId = decode_object_id(issuePostId)
    ConstituencyRepo.addCommentToIssueTickets(groupObjectId, loginUserId, issuePostObjectId, changeset)
  end



  def getCommentsOnIssueTickets(groupObjectId, issuePostId) do
    issuePostObjectId = decode_object_id(issuePostId)
    ConstituencyRepo.getCommentsOnIssueTickets(groupObjectId, issuePostObjectId)
  end



  def addVotersToTeamFromMasterList(changeset, group, teamId) do
    teamObjectId = decode_object_id(teamId)
    #check changeset contains phone key
    if Map.has_key?(changeset, :phone) do
      #add user to user table, group_team_member table with teamId and constituency_voters_database table
      #1. add user to user table, 2. Add for group_team_members table
      #check user exist in userDoc and add user to group_team_members
      {:ok, userDetails} = checkUserExistInUserDocAndAddToSubBooth(changeset, group, teamObjectId)
      #2. add user to constituency_voters_database col
      ConstituencyRepo.addUserToConstituencyVotersDatabase(group["_id"], teamObjectId, userDetails["_id"], changeset)
    else
      #add user to user table, and constituency_voters_database table
      #1.add user to users col without phone
      ##addUserWithoutPhone = ConstituencyRepo.addUserToUsersColWithoutPhone(changeset)
      #2. add user to constituency_voters_database col without userId
      ConstituencyRepo.addUserToConstituencyVotersDatabaseWithoutUserId(group["_id"], teamObjectId, changeset)
    end
  end



  def getVotersFromMasterList(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    ConstituencyRepo.getVotersFromMasterList(groupObjectId, teamObjectId)
  end


  def allocateVotersToBoothWorkers(_groupObjectId, _boothWorkerId, _voterIdsParam) do
    # boothWorkerObjectId = decode_object_id(boothWorkerId)
    # voterIds = [to_string(voterIdsParam)]
    # voterIdsList = Enum.reduce(voterIds, [], fn voterId, acc ->
    #   #find voter Id already allocated to this worker
    #   ##alreadyAllocated =
    # end)
  end



  def getAdminFeederInConstituencyGroup(groupObjectId) do
    ConstituencyRepo.getFeederMap(groupObjectId)
  end


  def checkFeederMapPresentInGroup(group)  do
    #to check feeder map is present in group or not
    if Map.has_key?(group, "feederMap") do
      checkMap(group)
    else
      addFeederMapToGroup(group["_id"])
    end
  end

  defp addFeederMapToGroup(groupObjectId) do
     #1. get total issues of constituency
      # {:ok, totalOpenIssuesCount} = ConstituencyRepo.getTotalOpenIssuesCountOfConstituency(groupObjectId)
      #2. get total booths abd discussions count
      getTotalBoothAndDiscussionsCount = ConstituencyRepo.getTotalBoothAndDiscussionsCount(groupObjectId)
      totalBoothsCount = getTotalBoothAndDiscussionsCount["totalBoothCount"]
      totalBoothDiscussionCount = getTotalBoothAndDiscussionsCount["totalBoothDiscussionCount"]
      #3. get total public street and forum discussions
      getTotalSubBoothAndDiscussionsCount = ConstituencyRepo.getTotalSubBoothAndDiscussionsCount(groupObjectId)
      totalSubBoothsCount = getTotalSubBoothAndDiscussionsCount["totalSubBoothCount"]
      totalSubBoothDiscussionCount = getTotalSubBoothAndDiscussionsCount["totalSubBoothDiscussionCount"]
      #4. get total announcement count
      # {:ok, totalAnnouncementCount} = ConstituencyRepo.getTotalConstituencyAnnouncementCount(groupObjectId)
      #5.total members count
      {:ok, totalUsersCount} = ConstituencyRepo.getTotalUsersCount(groupObjectId)
      totalUserCountShortForm = cond do
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
      feederMap = %{
        "totalBoothsCount" => totalBoothsCount,
        "totalSubBoothsCount" => totalSubBoothsCount - totalBoothsCount,
        "totalBoothsDiscussion" => totalBoothDiscussionCount,
        "totalSubBoothDiscussion" => totalSubBoothDiscussionCount,
      #  "totalOpenIssuesCount" => totalOpenIssuesCount,
      #  "totalAnnouncementCount" => totalAnnouncementCount,
        "totalUsersInWords" => totalUserCountShortForm,
        "totalUsersCount" => totalUsersCount,
        "category" => "C",
      }

      #inserting feeder map to group
      ConstituencyRepo.insertFeederMapToGroup(groupObjectId, feederMap)
  end


  defp checkMap(group) do
    getTotalBoothAndDiscussionsCount = ConstituencyRepo.getTotalBoothAndDiscussionsCount(group["_id"])
    totalBoothsCount = getTotalBoothAndDiscussionsCount["totalBoothCount"]
    if !Map.has_key?(group["feederMap"], "totalBoothsCount") do
      ConstituencyRepo.addTotalBoothCount(group["_id"], totalBoothsCount)
    end
    if !Map.has_key?(group["feederMap"], "totalSubBoothDiscussion") do
      getTotalSubBoothAndDiscussionsCount = ConstituencyRepo.getTotalSubBoothAndDiscussionsCount(group["_id"])
      totalSubBoothsDiscussion = getTotalSubBoothAndDiscussionsCount["totalSubBoothDiscussionCount"]
      ConstituencyRepo.totalSubBoothsDiscussion(group["_id"], totalSubBoothsDiscussion)
    end
    if !Map.has_key?(group["feederMap"], "totalSubBoothsCount") do
      getTotalSubBoothAndDiscussionsCount = ConstituencyRepo.getTotalSubBoothAndDiscussionsCount(group["_id"])
      totalSubBoothsCount = getTotalSubBoothAndDiscussionsCount["totalSubBoothsCount"]
      ConstituencyRepo.totalSubBoothsCount(group["_id"], totalSubBoothsCount - totalBoothsCount)
    end
    if !Map.has_key?(group["feederMap"], "totalBoothsDiscussion") do
      getTotalBoothAndDiscussionsCount = ConstituencyRepo.getTotalBoothAndDiscussionsCount(group["_id"])
      totalBoothDiscussionCount = getTotalBoothAndDiscussionsCount["totalBoothDiscussionCount"]
      ConstituencyRepo.totalBoothDiscussionCount(group["_id"], totalBoothDiscussionCount)
    end
    if !Map.has_key?(group["feederMap"], "totalUsersCount") do
      {:ok, totalUsersCount} = ConstituencyRepo.getTotalUsersCount(group["_id"])
      ConstituencyRepo.totalUsersCount(group["_id"], totalUsersCount)
    end
  end


  def checkFeederMapPresentInGroupCommunity(group)  do
    #to check feeder map is present in group or not
    if Map.has_key?(group, "feederMap") do
     group["feederMap"]
    else
      addFeederMapToGroupCommunity(group["_id"])
    end
  end


  defp  addFeederMapToGroupCommunity(groupObjectId) do
     {:ok, totalUsersCount} = ConstituencyRepo.getTotalUsersCount(groupObjectId)
     {:ok, totalTeamsCount} = ConstituencyRepo.getTotalTeamsCount(groupObjectId)
     feederMap = %{
       "totalUsersCommunityCount" => totalUsersCount,
       "totalTeamsCount" => totalTeamsCount
     }
     ConstituencyRepo.insertFeederMapToGroup(groupObjectId, feederMap)
 end

  # def addBoothCountsInGroup(groupObjectId) do
  #   #get counts of booth in group
  #   {:ok, getTotalBoothsCount} = ConstituencyRepo.getTotalBoothCountInGroup(groupObjectId)
  #   IO.puts "#{getTotalBoothsCount}"
  # end


  # def searchUserInGroup(groupObjectId, filter) do
  #   #get all userIds belongs to this group
  #   userIds = ConstituencyRepo.getUserIdsBelongsToGroup(groupObjectId)
  #   userIdList = for k <- userIds do
  #     [] ++ k["userId"]
  #   end
  #   #search based on filter = name/phone/voterId in users col
  #   ConstituencyRepo.searchUserInGroup(userIdList, filter)
  # end

  def searchUserInGroup(_groupObjectId, params) do
    #search based on filter = name/phone/voterId in users col
    ConstituencyRepo.searchUserInGroup(params)
  end


  def getTeamIdsName(groupObjectId, teams) do
    if teams["teams"] != [] do
      teamsObjectIds =   for teamId <- teams["teams"] do
        teamId["teamId"]
      end
      teamsList = ConstituencyRepo.teamNames(groupObjectId, teamsObjectIds)
      for teams <- teamsList do
        %{
          "teamId" => encode_object_id(teams["_id"]),
          "name" => teams["name"]
        }
      end
    else
      []
    end
  end
end
