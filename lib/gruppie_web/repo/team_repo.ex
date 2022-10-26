defmodule GruppieWeb.Repo.TeamRepo do
  alias GruppieWeb.Team
  # alias Gruppie.GroupMembership
  # alias Gruppie.Attendance
  import GruppieWeb.Repo.RepoHelper
  # import Gruppie.Handler.TimeNow


  @conn :mongo

  # @users_coll "users"

  @team_coll "teams"

  @group_team_members_coll "group_team_members"

  @view_teams_coll "VW_TEAMS"



  def get(teamId) do
    teamObjectId = decode_object_id(teamId)
    filter = %{ "_id" => teamObjectId, "isActive" => true }
    #IO.puts "#{filter}"
    projection =  %{ "updatedAt" => 0 }
    hd(Enum.to_list(Mongo.find(@conn, @team_coll, filter, [ projection: projection, limit: 1 ])))
    # #edited on 9 june 2022
    # Mongo.find_one(@conn, @team_coll, filter, [ projection: projection ])
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


  #for team post add auth
  def checkUserCanAddTeamPostAuth(loginUerId, groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUerId, "teams.teamId" => teamObjectId, "teams.allowedToAddPost" => true, "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_teams_coll, filter, [projection: project])
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

end
