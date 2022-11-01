defmodule GruppieWeb.Repo.NotificationRepo do
  import GruppieWeb.Handler.TimeNow

  @conn :mongo

  @saved_notifications_coll "saved_notifications"

  @group_team_members_coll "group_team_members"

  @student_database_coll "student_database"




  def getNotifications(loginUserId, groupObjectId, limit, params) do
    #update notification last seen time in group_team_members
    ##filterUpdate = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    ##update = %{ "$set" => %{ "notificationLastSeen" => bson_time() } }
    ##Mongo.update_one(@conn, @group_team_members_coll, filterUpdate, update)
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList}, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ]
    }
    pipeline = if params["page"] do
      #get results based on pagination
      pageNo = String.to_integer(params["page"])
      skip = (pageNo - 1) * limit
      [ %{"$match" => filterNotification}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      ##Mongo.find(@conn, @saved_notifications_coll, filterNotification, [sort: %{_id: -1}, skip: skip, limit: limit])
    else
      [%{ "$match" => filterNotification }, %{"$sort" => %{"_id" => -1}}, %{ "$limit" => limit }]
      ##Mongo.find(@conn, @saved_notifications_coll, filterNotification, [sort: %{_id: -1}, limit: limit])
    end
    ##Mongo.aggregate(@conn, @view_saved_notifications_coll, pipeline)
    Mongo.aggregate(@conn, @saved_notifications_coll, pipeline)
  end



  def getTotalNotificationsCount(loginUserId, groupObjectId) do
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{"$in" => teamIdList}, "createdById" => %{"$nin" => [loginUserId]}, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ]
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @saved_notifications_coll, filterNotification, [projection: project])
  end


  def getAllNotificationsUnseenCount(loginUserId, groupObjectId) do
    #get notification last seen time for this login user
    filter = %{"groupId" => groupObjectId, "userId" => loginUserId}
    projection = %{ "_id" => 0, "notificationLastSeen" => 1 }
    lastSeenTime = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filter, [projection: projection])))
    #get login user teams
    filterTeam = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    projectTeam = %{ "_id" => 0, "teams.teamId" => 1 }
    teams = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_coll, filterTeam, [projection: projectTeam])))
    teamIdList = Enum.reduce(teams["teams"], [], fn k, acc ->
      acc ++ [k["teamId"]]
    end)
    #get notification count greater the last seen count
    filterNotification = %{
      "$or" => [
        %{"groupId" => groupObjectId, "createdById" => %{ "$nin" => [loginUserId] }, "notification" => 1},
        %{"groupId" => groupObjectId, "teamId" => %{ "$in" => teamIdList }, "createdById" => %{ "$nin" => [loginUserId] }, "notification" => 2},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 3},
        %{"groupId" => groupObjectId, "receiverId" => loginUserId, "notification" => 4}
      ],
      "insertedAt" => %{ "$gt" => lastSeenTime["notificationLastSeen"] }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @saved_notifications_coll, filterNotification, [projection: project])
  end


  ############## group notifications #######################################

  def addGroupPostNotification(loginUser, group, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => group["_id"],
      "postId" => postObjectId,
      "insertedAt" => bson_time(),
      "type" => "groupPost",
      "notification" => 1
    }
    message = if group["category"] == "school" do
      loginUser["name"]<>" has posted in Notice Board"
    else
      if group["category"] == "corporate" do
        loginUser["name"]<>" has posted in Broadcast"
      else
        loginUser["name"]<>" has posted in "<>group["name"]
      end
    end
    insertMap = insertMap
    |> Map.put_new("message", message)

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



  def galleryAddNotification(loginUser, groupObjectId, albumObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "albumId" => albumObjectId,
      "insertedAt" => bson_time(),
      "type" => "gallery",
      "message" => loginUser["name"]<>" added a new Album in Gallery",
      "notification" => 1
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



  def schoolCalendarAddNotification(loginUser, groupObjectId, day, month, year) do
    dateList = [day, month, year]
    date = Enum.join(dateList, "-")
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "insertedAt" => bson_time(),
      "type" => "schoolCalendar",
      "month" => month,
      "message" => loginUser["name"]<>" added a new event on date: "<>date,
      "notification" => 1
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  ############################### team notifications ####################################


  def addTeamPostNotification(loginUser, groupObjectId, team, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "postId" => postObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "teamPost",
      "message" => loginUser["name"]<>" has posted in "<>team["name"],
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def removeNotificationFromTeam(postObjectId) do
    filter = %{
      "postId" => postObjectId
    }
    Mongo.delete_one(@conn, @saved_notifications_coll, filter)
  end



  def teamSubjectPostNotification(loginUser, groupObjectId, team, postObjectId, subject) do
    #message = loginUser["name"]<>" has posted in "<>subject["subjectName"]<>" subject in "<>team["name"]<>" team"
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "subjectId" => subject["_id"],
      "postId" => postObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "notesVideosPost",
      "message" => loginUser["name"]<>" has posted Notes in "<>subject["subjectName"]<>" subject ("<>team["name"]<>")",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def teamSubjectTopicPostNotification(loginUser, groupObjectId, team, postObjectId, subject, topicId) do
    #message = loginUser["name"]<>" has posted in "<>subject["subjectName"]<>" subject in "<>team["name"]<>" team"
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "subjectId" => subject["_id"],
      "postId" => postObjectId,
      "teamId" => team["_id"],
      "topicId" => topicId,
      "insertedAt" => bson_time(),
      "type" => "notesVideosPost",
      "message" => loginUser["name"]<>" has posted Notes in "<>subject["subjectName"]<>" subject ("<>team["name"]<>")",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def teamAddAssignmentNotification(loginUser, groupObjectId, team, assignmentObjectId, subject) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "subjectId" => subject["_id"],
      #"assignmentId" => assignmentObjectId,
      "postId" => assignmentObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "homeWorkPost",
      "message" => loginUser["name"]<>" has posted Homework in "<>subject["subjectName"]<>" subject ("<>team["name"]<>")",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def teamAddTestExamNotification(loginUser, groupObjectId, team, testExamObjectId, subject) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "subjectId" => subject["_id"],
      #"testExamId" => testExamObjectId,
      "postId" => testExamObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "testExamPost",
      "message" => loginUser["name"]<>" has Scheduled Test/Exam in "<>subject["subjectName"]<>" subject ("<>team["name"]<>")",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def addTripStartNotification(loginUser, groupObjectId, team) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "gps",
      "message" => team["name"]<>" trip started",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



  def addTripEndNotification(loginUser, groupObjectId, team) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "gps",
      "message" => team["name"]<>" trip ended",
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def addTimeTablePostNotification(loginUser, groupObjectId, team, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "postId" => postObjectId,
      "teamId" => team["_id"],
      "insertedAt" => bson_time(),
      "type" => "teamPost",
      "message" => loginUser["name"]<>" added a Timetable in "<>team["name"],
      "notification" => 2
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



############ Individual notifications ###################################

  def addIndividualPostNotification(loginUser, groupObjectId, friendObjectId, postObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "receiverId" => friendObjectId,
      "postId" => postObjectId,
      "insertedAt" => bson_time(),
      "type" => "individualPost",
      "message" => loginUser["name"]<>" has sent you message",
      "notification" => 3
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def absentMessageNotifiation(loginUserId, notificationMessage, userObjectId, groupObjectId, teamObjectId) do
    insertMap = %{
      "createdById" => loginUserId,
      "groupId" => groupObjectId,
      "receiverId" => userObjectId,
      "insertedAt" => bson_time(),
      "type" => "attendanceMessage",
      "message" => notificationMessage,
      "notification" => 4,
      "teamId" => teamObjectId,
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def marksCardAddNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, _rollNumber) do
    ##filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "rollNumber" => rollNumber }
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "isActive" => true }
    user = hd(Enum.to_list(Mongo.find(@conn, @student_database_coll, filter)))
    #insert into notification collection
    insertMap = %{
      "createdById" => loginUserId,
      "groupId" => groupObjectId,
      "receiverId" => userObjectId,
      "insertedAt" => bson_time(),
      "type" => "marksCard",
      "message" => user["name"]<>" marks card is uploaded",
      "notification" => 5,
      "teamId" => teamObjectId,
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def studentINNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, _rollNumber) do
    ##filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "rollNumber" => rollNumber }
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "isActive" => true }
    user = hd(Enum.to_list(Mongo.find(@conn, @student_database_coll, filter)))
    #insert into notification collection
    insertMap = %{
      "createdById" => loginUserId,
      "groupId" => groupObjectId,
      "receiverId" => userObjectId,
      "insertedAt" => bson_time(),
      "type" => "absentMessage",
      "message" => user["name"]<>" is IN now",
      "notification" => 4,
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def studentOUTNotification(loginUserId, groupObjectId, teamObjectId, userObjectId, _rollNumber) do
    ##filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "rollNumber" => rollNumber }
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "userId" => userObjectId, "isActive" => true }
    user = hd(Enum.to_list(Mongo.find(@conn, @student_database_coll, filter)))
    #insert into notification collection
    insertMap = %{
      "createdById" => loginUserId,
      "groupId" => groupObjectId,
      "receiverId" => userObjectId,
      "insertedAt" => bson_time(),
      "type" => "absentMessage",
      "message" => user["name"]<>" is OUT now",
      "notification" => 4,
    }
    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def attendanceNotification123(loginUserId, absentStudentIds, _rollNumbers, groupObjectId, teamObjectId) do
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentIds },
      "isActive" => true
      ##"$and" => [%{ "userId" => %{ "$in" => absentStudentIds } },
      ##          %{ "rollNumber" => %{ "$in" => rollNumbers } }]
    }
    absent = Mongo.find(@conn, @student_database_coll, filterAbsent)
    Enum.reduce(absent, [], fn k, _acc ->
      insertMap = %{
        "createdById" => loginUserId,
        "groupId" => groupObjectId,
        "receiverId" => k["userId"],
        "insertedAt" => bson_time(),
        "type" => "absentMessage",
        "message" => k["name"]<>" is absent for today's class",
        "notification" => 4,
        "teamId" => teamObjectId,
      }
      Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
    end)
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$nin" => absentStudentIds },
      "isActive" => true
      ##"$or" => [%{ "userId" => %{ "$nin" => absentStudentIds } },
      ##          %{ "rollNumber" => %{ "$nin" => rollNumbers } }]
    }
    present = Mongo.find(@conn, @student_database_coll, filterPresent)
    Enum.reduce(present, [], fn k, _acc ->
      insertMap = %{
        "createdById" => loginUserId,
        "groupId" => groupObjectId,
        "receiverId" => k["userId"],
        "insertedAt" => bson_time(),
        "type" => "absentMessage",
        "message" => k["name"]<>" is present for today's class",
        "notification" => 4,
        "teamId" => teamObjectId,
      }
      Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
    end)
  end

  def attendanceNotification(loginUserId, absentStudentIds, groupObjectId, teamObjectId) do
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$in" => absentStudentIds },
      "isActive" => true
    }
    absent = Mongo.find(@conn, @student_database_coll, filterAbsent)
    Enum.reduce(absent, [], fn k, _acc ->
      insertMap = %{
        "createdById" => loginUserId,
        "groupId" => groupObjectId,
        "receiverId" => k["userId"],
        "insertedAt" => bson_time(),
        "type" => "absentMessage",
        "message" => k["name"]<>" is absent for today's class",
        "notification" => 4,
        "teamId" => teamObjectId,
      }
      Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
    end)
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{ "$nin" => absentStudentIds },
      "isActive" => true
      ##"$or" => [%{ "userId" => %{ "$nin" => absentStudentIds } },
      ##          %{ "rollNumber" => %{ "$nin" => rollNumbers } }]
    }
    present = Mongo.find(@conn, @student_database_coll, filterPresent)
    Enum.reduce(present, [], fn k, _acc ->
      insertMap = %{
        "createdById" => loginUserId,
        "groupId" => groupObjectId,
        "receiverId" => k["userId"],
        "insertedAt" => bson_time(),
        "type" => "absentMessage",
        "message" => k["name"]<>" is present for today's class",
        "notification" => 4,
        "teamId" => teamObjectId,
      }
      Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
    end)
  end


  def addGroupPostCommentNotification(loginUser, group, commentObjectId, post) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => group["_id"],
      "receiverId" => post["userId"],
      "postId" => post["_id"],
      "commentId" => commentObjectId,
      "insertedAt" => bson_time(),
      "type" => "groupPostComment",
      "notification" => 3
    }
    message = if group["category"] == "school" do
      loginUser["name"]<>" has commented to your post in Notice Board"
    else
      if group["category"] == "corporate" do
        loginUser["name"]<>" has commented to your post in Broadcast"
      else
        loginUser["name"]<>" has commented to your post in "<>group["name"]
      end
    end
    insertMap = insertMap
    |> Map.put_new("message", message)

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



  def addGroupPostCommentReplyNotification(loginUser, group, comment) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => group["_id"],
      "receiverId" => comment["createdBy"],
      "postId" => comment["postId"],
      "commentId" => comment["_id"],
      "insertedAt" => bson_time(),
      "type" => "groupPostComment",
      "notification" => 3
    }
    message = if group["category"] == "school" do
      loginUser["name"]<>" has replied to your comment in Notice Board"
    else
      if group["category"] == "corporate" do
        loginUser["name"]<>" has replied to your comment in Broadcast"
      else
        loginUser["name"]<>" has replied to your comment in "<>group["name"]
      end
    end
    insertMap = insertMap
    |> Map.put_new("message", message)

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end



  def addTeamPostCommentNotification(loginUser, groupObjectId, team, post, commentObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "receiverId" => post["userId"],
      "postId" => post["_id"],
      "commentId" => commentObjectId,
      "insertedAt" => bson_time(),
      "type" => "teamPostComment",
      "message" => loginUser["name"]<>" has commented to your post in "<>team["name"],
      "notification" => 3
    }

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def addTeamPostCommentReplyNotification(loginUser, groupObjectId, team, comment) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "receiverId" => comment["createdBy"],
      "postId" => comment["postId"],
      "commentId" => comment["_id"],
      "insertedAt" => bson_time(),
      "type" => "teamPostComment",
      "message" => loginUser["name"]<>" has replied to your comment in "<>team["name"],
      "notification" => 3
    }

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def addIndividualPostCommentNotification(loginUser, groupObjectId, post, commentObjectId) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "receiverId" => post["senderId"],
      "postId" => post["_id"],
      "commentId" => commentObjectId,
      "insertedAt" => bson_time(),
      "type" => "individualPostComment",
      "message" => loginUser["name"]<>" has commented to your message",
      "notification" => 3
    }

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


  def addIndividualPostCommentReplyNotification(loginUser, groupObjectId, comment) do
    insertMap = %{
      "createdById" => loginUser["_id"],
      "groupId" => groupObjectId,
      "receiverId" => comment["createdBy"],
      "postId" => comment["postId"],
      "commentId" => comment["_id"],
      "insertedAt" => bson_time(),
      "type" => "individualPostComment",
      "message" => loginUser["name"]<>" has replied to your comment in message",
      "notification" => 3
    }

    Mongo.insert_one(@conn, @saved_notifications_coll, insertMap)
  end


end
