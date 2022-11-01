defmodule GruppieWeb.Repo.TeamRepo do
  alias GruppieWeb.Team
  import GruppieWeb.Repo.RepoHelper


  @conn :mongo

  @users_coll "users"

  @team_coll "teams"

  @group_team_members_coll "group_team_members"

  @view_teams_coll "VW_TEAMS"

  @student_database_coll "student_database"

  @staff_database_col "staff_database"

  @view_student_db_coll "VW_STUDENT_DB"

  @view_attendance_report_coll "VW_ATTENDANCE_REPORT"

  @view_class_subjects_col "VW_CLASS_SUBJECTS"

  @zoom_token_col "zoomToken"

  @subject_staff_db_col "subject_staff_database"

  @community_branches_coll "community_branches_db"

  @view_group_team_coll "VW_GROUP_TEAM_MEMBERS_DETAILS"


  def get(teamId) do
    teamObjectId = decode_object_id(teamId)
    filter = %{ "_id" => teamObjectId, "isActive" => true }
    #IO.puts "#{filter}"
    projection =  %{ "updatedAt" => 0 }
    find = Enum.to_list(Mongo.find(@conn, @team_coll, filter, [ projection: projection, limit: 1 ]))
    if find != [] do
      hd(find)
    else
      []
    end
    # hd(Enum.to_list(Mongo.find(@conn, @team_coll, filter, [ projection: projection, limit: 1 ])))
    # #edited on 9 june 2022
    # Mongo.find_one(@conn, @team_coll, filter, [ projection: projection ])
  end


  #get my teams list (only created by login user teams)
  def getMyTeams(groupObjectId, loginUserId) do
    filter = %{ "groupId" => groupObjectId, "adminId" => loginUserId, "isActive" => true }
    project = %{ "name" => 1, "image" => 1, "category" => 1, "enableAttendance" => 1, "class" => 1, "adminId" => 1 }
    Enum.to_list(Mongo.find(@conn, @team_coll, filter, [projection: project]))
  end


  #find class team for login user
  #def findClassTeamForLoginUser(loginUserId, groupObjectId) do
  #  filter = %{ "groupId" => groupObjectId, "adminId" => loginUserId, "class" => true, "isActive" => true }
  #  Enum.to_list(Mongo.find(@conn, @team_coll, filter))
  #end


  def getMyKidsClassForSchool(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "teamDetails.isActive" => true,
      "teamDetails.class" => true
    }
    project = %{"_id" => 0, "groupId" => 1, "teamDetails._id" => 1, "userId" => 1, "teamDetails.name" => 1, "teamDetails.image" => 1}
    ##project = %{"_id" => 0, "groupId" => 1, "teamDetails._id" => 1, "userId" => 1, "teamDetails.name" => 1, "studentDbDetails.name" => 1, "studentDbDetails.image" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_teams_coll, pipeline)
    |> Enum.to_list
    |> Enum.uniq
  end


  #find class team for login user as admin or teacher who can post in team
  def findClassTeamForLoginUser(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      # "$or" => [
      #   %{"teams.allowedToAddPost" => true},
      #   %{"teams.isTeamAdmin" => true}
      # ],
      "teamDetails.isActive" => true,
      "teamDetails.class" => true,
      #"teamDetails.enableAttendance" => true,
    }
    project = %{
      "teams.teamId" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
      "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.image" => 1, "teamDetails.category" => 1
    }
    pipeline = [%{ "$match" => filter }, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end


  #find class team for login user as admin or teacher who can post in team
  def findClassTeamForLoginUserAsTeacher(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "$or" => [
        %{"teams.allowedToAddPost" => true},
        %{"teams.isTeamAdmin" => true}
      ],
      "teamDetails.isActive" => true,
      "teamDetails.class" => true,
      #"teamDetails.enableAttendance" => true,
    }
    project = %{
      "teams.teamId" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
      "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.image" => 1, "teamDetails.category" => 1
    }
    pipeline = [%{ "$match" => filter }, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end



  def createTeam(loginUser, changeset, groupObjectId) do
    #create new object id as team id
    team_id = new_object_id()
    team_create_doc = Team.insert_team(team_id, loginUser["_id"], groupObjectId, changeset)
    Mongo.insert_one(@conn, @team_coll, team_create_doc)

    #insert into group_team_members doc
    team_members_doc = Team.insertGroupTeamMembersForLoginUser(team_id, loginUser)
    filter = %{ "groupId" => groupObjectId , "userId" => loginUser["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
    {:ok, encode_object_id(team_id)}
  end


  #create class team by admin
  def createClassTeam(user, changeset, groupObjectId) do
    #create new object id as team id
    team_id = new_object_id()
    team_create_doc = Team.insert_class_team(team_id, user["_id"], groupObjectId, changeset)
    Mongo.insert_one(@conn, @team_coll, team_create_doc)

    #insert into group_team_members doc
    team_members_doc = Team.insertGroupTeamMembersForLoginUser(team_id, user)
    filter = %{ "groupId" => groupObjectId, "userId" => user["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
    {:ok, encode_object_id(team_id)}
  end


  #create class team by admin
  def createBusTeam(user, changeset, groupObjectId) do
    #create new object id as team id
    team_id = new_object_id()
    team_create_doc = Team.insert_bus_team(team_id, user["_id"], groupObjectId, changeset)
    Mongo.insert_one(@conn, @team_coll, team_create_doc)

    #insert into group_team_members doc
    team_members_doc = Team.insertGroupTeamMembersForLoginUser(team_id, user)
    filter = %{ "groupId" => groupObjectId, "userId" => user["_id"] }
    update = %{ "$push" => %{ "teams" => team_members_doc } }
    Mongo.update_one(@conn, @group_team_members_coll, filter, update)
    {:ok, encode_object_id(team_id)}
  end



  #get all teams belong to login user
  def get_teams123(loginUserId, groupObjectId) do
    #get created teams/channels for login users
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true, "teamDetails.isActive" => true }
    project = %{ "teams.teamId" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
                 "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.category" => 1, "teamDetails.image" => 1,
                 "teamDetails.enableGps" => 1, "teamDetails.enableAttendance" => 1, "teamDetails.class" => 1, "teamDetails.place" => 1,
                 "teamDetails.subCategory" => 1, "teamDetails.adminId" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{"$sort" => %{"teamDetails.place" => 1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end


  def get_teams(loginUserId, groupObjectId) do
    filter = %{
      "userId" => loginUserId,
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "teams" => 1,
      "_id" => 0
    }
    Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  end

  def teamDetails(teamIds) do
    filter = %{
      "_id" => %{
        "$in" => teamIds
      },
      "isActive" => true
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
      "enableGps" => 1,
      "enableAttendance" => 1,
      "category" => 1,
      "canAddUser" => 1,
      "allowTeamPostCommentAll" => 1,
      "allowTeamPostAll" => 1,
      "adminId" => 1,
      "class" => 1
      # "insertedAt" => 0,
      # "updatedAt" => 0,
      # "isActive" => 0,
      # "groupId" => 0,
    }
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{"name" => -1}])
    |> Enum.to_list
  end


  def get_public_teams(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "category" => "public"
    }
    project = %{
      "teamId" => "$$CURRENT._id",
      "name" => 1,
      "image" => 1,
      "category" => 1,
    }
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{"name" => -1}])
    |> Enum.to_list
  end


  def teamDetailsForAdmin(teamIds) do
    filter = %{
      "_id" => %{
        "$in" => teamIds
      },
      "category" => %{
        "$nin" => ["booth", "subBooth"]
      },
      "isActive" => true
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
      "enableGps" => 1,
      "enableAttendance" => 1,
      "category" => 1,
      "canAddUser" => 1,
      "allowTeamPostCommentAll" => 1,
      "allowTeamPostAll" => 1,
      "adminId" => 1,
      "class" => 1
    }
    Mongo.find(@conn, @team_coll, filter, [projection: project, sort: %{"name" => -1}])
    |> Enum.to_list
  end


  def canPostTrue123(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "canPost" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def get_all_class_team_list(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "class" => true,
      "isActive" => true
    }
    project = %{
      "_id" => 1,
      "name" => 1,
      "image" => 1,
      "enableGps" => 1,
      "enableAttendance" => 1,
      "category" => 1,
      "canAddUser" => 1,
      "allowTeamPostCommentAll" => 1,
      "allowTeamPostAll" => 1,
      "adminId" => 1,
      "class" => 1
    }
    Mongo.find(@conn, @team_coll, filter, [projection: project])
    |> Enum.to_list
  end



  #get all teams belong to login user
  # def get_teams123(loginUserId, groupObjectId) do
  #   #first get login user teams for group
  #   filter = %{"userId" => loginUserId, "groupId" => groupObjectId, "isActive" => true}
  #   project = %{"_id" => 0, "teams.teamId" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1, "teams.isTeamAdmin" => 1}
  #   teamsFind = Mongo.find_one(@conn, @group_team_members_coll, filter, [projection: project])
  #   #get teams details from teams col for each team
  #   teamsList = Enum.reduce(teamsFind["teams"], [], fn k, acc ->
  #     #find details of teamId
  #     #teamId = encode_object_id(k["teamId"])
  #     teamDetails = getTeamDetails(k["teamId"])
  #     if teamDetails do
  #       finalMap = Map.merge(k, teamDetails)
  #     else
  #       finalMap = %{}
  #     end
  #     acc = acc ++ [finalMap]
  #   end)
  #   teamsList
  # end

  # defp getTeamDetails(teamObjectId) do
  #   filter = %{
  #     "_id" => teamObjectId,
  #     "isActive" => true
  #   }
  #   project = %{"_id" => 0, "name" => 1, "category" => 1, "image" => 1, "enableGps" => 1, "enableAttendance" => 1, "class" => 1, "place" => 1}
  #   Mongo.find_one(@conn, @team_coll, filter, [projection: project])
  # end



  #get all teams belong to login user
  def getTeamsExceptBooths(loginUserId, groupObjectId) do
    #get created teams/channels for login users
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "teamDetails.isActive" => true, "teamDetails.category" => %{"$ne" => "booth"} }
    project = %{ "teams.teamId" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
                 "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.category" => 1, "teamDetails.image" => 1,
                 "teamDetails.enableGps" => 1, "teamDetails.enableAttendance" => 1, "teamDetails.class" => 1, "teamDetails.place" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{"$sort" => %{"teamDetails.place" => 1}}]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end


  #add zoom meeting token to zoomToken
  def addZoomToken(changeset, groupObjectId) do
    changeset = changeset
                |>Map.put_new("groupId", groupObjectId)
                |>Map.put_new("isActive", true)
                |>Map.put_new("alreadyOnZoomLive", false)
    Mongo.insert_one(@conn, @zoom_token_col, changeset)
  end


  #def getZoomToken(groupObjectId) do
  #  filter = %{
  #    "groupId" => groupObjectId,
  #    "isActive" => true
  #  }
  #  Enum.to_list(Mongo.find(@conn, @zoom_token_col, filter))
  #end


  #get all teams belong to login user
  #def get_video_conference_teams(loginUserId, groupObjectId) do
    #get created teams/channels for login users
  #  filter = %{
  #              "groupId" => groupObjectId,
  #              "userId" => loginUserId,
  #              "teamDetails.isActive" => true,
  #              "teamDetails.class" => true,
  #              "teamDetails.jitsiToken" => %{
  #                 "$exists" => true
  #               }
  #            }
  #  project = %{ "teams.teamId" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
  #               "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.category" => 1, "teamDetails.image" => 1,
  #               "teamDetails.enableGps" => 1, "teamDetails.enableAttendance" => 1, "teamDetails.jitsiToken" => 1,
  #               "teamDetails.alreadyOnJitsiLive" => 1, "teamDetails.jitsiMeetCreatedBy" => 1 }
  #  pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
  #  Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  #end





  #get all teams belong to login user
  def get_video_conference_teams(loginUserId, groupObjectId) do
    #get created teams/channels for login users
    filter = %{
                "groupId" => groupObjectId,
                "userId" => loginUserId,
                "teamDetails.isActive" => true,
                #"teamDetails.class" => true,
                "teamDetails.zoomKey" => %{
                   "$exists" => true
                },
                "teamDetails.zoomSecret" => %{
                  "$exists" => true
                }
              }
    project = %{ "teams.teamId" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1,
                 "teams.isTeamAdmin" => 1, "_id" => 0, "teamDetails.name" => 1, "teamDetails.category" => 1, "teamDetails.image" => 1,
                 "teamDetails.enableGps" => 1, "teamDetails.enableAttendance" => 1, "teamDetails.zoomMeetingId" => 1, "teamDetails.alreadyOnJitsiLive" => 1,
                 "teamDetails.jitsiMeetCreatedBy" => 1,  "teamDetails.zoomKey" => 1, "teamDetails.zoomSecret" => 1, "teamDetails.zoomMail" => 1,
                 "teamDetails.zoomPassword" => 1, "teamDetails.zoomMeetingPassword" => 1, "teamDetails.meetingIdOnLive" => 1
              }
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "teamDetails.name" => 1 } }]
    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
  end



  def getAllJitsiEnabledTeamsForGroup(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
      "jitsiToken" => %{
        "$exists" => true
      }
    }
    project = %{"_id" => 1, "name" => 1, "image" => 1}
    Enum.to_list(Mongo.find(@conn, @team_coll, filter, [projection: project]))
  end



  #def updateZoomMeetingIdWhenStart(changeset, groupObjectId, zoomObjectId, loginUserId) do
  #  #update meeting id in zoom channel list
  #  filter = %{
  #    "_id" => zoomObjectId,
  #    "groupId" => groupObjectId
  #  }
  #  changeset = Map.put_new(changeset, "meetingCreatedAt", bson_time())
  #  #IO.puts "#{changeset["zoomMeetingId"]}"
  #  update = %{"$set" =>
  #              %{
  #                "zoomMeetingId" => changeset["zoomMeetingId"],
  #                "teamId" => decode_object_id(changeset["teamId"]),
  #                "meetingCreatedAt" => bson_time(),
  #                "zoomMeetingCreatedBy" => loginUserId,
  #                "alreadyOnZoomLive" => true
  #              }
  #            }
  #  Mongo.update_one(@conn, @zoom_token_col, filter, update)
  #end


  #def checkLoginUserCreatedZoomMeeting(loginUserId, zoomObjectId) do
  #  filter = %{
  #    "_id" => zoomObjectId,
  #    "zoomMeetingCreatedBy" => loginUserId,
  #    "alreadyOnZoomLive" => true
  #  }
  #  Mongo.count(@conn, @zoom_token_col, filter)
  #end


  #def removeZoomMeetingIdWhenStop(groupObjectId, zoomObjectId, loginUserId) do
  #  filter = %{
  #    "_id" => zoomObjectId,
  #    "groupId" => groupObjectId
  #  }
  #  update = %{"$unset" => %{"zoomMeetingCreatedBy" => loginUserId, "teamId" => "", "zoomMeetingId" => ""},
  #             "$set" => %{"alreadyOnZoomLive" => false}}
  #  Mongo.update_one(@conn, @zoom_token_col, filter, update)
  #end



  #from friend view, team_index.json
  def getCreatedTeamMembersCount(group_object_id, team_object_id) do
    filter = %{ "groupId" => group_object_id, "teams.teamId" => team_object_id, "isActive" => true }
    project = %{"_id" => 1}
    ##Mongo.count(@conn, @view_teams_coll, filter)
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  #for team post add auth
  def checkUserCanAddTeamPostAuth(loginUerId, groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUerId, "teams.teamId" => teamObjectId, "teams.allowedToAddPost" => true, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end


  #team auth check
  def isTeamMemberByUserId(login_user_object_id, group_object_id, team_object_id) do
    filterCreatedTeam = %{
      "groupId" => group_object_id,
      "userId" => login_user_object_id,
      "teams.teamId" => team_object_id,
      "isActive" => true
    }
    project = %{"_id" => 1}
    ##Mongo.count(@conn, @view_teams_coll, filterCreatedTeam)
    Mongo.count(@conn, @group_team_members_coll, filterCreatedTeam, [projection: project])
  end


  def isTeamMemberByUserPhone(phoneNumber, groupObjectId, teamObjectId) do
    filterCreatedTeam = %{
      "groupId" => groupObjectId,
      "teams.teamId" => teamObjectId,
      "userDetails.phone" => phoneNumber,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filterCreatedTeam, [projection: project])
  end


#  def isTeamMemberByUserPhoneDetail(phoneNumber, groupObjectId, teamObjectId) do
#    filterCreatedTeam = %{
#      "userDetails.phone" => phoneNumber,
#      "groupId" => groupObjectId,
#      "teams.teamId" => teamObjectId
#    }
#    pipeline = [%{ "$match" => filterCreatedTeam }]
#    Enum.to_list(Mongo.aggregate(@conn, @view_teams_coll, pipeline))
#  end



  #to find created team is login users team
  def isLoginUserTeam(groupObjectId, teamObjectId, loginUserId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "adminId" => loginUserId,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_coll, filter, [projection: project])
  end


  #def getTeamUsersList123(groupObjectId, teamObjectId, loginUserId, checkTeamAdmin) do
  #  filter = %{
  #    "groupId" => groupObjectId,
  #    "teams.teamId" => teamObjectId,
  #    "isActive" => true,
  #    "userId" => %{ "$nin" => [loginUserId] }
  #  }
  #  if checkTeamAdmin > 0 do #checking team is my team or other's team
      #get name and phone from team_members col
  #    projection = %{ "_id" => 0, "userId" => 1, "name" => "$$CURRENT.teams.userName", "userDetails.phone" => 1, "userDetails.image" => 1, "teams.allowedToAddUser" => 1,
  #                    "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1}
  #  else
      #get name and phone from user col/ profile
  #    projection = %{ "_id" => 0, "userId" => 1, "name" => "$$CURRENT.userDetails.name", "userDetails.phone" => 1, "userDetails.image" => 1, "teams.allowedToAddUser" => 1,
  #                    "teams.allowedToAddPost" => 1, "teams.allowedToAddComment" => 1}
  #  end
    #sort = %{ "name" => 1 }
  #  pipeline = [ %{ "$match" => filter }, %{ "$project" => projection } ]
  #  Mongo.aggregate(@conn, @view_teams_coll, pipeline)
  #end


  #get userId belongs to team from group_team_mem col
  # def getTeamUsersList123(groupObjectId, teamObjectId, loginUserId) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     #"userId" => %{ "$nin" => [loginUserId] },
  #     "teams.teamId" => teamObjectId,
  #     "isActive" => true,
  #   }
  #   project = %{"_id" => 0, "userId" => 1}
  #   Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
  # end

  #get userId belongs to team from group_team_mem col
  def getTeamUsersList(groupObjectId, teamObjectId, _loginUserId) do
    filter = %{
      "groupId" => groupObjectId,
      #"userId" => %{ "$nin" => [loginUserId] },
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{"_id" => 0, "userId" => 1, "teams.teamId.$" => 1, "teams.allowedToAddUser" => 1, "teams.allowedToAddPost" => 1,
                "teams.allowedToAddComment" => 1}
    Mongo.find(@conn, @group_team_members_coll, filter, [projection: project])
    |> Enum.to_list
  end

  def getUserDetailsForTeam(userIds) do
    filter = %{
      "_id" => %{"$in" => userIds}
    }
    projection =  %{ "password_hash" => 0, "insertedAt" => 0, "updatedAt" => 0, "user_secret_otp" => 0 }
    Mongo.find(@conn, @users_coll, filter, [projection: projection])
    |> Enum.to_list
  end


  def getTeamUsersListPage(groupObjectId, teamObjectId, pageNo) do
    filter = %{
      "groupId" => groupObjectId,
      #"userId" => %{ "$nin" => [loginUserId] },
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "groupId" => 0,
      "teamId" => 0,
    }
    skip = (pageNo - 1) * 15
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }, %{ "$sort" => %{ "userDetails.name" => 1 }}, %{"$skip" => skip},  %{"$limit" => 15}]
    Mongo.aggregate(@conn, @view_group_team_coll, pipeline)
    |> Enum.to_list
  end


  def getUsersCountTeam(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      #"userId" => %{ "$nin" => [loginUserId] },
      "teams.teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @group_team_members_coll, filter, [projection: project])
  end


  def checkStudentAlreadyExistInClass(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    projection = %{"_id" => 1}
    Mongo.count(@conn, @student_database_coll, filter, [project: projection])
  end



  def findUserIsStaff(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @staff_database_col, filter, [projection: project, limit: 1])
  end

  def findUserIsStaffForUsersName(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "name" => 1}
    Mongo.find_one(@conn, @staff_database_col, filter, [projection: project])
    #|> Enum.to_list()
  end


  def findUserIsStudentForUsersName(userObjectId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "name" => 1}
    Mongo.find_one(@conn, @student_database_coll, filter, [projection: project])
    #|> Enum.to_list()
  end



  def getTeamsCountForUserAsAdmin(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "teamDetails.adminId" => userObjectId
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end


  def getTeamsCountForUser123(userObjectId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
  end



  def getAttendanceList(_loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{ "_id" => 0, "name" => 1, "image" => 1, "rollNumber" => 1, "userId" => 1 }
    Mongo.find(@conn, @student_database_coll, filter, [projection: project])
    |> Enum.to_list
  end


  def findStudentByIdAndrollNumberForAttendance(absentStudentIds, _rollNumbers, groupObjectId, teamObjectId) do
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentIds },
    }
    project = %{ "_id" => 0, "name" => 1, "userDetails" => 1 }
    pipeline = [%{"$match" => filterAbsent}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_student_db_coll, pipeline)
  end


  def findStudentByIdForAttendance(absentStudentObjectIds, groupObjectId, teamObjectId) do
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentObjectIds },
    }
    project = %{ "_id" => 0, "phoneNumber" => "$$CURRENT.userDetails.phone" }
    pipeline = [%{"$match" => filterAbsent}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_student_db_coll, pipeline)
    |> Enum.to_list
  end


  def getSubjectNameById(subjectId) do
    filter = %{
      "_id" => subjectId
    }
    project = %{"_id" => 0, "subjectName" => 1}
    Mongo.find_one(@conn, @subject_staff_db_col, filter, [projection: project])
  end



  def pushMorningAttendanceForStudents(absentStudentIds, _rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime) do
    #to update false for absent students
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentIds },
      "isActive" => true
    }
    #to update true for present students
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$nin" => absentStudentIds },
      "isActive" => true
    }
    #push morning attendance
    pushAbsent = %{ "$push" => %{ "attendance" => %{"morningAttendance" => false,"year" => dateTimeMap["year"],
                    "month" => dateTimeMap["month"], "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"],
                    "minute" => dateTimeMap["minute"], "seconds" => dateTimeMap["seconds"],
                    "attendanceTakenAt" => currentTime, "period" => "morning" } } }
    pushPresent = %{ "$push" => %{ "attendance" => %{ "morningAttendance" => true, "year" => dateTimeMap["year"],
                     "month" => dateTimeMap["month"], "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"],
                     "minute" => dateTimeMap["minute"], "seconds" => dateTimeMap["seconds"],
                     "attendanceTakenAt" => currentTime, "period" => "morning"  } } }
    Mongo.update_many(@conn, @student_database_coll, filterAbsent, pushAbsent)
    Mongo.update_many(@conn, @student_database_coll, filterPresent, pushPresent)
  end



  def pushAfternoonAttendanceForStudents(absentStudentIds, _rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime) do
    #to update false for absent students
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentIds },
      "isActive" => true
    }
    #to update true for present students
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$nin" => absentStudentIds },
      "isActive" => true
    }
    #push afternoon attendance
    pushAbsent = %{ "$push" => %{ "attendance" => %{"afternoonAttendance" => false,"year" => dateTimeMap["year"],
                    "month" => dateTimeMap["month"], "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"],
                    "minute" => dateTimeMap["minute"], "seconds" => dateTimeMap["seconds"],
                    "attendanceTakenAt" => currentTime, "period" => "afternoon" } } }
    pushPresent = %{ "$push" => %{ "attendance" => %{ "afternoonAttendance" => true, "year" => dateTimeMap["year"],
                     "month" => dateTimeMap["month"], "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"],
                     "minute" => dateTimeMap["minute"], "seconds" => dateTimeMap["seconds"],
                     "attendanceTakenAt" => currentTime, "period" => "afternoon"  } } }
    Mongo.update_many(@conn, @student_database_coll, filterAbsent, pushAbsent)
    Mongo.update_many(@conn, @student_database_coll, filterPresent, pushPresent)
  end



  def updateMorningAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime) do
    #remove attendance taken in this day and in this period to insert newly
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{
      "$pull" => %{
        "attendance" => %{ "day" => dateTimeMap["day"], "period" => "morning" }
      }
    }
    Mongo.update_many(@conn, @student_database_coll, filter, update)
    pushMorningAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
  end



  def updateAfternoonAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime) do
    #remove attendance taken in this day and in this period to insert newly
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{
      "$pull" => %{
        "attendance" => %{ "day" => dateTimeMap["day"], "period" => "afternoon" }
      }
    }
    Mongo.update_many(@conn, @student_database_coll, filter, update)
    pushAfternoonAttendanceForStudents(absentStudentIds, rollNumbers, groupObjectId, teamObjectId, dateTimeMap, currentTime)
  end


  def getIndividualStudentAttendanceReport(groupObjectId, teamObjectId, studentObjectId, month, year, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentObjectId,
      ##"rollNumber" => rollNumber,
      "attendance.month" => String.to_integer(month),
      "attendance.year" => String.to_integer(year)
    }
    project = %{ "_id" => 0, "day" => "$$CURRENT.attendance.day"}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{ "$sort" => %{ "day" => 1 } }]
    get = Enum.uniq(Mongo.aggregate(@conn, @view_attendance_report_coll, pipeline))
    cursor = Enum.reduce(get, [], fn k, acc ->
      filterDay = %{
        "groupId" => groupObjectId,
        "teamId" => teamObjectId,
        "userId" => studentObjectId,
        ##"rollNumber" => rollNumber,
        "attendance.month" => String.to_integer(month),
        "attendance.year" => String.to_integer(year),
        "attendance.day" => k["day"]
      }
      projectDay = %{ "_id" => 0, "day" => "$$CURRENT.attendance.day", "month" => "$$CURRENT.attendance.month",
              "morningAttendance" => "$$CURRENT.attendance.morningAttendance", "afternoonAttendance" => "$$CURRENT.attendance.afternoonAttendance"}
      pipelineDay = [%{"$match" => filterDay},%{"$project" => projectDay}]
      find = Mongo.aggregate(@conn, @view_attendance_report_coll, pipelineDay)
      map1 = Enum.at(find, 0)
      map2 = Enum.at(find, 1)
      if !is_nil(map2) do
        mergeMap = Map.merge(map1, map2)
        acc ++ [mergeMap]
      else
        acc ++ [map1]
      end
    end)
    cursor
  end



  def getMonthAttendanceCountForStudentsInMorning(groupObjectId, teamObjectId, userObjectId, _rollNumber, month, year) do
    filterMorningAttendance = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      ##"rollNumber" => rollNumber,
      "attendance.period" => "morning",
      "attendance.month" => String.to_integer(month),
      "attendance.year" => String.to_integer(year),
      "attendance.morningAttendance" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filterMorningAttendance, [projection: project])
  end


  def getTotalMonthAttendanceCountForStudentsInMorning(groupObjectId, teamObjectId, userObjectId, _rollNumber, month, year) do
    filterMorningAttendance = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      ##"rollNumber" => rollNumber,
      "attendance.period" => "morning",
      "attendance.month" => String.to_integer(month),
      "attendance.year" => String.to_integer(year)
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filterMorningAttendance, [projection: project])
  end


  def getMonthAttendanceCountForStudentsInAfternoon(groupObjectId, teamObjectId, userObjectId, _rollNumber, month, year) do
    filterMorningAttendance = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      ##"rollNumber" => rollNumber,
      "attendance.period" => "afternoon",
      "attendance.month" => String.to_integer(month),
      "attendance.year" => String.to_integer(year),
      "attendance.afternoonAttendance" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filterMorningAttendance, [projection: project])
  end


  def getTotalMonthAttendanceCountForStudentsInAfternoon(groupObjectId, teamObjectId, userObjectId, _rollNumber, month, year) do
    filterMorningAttendance = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      ##"rollNumber" => rollNumber,
      "attendance.period" => "afternoon",
      "attendance.month" => String.to_integer(month),
      "attendance.year" => String.to_integer(year)
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filterMorningAttendance, [projection: project])
  end





  def checkMorningAttendanceAlreadyTaken(groupObjectId, teamObjectId, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "attendance.day" => dateTimeMap["day"],
      "attendance.month" => dateTimeMap["month"],
      "attendance.year" => dateTimeMap["year"],
      "attendance.period" => "morning"
    }
    length(Enum.to_list(Mongo.aggregate(@conn, @view_attendance_report_coll, [%{"$match" => filter}])))
  end





  def checkAfternoonAttendanceAlreadyTaken(groupObjectId, teamObjectId, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "attendance.day" => dateTimeMap["day"],
      "attendance.month" => dateTimeMap["month"],
      "attendance.year" => dateTimeMap["year"],
      "attendance.period" => "afternoon"
    }
    length(Enum.to_list(Mongo.aggregate(@conn, @view_attendance_report_coll, [%{"$match" => filter}])))
  end



  def checkLoginUserIsStudent(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @student_database_coll, filter, [projection: project])
  end


  def getStudentNameWithRollNumber(userId, _rollNumber, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    projection = %{ "_id" => 0, "name" => 1 }
    Mongo.find(@conn, @student_database_coll, filter, [projection: projection])
  end


  def getStudentName(userId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userId,
      "isActive" => true
    }
    projection = %{ "_id" => 0, "name" => 1 }
    Mongo.find(@conn, @student_database_coll, filter, [projection: projection])
  end


  def addStudentIn(groupObjectId, teamObjectId, userObjectId, _rollNumber, currentTime, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    #push morning attendance
    update = %{ "$push" => %{ "attendance" => %{"year" => dateTimeMap["year"], "month" => dateTimeMap["month"],
                              "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"], "minute" => dateTimeMap["minute"],
                              "seconds" => dateTimeMap["seconds"], "attendanceTakenAt" => currentTime, "status" => "IN" } } }
    Mongo.update_one(@conn, @student_database_coll, filter, update)
  end



  def addStudentOut(groupObjectId, teamObjectId, userObjectId, _rollNumber, currentTime, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    #push morning attendance
    update = %{ "$push" => %{ "attendance" => %{"year" => dateTimeMap["year"], "month" => dateTimeMap["month"],
                              "day" => dateTimeMap["day"], "hour" => dateTimeMap["hour"], "minute" => dateTimeMap["minute"],
                              "seconds" => dateTimeMap["seconds"], "attendanceTakenAt" => currentTime, "status" => "OUT" } } }
    Mongo.update_one(@conn, @student_database_coll, filter, update)
  end


  def findKidAttendanceINAlreadyTaken(groupObjectId, teamObjectId, userObjectId, _rollNumber, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true,
      ##"rollNumber" => rollNumber,
      "attendance.day" => dateTimeMap["day"],
      "attendance.status" => "IN"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filter, [projection: project])
  end


  def findKidAttendanceOUTAlreadyTaken(groupObjectId, teamObjectId, userObjectId, _rollNumber, dateTimeMap) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true,
      ##"rollNumber" => rollNumber,
      "attendance.day" => dateTimeMap["day"],
      "attendance.status" => "OUT"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_attendance_report_coll, filter, [projection: project])
  end


  def findStudentFromDatabaseForLoginUser(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true
    }
    project = %{"attendance" => 0, "marksCard" => 0, "userDetails" => 0}
    #Enum.to_list(Mongo.find(@conn, @view_student_db_coll, filter))
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Enum.to_list(Mongo.aggregate(@conn, @view_student_db_coll, pipeline))
  end



  def getClassSubjects(groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
    }
    project = %{ "subjectDetails.classSubjects" => 1, "subjectDetails._id" => 1, "groupId" => 1 }
    pipeline = [%{ "$match" => filter }, %{ "$project" => project }]
    Mongo.aggregate(@conn, @view_class_subjects_col, pipeline)
  end


  def getBranches(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
      "branchName" => 1,
      "image" => 1,
    }
    Mongo.find(@conn, @community_branches_coll, filter, [projection: project])
    |> Enum.to_list()
  end



end
