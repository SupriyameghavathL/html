defmodule GruppieWeb.Api.V1.ConstituencyView do
  use GruppieWeb, :view
  #alias Gruppie.Repo.AdminRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  import GruppieWeb.Repo.RepoHelper
  alias GruppieWeb.Repo.UserRepo
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.AdminRepo


  def render("booth_workers_teams.json", %{booths: booths, groupObjectId: groupObjectId, team: team, loginUser: loginUser}) do
    list = Enum.reduce(booths, [], fn k, acc ->
      #IO.puts "#{k}"
      #get booth members count
      {:ok, boothMembersCount} = ConstituencyRepo.getBoothMembersCount(groupObjectId, k["_id"])
      #IO.puts "#{boothMembersCount}"
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          #"boothName" => k["name"],
          "name" => k["name"],
          #"boothImage" => k["image"],
          "image" => k["image"],
          "adminName" => k["adminName"],
          "phone" => k["phone"],
          #"totalBoothMembersCount" => boothMembersCount,
          "members" => boothMembersCount,
          "allowTeamPostAll" => true,
          "allowTeamPostCommentAll" => true,
          "canAddUser" => true,
          "isTeamAdmin" => if loginUser["_id"] == team["adminId"] do
            true
          else
            false
          end,
          "category" => k["category"],
          "groupId" => encode_object_id(groupObjectId),
          "userName" => k["adminName"],
          "userId" => encode_object_id(k["userId"]),
          "userImage" => k["userImage"]
      }
      acc ++ [map]
    end)
    %{data: list}
  end


  def render("get_voters_master_list.json", %{votersMasterList: votersMasterList}) do
    list = Enum.reduce(votersMasterList, [], fn k, acc ->
      map = %{
        "groupId" => encode_object_id(k["groupId"]),
        "teamId" => encode_object_id(k["teamId"]),
        "name" => k["name"],
        "image" => k["image"],
        "phone" => k["phone"],
        "fatherName" => k["fatherName"],
        "husbandName" => k["husbandName"],
        "voterId" => k["voterId"],
        "serialNumber" => k["serialNumber"],
        "address" => k["address"],
        "dob" => k["dob"],
        "age" => k["age"],
        "gender" => k["gender"],
        "bloodGroup" => k["aadharNumber"],
        "aadharNumber" => k["aadharNumber"],
        "email" => k["email"]

      }
      acc ++ [map]
    end)
    %{data: list}
  end


  def render("booth_workers_teams_election_list.json", %{booths: booths, groupObjectId: groupObjectId}) do
    list = Enum.reduce(booths, [], fn k, acc ->
      #get count of members allocated under booth worker
      ##
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"],
          "adminName" => k["adminName"],
          "phone" => k["phone"],
          "canAddUser" => true,
          "isTeamAdmin" => true,
          "category" => k["category"],
          "groupId" => encode_object_id(groupObjectId)
      }
      acc ++ [map]
    end)
    %{data: list}
  end




  def render("all_booths.json", %{booths: booths, groupObjectId: groupObjectId}) do
    list = Enum.reduce(booths, [], fn k, acc ->
      #1st get committee id that is default Committee of worker
      filterCommitteeTrue = if k["boothCommittees"] do
        #filter defaultCommittee=true to show that committeeId
        Enum.filter(k["boothCommittees"], fn(k) ->
          k["defaultCommittee"] == true
        end)
      else
        []
      end
      #get booth members count
      ###{:ok, boothMembersCount} = ConstituencyRepo.getBoothMembersCount(groupObjectId, k["_id"])
      #IO.puts "#{boothMembersCount}"
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          #"boothName" => k["name"],
          "name" => k["name"],
          #"boothImage" => k["image"],
          "boothNumber" => k["boothNumber"],
          "boothAddress" => k["boothAddress"],
          "aboutBooth" => k["aboutBooth"],
          "image" => k["image"],
          # "workersCount" => 100,
          # "usersCount" => 10000,
          # "downloadedUserCount" => 1000,
          ##"adminName" => k["adminName"],
          ##"phone" => k["phone"],
          #"totalBoothMembersCount" => boothMembersCount,
          ##"members" => boothMembersCount,
          "allowTeamPostAll" => true,
          "allowTeamPostCommentAll" => true,
          "canAddUser" => true,
          "isTeamAdmin" => true,
          "category" => k["category"],
          "groupId" => encode_object_id(groupObjectId),
          "boothCommittee" => if length(filterCommitteeTrue) > 0 do
            hd(filterCommitteeTrue)
          else
            %{}
          end
      }
      map = if Map.has_key?(k, "zpId") do
        map
        |> Map.put("zpId", encode_object_id(k["zpId"]))
      else
        map
      end
      #get admin name and phpne number from user table
      adminDetail = UserRepo.find_user_by_id(k["adminId"])
      map = map
            |> Map.put_new("adminName", adminDetail["name"])
            |> Map.put_new("phone", adminDetail["phone"])
            |> Map.put_new("userName", adminDetail["name"])
            |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
            |> Map.put_new("userImage", adminDetail["image"])
      acc ++ [map]
    end)
    %{data: list}
  end



  def render("all_booths_election_list.json", %{booths: booths, groupObjectId: groupObjectId}) do
    list = Enum.reduce(booths, [], fn k, acc ->
      #1st get committee id that is default Committee of worker
      filterCommitteeTrue = if k["boothCommittees"] do
        #filter defaultCommittee=true to show that committeeId
        Enum.filter(k["boothCommittees"], fn(k) ->
          k["defaultCommittee"] == true
        end)
      else
        []
      end
      #get subBooth/street teams under this booth team members count
      ##totalBoothSubBoothMembersCount = ConstituencyRepo.getTotalBoothSubBoothMembersCount123(groupObjectId, k["_id"]) #k["_id"] is boothId
      map = %{
          "boothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"],
          "canAddUser" => true,
          "isTeamAdmin" => true,
          "category" => k["category"],
          "groupId" => encode_object_id(groupObjectId),
          "boothCommittee" => if length(filterCommitteeTrue) > 0 do
            hd(filterCommitteeTrue)
          else
            %{}
          end
      }
      #get admin name and phone number from user table
      adminDetail = UserRepo.find_user_by_id(k["adminId"])
      map = map
            |> Map.put_new("adminName", adminDetail["name"])
            |> Map.put_new("phone", adminDetail["phone"])
            |> Map.put_new("userName", adminDetail["name"])
            |> Map.put_new("userId", encode_object_id(adminDetail["_id"]))
            |> Map.put_new("userImage", adminDetail["image"])
      acc ++ [map]
    end)
    %{data: list}
  end


  def render("sub_booth_teams123.json", %{subBooths: subBooths, groupObjectId: groupObjectId}) do
    list = Enum.reduce(subBooths, [], fn k, acc ->
      #IO.puts "#{k}"
      #get booth members count
      {:ok, membersCount} = ConstituencyRepo.getBoothMembersCount(groupObjectId, k["_id"])
      #IO.puts "#{membersCount}"
      map = %{
          "subBoothId" => encode_object_id(k["_id"]),
          "teamId" => encode_object_id(k["_id"]),
          "name" => k["name"],
          "image" => k["image"],
          "adminName" => k["adminName"],
          "phone" => k["phone"],
          #"totalBoothMembersCount" => membersCount,
          "members" => membersCount,
          "allowTeamPostAll" => true,
          "allowTeamPostCommentAll" => true,
          "canAddUser" => true,
          "isTeamAdmin" => true,
          "category" => k["category"]
      }
      acc ++ [map]
    end)
    %{data: list}
  end


  # def render("booth_team_members123.json", %{ boothUsers: boothUsers, loginUserId: loginUserId, group: group }) do
  #   # IO.puts "#{group}"
  #   usersList = Enum.reduce(boothUsers, [], fn k, acc ->
  #      #check user downloaded and logged in from user_category_apps
  #      {:ok, getUserInUserCategoryApps} = AdminRepo.getUserInUserCategoryApps(k["userId"], group["_id"])
  #      if getUserInUserCategoryApps == 0 do
  #        #not downloaded
  #        userDownloadedApp = false
  #      else
  #        userDownloadedApp = true
  #      end
  #      #to check voter id field exists and updated
  #      {:ok, checkVoterFieldUpdate} = ConstituencyCategoryRepo.checkVoterFieldUpdate(k["userId"])
  #      voterIdExists = if checkVoterFieldUpdate == 1 do
  #       false
  #      else
  #       true
  #      end
  #     #get number of teams of this user
  #     ##{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
  #     #get this userId notification_token
  #     userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
  #     #IO.puts "#{userNotificationPushToken}"
  #     map = %{
  #       "userId" => encode_object_id(k["userId"]),
  #       "phone" => k["userDetails"]["phone"],
  #       "image" => k["userDetails"]["image"],
  #       "allowedToAddUser" => k["teams"]["allowedToAddUser"],
  #       "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
  #       "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
  #       ##"teamCount" => getTeamsCount,
  #       "name" => k["name"],
  #       "roleOnConstituency" => k["userDetails"]["roleOnConstituency"],
  #       "dob" => k["userDetails"]["dob"],
  #       "gender" => k["userDetails"]["gender"],
  #       "bloodGroup" => k["userDetails"]["bloodGroup"],
  #       "voterId" => k["userDetails"]["voterId"],
  #       "aadharNumber" => k["userDetails"]["aadharNumber"],
  #       "address" => k["userDetails"]["address"],
  #       "email" => k["userDetails"]["email"],
  #       "religion" => k["userDetails"]["religion"],
  #       "caste" => k["userDetails"]["caste"],
  #       "subCaste" => k["userDetails"]["subCaste"],
  #       "designation" => k["userDetails"]["designation"],
  #       "qualification" => k["userDetails"]["qualification"],
  #       "willVote" => k["userDetails"]["willVote"],
  #       "nonResidentialVoter" => k["userDetails"]["nonResidentialVoter"],
  #       "influencer" => k["userDetails"]["influencer"],
  #       "typeOfInfluencer" => k["userDetails"]["typeOfInfluencer"],
  #       "noOfVotes" => k["userDetails"]["noOfVotes"],
  #       "voterId" => k["userDetails"]["voterId"],
  #       "userDownloadedApp" => userDownloadedApp,
  #       "pushTokens" => userNotificationPushToken,
  #       "voterIdExists" => voterIdExists,
  #       "isLoginUser" => if k["userId"] == loginUserId do
  #         true
  #       else
  #         false
  #       end
  #     }
  #     acc ++ [map]
  #   end)
  #   %{ data: usersList }
  # end


  def render("booth_team_members.json", %{ boothUsers: boothUsers, loginUserId: loginUserId, group: group }) do
    # IO.puts "#{group}"
    usersList = Enum.reduce(boothUsers, [], fn k, acc ->
       #check user downloaded and logged in from user_category_apps
       {:ok, getUserInUserCategoryApps} = AdminRepo.getUserInUserCategoryApps(k["userId"], group["_id"])
       userDownloadedApp = if getUserInUserCategoryApps == 0 do
         #not downloaded
         false
       else
         true
       end
       #to check voter id field exists and
      #get number of teams of this user
      ##{:ok, getTeamsCount} = TeamRepo.getTeamsCountForUserAsAdmin(k["userId"], groupObjectId)
      #get this userId notification_token
      userNotificationPushToken = ConstituencyRepo.getUserNotificationPushToken(k["userId"])
      #IO.puts "#{userNotificationPushToken}"
      map = %{
        "userId" => encode_object_id(k["userId"]),
        "phone" => k["phone"],
        "image" => k["image"],
        "allowedToAddUser" => k["teams"]["allowedToAddUser"],
        "allowedToAddTeamPost" => k["teams"]["allowedToAddPost"],
        "allowedToAddTeamPostComment" => k["teams"]["allowedToAddComment"],
        ##"teamCount" => getTeamsCount,
        "name" => k["name"],
        "roleOnConstituency" => k["roleOnConstituency"],
        "dob" => k["dob"],
        "gender" => k["gender"],
        "bloodGroup" => k["bloodGroup"],
        "voterId" => k["voterId"],
        "aadharNumber" => k["userDetails"]["aadharNumber"],
        "address" => k["address"],
        "email" => k["email"],
        "religion" => k["religion"],
        "caste" => k["caste"],
        "subCaste" => k["subCaste"],
        "designation" => k["designation"],
        "qualification" => k["qualification"],
        "willVote" => k["willVote"],
        "nonResidentialVoter" => k["nonResidentialVoter"],
        "influencer" => k["influencer"],
        "typeOfInfluencer" => k["typeOfInfluencer"],
        "noOfVotes" => k["noOfVotes"],
        "blocked" => k["blocked"],
        "userDownloadedApp" => userDownloadedApp,
        "pushTokens" => userNotificationPushToken,
        # "voterIdExists" => voterIdExists,
        "isLoginUser" => if k["userId"] == loginUserId do
          true
        else
          false
        end
      }
      acc ++ [map]
    end)
    usersList = usersList
    |> Enum.sort_by(& String.downcase(&1["name"]))
    %{ data: usersList }
  end


  def render("user_profile_detail.json", %{ user: user, teams: teamsNameList}) do
    userStringId = encode_object_id(user["_id"])
    user = user
    |> Map.delete("_id")
    |> Map.put("teams", teamsNameList)
    |> Map.put("userId", userStringId)
    |> Map.delete("user_secret_otp")
    |> Map.delete("password_hash")
    user = if user["profileUpdatedBy"] do
      Map.put(user, "profileUpdatedBy", encode_object_id(user["profileUpdatedBy"]))
    else
      user
    end
    %{ data: user }
  end


  def render("family_voters_list.json", %{ familyVotersList: familyVotersList }) do
    #IO.puts "#{familyVotersList}"
    votersList = Enum.reduce(familyVotersList, [], fn k, acc ->
      #IO.puts "#{k}"
      map = %{
        "name" => k["name"],
        "relationship" => k["relationship"],
        "address" => k["address"],
        "country" => "IN",
        "phone" => k["phone"],
        "dob" => k["dob"],
        "gender" => k["gender"],
        "bloodGroup" => k["bloodGroup"],
        "voterId" => k["voterId"],
        "aadharNumber" => k["aadharNumber"],
        "image" => k["image"],
        "familyMemberId" => k["familyMemberId"],
        "userId" => k["userId"],
        "email" => k["email"],
        "qualification" => k["qualification"],
        "designation" => k["designation"],
        #"education" => k["education"],
        #"occupation" => k["occupation"],
        "religion" => k["religion"],
        "caste" => k["caste"],
        "subCaste" => k["subCaste"],
      }
      acc ++ [map]
    end)
    %{ data: votersList }
  end



  def render("myBoothTeams.json", %{ myBoothTeams: myBoothTeams, groupObjectId: groupObjectId }) do
    result = Enum.reduce(myBoothTeams, [], fn k, acc ->
      #get booth members count
      {:ok, boothMembersCount} = ConstituencyRepo.getBoothMembersCount(groupObjectId, k["teams"]["teamId"])
      map = %{
        "teamId" => encode_object_id(k["teams"]["teamId"]),
        "boothId" => encode_object_id(k["teams"]["teamId"]),
        "name" => k["teamDetails"]["name"],
        "image" => k["teamDetails"]["image"],
        "members" => boothMembersCount,
        "category" => k["teamDetails"]["category"],
        "userId" => encode_object_id(k["teamDetails"]["adminId"]),   #adminId as userId to get profile details in my Teams heirarchy in more option
        "allowTeamPostAll" => true,
        "allowTeamPostCommentAll" => true,
        "canAddUser" => true,
        "isTeamAdmin" => true,
        "groupId" => encode_object_id(groupObjectId)
      }
      acc ++ [map]
    end)
    %{ data: result }
  end


  def render("mySubBoothTeams.json", %{ mySubBoothTeams: mySubBoothTeams, groupObjectId: groupObjectId }) do
    result = Enum.reduce(mySubBoothTeams, [], fn k, acc ->
      #get booth members count
      {:ok, boothMembersCount} = ConstituencyRepo.getBoothMembersCount(groupObjectId, k["teams"]["teamId"])
      map = %{
        "teamId" => encode_object_id(k["teams"]["teamId"]),
        "subBoothId" => encode_object_id(k["teams"]["teamId"]),
        "name" => k["teamDetails"]["name"],
        "image" => k["teamDetails"]["image"],
        "members" => boothMembersCount,
        "category" => k["teamDetails"]["category"],
        "userId" => encode_object_id(k["teamDetails"]["adminId"]),
        "allowTeamPostAll" => true,
        "allowTeamPostCommentAll" => true,
        "canAddUser" => true,
        "isTeamAdmin" => true,
        "groupId" => encode_object_id(groupObjectId)
      }
      acc ++ [map]
    end)
    %{ data: result }
  end


  def render("constituency_issues.json", %{ constituencyIssues: constituencyIssues }) do
    result = Enum.reduce(constituencyIssues, [], fn k, acc ->
      map = %{
        "issueId" => encode_object_id(k["_id"]),
        "issue" => k["issue"],
        "jurisdiction" => k["jurisdiction"],
        "dueDays" => k["dueDays"],
        "groupId" => encode_object_id(k["groupId"]),
      }
      #department user detail
      departmentUserMap = if !is_nil(k["departmentUserId"]) do
        #get this user details from users col
        departmentUserDetails = UserRepo.find_user_by_id(k["departmentUserId"])
        %{
          "userId" => encode_object_id(k["departmentUserId"]),
          "name" => departmentUserDetails["name"],
          "phone" => departmentUserDetails["phone"],
          "designation" => departmentUserDetails["constituencyDesignation"]
        }
      else
        %{
          "userId" => k["null"],
          "name" => k["null"],
          "phone" => k["null"],
          "designation" => k["null"]
        }
      end
      map = Map.put_new(map, "departmentUser", departmentUserMap)
      #party user detail
      partyUserMap = if !is_nil(k["partyUserId"]) do
        #get this user details from users col
        partyUserDetails = UserRepo.find_user_by_id(k["partyUserId"])
        %{
          "userId" => encode_object_id(k["partyUserId"]),
          "name" => partyUserDetails["name"],
          "phone" => partyUserDetails["phone"],
          "designation" => partyUserDetails["constituencyDesignation"]
        }
      else
        %{
          "userId" => k["null"],
          "name" => k["null"],
          "phone" => k["null"],
          "designation" => k["null"]
        }
      end
      map = Map.put_new(map, "partyUser", partyUserMap)

      acc ++ [map]
    end)
    %{ data: result }
  end



  def render("booth_coordinators123.json", %{ getBoothCoordinators: getBoothCoordinators }) do
    result = Enum.reduce(getBoothCoordinators, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["userDetails"]["_id"]),
        "name" => k["userDetails"]["name"],
        "phone" => k["userDetails"]["phone"],
        "address" => k["userDetails"]["address"],
        "dob" => k["userDetails"]["dob"],
        "gender" => k["userDetails"]["gender"],
        "bloodGroup" => k["userDetails"]["bloodGroup"],
        "salary" => k["userDetails"]["salary"],
        "voterId" => k["userDetails"]["voterId"],
        "aadharNumber" => k["userDetails"]["aadharNumber"]
        #"role" => k["userDetails"]["roleOnConstituency"]
      }
      acc ++ [map]
    end)
    %{ data: result }
  end



  def render("my_booth_subbooth_teams.json", %{ myBoothOrSubBoothTeams: myBoothOrSubBoothTeams }) do
    result = Enum.reduce(myBoothOrSubBoothTeams, [], fn k, acc ->
      map = %{
        "teamId" => encode_object_id(k["teamId"]),
        "name" => k["teamName"]
      }
      acc ++ [map]
    end)
    %{ data: result }
  end




  ############################ ISSUES list baseed on roles#################################################################
  def render("get_issues_tickets_list_department_taskforce.json", %{ issuesTicketsList: issuesTicketsList, groupObjectId: groupObjectId, issueIds: issueIds,
                                                          params: params, pageLimit: pageLimit }) do

    if !issuesTicketsList do
      %{ data: [], totalNumberOfPages: 0 }
    end
    result = Enum.reduce(issuesTicketsList, [], fn k, acc ->
      #get coordinator for this team/booth
      ##getCoordinators = ConstituencyRepo.getListOfBoothCoordinators(groupObjectId, k["teamId"])
      ##ordinatorList = Enum.reduce(getCoordinators, [], fn k, acc ->
      ##  #get userDetail from users_col###################
      ##  coordinatorDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      ##  map = %{
      ##    "_id" => encode_object_id(coordinatorDetails["_id"]),
      ##    "name" => coordinatorDetails["name"],
      ##    "phone" => coordinatorDetails["phone"],
      ##    #"image" => coordinatorDetails["image"],
      ##    "constituencyDesignation" => "Booth Coordinator"
      ##  }
      ##  acc ++ [map]
      ##end)
      #get issueId details from constituency_issues ####################
      getConstituencyIssueDetails = ConstituencyRepo.getConstituencyIssueDetailsById(k["issueId"])
      taskForceMap = if !is_nil(getConstituencyIssueDetails["departmentUserId"]) do
        #get department and party task force user details
        departmentTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["departmentUserId"])
        partyTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["partyUserId"])
        %{
          departmentTaskForceMap:  %{
            "_id" => encode_object_id(departmentTaskForceDetails["_id"]),
            "name" => departmentTaskForceDetails["name"],
            "phone" => departmentTaskForceDetails["phone"],
            #"image" => departmentTaskForceDetails["image"],
            "constituencyDesignation" => if departmentTaskForceDetails["constituencyDesignation"] do
              departmentTaskForceDetails["constituencyDesignation"]
            else
              "Department Task Force"
            end
          },
          partTaskForceMap:  %{
            "_id" => encode_object_id(partyTaskForceDetails["_id"]),
            "name" => partyTaskForceDetails["name"],
            "phone" => partyTaskForceDetails["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if partyTaskForceDetails["constituencyDesignation"] do
              partyTaskForceDetails["constituencyDesignation"]
            else
              "Party Task Force"
            end
          }
        }
      else
        %{
          departmentTaskForceMap: %{},
          partTaskForceMap: %{}
        }
      end
      #get team details with team incharge details (Booth president/ Booth member/worker)
      #get team details from teamId
      teamDetails = ConstituencyRepo.getTeamDetailsById(k["teamId"])
      boothInchargeMap = if teamDetails["category"] == "booth" do
        #is is a booth team so just show booth president/admin name
        boothTeamAdminId = teamDetails["adminId"]
        #get booth admin details
        adminUserDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamAdminId)
        # add details to teamDetail map
        [
          %{
            "teamName" => teamDetails["name"],
            "_id" => encode_object_id(adminUserDetail["_id"]),
            "name" => adminUserDetail["name"],
            "phone" => adminUserDetail["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if adminUserDetail["constituencyDesignation"] do
              adminUserDetail["constituencyDesignation"]
            else
              "Booth President"
            end
          }
        ]
      else
        if teamDetails["category"] == "subBooth" do
          #get booth team for subBooth // getBoothTeamDetailForSubBooth(teamDetails["boothTeamId"])
          boothTeamDetailsForSubBooth = ConstituencyRepo.getTeamDetailsById(teamDetails["boothTeamId"])
          #IO.puts "#{boothTeamDetailsForSubBooth}"
          subBoothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(teamDetails["adminId"])
          boothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamDetailsForSubBooth["adminId"])
          [
           %{
              "teamName" => boothTeamDetailsForSubBooth["name"],
              #"teamCategory" => boothTeamDetailsForSubBooth["category"],
              "_id" => encode_object_id(boothAdminDetail["_id"]),
              "name" => boothAdminDetail["name"],
              "phone" => boothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if boothAdminDetail["constituencyDesignation"] do
                boothAdminDetail["constituencyDesignation"]
              else
                "Booth President"
              end
            },
            %{
              "teamName" => teamDetails["name"],
              #"teamCategory" => teamDetails["category"],
              "_id" => encode_object_id(subBoothAdminDetail["_id"]),
              "name" => subBoothAdminDetail["name"],
              "phone" => subBoothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if subBoothAdminDetail["constituencyDesignation"] do
                subBoothAdminDetail["constituencyDesignation"]
              else
                "Booth Member"
              end
            }
          ]
        end
      end
      #issues post map #############################################
      #get issue posted user detail
      issueCreatedByDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      issuePostMap = %{
        "issuePostId" => encode_object_id(k["_id"]),
        "issuePartyTaskForceStatus" => k["partyTaskForceStatus"],
        "adminStatus" => k["adminStatus"],
        "issueDepartmentTaskForceStatus" => k["departmentTaskForceStatus"],
        "issueCreatedById" => encode_object_id(issueCreatedByDetails["_id"]),
        "issueCreatedByName" => issueCreatedByDetails["name"],
        "issueCreatedByPhone" => issueCreatedByDetails["phone"],
        "issueCreatedByImage" => issueCreatedByDetails["image"],
        "issueCreatedAt" => k["insertedAt"],
        "issueText" => k["text"],
        "issueLocation" => k["location"],
        ##"boothCoordinators" => coordinatorList,
        "constituencyIssue" => getConstituencyIssueDetails["issue"],
        "constituencyIssueJurisdiction" => getConstituencyIssueDetails["jurisdiction"],
        "constituencyIssueDepartmentTaskForce" => taskForceMap.departmentTaskForceMap,
        "constituencyIssuePartyTaskForce" => taskForceMap.partTaskForceMap,
        "boothIncharge" => boothInchargeMap,
      }
      issuePostMap = if !is_nil(k["fileName"]) do
        issuePostMap
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        issuePostMap
      end
      issuePostMap = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          issuePostMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          issuePostMap
        end
      else
        issuePostMap
      end
      #if thumbnailImage for video and pdf is not nil then display
      issuePostMap = if !is_nil(k["thumbnailImage"]) do
        issuePostMap
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        issuePostMap
      end
      acc ++ [issuePostMap]
    end)
    #get total number of pages (For Pagination)
    {:ok, issuesPostCount} = ConstituencyRepo.getTotalIssuesTicketsCountOnOptionSelectedForDepartmentTaskForce(groupObjectId, issueIds, params["option"])
    pageCount = Float.ceil(issuesPostCount / pageLimit)
    totalPages = round(pageCount)

    %{ data: result, totalNumberOfPages: totalPages, totalPostCount: issuesPostCount }
  end





  def render("get_issues_tickets_list_party_taskforce.json", %{ issuesTicketsList: issuesTicketsList, groupObjectId: groupObjectId, issueIds: issueIds,
                                                          params: params, pageLimit: pageLimit }) do

    if !issuesTicketsList do
      %{ data: [], totalNumberOfPages: 0 }
    end
    result = Enum.reduce(issuesTicketsList, [], fn k, acc ->
      #get coordinator for this team/booth
      ##getCoordinators = ConstituencyRepo.getListOfBoothCoordinators(groupObjectId, k["teamId"])
      ##coordinatorList = Enum.reduce(getCoordinators, [], fn k, acc ->
      ##  #get userDetail from users_col###################
      ##  coordinatorDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      ##  map = %{
      ##    "_id" => encode_object_id(coordinatorDetails["_id"]),
      ##    "name" => coordinatorDetails["name"],
      ##    "phone" => coordinatorDetails["phone"],
      ##    #"image" => coordinatorDetails["image"],
      ##    "constituencyDesignation" => "Booth Coordinator"
      ##  }
      ##  acc ++ [map]
      ##end)
      #get issueId details from constituency_issues ####################
      getConstituencyIssueDetails = ConstituencyRepo.getConstituencyIssueDetailsById(k["issueId"])
      taskForceMap = if !is_nil(getConstituencyIssueDetails["departmentUserId"]) do
        #get department and party task force user details
        departmentTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["departmentUserId"])
        partyTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["partyUserId"])
        %{
          departmentTaskForceMap: %{
            "_id" => encode_object_id(departmentTaskForceDetails["_id"]),
            "name" => departmentTaskForceDetails["name"],
            "phone" => departmentTaskForceDetails["phone"],
            #"image" => departmentTaskForceDetails["image"],
            "constituencyDesignation" => if departmentTaskForceDetails["constituencyDesignation"] do
              departmentTaskForceDetails["constituencyDesignation"]
            else
              "Department Task Force"
            end
          },
          partTaskForceMap: %{
            "_id" => encode_object_id(partyTaskForceDetails["_id"]),
            "name" => partyTaskForceDetails["name"],
            "phone" => partyTaskForceDetails["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if partyTaskForceDetails["constituencyDesignation"] do
              partyTaskForceDetails["constituencyDesignation"]
            else
              "Party Task Force"
            end
          }

        }
      else
        %{
          departmentTaskForceMap: %{},
          partTaskForceMap: %{}
        }
      end
      #get team details with team incharge details (Booth president/ Booth member/worker)
      #get team details from teamId
      teamDetails = ConstituencyRepo.getTeamDetailsById(k["teamId"])
      boothInchargeMap = if teamDetails["category"] == "booth" do
        #is is a booth team so just show booth president/admin name
        boothTeamAdminId = teamDetails["adminId"]
        #get booth admin details
        adminUserDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamAdminId)
        # add details to teamDetail map
        [
          %{
            "teamName" => teamDetails["name"],
            "_id" => encode_object_id(adminUserDetail["_id"]),
            "name" => adminUserDetail["name"],
            "phone" => adminUserDetail["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if adminUserDetail["constituencyDesignation"] do
              adminUserDetail["constituencyDesignation"]
            else
              "Booth President"
            end
          }
        ]
      else
        if teamDetails["category"] == "subBooth" do
          #get booth team for subBooth // getBoothTeamDetailForSubBooth(teamDetails["boothTeamId"])
          boothTeamDetailsForSubBooth = ConstituencyRepo.getTeamDetailsById(teamDetails["boothTeamId"])
          #IO.puts "#{boothTeamDetailsForSubBooth}"
          subBoothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(teamDetails["adminId"])
          boothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamDetailsForSubBooth["adminId"])
          [
           %{
              "teamName" => boothTeamDetailsForSubBooth["name"],
              #"teamCategory" => boothTeamDetailsForSubBooth["category"],
              "_id" => encode_object_id(boothAdminDetail["_id"]),
              "name" => boothAdminDetail["name"],
              "phone" => boothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if boothAdminDetail["constituencyDesignation"] do
                boothAdminDetail["constituencyDesignation"]
              else
                "Booth President"
              end
            },
            %{
              "teamName" => teamDetails["name"],
              #"teamCategory" => teamDetails["category"],
              "_id" => encode_object_id(subBoothAdminDetail["_id"]),
              "name" => subBoothAdminDetail["name"],
              "phone" => subBoothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if subBoothAdminDetail["constituencyDesignation"] do
                subBoothAdminDetail["constituencyDesignation"]
              else
                "Booth Member"
              end
            }
          ]
        end
      end
      #issues post map #############################################
      #get issue posted user detail
      issueCreatedByDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      issuePostMap = %{
        "issuePostId" => encode_object_id(k["_id"]),
        "issuePartyTaskForceStatus" => k["partyTaskForceStatus"],
        "adminStatus" => k["adminStatus"],
        "issueDepartmentTaskForceStatus" => k["departmentTaskForceStatus"],
        "issueCreatedById" => encode_object_id(issueCreatedByDetails["_id"]),
        "issueCreatedByName" => issueCreatedByDetails["name"],
        "issueCreatedByPhone" => issueCreatedByDetails["phone"],
        "issueCreatedByImage" => issueCreatedByDetails["image"],
        "issueCreatedAt" => k["insertedAt"],
        "issueText" => k["text"],
        "issueLocation" => k["location"],
        ##"boothCoordinators" => coordinatorList,
        "constituencyIssue" => getConstituencyIssueDetails["issue"],
        "constituencyIssueJurisdiction" => getConstituencyIssueDetails["jurisdiction"],
        "constituencyIssueDepartmentTaskForce" => taskForceMap.departmentTaskForceMap,
        "constituencyIssuePartyTaskForce" => taskForceMap.partTaskForceMap,
        "boothIncharge" => boothInchargeMap,
      }
      if !is_nil(k["fileName"]) do
        issuePostMap
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        issuePostMap
      end
      if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          issuePostMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          issuePostMap
        end
      else
        issuePostMap
      end
      #if thumbnailImage for video and pdf is not nil then display
      if !is_nil(k["thumbnailImage"]) do
        issuePostMap
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        issuePostMap
      end
      acc ++ [issuePostMap]
    end)
    #get total number of pages (For Pagination)
    {:ok, issuesPostCount} = ConstituencyRepo.getTotalIssuesTicketsCountOnOptionSelectedForTaskForce(groupObjectId, issueIds, params["option"])
    pageCount = Float.ceil(issuesPostCount / pageLimit)
    totalPages = round(pageCount)

    %{ data: result, totalNumberOfPages: totalPages, totalPostCount: issuesPostCount }
  end




  def render("get_issues_tickets_list_admin.json", %{ issuesTicketsList: issuesTicketsList, groupObjectId: groupObjectId,
                                                      params: params, pageLimit: pageLimit }) do

    if !issuesTicketsList do
      %{ data: [], totalNumberOfPages: 0 }
    end
    result = Enum.reduce(issuesTicketsList, [], fn k, acc ->
      #get coordinator for this team/booth
      ##getCoordinators = ConstituencyRepo.getListOfBoothCoordinators(groupObjectId, k["teamId"])
      ##coordinatorList = Enum.reduce(getCoordinators, [], fn k, acc ->
      ##  #get userDetail from users_col###################
      ##  coordinatorDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      ##  map = %{
      ##    "_id" => encode_object_id(coordinatorDetails["_id"]),
      ##    "name" => coordinatorDetails["name"],
      ##    "phone" => coordinatorDetails["phone"],
      ##    #"image" => coordinatorDetails["image"],
      ##    "constituencyDesignation" => "Booth Coordinator"
      ##  }
      ##  acc ++ [map]
      ##end)
      #get issueId details from constituency_issues ####################
      getConstituencyIssueDetails = ConstituencyRepo.getConstituencyIssueDetailsById(k["issueId"])
      taskForceMap = if !is_nil(getConstituencyIssueDetails["departmentUserId"]) do
        #get department and party task force user details
        departmentTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["departmentUserId"])
        partyTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["partyUserId"])
        %{
          departmentTaskForceMap: %{
            "_id" => encode_object_id(departmentTaskForceDetails["_id"]),
            "name" => departmentTaskForceDetails["name"],
            "phone" => departmentTaskForceDetails["phone"],
            #"image" => departmentTaskForceDetails["image"],
            "constituencyDesignation" => if departmentTaskForceDetails["constituencyDesignation"] do
              departmentTaskForceDetails["constituencyDesignation"]
            else
              "Department Task Force"
            end
          },
          partTaskForceMap: %{
            "_id" => encode_object_id(partyTaskForceDetails["_id"]),
            "name" => partyTaskForceDetails["name"],
            "phone" => partyTaskForceDetails["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if partyTaskForceDetails["constituencyDesignation"] do
              partyTaskForceDetails["constituencyDesignation"]
            else
              "Party Task Force"
            end
          }
        }
      else
        %{
          departmentTaskForceMap: %{},
          partTaskForceMap: %{}
        }
      end
      #get team details with team incharge details (Booth president/ Booth member/worker)
      #get team details from teamId
      teamDetails = ConstituencyRepo.getTeamDetailsById(k["teamId"])
      boothInchargeMap = if teamDetails["category"] == "booth" do
        #is is a booth team so just show booth president/admin name
        boothTeamAdminId = teamDetails["adminId"]
        #get booth admin details
        adminUserDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamAdminId)
        # add details to teamDetail map
        [
          %{
            "teamName" => teamDetails["name"],
            "_id" => encode_object_id(adminUserDetail["_id"]),
            "name" => adminUserDetail["name"],
            "phone" => adminUserDetail["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if adminUserDetail["constituencyDesignation"] do
              adminUserDetail["constituencyDesignation"]
            else
              "Booth President"
            end
          }
        ]
      else
        if teamDetails["category"] == "subBooth" do
          #get booth team for subBooth // getBoothTeamDetailForSubBooth(teamDetails["boothTeamId"])
          boothTeamDetailsForSubBooth = ConstituencyRepo.getTeamDetailsById(teamDetails["boothTeamId"])
          #IO.puts "#{boothTeamDetailsForSubBooth}"
          subBoothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(teamDetails["adminId"])
          boothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamDetailsForSubBooth["adminId"])
          [
           %{
              "teamName" => boothTeamDetailsForSubBooth["name"],
              #"teamCategory" => boothTeamDetailsForSubBooth["category"],
              "_id" => encode_object_id(boothAdminDetail["_id"]),
              "name" => boothAdminDetail["name"],
              "phone" => boothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if boothAdminDetail["constituencyDesignation"] do
                boothAdminDetail["constituencyDesignation"]
              else
                "Booth President"
              end
            },
            %{
              "teamName" => teamDetails["name"],
              #"teamCategory" => teamDetails["category"],
              "_id" => encode_object_id(subBoothAdminDetail["_id"]),
              "name" => subBoothAdminDetail["name"],
              "phone" => subBoothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if subBoothAdminDetail["constituencyDesignation"] do
                subBoothAdminDetail["constituencyDesignation"]
              else
                "Booth Member"
              end
            }
          ]
        end
      end
      #issues post map #############################################
      #get issue posted user detail
      issueCreatedByDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      issuePostMap = %{
        "issuePostId" => encode_object_id(k["_id"]),
        "issuePartyTaskForceStatus" => k["partyTaskForceStatus"],
        "adminStatus" => k["adminStatus"],
        "issueDepartmentTaskForceStatus" => k["departmentTaskForceStatus"],
        "issueCreatedById" => encode_object_id(issueCreatedByDetails["_id"]),
        "issueCreatedByName" => issueCreatedByDetails["name"],
        "issueCreatedByPhone" => issueCreatedByDetails["phone"],
        "issueCreatedByImage" => issueCreatedByDetails["image"],
        "issueCreatedAt" => k["insertedAt"],
        "issueText" => k["text"],
        "issueLocation" => k["location"],
        ##"boothCoordinators" => coordinatorList,
        "constituencyIssue" => getConstituencyIssueDetails["issue"],
        "constituencyIssueJurisdiction" => getConstituencyIssueDetails["jurisdiction"],
        "constituencyIssueDepartmentTaskForce" => taskForceMap.departmentTaskForceMap,
        "constituencyIssuePartyTaskForce" => taskForceMap.partTaskForceMap,
        "boothIncharge" => boothInchargeMap,
      }
      issuePostMap = if !is_nil(k["fileName"]) do
        issuePostMap
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        issuePostMap
      end
      issuePostMap = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          issuePostMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          issuePostMap
        end
      else
        issuePostMap
      end
      #if thumbnailImage for video and pdf is not nil then display
      issuePostMap = if !is_nil(k["thumbnailImage"]) do
        issuePostMap
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        issuePostMap
      end
      acc ++ [issuePostMap]
    end)
    #get total number of pages (For Pagination)
    {:ok, issuesPostCount} = ConstituencyRepo.getTotalIssuesTicketsCountOnOptionSelectedForAdmin(groupObjectId, params["option"])
    pageCount = Float.ceil(issuesPostCount / pageLimit)
    totalPages = round(pageCount)

    %{ data: result, totalNumberOfPages: totalPages, totalPostCount: issuesPostCount }
  end




  def render("get_issues_tickets_list_booth_president.json", %{ issuesTicketsList: issuesTicketsList, groupObjectId: groupObjectId, teamIds: teamIds,
                                                params: params, pageLimit: pageLimit }) do
    if !issuesTicketsList do
      %{ data: [], totalNumberOfPages: 0 }
    end
    result = Enum.reduce(issuesTicketsList, [], fn k, acc ->
      ###get coordinator for this team/booth
      ##getCoordinators = ConstituencyRepo.getListOfBoothCoordinators(groupObjectId, k["teamId"])
      ##coordinatorList = Enum.reduce(getCoordinators, [], fn k, acc ->
      ##  #get userDetail from users_col###################
      ##  coordinatorDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      ##  map = %{
      ##    "_id" => encode_object_id(coordinatorDetails["_id"]),
      ##    "name" => coordinatorDetails["name"],
      ##    "phone" => coordinatorDetails["phone"],
      ##    #"image" => coordinatorDetails["image"],
      ##    "constituencyDesignation" => "Booth Coordinator"
      ##  }
      ##  acc ++ [map]
      ##end)
      #get issueId details from constituency_issues ####################
      getConstituencyIssueDetails = ConstituencyRepo.getConstituencyIssueDetailsById(k["issueId"])
      taskForceMap = if !is_nil(getConstituencyIssueDetails["departmentUserId"]) do
        #get department and party task force user details
        departmentTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["departmentUserId"])
        partyTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["partyUserId"])
        %{
          departmentTaskForceMap:  %{
            "_id" => encode_object_id(departmentTaskForceDetails["_id"]),
            "name" => departmentTaskForceDetails["name"],
            "phone" => departmentTaskForceDetails["phone"],
            #"image" => departmentTaskForceDetails["image"],
            "constituencyDesignation" => if departmentTaskForceDetails["constituencyDesignation"] do
              departmentTaskForceDetails["constituencyDesignation"]
            else
              "Department Task Force"
            end
          },
          partTaskForceMap:  %{
            "_id" => encode_object_id(partyTaskForceDetails["_id"]),
            "name" => partyTaskForceDetails["name"],
            "phone" => partyTaskForceDetails["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if partyTaskForceDetails["constituencyDesignation"] do
              partyTaskForceDetails["constituencyDesignation"]
            else
              "Party Task Force"
            end
          }
        }
      else
        %{
          departmentTaskForceMap: %{},
          partTaskForceMap: %{}
        }
      end
      #get team details with team incharge details (Booth president/ Booth member/worker)
      #get team details from teamId
      teamDetails = ConstituencyRepo.getTeamDetailsById(k["teamId"])
      boothInchargeMap = if teamDetails["category"] == "booth" do
        #is is a booth team so just show booth president/admin name
        boothTeamAdminId = teamDetails["adminId"]
        #get booth admin details
        adminUserDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamAdminId)
        # add details to teamDetail map
        [
          %{
            "teamName" => teamDetails["name"],
            "_id" => encode_object_id(adminUserDetail["_id"]),
            "name" => adminUserDetail["name"],
            "phone" => adminUserDetail["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if adminUserDetail["constituencyDesignation"] do
              adminUserDetail["constituencyDesignation"]
            else
              "Booth President"
            end
          }
        ]
      else
        if teamDetails["category"] == "subBooth" do
          #get booth team for subBooth // getBoothTeamDetailForSubBooth(teamDetails["boothTeamId"])
          boothTeamDetailsForSubBooth = ConstituencyRepo.getTeamDetailsById(teamDetails["boothTeamId"])
          #IO.puts "#{boothTeamDetailsForSubBooth}"
          subBoothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(teamDetails["adminId"])
          boothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamDetailsForSubBooth["adminId"])
          [
           %{
              "teamName" => boothTeamDetailsForSubBooth["name"],
              #"teamCategory" => boothTeamDetailsForSubBooth["category"],
              "_id" => encode_object_id(boothAdminDetail["_id"]),
              "name" => boothAdminDetail["name"],
              "phone" => boothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if boothAdminDetail["constituencyDesignation"] do
                boothAdminDetail["constituencyDesignation"]
              else
                "Booth President"
              end
            },
            %{
              "teamName" => teamDetails["name"],
              #"teamCategory" => teamDetails["category"],
              "_id" => encode_object_id(subBoothAdminDetail["_id"]),
              "name" => subBoothAdminDetail["name"],
              "phone" => subBoothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if subBoothAdminDetail["constituencyDesignation"] do
                subBoothAdminDetail["constituencyDesignation"]
              else
                "Booth Member"
              end
            }
          ]
        end
      end
      #issues post map #############################################
      #get issue posted user detail
      issueCreatedByDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      issuePostMap = %{
        "issuePostId" => encode_object_id(k["_id"]),
        "issuePartyTaskForceStatus" => k["partyTaskForceStatus"],
        "adminStatus" => k["adminStatus"],
        "issueDepartmentTaskForceStatus" => k["departmentTaskForceStatus"],
        "issueCreatedById" => encode_object_id(issueCreatedByDetails["_id"]),
        "issueCreatedByName" => issueCreatedByDetails["name"],
        "issueCreatedByPhone" => issueCreatedByDetails["phone"],
        "issueCreatedByImage" => issueCreatedByDetails["image"],
        "issueCreatedAt" => k["insertedAt"],
        "issueText" => k["text"],
        "issueLocation" => k["location"],
        ##"boothCoordinators" => coordinatorList,
        "constituencyIssue" => getConstituencyIssueDetails["issue"],
        "constituencyIssueJurisdiction" => getConstituencyIssueDetails["jurisdiction"],
        "constituencyIssueDepartmentTaskForce" => taskForceMap.departmentTaskForceMap,
        "constituencyIssuePartyTaskForce" => taskForceMap.partTaskForceMap,
        "boothIncharge" => boothInchargeMap,
      }
      issuePostMap = if !is_nil(k["fileName"]) do
        issuePostMap
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        issuePostMap
      end
      issuePostMap = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          issuePostMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          issuePostMap
        end
      else
        issuePostMap
      end
      #if thumbnailImage for video and pdf is not nil then display
      issuePostMap = if !is_nil(k["thumbnailImage"]) do
        issuePostMap
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        issuePostMap
      end
      #merge both issue_post_details and issue_posts map
      ##finalMap = Map.merge(map, issuePostMap)
      ##finalMap1 = Map.merge(%{"teamDetails" => userTeamDetailsMap}, finalMap)
      acc ++ [issuePostMap]
    end)
    #get total number of pages (For Pagination)
    {:ok, issuesPostCount} = ConstituencyRepo.getTotalIssuesTicketsCountOnOptionSelectedForBoothPresident(groupObjectId, teamIds, params["option"])
    pageCount = Float.ceil(issuesPostCount / pageLimit)
    totalPages = round(pageCount)
    %{ data: result, totalNumberOfPages: totalPages, totalPostCount: issuesPostCount }
  end




  def render("get_issues_tickets_list_public.json", %{ issuesTicketsList: issuesTicketsList, groupObjectId: groupObjectId, loginUserId: loginUserId,
                                                       params: params, pageLimit: pageLimit }) do
    if !issuesTicketsList do
      %{ data: [], totalNumberOfPages: 0 }
    end
    result = Enum.reduce(issuesTicketsList, [], fn k, acc ->
      getConstituencyIssueDetails = ConstituencyRepo.getConstituencyIssueDetailsById(k["issueId"])
      taskForceMap = if !is_nil(getConstituencyIssueDetails["departmentUserId"]) do
        #get department and party task force user details
        departmentTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["departmentUserId"])
        partyTaskForceDetails = ConstituencyRepo.getUserDetailFromUserCol(getConstituencyIssueDetails["partyUserId"])
        %{
          departmentTaskForceMap:  %{
            "_id" => encode_object_id(departmentTaskForceDetails["_id"]),
            "name" => departmentTaskForceDetails["name"],
            "phone" => departmentTaskForceDetails["phone"],
            #"image" => departmentTaskForceDetails["image"],
            "constituencyDesignation" => if departmentTaskForceDetails["constituencyDesignation"] do
              departmentTaskForceDetails["constituencyDesignation"]
            else
              "Department Task Force"
            end
          },
          partTaskForceMap:  %{
            "_id" => encode_object_id(partyTaskForceDetails["_id"]),
            "name" => partyTaskForceDetails["name"],
            "phone" => partyTaskForceDetails["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if partyTaskForceDetails["constituencyDesignation"] do
              partyTaskForceDetails["constituencyDesignation"]
            else
              "Party Task Force"
            end
          }
        }
      else
        %{
          departmentTaskForceMap: %{},
          partTaskForceMap: %{}
        }
      end
      #get team details with team incharge details (Booth president/ Booth member/worker)
      #get team details from teamId
      teamDetails = ConstituencyRepo.getTeamDetailsById(k["teamId"])
      boothInchargeMap = if teamDetails["category"] == "booth" do
        #is is a booth team so just show booth president/admin name
        boothTeamAdminId = teamDetails["adminId"]
        #get booth admin details
        adminUserDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamAdminId)
        # add details to teamDetail map
        [
          %{
            "teamName" => teamDetails["name"],
            "_id" => encode_object_id(adminUserDetail["_id"]),
            "name" => adminUserDetail["name"],
            "phone" => adminUserDetail["phone"],
            #"image" => partyTaskForceDetails["image"],
            "constituencyDesignation" => if adminUserDetail["constituencyDesignation"] do
              adminUserDetail["constituencyDesignation"]
            else
              "Booth President"
            end
          }
        ]
      else
        if teamDetails["category"] == "subBooth" do
          #get booth team for subBooth // getBoothTeamDetailForSubBooth(teamDetails["boothTeamId"])
          boothTeamDetailsForSubBooth = ConstituencyRepo.getTeamDetailsById(teamDetails["boothTeamId"])
          #IO.puts "#{boothTeamDetailsForSubBooth}"
          subBoothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(teamDetails["adminId"])
          boothAdminDetail = ConstituencyRepo.getUserDetailFromUserCol(boothTeamDetailsForSubBooth["adminId"])
          [
           %{
              "teamName" => boothTeamDetailsForSubBooth["name"],
              #"teamCategory" => boothTeamDetailsForSubBooth["category"],
              "_id" => encode_object_id(boothAdminDetail["_id"]),
              "name" => boothAdminDetail["name"],
              "phone" => boothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if boothAdminDetail["constituencyDesignation"] do
                boothAdminDetail["constituencyDesignation"]
              else
                "Booth President"
              end
            },
            %{
              "teamName" => teamDetails["name"],
              #"teamCategory" => teamDetails["category"],
              "_id" => encode_object_id(subBoothAdminDetail["_id"]),
              "name" => subBoothAdminDetail["name"],
              "phone" => subBoothAdminDetail["phone"],
              #"image" => partyTaskForceDetails["image"],
              "constituencyDesignation" => if subBoothAdminDetail["constituencyDesignation"] do
                subBoothAdminDetail["constituencyDesignation"]
              else
                "Booth Member"
              end
            }
          ]
        end
      end
      #issues post map #############################################
      #get issue posted user detail
      issueCreatedByDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
      issuePostMap = %{
        "issuePostId" => encode_object_id(k["_id"]),
        "issuePartyTaskForceStatus" => k["partyTaskForceStatus"],
        "adminStatus" => k["adminStatus"],
        "issueDepartmentTaskForceStatus" => k["departmentTaskForceStatus"],
        "issueCreatedById" => encode_object_id(issueCreatedByDetails["_id"]),
        "issueCreatedByName" => issueCreatedByDetails["name"],
        "issueCreatedByPhone" => issueCreatedByDetails["phone"],
        "issueCreatedByImage" => issueCreatedByDetails["image"],
        "issueCreatedAt" => k["insertedAt"],
        "issueText" => k["text"],
        "issueLocation" => k["location"],
        ##"boothCoordinators" => coordinatorList,
        "constituencyIssue" => getConstituencyIssueDetails["issue"],
        "constituencyIssueJurisdiction" => getConstituencyIssueDetails["jurisdiction"],
        "constituencyIssueDepartmentTaskForce" => taskForceMap.departmentTaskForceMap,
        "constituencyIssuePartyTaskForce" => taskForceMap.partTaskForceMap,
        "boothIncharge" => boothInchargeMap,
      }
      issuePostMap = if !is_nil(k["fileName"]) do
        issuePostMap
        |> Map.put_new("fileName", k["fileName"])
        |> Map.put_new("fileType", k["fileType"])
      else
        issuePostMap
      end
      issuePostMap = if !is_nil(k["video"]) do
        if k["fileType"] == "youtube" do
          watch = "https://www.youtube.com/watch?v="<>k["video"]<>""
          thumbnail = "https://img.youtube.com/vi/"<>k["video"]<>"/0.jpg"
          issuePostMap
          |> Map.put_new("video", watch)
          |> Map.put_new("fileType", k["fileType"])
          |> Map.put_new("thumbnail", thumbnail)
        else
          issuePostMap
        end
      end
      #if thumbnailImage for video and pdf is not nil then display
      issuePostMap = if !is_nil(k["thumbnailImage"]) do
        issuePostMap
        |> Map.put_new("thumbnailImage", k["thumbnailImage"])
      else
        issuePostMap
      end
      #merge both issue_post_details and issue_posts map
      ##finalMap = Map.merge(map, issuePostMap)
      ##finalMap1 = Map.merge(%{"teamDetails" => userTeamDetailsMap}, finalMap)
      acc ++ [issuePostMap]
    end)

    #get total number of pages (For Pagination)
    {:ok, issuesPostCount} = ConstituencyRepo.getTotalIssuesTicketsCountOnOptionSelectedForPublic(groupObjectId, loginUserId, params["option"])
    pageCount = Float.ceil(issuesPostCount / pageLimit)
    totalPages = round(pageCount)

    %{ data: result, totalNumberOfPages: totalPages, totalPostCount: issuesPostCount }
  end





  def render("get_issues_comments_list.json", %{ issuesCommentsList: issuesCommentsList, loginUserId: loginUserId }) do
    if is_nil(issuesCommentsList["comments"]) do
      %{ data: [] }
    else
      list = Enum.reduce(issuesCommentsList["comments"], [], fn k, acc ->
        #get comment createdBy user details
        userDetails = ConstituencyRepo.getUserDetailFromUserCol(k["userId"])
        #check login user = userId of comment to provide delete option
        canEdit = if k["userId"] == loginUserId do
          true
        else
          false
        end
        map = %{
          "commentId" => k["commentId"],
          "text" => k["text"],
          "insertedAt" => k["insertedAt"],
          "name" => userDetails["name"],
          "image" => userDetails["image"],
          "constituencyDesignation" => userDetails["constituencyDesignation"],
          "canEdit" => canEdit,
        }
        acc ++ [map]
      end)
      %{ data: list }
    end
  end



  def render("booth_committees_list.json", %{ committeesList: committeesList }) do
    if is_nil(committeesList["boothCommittees"]) do
      %{ data: [] }
    else
      list = Enum.reduce(committeesList["boothCommittees"], [], fn k, acc ->
        map = %{
          "committeeId" => k["committeeId"],
          "committeeName" => k["committeeName"],
          "defaultCommittee" => k["defaultCommittee"]
        }
        acc ++ [map]
      end)
      %{ data: list }
    end
  end



  def render("get_issues_tickets_list_event_at.json", %{ eventAt: eventAt }) do
    #IO.puts "#{eventAt}"
    map = if eventAt == [] do  #if list is empty
      %{
        "eventName" => "issuesTickets",
        "eventType" => 101,
        "eventAt" => bson_time()
      }
    else
      #IO.puts "#{eventAt}"
      %{
        "eventName" => "issuesTickets",
        "eventType" => 101,
        "eventAt" => hd(eventAt)["updatedAt"]
      }
    end
    %{ data: [map] }
  end



  def render("get_admin_feeder_list.json", %{ adminFeederList: adminFeederList }) do
    #map = adminFeederList
    %{ data: [adminFeederList["feederMap"]] }
  end



  def render("get_constituency_group_banner.json", %{ groupBanner: groupBanner }) do
    %{ data: [groupBanner] }
  end


  def render("search_user.json", %{searchUser: searchUser}) do
    list = Enum.reduce(searchUser, [], fn k, acc ->
      map = %{
        "userId" => encode_object_id(k["_id"]),
        "name" => k["name"],
        "phone" => k["phone"],
        "voterId" => k["voterId"],
        "image" => k["image"]
      }
      acc ++ [map]
    end)
    %{ data: list }
  end


end
