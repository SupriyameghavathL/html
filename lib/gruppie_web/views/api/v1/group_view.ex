defmodule GruppieWeb.Api.V1.GroupView do
  use GruppieWeb, :view
  alias GruppieWeb.Repo.UserRepo
  alias GruppieWeb.Repo.GroupRepo
  alias GruppieWeb.Repo.ConstituencyRepo
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Handler.SchoolCollegeRegisterHandler
  import GruppieWeb.Repo.RepoHelper


  def render("groups.json", %{ groups: groups, conn: _conn }) do
    # login_user = Guardian.Plug.current_resource(conn)
    final_list = Enum.reduce(groups, [], fn group, acc ->
      #get group post unseen count
#      {:ok, groupUnseenCount} = GroupPostRepo.getGroupPostUnseenCount(login_user["_id"], group["groupId"])
        #get all teams of this group to get unseen team post count
  #      teams = ReferrerHandler.get_teams(conn, group)
        #if only my team (no other team)
  #      if length(teams) == 0 do
          #get my team post unseen count
#          {:ok, teamPostUnseenCount} = TeamPostRepo.getTeamPostUnseenCount(login_user["_id"], group["groupId"], login_user["_id"])
          #total of group and teams unseen count
  #        totalUnseenCount = teamPostUnseenCount + groupUnseenCount
#        else
#          team_list = Enum.reduce(teams, [], fn team, acc ->
            #get others team post unseen count
#            {:ok, teamPostUnseenCount} = TeamPostRepo.getTeamPostUnseenCount(login_user["_id"], group["groupId"], team["_id"])
#            acc ++ [teamPostUnseenCount]
#          end)
#          otherTeamPostUnseen = Enum.sum(team_list)
          #get my teams unseen count
#          {:ok, myTeamPostUnseenCount} = TeamPostRepo.getTeamPostUnseenCount(login_user["_id"], group["groupId"], login_user["_id"])
          #total teams unseen count
#          totalTeamsUnseen = otherTeamPostUnseen + myTeamPostUnseenCount
          #total of group and teams unseen count
  #        totalUnseenCount = 0 + groupUnseenCount
  #      end

      groupMap = %{
        "id" => fetch_id_from_object(group["groupId"]),
        "name" => group["groupDetails"]["name"],
        "type" => group["groupDetails"]["type"],
        "isAdmin" => group["isAdmin"],
  #      "totalUnseenCount" => totalUnseenCount,
        "isAdminChangeAllowed" => group["groupDetails"]["isAdminChangeAllowed"],
        "isPostShareAllowed" => group["groupDetails"]["isPostShareAllowed"],
        "canPost" => group["canPost"],
      }
      if !is_nil(group["groupDetails"]["category"]) do
        Map.put_new(groupMap, "category", group["groupDetails"]["category"])
      end
      if !is_nil(group["groupDetails"]["subCategory"]) do
        Map.put_new(groupMap, "subCategory", group["groupDetails"]["subCategory"])
      end
      if !is_nil(group["groupDetails"]["avatar"]) do
        Map.put_new(groupMap, "image", group["groupDetails"]["avatar"])
      end
      if !is_nil(group["groupDetails"]["aboutGroup"]) do
        Map.put_new(groupMap, "aboutGroup", group["groupDetails"]["aboutGroup"])
      end
      if !is_nil(group["groupDetails"]["constituencyName"]) do
        Map.put_new(groupMap, "constituencyName", group["groupDetails"]["constituencyName"])
      end
      if !is_nil(group["groupDetails"]["appVersion"]) do
        Map.put_new(groupMap, "appVersion", trunc(group["groupDetails"]["appVersion"]))
      end
      if !is_nil(group["groupDetails"]["categoryName"]) do
        Map.put_new(groupMap, "categoryName", group["groupDetails"]["categoryName"])
      ##else
        ##groupMap = Map.put_new(groupMap, "categoryName", group["groupDetails"]["category"])
      end
      acc ++ [ groupMap ]
    end)
    %{ data: final_list }
  end



  ######Group show response
  def render("group_show.json", %{ group: group, conn: conn }) do
    login_user = Guardian.Plug.current_resource(conn)
    #to get group admin details
    admin = UserRepo.find_user_by_id(group["adminId"])
    #2. check login user is authorized user of group
    checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], login_user["_id"])
    groupMap = %{
      "id" => fetch_id_from_object(group["_id"]),
      "name" => group["name"],
      "type" => group["type"],
      "image" => group["avatar"],
      "adminId" => fetch_id_from_object(admin["_id"]),
      "adminName" => admin["name"],
      "adminPhone" => admin["phone"],
      "totalUsers" => 0,
      "totalPostsCount" => 0,
      "totalCommentsCount" => 0,
      "isAdmin" => false,
      ##"isAuthorizedUser" => isAuthorizedUser,
      "canPost" => checkCanPost["canPost"], #authorized user
      "isAdminChangeAllowed" => group["isAdminChangeAllowed"],
      "isPostShareAllowed" => group["isPostShareAllowed"],
      "allowPostAll" => group["allowPostAll"],
      "category" => group["category"],
      "notificationUnseenCount" => 0,
      "zoomKey" => group["zoomKey"],
      "zoomSecret" => group["zoomSecret"],
      "zoomMail" => group["zoomMail"],
      "zoomPassword" => group["zoomPassword"],
      "zoomMeetingId" => group["zoomMeetingId"],
      "zoomMeetingPassword" => group["zoomMeetingPassword"],
    }
    if !is_nil(group["aboutGroup"]) do
      Map.put_new(groupMap, "aboutGroup", group["aboutGroup"])
    end
    if !is_nil(group["appVersion"]) do
      Map.put_new(groupMap, "appVersion", group["appVersion"])
    end
    if !is_nil(group["category"]) do
      Map.put_new(groupMap, "category", group["category"])
    end
    if !is_nil(group["subCategory"]) do
     Map.put_new(groupMap, "subCategory", group["subCategory"])
    end
    if !is_nil(group["avatar"]) do
      Map.put_new(groupMap, "image", group["avatar"])
    end
    #check user is admin
    if login_user["_id"] == group["adminId"] do
       Map.put(groupMap, "isAdmin", true)
    end
    ###############  Check category of app ##################
    cond do
      #### if category = school
      group["category"] == "school" ->
        # check isTeacher
        isTeacher = GroupRepo.checkIsTeacher(group["_id"], login_user["_id"])
        # check isStudent
        isStudent = GroupRepo.checkIsStudent(group["_id"], login_user["_id"])
        if isTeacher do
          Map.put(groupMap, "isTeacher", true)
        else
          Map.put(groupMap, "isTeacher", false)
        end
        if isStudent do
          Map.put(groupMap, "isStudent", true)
        else
          Map.put(groupMap, "isStudent", false)
        end
      #### if category = constituency
      group["category"] == "constituency" ->
        groupMap = groupMap
        |> Map.put("isAdmin", false)
        |> Map.put("isAuthorizedUser", false)
        |> Map.put("isDepartmentTaskForce", false)
        |> Map.put("isPartyTaskForce", false)
        ##|> Map.put_new("isAuthorizedUser", false)
        |> Map.put("isBoothPresident", false)
        |> Map.put("isBoothMember", false)
        |> Map.put("isPublic", false)
        |> Map.put("isBoothWorker", false)
        #3. check login user is booth president
        checkIsBoothPresident = GroupRepo.checkLoginUserIsBoothPresident(group["_id"], login_user["_id"])
        if length(checkIsBoothPresident) > 0 do
          groupMap = Map.put(groupMap, "isBoothPresident", true)
          groupMap = Map.put(groupMap, "boothCount", length(checkIsBoothPresident))
          #check how many booths and if more than 1 then just provide count. If equal to one then provide the boothId/teamId
          if length(checkIsBoothPresident) == 1 do
            groupMap
            |> Map.put("boothId", fetch_id_from_object(hd(checkIsBoothPresident)["_id"]))
            |> Map.put("boothName", hd(checkIsBoothPresident)["name"])
          end
        end
        #4. check isBooth worker/ page pramukh
        checkIsBoothWorker = ConstituencyRepo.checkIsBoothWorker(login_user["_id"], group["_id"]) #check booth worker/page pramukh is having subBooths under him
        if length(checkIsBoothWorker) > 0 do
          #is page pramukh or booth worker
          groupMap = Map.put(groupMap, "isBoothWorker", true)
          groupMap = Map.put(groupMap, "subBoothCount", length(checkIsBoothWorker))
          #check how many sub booths and if more than 1 then just provide count. If equal to one then provide the subBoothId/teamId
          if length(checkIsBoothWorker) == 1 do
            groupMap = Map.put(groupMap, "subBoothId", fetch_id_from_object(hd(checkIsBoothWorker)["_id"]))
            groupMap = Map.put(groupMap, "subBoothName", hd(checkIsBoothWorker)["name"])
            #get members count for this one subBooth
            {:ok, subBoothMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(group["_id"], hd(checkIsBoothWorker)["_id"])
            Map.put(groupMap, "subBoothMembers", subBoothMembersCount)
          end
        end
        #5. check isBoothMember
        {:ok, checkIsBoothMember} = ConstituencyRepo.checkIsBoothMember(login_user["_id"], group["_id"])
        #6. check user isPartyTaskForce
        {:ok, checkIsPartyPerson} = ConstituencyRepo.checkUserIsPartyPerson(login_user["_id"], group["_id"])
        #7. check user isDepartmentTaskForce
        {:ok, checkIsDepartmentPerson} = ConstituencyRepo.checkUserIsDepartmentPerson(login_user["_id"], group["_id"])
        #check login user isAdmin
        if login_user["_id"] == group["adminId"] do
          Map.put(groupMap, "isAdmin", true)
        end
        if checkCanPost["canPost"] == true do
          Map.put(groupMap, "isAuthorizedUser", true)
        end
        if checkIsBoothMember > 0 do
          Map.put(groupMap, "isBoothMember", true)
        end
        if checkIsPartyPerson > 0 do
          Map.put(groupMap, "isPartyTaskForce", true)
        end
        if checkIsDepartmentPerson > 0 do
          Map.put(groupMap, "isDepartmentTaskForce", true)
        end
        if login_user["_id"] != group["adminId"] && checkCanPost["canPost"] == false && length(checkIsBoothPresident) == 0 && length(checkIsBoothWorker) == 0 &&
          checkIsBoothMember == 0 && checkIsPartyPerson == 0 && checkIsDepartmentPerson == 0 do
          Map.put(groupMap, "isPublic", true)
        end
      #### if category = constituency
      group["category"] == "community" ->
        groupMap = groupMap
        |> Map.put("isAdmin", false)
        |> Map.put("isAuthorizedUser", false)
        |> Map.put("isDepartmentTaskForce", false)
        |> Map.put("isPartyTaskForce", false)
        ##|> Map.put_new("isAuthorizedUser", false)
        |> Map.put("isBoothPresident", false)
        |> Map.put("isBoothMember", false)
        |> Map.put("isPublic", true)
        |> Map.put("isBoothWorker", false)
        #check login user isAdmin
        if login_user["_id"] == group["adminId"] do
          Map.put(groupMap, "isAdmin", true)
        end
        if checkCanPost["canPost"] == true do
          Map.put(groupMap, "isAuthorizedUser", true)
        end
        if login_user["_id"] == group["adminId"] || checkCanPost["canPost"] == true do
          Map.put(groupMap, "isPublic", false)
        end
      true ->
        groupMap
    end

    %{ data: [ groupMap ] }
  end


  def render("group_events.json", %{getEventsList: getEventsList, loginUserId: loginUserId, group: group}) do
    groupObjectId = group["_id"]
    #get login user all teamIds for group
    userTeamIds = GroupRepo.getUserTeamIds(groupObjectId, loginUserId)
    #IO.puts "#{getEventsList}"
    #firstly get events list for groupPost, teamPost
    eventsList = Enum.at(getEventsList, 0)
    ##IO.puts "#{eventsList["eventsList"]}"
    eventsList = Enum.reduce(eventsList["eventsList"], [], fn k, acc ->
      #IO.puts "#{k["insertedId"]}"
      map = %{
        "groupId" => fetch_id_from_object(k["groupId"]),
        "eventName" => k["eventName"],
        "eventType" => k["eventType"],
        "eventAt" => k["eventAt"],
        #"insertedId" => fetch_id_from_object(k["insertedId"])
      }
      #if !is_nil(k["insertedId"]) do
      #  map = Map.put_new(map, "insertedId", fetch_id_from_object(k["insertedId"]))
      #end
      map = if !is_nil(k["teamId"]) do
        Map.put_new(map, "teamId", fetch_id_from_object(k["teamId"]))
      else
        map
      end
      map = if !is_nil(k["subjectId"]) do
        Map.put_new(map, "subjectId", fetch_id_from_object(k["subjectId"]))
      else
        map
      end
      map = if !is_nil(k["testExamId"]) do
        Map.put_new(map, "testExamId", fetch_id_from_object(k["testExamId"]))
      else
        map
      end
      acc ++ [map]
    end)  ## [eventList]
    #secondly get subject count for class
    classSubjectCount = Enum.at(getEventsList, 1)
    ##IO.puts "#{classSubjectCount["subjectCount"]}"
    ######classSubjectCountList = [%{"subjectCountList" => classSubjectCount["subjectCount"]}]
    #thirdly get teams count for dashboard, live class, all class
    #get team count for loginuser (dashboard, live class and homework/notes/markscard... class list)
    #get dashboard teams count for login user
    {:ok, dashboardTeamsCount} = GroupRepo.getLoginUserDashboardTeamcounts(loginUserId, groupObjectId)
    #get live class teams list count for login user
    {:ok, getLiveClassTeamsCount} = GroupRepo.getLoginUserLiveClassTeamsCount(loginUserId, groupObjectId)
    #get class teams count for notes, HW, markscard etc...
    {:ok, getClassTeamsCount} = GroupRepo.getLoginUserClassTeamsCount(loginUserId, groupObjectId)
    #get loginUser last inserted team time
    getLoginUserLastInsertedTeamTime = GroupRepo.getLoginUserLastInsertedTeamTime(loginUserId, groupObjectId)
    ######get login user last team updated at time from team_col
    getLoginUserLastUpdatedTeamTime = ConstituencyRepo.getLoginUserLastUpdatedConstituencyTeamTime(userTeamIds)
    lastTeamUpdatedEventAt = if getLoginUserLastUpdatedTeamTime != [] do
      getLoginUserLastUpdatedTeamTime["updatedAt"]
    else
      bson_time()
    end
    #########get last gallery post updated at time
    lastGalleryPostEventAt = ConstituencyRepo.getLastGalleryPostUpdatedAtEventFromEventCol(groupObjectId)
    galleryPostEvent = if !is_nil(lastGalleryPostEventAt) do
      lastGalleryPostEventAt["eventAt"]
    else
      bson_time()
    end
    #get login user groups count
    {:ok, getSchoolGroupCount} = GroupRepo.getSchoolGroupCountForLoginUser(loginUserId)
    #get latest notification updatedAt time
    latestNotificationAt = GroupRepo.getLatesNotificationUpdatedAtTime(groupObjectId, loginUserId, userTeamIds)
    #get last social media link updatedAt time
    latestSocialMediaLinkUpdatedAt = GroupRepo.getLatestSocialMediaLinkUpdatedAt(groupObjectId)
    teamCountMap = %{
      "dashboardTeamCount" => dashboardTeamsCount,
      "liveClassTeamCount" => getLiveClassTeamsCount,
      "getAllClassTeamCount" => getClassTeamsCount,
      "schoolGroupCount" => getSchoolGroupCount,
      # "lastInsertedTeamTime" => getLoginUserLastInsertedTeamTime,
      "lastInsertedTeamTime" => Enum.max([getLoginUserLastInsertedTeamTime, lastTeamUpdatedEventAt, latestSocialMediaLinkUpdatedAt]),
      "lastNotificationAt" => latestNotificationAt["insertedAt"],
      "galleryPostEventAt" => galleryPostEvent,
      "accessKey" => "NZZPHWUCQLCGPKDSWXHA",
      "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0"
    }
    if group["trialEndPeriod"] do
      trailDaysPending = SchoolCollegeRegisterHandler.getTrailPeriodRemainingDays(group["trialEndPeriod"])
      Map.put_new(teamCountMap, "trailPeriodPending", trailDaysPending)
    end
    ######listOfTeamsCount = [%{"teamsListCount" => teamCountMap}]

    #first merge all the maps
    mergeMap1 = Map.merge(%{"teamsListCount" => teamCountMap}, %{"subjectCountList" => classSubjectCount["subjectCount"]})
    mergeEventMap = Map.merge(mergeMap1, %{"eventList" => eventsList})

    #add url to generate image preview like whatsapp before user download the image(Url sent from vinod)
    imagePreviewUrlMap = %{"imagePreviewUrl" => "https://ik.imagekit.io/mxfzvmvkayv/"}
    #merge map final
    mergeMapFinal = Map.merge(mergeEventMap, imagePreviewUrlMap)

    %{data: [mergeMapFinal]}
  end


  def render("group_events_constituency.json", %{loginUserId: loginUserId, group: group}) do
    #get login user all teamIds for group
    userTeamIds = GroupRepo.getUserTeamIds(group["_id"], loginUserId)
    activeTeamForUserTeamIds = GroupRepo.getAllActiveIdsOfTeam(userTeamIds)  #get all active teamIds only
    #create map for all the roles
    roleMap = %{
      "isAdmin" => false,
      "isAuthorizedUser" => false,
      "isBoothPresident" => false,
      "isBoothMember" => false,
      "isBoothWorker" => false,
      "isPartyTaskForce" => false,
      "isDepartmentTaskForce" => false,
      "isPublic" => false
    }
    #2. check login user is authorized user of group
    checkCanPost = GroupRepo.checkUserCanPostInGroup(group["_id"], loginUserId)
    #3. check login user is booth president
    {:ok, checkIsBoothPresident} = GroupRepo.checkLoginUserIsBoothPresidentForEvent(group["_id"], loginUserId)
    #4. check isBooth worker/ page pramukh
    {:ok, checkIsBoothWorker} = ConstituencyRepo.checkIsBoothWorkerForEvent(loginUserId, group["_id"])
    #5. check isBoothMember
    {:ok, checkIsBoothMember} = ConstituencyRepo.checkIsBoothMember(loginUserId, group["_id"])
    #6. check user isPartyTaskForce
    {:ok, checkIsPartyPerson} = ConstituencyRepo.checkUserIsPartyPerson(loginUserId, group["_id"])
    #7. check user isDepartmentTaskForce
    {:ok, checkIsDepartmentPerson} = ConstituencyRepo.checkUserIsDepartmentPerson(loginUserId, group["_id"])
    #get roles of login user in constituency app for events
    roleMap = if loginUserId == group["adminId"] do
      Map.put(roleMap, "isAdmin", true)
    else
      roleMap
    end
    roleMap = if checkCanPost["canPost"] == true do
      Map.put(roleMap, "isAuthorizedUser", true)
    else
      roleMap
    end
    roleMap =  if checkIsBoothPresident > 0 do
      Map.put(roleMap, "isBoothPresident", true)
    else
      roleMap
    end
    roleMap = if checkIsBoothWorker > 0 do
      Map.put(roleMap, "isBoothWorker", true)
    else
      roleMap
    end
    roleMap = if checkIsBoothMember > 0 do
      Map.put(roleMap, "isBoothMember", true)
    else
      roleMap
    end
    roleMap = if checkIsPartyPerson > 0 do
      Map.put(roleMap, "isPartyTaskForce", true)
    else
      roleMap
    end
    roleMap = if checkIsDepartmentPerson > 0 do
      Map.put(roleMap, "isDepartmentTaskForce", true)
    else
      roleMap
    end
    roleMap =  if loginUserId != group["adminId"] && checkCanPost["canPost"] == false && checkIsBoothPresident == 0 && checkIsBoothWorker == 0 &&
      checkIsBoothMember == 0 && checkIsPartyPerson == 0 && checkIsDepartmentPerson == 0 do
      Map.put(roleMap, "isPublic", true)
    else
      roleMap
    end
    #check user is admin or [president]
    lastBoothUpdatedAtEvent = cond do
      roleMap["isAdmin"] == true || roleMap["isAuthorizedUser"] == true ->
        #get last booth updatedAt time event
        lastBoothUpdatedAt = ConstituencyRepo.getLastConstituencyBoothUpdatedAtEvent(group["_id"])
        lastBoothUpdatedAt["updatedAt"]
      roleMap["isBoothPresident"] == true ->
        []
      roleMap["isBoothWorker"] == true ->
        []
      roleMap["isBoothMember"] == true ->
        []
      roleMap["isPartyTaskForce"] == true ->
        []
      roleMap["isDepartmentTaskForce"] == true ->
        []
      roleMap["isPublic"] == true ->
        []
    end
    #get anouncement post event at time
    #########get last anouncement / last group post
    lastAnouncementEventAt = ConstituencyRepo.getLastGroupPostEventFromEventCol(group["_id"])
    #IO.puts "#{lastAnouncementEventAt}"
    anouncementPostEvent = if !is_nil(lastAnouncementEventAt) do
      lastAnouncementEventAt["eventAt"]
    else
      bson_time()
    end
    #########get last gallery post updated at time
    lastGalleryPostEventAt = ConstituencyRepo.getLastGalleryPostUpdatedAtEventFromEventCol(group["_id"])
    galleryPostEvent = if !is_nil(lastGalleryPostEventAt) do
      lastGalleryPostEventAt["eventAt"]
    else
      bson_time()
    end
    #########get last banner updated event
    bannerPostEventAt = if group["bannerUpdatedAt"] do
      group["bannerUpdatedAt"]
    else
      bson_time()
    end
    ##########get last calendar post updatedAt time
    lastCalendarEventAt = ConstituencyRepo.getLastCalendarEventUpdatedAtFromEventCol(group["_id"])
    calendarEvent = if !is_nil(lastCalendarEventAt) do
      lastCalendarEventAt["eventAt"]
    else
      bson_time()
    end
    #########get last profile updatedAt for login user
    getLastProfileUpdatedEventAt = ConstituencyRepo.getUserProfileLastUpdatedAtEvent(loginUserId)
    myProfileLastUpdatedEventAt = getLastProfileUpdatedEventAt["updatedAt"]
    ######get login user last team inserted at time from grp_team_mem
    getLoginUserLastInsertedTeamTime = GroupRepo.getLoginUserLastInsertedTeamTime(loginUserId, group["_id"])
    ######get login user last team updated at time from team_col
    getLoginUserLastUpdatedTeamTime = ConstituencyRepo.getLoginUserLastUpdatedConstituencyTeamTime(userTeamIds)
    lastTeamUpdatedEventAt = if getLoginUserLastUpdatedTeamTime != [] do
      getLoginUserLastUpdatedTeamTime["updatedAt"]
    else
      bson_time()
    end
    #####get login user last notification feed event at time // so to get teamPost notification event i need to pass activeTeamForUserTeamIds
    getLastNotificationFeedEventAt = GroupRepo.getLatesNotificationUpdatedAtTime(group["_id"], loginUserId, activeTeamForUserTeamIds)
    # lastNotificationFeedEventAt = if getLastNotificationFeedEventAt != [] do
    #   getLastNotificationFeedEventAt["insertedAt"]
    # else
    #   bson_time()
    # end
    lastNotificationFeedEventAt = getLastNotificationFeedEventAt["insertedAt"]
    #get dashboard team last post time, members count for login user
    ####lastTeamPostEventAt = getHomePageTeamPostEventAtTime(activeTeamForUserTeamIds, group["_id"], loginUserId)
    #IO.puts "#{lastTeamPostEventAt}"
    #final result
    constituencyEventMap = %{
      "roles" => roleMap,
      "announcementPostEventAt" => anouncementPostEvent,
      "galleryPostEventAt" => galleryPostEvent,
      "bannerPostEventAt" => bannerPostEventAt,
      "calendarEventAt" => calendarEvent,
      "notificationFeedEventAt" => lastNotificationFeedEventAt,
      ##"homeTeamsLastPostEventAt" => lastTeamPostEventAt,
      "homeTeamsLastPostEventAt" => [],
      "myProfileUpdatedEventAt" => myProfileLastUpdatedEventAt,
      "lastInsertedTeamTime" => getLoginUserLastInsertedTeamTime,
      "lastUpdatedTeamTime" => lastTeamUpdatedEventAt,
      #only for admin
      "allBoothsPostEventAt" => [],
      "lastInsertedBoothTeamTime" => lastBoothUpdatedAtEvent
    }
    #school events - Send null|empty
    schoolEventMapMap = %{
      "teamsListCount" => %{
        #digitalocea access keys
        "secretKey" => "0BOBamyRMoWstLoX96aTg92Q9EMOZg9B7dXY/35BMn0",
        "accessKey" => "NZZPHWUCQLCGPKDSWXHA"
      },
      "subjectCountList" => [],
      "imagePreviewUrl" => "https://ik.imagekit.io/mxfzvmvkayv/",
      "eventList" => []
    }
    finalResult = Map.merge(constituencyEventMap, schoolEventMapMap)
    #IO.puts "#{[finalResult]}"
    %{ data: [ finalResult ] }
  end


  def render("group_events_constituency_all_booth.json", %{groupObjectId: groupObjectId}) do
    #######get last updated my booth team for booth president
    # getLastUpdatedBoothTeamEventAt = ConstituencyRepo.getLastUpdatedAllBoothTeamEventAtTime(groupObjectId)
    # lastUpdatedMyBoothTeamEventAt = if getLastUpdatedMyBoothTeamEventAt != [] do
    #   hd(getLastUpdatedMyBoothTeamEventAt)["updatedAt"]
    # else
    #   bson_time()
    # end
    #1. get all booths id for admin
    getAllBoothIds = ConstituencyRepo.getAllBoothTeamIds(groupObjectId)
    #2. get last post updatedAt time for all the boothIds
    boothPostEventList = Enum.reduce(getAllBoothIds, [], fn k, acc ->
      boothId = k["_id"] #boothId or teamId
      #get this booth members count
      # {:ok, boothMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, boothId)
      #get last post done in booth
      lastBoothPostUpdatedAt = ConstituencyRepo.getLastTeamPostEventFromEventCol(groupObjectId, boothId)
      #get last committeeUpdatedAt time event for booth team
      # lastCommitteeForBoothUpdatedAt = ConstituencyRepo.lastCommitteeForBoothUpdatedAtEvent(groupObjectId, boothId)
      # if lastCommitteeForBoothUpdatedAt != [] do
      #   lastCommitteeForBoothUpdatedAtEventTime = hd(lastCommitteeForBoothUpdatedAt)["committeeUpdatedAt"]
      # else
      #   lastCommitteeForBoothUpdatedAtEventTime = nil
      # end
      #get last user/member for team/booth upadtedAt
      # lastUserToTeamUpdatedAt = ConstituencyRepo.lastUserToTeamUpdatedAt(groupObjectId, boothId)
      # if length(lastUserToTeamUpdatedAt) > 0 do
      #   lastUserToTeamUpdatedAtEventTime = hd(lastUserToTeamUpdatedAt)["lastUserUpdatedAt"]
      # else
      #   lastUserToTeamUpdatedAtEventTime = bson_time()
      # end
      #get login user can post and comment in team
      # canPostInTeam = ConstituencyRepo.checkUserCanPostInTeam(groupObjectId, boothId, loginUserId)
      # if canPostInTeam != [] do
      #   #IO.puts "#{}"
      #   canPostInTeam = hd(canPostInTeam)["teams"]["allowedToAddPost"]
      #   #canCommentInTeam = hd(canPostInTeam)["teams"]["allowedToAddComment"]
      #   canCommentInTeam = true
      # else
      #   canPostInTeam = true
      #   canCommentInTeam = true
      # end
      #IO.puts "#{bson_time()}"
      boothPostMap = if lastBoothPostUpdatedAt != [] do
        %{
          "boothId" => encode_object_id(boothId),
          "lastBoothPostAt" => lastBoothPostUpdatedAt["eventAt"],
          "members" => 36,
          "canPost" => true,
          "canComment" => true,
          "lastCommitteeForBoothUpdatedEventAt" => bson_time(),
          "lastUserToTeamUpdatedAtEventAt" => bson_time()
        }
      else
        %{
          "boothId" => encode_object_id(boothId),
          "lastBoothPostAt" => lastBoothPostUpdatedAt["eventAt"],
          "members" => 36,
          "canPost" => true,
          "canComment" => true,
          "lastCommitteeForBoothUpdatedEventAt" => bson_time(),
          "lastUserToTeamUpdatedAtEventAt" => bson_time()
        }
      end
      acc ++ [boothPostMap]
    end)
    %{data: boothPostEventList}
  end


  def render("team_post_events.json", %{groupObjectId: groupObjectId, teamObjectId: teamObjectId, loginUserId: loginUserId}) do
    #1. get last team post posted at event
    lastTeamPostUpdatedAt = ConstituencyRepo.getLastTeamPostEventFromEventCol(groupObjectId, teamObjectId)
    ##1. Get last team posted at time
    teamPostEventAt = if lastTeamPostUpdatedAt != [] do
      lastTeamPostUpdatedAt["eventAt"]
    else
      bson_time()
    end
    ###2. get this team members count
    {:ok, teamMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, teamObjectId)
    ###3. get login user can post and comment in team
    checkCanPostInTeam = ConstituencyRepo.checkUserCanPostInTeam(groupObjectId, teamObjectId, loginUserId)
    canPost = if checkCanPostInTeam != [] do
      %{
        canPostInTeam: hd(checkCanPostInTeam)["teams"]["allowedToAddPost"],
        canCommentInTeam: hd(checkCanPostInTeam)["teams"]["allowedToAddComment"]
      }
    else
      checkIsGroupAdmin = ConstituencyRepo.checkUserCanPost(groupObjectId, loginUserId)
      if checkIsGroupAdmin["canPost"] != true  do
        %{
        canPostInTeam: false,
        canCommentInTeam: true,
        }
      else
        %{
          canPostInTeam: true,
          canCommentInTeam: true,
        }
      end
    end
    map = %{
      "teamId" => encode_object_id(teamObjectId),
      "lastTeamPostAt" => teamPostEventAt,
      "members" => teamMembersCount,
      "canPost" => canPost.canPostInTeam,
      "canComment" => canPost.canCommentInTeam
    }
    #final result
    %{ data: [map] }
  end


  def render("team_events.json", %{groupObjectId: groupObjectId, team: team}) do
    teamObjectId = team["_id"]
    ###1. get this team members count
    {:ok, teamMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, teamObjectId)
    ###2. get last user/member for team/booth upadtedAt
    lastUserToTeamUpdatedAt = ConstituencyRepo.lastUserToTeamUpdatedAt(groupObjectId, teamObjectId)
    lastUserToTeamUpdatedAtEventTime = if length(lastUserToTeamUpdatedAt) > 0 do
      hd(lastUserToTeamUpdatedAt)["lastUserUpdatedAt"]
    else
      bson_time()
    end
    map = %{
      "teamId" => encode_object_id(teamObjectId),
      "members" => teamMembersCount,
      "lastUserToTeamUpdatedAtEventAt" => lastUserToTeamUpdatedAtEventTime
    }
    #check team is booth category team to get events related to booths team
    if team["category"] == "booth" do
      #get last committeeUpdatedAt time event for booth team
      lastCommitteeForBoothUpdatedAt = ConstituencyRepo.lastCommitteeForBoothUpdatedAtEvent(groupObjectId, teamObjectId)
      lastCommitteeForBoothUpdatedAtEventTime = if lastCommitteeForBoothUpdatedAt != [] do
        hd(lastCommitteeForBoothUpdatedAt)["committeeUpdatedAt"]
      else
        bson_time()
      end
      map
      |> Map.put_new("lastCommitteeForBoothUpdatedEventAt", lastCommitteeForBoothUpdatedAtEventTime)
    end
    #final result
    %{ data: [map] }
  end


  def render("group_events_constituency_subbooth.json", %{loginUserId: _loginUserId, groupObjectId: groupObjectId, boothTeamId: boothTeamId}) do
    boothTeamObjectId = decode_object_id(boothTeamId)
    #######get last updated subbooth team for selected booth team
    getLastUpdatedSubBoothTeamEventAt = ConstituencyRepo.getLastUpdatedSubBoothTeamEventAtTime(groupObjectId, boothTeamObjectId)
    lastUpdatedSubBoothTeamEventAt = if getLastUpdatedSubBoothTeamEventAt != [] do
      hd(getLastUpdatedSubBoothTeamEventAt)["updatedAt"]
    else
      bson_time()
    end
    #######get all subBooth teams for selected booth team
    subBoothTeamIds = ConstituencyRepo.getSubBoothTeamIdsForSelectedBooth(groupObjectId, boothTeamObjectId)
    #get team post last event for each sub booth team
    lastTeamPostEventList = Enum.reduce(subBoothTeamIds, [], fn k, acc ->
      teamObjectId = k["_id"]
      #get this team members count
      {:ok, teamMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, teamObjectId)
      #get last team post posted at event
      lastTeamPostUpdatedAt = ConstituencyRepo.getTeamLastPostUpdatedAtEvent(groupObjectId, teamObjectId)
      teamPostMap = if lastTeamPostUpdatedAt != [] do
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => hd(lastTeamPostUpdatedAt)["updatedAt"],
          "members" => teamMembersCount
        }
      else
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => bson_time(),
          "members" => teamMembersCount
        }
      end
      acc ++ [teamPostMap]
    end)
    subBoothPostEventMap = %{
      "subBoothTeamsLastPostEventAt" => lastTeamPostEventList
    }
    subBoothLastUpdatedAtMap = %{
      "lastUpdatedSubBoothTeamTime" => lastUpdatedSubBoothTeamEventAt
    }
    finalMap = Map.merge(subBoothLastUpdatedAtMap, subBoothPostEventMap)
    #final result
    %{ data: [finalMap] }
  end


  def render("group_events_constituency_my_booth.json", %{loginUserId: loginUserId, groupObjectId: groupObjectId}) do
    #######get last updated my booth team for booth president
    getLastUpdatedMyBoothTeamEventAt = ConstituencyRepo.getLastUpdatedMyBoothTeamEventAtTime(groupObjectId, loginUserId)
    lastUpdatedMyBoothTeamEventAt = if getLastUpdatedMyBoothTeamEventAt != [] do
      hd(getLastUpdatedMyBoothTeamEventAt)["updatedAt"]
    else
      bson_time()
    end
    #######get my Booth teams for booth president = login user
    myBoothTeamIds = ConstituencyRepo.getMyBoothTeamIdsForBoothPresident(groupObjectId, loginUserId)
    #get team post last event for each sub booth team
    lastMyBoothPostEventList = Enum.reduce(myBoothTeamIds, [], fn k, acc ->
      teamObjectId = k["_id"]
      #get this team members count
      {:ok, teamMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, teamObjectId)
      #get last team post posted at event
      lastTeamPostUpdatedAt = ConstituencyRepo.getTeamLastPostUpdatedAtEvent(groupObjectId, teamObjectId)
      #get last committeeUpdatedAt time event for booth team
      lastCommitteeForBoothUpdatedAt = ConstituencyRepo.lastCommitteeForBoothUpdatedAtEvent(groupObjectId, teamObjectId)
      lastCommitteeForBoothUpdatedAtEventTime = if lastCommitteeForBoothUpdatedAt != [] do
        hd(lastCommitteeForBoothUpdatedAt)["committeeUpdatedAt"]
      else
        nil
      end
      #get last user/member for team/booth upadtedAt
      lastUserToTeamUpdatedAt = ConstituencyRepo.lastUserToTeamUpdatedAt(groupObjectId, teamObjectId)
      lastUserToTeamUpdatedAtEventTime = if length(lastUserToTeamUpdatedAt) > 0 do
       hd(lastUserToTeamUpdatedAt)["lastUserUpdatedAt"]
      else
        bson_time()
      end
      #get login user can post and comment in team
      canPostInTeam = ConstituencyRepo.checkUserCanPostInTeam(groupObjectId, teamObjectId, loginUserId)
      canPost =if canPostInTeam != [] do
        %{
          canPostInTeam: hd(canPostInTeam)["teams"]["allowedToAddPost"],
          canCommentInTeam: true
        }
      else
        %{
          canPostInTeam: true,
          canCommentInTeam: true
        }
      end
      teamPostMap = if lastTeamPostUpdatedAt != [] do
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => hd(lastTeamPostUpdatedAt)["updatedAt"],
          "members" => teamMembersCount,
          "canPost" => canPost.canPostInTeam,
          "canComment" => canPost.canCommentInTeam,
          "lastCommitteeForBoothUpdatedEventAt" => lastCommitteeForBoothUpdatedAtEventTime,
          "lastUserToTeamUpdatedAtEventAt" => if lastUserToTeamUpdatedAtEventTime == nil do
            bson_time()
          else
            lastUserToTeamUpdatedAtEventTime
          end
        }
      else
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => bson_time(),
          "members" => teamMembersCount,
          "canPost" => canPost.canPostInTeam,
          "canComment" => canPost.canCommentInTeam,
          "lastCommitteeForBoothUpdatedEventAt" => lastCommitteeForBoothUpdatedAtEventTime,
          "lastUserToTeamUpdatedAtEventAt" => if lastUserToTeamUpdatedAtEventTime == nil do
            bson_time()
          else
            lastUserToTeamUpdatedAtEventTime
          end
        }
      end
      acc ++ [teamPostMap]
    end)
    myBoothPostEventMap = %{
      "myBoothTeamsLastPostEventAt" => lastMyBoothPostEventList
    }
    myBoothLastUpdatedAtMap = %{
      "lastUpdatedMyBoothTeamTime" => lastUpdatedMyBoothTeamEventAt
    }
    finalMap = Map.merge(myBoothPostEventMap, myBoothLastUpdatedAtMap)
    #final result
    %{ data: [finalMap] }
  end


  def render("group_events_constituency_my_subbooth.json", %{loginUserId: loginUserId, groupObjectId: groupObjectId}) do
    #######get last updated my booth team for booth president
    getLastUpdatedMyBoothTeamEventAt = ConstituencyRepo.getLastUpdatedMySubBoothTeamEventAtTime(groupObjectId, loginUserId)
    lastUpdatedMySubBoothTeamEventAt = if getLastUpdatedMyBoothTeamEventAt != [] do
      hd(getLastUpdatedMyBoothTeamEventAt)["updatedAt"]
    else
      bson_time()
    end
    #######get my Booth teams for booth president = login user
    myBoothTeamIds = ConstituencyRepo.getMySubBoothTeamIdsForBoothWorker(groupObjectId, loginUserId)
    #get team post last event for each sub booth team
    lastMySubBoothPostEventList = Enum.reduce(myBoothTeamIds, [], fn k, acc ->
      teamObjectId = k["_id"]
      #get this team members count
      {:ok, teamMembersCount} = ConstituencyRepo.getTotalTeamMembersCount(groupObjectId, teamObjectId)
      #get last team post posted at event
      lastTeamPostUpdatedAt = ConstituencyRepo.getTeamLastPostUpdatedAtEvent(groupObjectId, teamObjectId)
      #get last user/member for team/booth upadtedAt
      lastUserToTeamUpdatedAt = ConstituencyRepo.lastUserToTeamUpdatedAt(groupObjectId, teamObjectId)
      lastUserToTeamUpdatedAtEventTime = if length(lastUserToTeamUpdatedAt) > 0 do
        hd(lastUserToTeamUpdatedAt)["lastUserUpdatedAt"]
      else
        bson_time()
      end
      #get login user can post and comment in team
      canPostInTeam = ConstituencyRepo.checkUserCanPostInTeam(groupObjectId, teamObjectId, loginUserId)
      canPost = if canPostInTeam != [] do
        #IO.puts "#{}"
        %{
          canPostInTeam: hd(canPostInTeam)["teams"]["allowedToAddPost"],
          canCommentInTeam: true
        }
      else
        %{
          canPostInTeam: true,
          canCommentInTeam: true
        }
      end
      teamPostMap = if lastTeamPostUpdatedAt != [] do
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => hd(lastTeamPostUpdatedAt)["updatedAt"],
          "members" => teamMembersCount,
          "canPost" => canPost.canPostInTeam,
          "canComment" => canPost.canCommentInTeam,
          "lastUserToTeamUpdatedAtEventAt" => if lastUserToTeamUpdatedAtEventTime == nil do
            bson_time()
          else
            lastUserToTeamUpdatedAtEventTime
          end
        }
      else
        %{
          "teamId" => encode_object_id(teamObjectId),
          "lastTeamPostAt" => bson_time(),
          "members" => teamMembersCount,
          "canPost" => canPost.canPostInTeam,
          "canComment" => canPost.canCommentInTeam,
          "lastUserToTeamUpdatedAtEventAt" => if lastUserToTeamUpdatedAtEventTime == nil do
            bson_time()
          else
            lastUserToTeamUpdatedAtEventTime
          end
        }
      end
      acc ++ [teamPostMap]
    end)
    mySubBoothPostEventMap = %{
      "mySubBoothTeamsLastPostEventAt" => lastMySubBoothPostEventList
    }
    mySubBoothLastUpdatedAtMap = %{
      "lastUpdatedMySubBoothTeamTime" => lastUpdatedMySubBoothTeamEventAt
    }
    finalMap = Map.merge(mySubBoothPostEventMap, mySubBoothLastUpdatedAtMap)
    #final result
    %{ data: [finalMap] }
  end


  def render("group_live_class_events.json", %{getLiveClassEventsList: getLiveClassEventsList, loginUserId: _loginUserId, groupObjectId: _groupObjectId}) do
    eventsList = Enum.reduce(getLiveClassEventsList, [], fn k, acc ->
      map = %{
        "groupId" => fetch_id_from_object(k["groupId"]),
        "teamId" => fetch_id_from_object(k["teamId"]),
        "eventName" => k["eventName"],
        "eventType" => k["eventType"],
        #"meetingOnLiveId" => fetch_id_from_object(k["meetingOnLiveId"]),
        "createdById" => fetch_id_from_object(k["createdById"]),
        "createdByName" => k["createdByName"]
      }
      #IO.puts "#{k}"
      map = if k["meetingOnLiveId"] != "" do
        Map.put_new(map, "meetingOnLiveId", fetch_id_from_object(k["meetingOnLiveId"]))
      else
        map
      end
      acc ++ [map]
    end)
    %{data: eventsList}
  end


  def render("group_live_testexam_events.json", %{getLiveTestExamEventsList: getLiveTestExamEventsList, loginUserId: _loginUserId, groupObjectId: _groupObjectId}) do
    eventsList = Enum.reduce(getLiveTestExamEventsList, [], fn k, acc ->
      map = %{
        "groupId" => fetch_id_from_object(k["groupId"]),
        "teamId" => fetch_id_from_object(k["teamId"]),
        "eventName" => k["eventName"],
        "eventType" => k["eventType"],
        "subjectId" => fetch_id_from_object(k["subjectId"]),
        "testExamId" => fetch_id_from_object(k["testExamId"]),
        "createdById" => fetch_id_from_object(k["createdById"]),
        "createdByName" => k["createdByName"]
      }
      acc ++ [map]
    end)
    %{data: eventsList}
  end


  def render("getTalukList.json", %{talukList: talukList, loginUser: loginUser}) do
    list = Enum.reduce(talukList, [], fn k, acc ->
      #get number of groups belogs to particular taluk
      getTalukGroups = GroupRepo.getTalukGroupsListForSchoolGroup(k["taluk"])
      map = %{
        "talukName" => k["taluk"],
        "talukImage" => k["image"],
        "groupCount" => length(getTalukGroups)
      }
      if length(getTalukGroups) == 1 do
        map
        |> Map.put_new("groupId", fetch_id_from_object(hd(getTalukGroups)["_id"]))
        |> Map.put_new("groupName", hd(getTalukGroups)["name"])
        |> Map.put_new("groupImage", hd(getTalukGroups)["image"])
        map = if hd(getTalukGroups)["adminId"] == loginUser["_id"] do
          Map.put_new(map, "isAdmin", true)
        else
          Map.put_new(map, "isAdmin", false)
        end
        #check login user can post in group or not
        checkCanPost = GroupRepo.checkUserCanPostInGroup(hd(getTalukGroups)["_id"], loginUser["_id"])
        map
        |> Map.put_new("canPost", checkCanPost["canPost"])
      end
      acc ++ [map]
    end)
    %{data: list}
  end







  def fetch_id_from_object(bson_obj) do
    bson_id = BSON.ObjectId.encode!( bson_obj );
    bson_id
  end

end
