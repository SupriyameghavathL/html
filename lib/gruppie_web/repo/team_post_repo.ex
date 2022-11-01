defmodule GruppieWeb.Repo.TeamPostRepo do
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow
  alias GruppieWeb.Repo.NotificationRepo

  @conn :mongo

  @post_col "posts"

  @group_team_members_col "group_team_members"

  @view_post_col "VW_POSTS"

  @view_team_col "VW_TEAMS"

  @view_team_time_table_col "VW_TEAM_TIME_TABLE"

  @view_team_year_time_table_col "VW_TEAM_YEAR_TIME_TABLE"

  @vehicle_track_col "vehicle_track"

  @team_time_table_col "team_time_table"

  @view_student_db_col "VW_STUDENT_DB"

  @view_subject_post_col "VW_SUBJECT_POSTS"

  @student_db_col "student_database"

  @marks_card_col "marks_card"

  @teams_col "teams"

  @school_assignment_col "school_assignment"

  @school_testexam_col "school_testexam"

  @team_year_timetable_col "team_year_time_table"

  @subject_staff_db_col "subject_staff_database"

  @staff_db_col "staff_database"

  @subject_post_col "subject_posts"

  @school_markscard_db_col "school_markscard_database"

  @school_offline_testexam_timetable_col "school_offline_testexam_timetable"
  #####
  @online_class_attendance_col "online_class_attendance"

  @offline_class_attendance_col "offline_class_attendance"

  @view_subject_post_topics_col "VW_SUBJECT_POST_TOPICS"

  @school_fee_db_col "school_fees_database"

  @school_class_fees_col "school_class_fees"

  @view_school_fee_db_col "VW_SCHOOL_FEES_DB"

  @view_school_fee_paid_details "VW_SCHOOL_FEE_PAID_DETAILS"

  @view_school_assignment_col "VW_SCHOOL_ASSIGNMENT"

  @view_school_testexam_col "VW_SCHOOL_TESTEXAM"

  @view_school_student_assignment_col "VW_SCHOOL_STUDENT_ASSIGNMENT"

  @view_school_student_testexam_col "VW_SCHOOL_STUDENT_TESTEXAM"

  @group_action_events_col "group_action_events"

  @view_school_markscard_db_col "VW_SCHOOL_MARKSCARD_DB"

  @view_offline_class_attendance_col "VW_OFFLINE_CLASS_ATTENDANCE"

  @view_student_leave_apply_col "VW_STUDENTS_LEAVE_APPLIES"

  @groups_col "groups"




  def getTeamPostReadMore(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    pipeline = [%{ "$match" => filter }]
    hd(Enum.to_list(Mongo.aggregate(@conn, @view_post_col, pipeline)))
  end



  def add(changeset, loginUserId, groupObjectId, teamObjectId) do
    changeset = changeset
    |> update_map_with_key_value(:groupId, groupObjectId)
    |> update_map_with_key_value(:teamId, teamObjectId)
    |> update_map_with_key_value(:userId, loginUserId)
    |> update_map_with_key_value(:type, "teamPost")
    Mongo.insert_one(@conn, @post_col, changeset)
  end


  def addSubjectVicePostsForTeam(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId, topicMap, chapterObjectId) do
    topicMap = topicMap
    |> Map.put(:fileType, changeset.fileType)
    |> Map.put(:insertedAt, bson_time())
    |> Map.put(:createdById, encode_object_id(loginUser["_id"]))
    |> Map.put(:studentStatusCompleted, [])
    # topicMap = %{topicId: encode_object_id(new_object_id), topicName: changeset.topicName, fileType: changeset.fileType,
    #               insertedAt: bson_time(), createdById: encode_object_id(loginUser["_id"]), studentStatusCompleted: []}
    topicMap = if Map.has_key?(changeset, :fileName) do   #image/pdf/videoFile
      Map.put_new(topicMap, :fileName, changeset.fileName)
    else
      topicMap
    end
    topicMap = if Map.has_key?(changeset, :video) do  #youtube video
      Map.put_new(topicMap, :video, changeset.video)
    else
      topicMap
    end
    topicMap = if Map.has_key?(changeset, :thumbnailImage) do  #if pdf or video then thumbnail image is coming from front end
      Map.put_new(topicMap, :thumbnailImage, changeset.thumbnailImage)
    else
     topicMap
    end
    changesetDoc = if Map.has_key?(topicMap, :chapterName) do
      chapterName = topicMap.chapterName
      topicMap = Map.delete(topicMap, :chapterName)
      %{
        _id: chapterObjectId,
        chapterName: chapterName,
        groupId: groupObjectId,
        teamId: teamObjectId,
        userId: loginUser["_id"],
        subjectId: subjectObjectId,
        isActive: true,
        insertedAt: bson_time(),
        updatedAt: bson_time(),
        topics: [topicMap],
      }
    else
      %{
        _id: chapterObjectId,
        chapterName: changeset.chapterName,
        groupId: groupObjectId,
        teamId: teamObjectId,
        userId: loginUser["_id"],
        subjectId: subjectObjectId,
        isActive: true,
        insertedAt: changeset.insertedAt,
        updatedAt: changeset.updatedAt,
        topics: [topicMap],
      }
    end
    Mongo.insert_one(@conn, @subject_post_col, changesetDoc)
  end


  def addToSubjectToMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, syllabusInsertDoc) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "syllabus" => syllabusInsertDoc
      }
    }
    Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end



  def getSubjectVicePosts(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    pipeline = [%{"$match" => filter}]
    Mongo.aggregate(@conn, @view_subject_post_col, pipeline)
    |>Enum.to_list()
  end


  def checkWhetherChapterIsCreatedForId(groupObjectId, teamObjectId, _subjectObjectId, chapterObjectId) do
    filter = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
    }
    Mongo.count(@conn, @subject_post_col, filter)
  end


  def getChapterNameFromMaster(groupObjectId, teamObjectId, subjectObjectId, chapterId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "syllabus.chapterId" => chapterId,
    }
    project = %{
      "syllabus.chapterName.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @subject_staff_db_col, filter, [projection: project])
  end


  def addTopicsToChapter(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, topicId) do
    changeset = changeset
                  |> update_map_with_key_value(:insertedAt, bson_time())
                  |> update_map_with_key_value(:topicId, topicId)
                  |> update_map_with_key_value(:createdById, encode_object_id(loginUser["_id"]))
                  |> update_map_with_key_value(:studentStatusCompleted, [])
    filter = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true,
    }
    update = %{"$push" => %{"topics" => changeset}}
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @subject_post_col, filter, update)
    {:ok, %{topicId: topicId}}
  end


  def topicAddToExistingChapterMaster(groupObjectId,teamObjectId, subjectObjectId, chapter_id, insertTopicDoc) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "syllabus.chapterId" => chapter_id,
      "isActive" => true,
    }
    update = %{
      "$push" => %{
        "syllabus.$.topicsList" => insertTopicDoc
      },
      "$inc" => %{
        "syllabus.$.totalTopicsCount" => 1,
      }
    }
    Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end


  def removeChapterFromSubject(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId) do
    removeChapterInMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId)
    filter = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
    }
    Mongo.delete_one(@conn, @subject_post_col, filter)
  end


  defp removeChapterInMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId)  do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "syllabus.chapterId" => encode_object_id(chapterObjectId),
      "isActive" => true,
    }
    update = %{
      "$pull" => %{
        "syllabus" => %{
          "chapterId" => encode_object_id(chapterObjectId),
        }
      }
    }
    Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end


  def removeTopicFromChapter(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topicId) do
    removeTopicInMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topicId)
    filter = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
    }
    update = %{"$pull" => %{"topics" => %{"topicId" => topicId}}}
    Mongo.update_one(@conn, @subject_post_col, filter, update)
  end


  defp removeTopicInMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topicId)  do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "syllabus.chapterId" => encode_object_id(chapterObjectId),
      "isActive" => true,
    }
    update = %{
      "$pull" => %{
        "syllabus.$.topicsList" => %{
          "topicId" => topicId,
        }
      },
      "$inc" => %{
        "syllabus.$.totalTopicsCount" => -1
      }
    }
   Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end




  def addStatusCompletedToTopicsByStudent(loginUserId, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topic_id) do
    #update student id as completed/not completed
    filterUpdate = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "topics.topicId" => topic_id
    }
    #find login user already completed topic
    {:ok, findStudentAlreadyCompleted} = findStudentCompletedTopics(loginUserId, groupObjectId, teamObjectId, chapterObjectId, topic_id)
    #if not already that is result is 0 then update to true
    if findStudentAlreadyCompleted == 0 do
      update = %{"$push" => %{"topics.$.studentStatusCompleted" => encode_object_id(loginUserId)}}
      Mongo.update_one(@conn, @subject_post_col, filterUpdate, update)
    else
      #not completed topic, update to false
      update = %{"$pull" => %{"topics.$.studentStatusCompleted" => encode_object_id(loginUserId)}}
      Mongo.update_one(@conn, @subject_post_col, filterUpdate, update)
    end
  end


  #teamPostView: to get student name and id from student db (topics completed status check)
  def getStudentDetailFromDb(groupObjectId, teamObjectId, userIdsArray) do
    userObjectIdArray = Enum.reduce(userIdsArray, [], fn k, acc ->
      userObjectId = decode_object_id(k)
      acc ++ [userObjectId]
    end)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => userObjectIdArray
      },
      "isActive" => true
    }
    project = %{"_id" => 1, "name" => 1, "userId" => 1}
    studentsList = Enum.to_list(Mongo.find(@conn, @student_db_col, filter, [projection: project]))
    #convert _id, userId to string from objectId
    Enum.reduce(studentsList, [], fn k, acc ->
      k = k
          |> Map.delete("_id")
          |> Map.put_new("studentDbId", encode_object_id(k["_id"]))
          |> Map.put("userId", encode_object_id(k["userId"]))
      acc ++ [k]
    end)
  end

  #teamPostView: to check login user is completed topics or not
  def findStudentCompletedTopics(loginUserId, groupObjectId, teamObjectId, chapterObjectId, topicId) do
    filter = %{
      "_id" => chapterObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "topics.topicId" => topicId,
      "topics.studentStatusCompleted" => %{
        "$in" => [encode_object_id(loginUserId)]
      }
    }
    project = %{"_id" => 1}
    #IO.puts "#{filter}"
    Mongo.count(@conn, @view_subject_post_topics_col, filter, [projection: project])
  end




  def updateJitsiTokenOnStart(loginUserId, groupObjectId, teamObjectId, meetingOnLiveId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "class" => true,
      "isActive" => true,
    }
    update = %{"$set" => %{"alreadyOnJitsiLive" => true, "jitsiMeetCreatedBy" => loginUserId, "meetingIdOnLive" => meetingOnLiveId}}
    Mongo.update_one(@conn, @teams_col, filter, update)
  end


  def addAttendanceDocumentForThiMeetingId(loginUser, groupObjectId, teamObjectId, meetingIdOnLive) do
    insertMap = %{
      "_id" => meetingIdOnLive,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      ##"meetingCreatedById" => loginUser["_id"],
      ##"meetingCreatedByName" => loginUser["name"],
      "meetingCreatedBy" => loginUser["_id"],
      "meetingCreatedByName" => loginUser["name"],
      "isActive" => false,  #return to true when attendance is submitted by teacher with subjectId, meeting endedAt timing
      ##"meetingCreatedAt" => bson_time(),
      "meetingCreatedAtTime" => bson_time(),
      "attendance" => []
    }
    Mongo.insert_one(@conn, @online_class_attendance_col, insertMap)
  end



  def pushOnlineAttendance(changeset, groupObjectId, teamObjectId) do
    changeset = changeset
                |> Map.put_new(:groupId, groupObjectId)
                |> Map.put_new(:teamId, teamObjectId)
                |> Map.put(:meetingCreatedById, decode_object_id(changeset.meetingCreatedById))
    Mongo.insert_one(@conn, @online_class_attendance_col, changeset)
  end


  def createOnlineClassAttendanceForTeam(loginUserId, groupObjectId, teamObjectId, meetingOnLiveId) do
    insertMap = %{
      "_id" => meetingOnLiveId,
      "meetingCreatedBy" => loginUserId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => false,  #return to true when attendance is submitted by teacher with subjectId, meeting endedAt timing
      "meetingCreatedAtTime" => bson_time(),
      "attendance" => []
    }
    Mongo.insert_one(@conn, @online_class_attendance_col, insertMap)
  end

  ######## OLD ###########
  def findStudentAlreadyJoinedMeeting(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId) do
    meetingJoinedAtBsonTime = bson_time()
    filter = %{
      "_id" => meetingOnLiveId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => false,
      "attendance.studentDbId" => studentDetail["studentDbId"]
    }
    project = %{"_id" => 1}
    #IO.puts "#{filter}"
    {:ok, alreadyJoined} = Mongo.count(@conn, @online_class_attendance_col, filter, [projection: project])
    if alreadyJoined > 0 do
      #get only time and minute to save in meetingJoinedAtTime
      currentTime = NaiveDateTime.utc_now
      indianCurrentTime = NaiveDateTime.add(currentTime, 19800)
      time = if indianCurrentTime.hour > 12 do
        %{
          indianHour: to_string(indianCurrentTime.hour - 12),
          zone: "PM"
        }
      else
        %{
          indianHour: to_string(indianCurrentTime.hour - 12),
          zone: "AM"
        }
      end
      indianMinute = to_string(indianCurrentTime.minute)
      indianTime = time.indianHour<>":"<>indianMinute<>time.zone
      #just push meetingJoinedAtTime time to particular student
      update = %{"$push" => %{"attendance.$.meetingJoinedAtBsonTime" => meetingJoinedAtBsonTime, "attendance.$.meetingJoinedAtTime" => indianTime}}
      Mongo.update_one(@conn, @online_class_attendance_col, filter, update)
    else
      #add newly to the attendance (Student joined newly)
      addStudentOnlineAttendance(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId)
    end
  end


  #################### NEW ###################
  def findStudentAlreadyJoinedThisMeeting(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId) do
    meetingJoinedAtBsonTime = bson_time()
    filter = %{
      "_id" => meetingOnLiveId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => false,
      "attendance.studentDbId" => studentDetail["studentDbId"]
    }
    project = %{"_id" => 1}
    {:ok, alreadyJoined} = Mongo.count(@conn, @online_class_attendance_col, filter, [projection: project])
    if alreadyJoined > 0 do
      #get only time and minute to save in meetingJoinedAtTime
      currentTime = NaiveDateTime.utc_now
      indianCurrentTime = NaiveDateTime.add(currentTime, 19800)
      time = if indianCurrentTime.hour > 12 do
        %{
          indianHour: to_string(indianCurrentTime.hour - 12),
          zone: "PM"
        }
      else
        %{
          indianHour: to_string(indianCurrentTime.hour - 12),
          zone: "AM"
        }
      end
      indianMinute = to_string(indianCurrentTime.minute)
      indianTime = time.indianHour<>":"<>indianMinute<>time.zone
      #just push meetingJoinedAtTime time to particular student
      update = %{"$push" => %{"attendance.$.meetingJoinedAtBsonTime" => meetingJoinedAtBsonTime, "attendance.$.meetingJoinedAtTime" => indianTime}}
      Mongo.update_one(@conn, @online_class_attendance_col, filter, update)
    else
      #add newly to the attendance (Student joined newly)
      addStudentOnlineAttendance(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId)
    end
  end


  def addStudentOnlineAttendance(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId) do
    meetingJoinedAtBsonTime = bson_time()
    #get only time and minute to save in meetingJoinedAtTime
    currentTime = NaiveDateTime.utc_now
    indianCurrentTime = NaiveDateTime.add(currentTime, 19800)
    time = if indianCurrentTime.hour > 12 do
      %{
        indianHour: to_string(indianCurrentTime.hour - 12),
        zone: "PM"
      }
    else
      %{
        indianHour: to_string(indianCurrentTime.hour - 12),
        zone: "AM"
      }
    end
    indianMinute = to_string(indianCurrentTime.minute)
    indianTime = time.indianHour<>":"<>indianMinute<>time.zone
    #get only time and minute to save in meetingJoinedAtTime
    updateDoc = studentDetail
                |> Map.put_new("meetingJoinedAtTime", [indianTime])
                |> Map.put_new("meetingJoinedAtBsonTime", [meetingJoinedAtBsonTime])
    filter = %{
      "_id" => meetingOnLiveId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => false
    }
    #IO.puts "#{updateDoc}"
    update = %{"$push" => %{"attendance" => updateDoc}}
    Mongo.update_one(@conn, @online_class_attendance_col, filter, update)
  end


  def submitOnlineClassAttendanceForTeam(_loginUserId, groupObjectId, teamObjectId, subjectObjectId, meetingOnLiveId, dateTimeMap) do
    #IO.puts "#{params}"
    filter = %{
      "_id" => meetingOnLiveId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId
    }
    update = %{"$set" => %{"isActive" => true, "subjectId" => subjectObjectId, "meetingEndedAtTime" => bson_time(), "month" => dateTimeMap["month"]}}
    Mongo.update_one(@conn, @online_class_attendance_col, filter, update)
  end


  def submitAttendanceForLiveClass(_loginUserId, groupObjectId, teamObjectId, subjectObjectId, meetingOnLiveId, dateTimeMap, subjectName) do
    #IO.puts "#{params}"
    filter = %{
      "_id" => meetingOnLiveId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId
    }
    update = %{"$set" => %{"isActive" => true, "subjectId" => subjectObjectId, "subjectName" => subjectName, "meetingEndedAtTime" => bson_time(), "month" => dateTimeMap["month"]}}
    Mongo.update_one(@conn, @online_class_attendance_col, filter, update)
  end



  def endLiveClassEvent(_loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "eventType" => 7
    }
    Mongo.delete_many(@conn, @group_action_events_col, filter)
  end


  def getAllStudentsForOnlineClassAttendance(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1, "name" => 1, "rollNumber" => 1, "userId" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getOnlineClassConductedListForMonth(groupObjectId, teamObjectId, month) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "month" => month,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    project = %{"_id" => 1, "meetingCreatedAtTime" => 1, "meetingCreatedBy" => 1, "subjectId" => 1, "meetingCreatedByName" => 1, "subjectName" => 1}
    Mongo.find(@conn, @online_class_attendance_col, filter, [projection: project, sort: %{}])
    |> Enum.to_list
  end


  def checkStudentIsPresentForMeetingId(studentDbObjectId, userObjectId, meetingObjectId) do
    filter = %{
      "_id" => meetingObjectId,
      "attendance.studentDbId" => studentDbObjectId,
      "attendance.userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @online_class_attendance_col, filter, [projection: project])
  end


  ####*****Not required, now directly taking fron online_atrendance_col****#########
  def getStaffMeetingCreatedByName(groupObjectId, userObjectId) do
    filter = %{
      "userId" => userObjectId,
      "groupId" => groupObjectId
    }
    project = %{"_id" => 0, "name" => 1}
    Mongo.find(@conn, @staff_db_col, filter, [projection: project])
    |> Enum.to_list
    |> hd
  end


  def getSubjectNameForMeeting(_groupObjectId, subjectObjectId) do
    filter = %{
      "_id" => subjectObjectId,
      # "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "subjectName" => 1}
    #Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project])
    #|> Enum.to_list
    #|> hd
    Mongo.find_one(@conn, @subject_staff_db_col, filter, [projection: project])
  end


  #for online attendance
  #def getPresentStudentsListForMonth(groupObjectId, teamObjectId, month) do
  #  filter = %{
  #    "groupId" => groupObjectId,
  #    "teamId" => teamObjectId,
  #    "month" => month,
  #    "isActive" => true
  #  }
  #  project = %{"_id" => 0, "attendance" => 1}
  #  Mongo.find(@conn, @online_class_attendance_col, filter, [projection: project])
  #  |> Enum.to_list
  #  |> hd
  #end


  def checkLoginUserCreatedJitsiMeeting(loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "jitsiMeetCreatedBy" => loginUserId
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @teams_col, filter, [projection: project])
  end


  def checkLoginUserCreatedLiveMeeting(loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "createdById" => loginUserId
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @group_action_events_col, filter, [projection: project])
  end


  def updateJitsiTokenOnStop(loginUserId, groupObjectId, teamObjectId, meetingIdOnLive) do
    filter = %{
      "_id" => teamObjectId,
      "groupId" => groupObjectId,
      "class" => true,
      "isActive" => true
    }
    #if meetingIdOnLive == "null" do
    update = %{"$set" => %{"alreadyOnJitsiLive" => false},
              "$unset" => %{"jitsiMeetCreatedBy" => loginUserId, "meetingIdOnLive" => meetingIdOnLive}}
    #else
    #  update = %{"$set" => %{"alreadyOnJitsiLive" => false},
    #           "$unset" => %{"jitsiMeetCreatedBy" => loginUserId, "meetingIdOnLive" => meetingIdOnLive}}
    #end
    Mongo.update_one(@conn, @teams_col, filter, update)
  end



  def getAllPostsOfTeam123(conn, groupObjectId, teamObjectId, limit, _checkMyTeamCount) do
    query_params = conn.query_params
    # loginUser = Guardian.Plug.current_resource(conn)
    #update team post last seen time for login user
    ####filterUpdate = %{"userId" => loginUser["_id"], "groupId" => groupObjectId, "teams.teamId" => teamObjectId}
    ####update = %{ "$set" => %{ "teams.$.teamPostLastSeen" => bson_time() } } #current time update
    ####Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    #get team posts from VW_POSTS
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "isActive" => true }
    ####if checkMyTeamCount > 0 do
      #login user team - So get user name from team details from group_team_members
    ####  project = %{ "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image",
    ####              "_id" => 1, "comments" => 1, "likes" => 1, "text" => 1, "title" => 1, "fileName" => 1, "fileType" => 1, "video" => 1,
    ####              "groupId" => 1, "userId" => 1, "isActive" => 1, "insertedAt" => 1, "updatedAt" => 1, "thumbnailImage" => 1}
    ####else
    ####  #other's team - So get user name from userDetails (Users collection)
    ####  project = %{ "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image",
    ####              "_id" => 1, "comments" => 1, "likes" => 1, "text" => 1, "title" => 1, "fileName" => 1, "fileType" => 1, "video" => 1,
    ####              "groupId" => 1, "userId" => 1, "isActive" => 1, "insertedAt" => 1, "updatedAt" => 1, "thumbnailImage" => 1}
    ####end

    #get user name from userDetails (Users collection)
    project = %{ "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image",
    "_id" => 1, "comments" => 1, "likes" => 1, "text" => 1, "title" => 1, "fileName" => 1, "fileType" => 1, "video" => 1,
    "groupId" => 1, "userId" => 1, "isActive" => 1, "insertedAt" => 1, "updatedAt" => 1, "thumbnailImage" => 1}

    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_post_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }} ]
      Mongo.aggregate(@conn, @view_post_col, pipeline)
    end
  end


  def getAllPostsOfTeam(conn, groupObjectId, teamObjectId, limit) do
    query_params = conn.query_params
    loginUser = Guardian.Plug.current_resource(conn)
    #filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "isActive" => true }
    filter = %{
      "$or" => [
        %{"groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "isActive" => true},
        %{"groupId" => groupObjectId, "bdayUserId" => loginUser["_id"], "type" => "birthdayPost", "isActive" => true},
        ##TEMPORARY
        ##%{"groupId" => groupObjectId, "type" => "birthdayPost", "isActive" => true}
      ]
    }
    #get user name from userDetails (Users collection)
    project = %{ "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image",
    "_id" => 1, "comments" => 1, "likes" => 1, "text" => 1, "title" => 1, "fileName" => 1, "fileType" => 1, "video" => 1,
    "groupId" => 1, "userId" => 1, "isActive" => 1, "insertedAt" => 1, "updatedAt" => 1, "thumbnailImage" => 1, "type" => 1, "bdayUserId" => 1}

    if !is_nil(query_params["page"]) do
      pageNo = String.to_integer(query_params["page"])
      skip = (pageNo - 1) * limit
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }}, %{"$skip" => skip}, %{"$limit" => limit} ]
      Mongo.aggregate(@conn, @view_post_col, pipeline)
    else
      pipeline = [ %{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{ "_id" => -1 }} ]
      Mongo.aggregate(@conn, @view_post_col, pipeline)
    end
  end


  def getTeamPostUnseenCount(login_user_id, group_object_id, team_object_id) do
    lastSeenTime = getUserLastSeenTime(login_user_id, group_object_id, team_object_id)
    filter = %{
      "groupId" => group_object_id,
      "teamId" => team_object_id,
      "type" => "teamPost",
      "insertedAt" => %{ "$gt" => lastSeenTime["teamPostLastSeen"] }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end

  # / UP
  defp getUserLastSeenTime(login_user_id, group_object_id, team_object_id) do
    filter = %{
      "groupId" => group_object_id,
      "userId" => login_user_id,
      "teams.teamId" => team_object_id
    }
    project = %{ "_id" => 0, "teams.$.teamPostLastSeen" => 1 }
    list = Enum.to_list(Mongo.find(@conn, @group_team_members_col, filter, [projection: project]))
    hd(hd(list)["teams"])
  end



  #get total post count of group
  def getTeamPostsCount(group_object_id, team_object_id) do
    filter = %{
      "groupId" => group_object_id,
      "teamId" => team_object_id,
      "type" => "teamPost",
      "isActive" => true,
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def findTeamPostById(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "isActive" => true }
    hd(Enum.to_list(Mongo.find(@conn, @post_col, filter)))
  end


  def findTeamPostExistById(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "isActive" => true }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end


  def deleteTeamPost(groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true, "type" => "teamPost" }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @post_col, filter, update)
  end


  def checkAlreadyTripExist(groupObjectId, team, loginUser, latitude, longitude) do
    filter = %{"groupId" => groupObjectId, "teamId" => team["_id"], "userId" => loginUser["_id"]}
    project = %{"_id" => 1}
    {:ok, count} = Mongo.count(@conn, @vehicle_track_col, filter, [projection: project])
    if count > 0 do
      #update current time
      update = %{"$set" => %{ "updatedAt" => bson_time(), "latitude" => latitude, "longitude" => longitude }}
      Mongo.update_one(@conn, @vehicle_track_col, filter, update)
    else
      currentTime = bson_time()
      #insert newly
      insertBusTrackDetail(groupObjectId, team["_id"], loginUser["_id"], latitude, longitude, currentTime)
      #add notification for team users
      NotificationRepo.addTripStartNotification(loginUser, groupObjectId, team)
      #add trip start post to team
    #  changeset = %{comments: 0, insertedAt: currentTime, isActive: true, likes: 0, title: "Trip Started", updatedAt: currentTime}
    #  add(changeset, loginUserId, groupObjectId, teamObjectId)
    end
  end


  def endTrip(groupObjectId, team, loginUser) do
    filter = %{"groupId" => groupObjectId, "teamId" => team["_id"]}
    Mongo.delete_many(@conn, @vehicle_track_col, filter)
    #put trip end notification
    NotificationRepo.addTripEndNotification(loginUser, groupObjectId, team)
  end


  def getTripLocation(groupObjectId, teamObjectId) do
    filter = %{"groupId" => groupObjectId,"teamId" => teamObjectId }
    project = %{"latitude" => 1, "longitude" => 1, "insertedAt" => 1, "_id" => 0 }
    Enum.to_list(Mongo.find(@conn, @vehicle_track_col, filter, [projection: project]))
  end


  #def addTimeTable(changeset, loginUserId, groupObjectId, teamObjectId) do
  #  changeset1 = changeset
  #              |> update_map_with_key_value(:groupId, groupObjectId)
  #              |> update_map_with_key_value(:teamId, teamObjectId)
  #              |> update_map_with_key_value(:userId, loginUserId)
  #  Mongo.insert_one(@conn, @team_time_table_col, changeset1)
  #end


  def getAllTeamsIdForLoginUser(loginUserId, groupObjectId) do
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    project = %{ "_id" => 0, "teams.teamId" => 1 }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    cursor = Mongo.aggregate(@conn, @view_team_col, pipeline)
    Enum.reduce(cursor, [], fn k, acc ->
      acc ++ [k["teams"]["teamId"]]
    end)
  end


  def getStudentListToAddmarksCard(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    project = %{"_id" => 0, "userId" => 1, "name" => 1, "fatherName" => 1, "motherName" => 1, "dob" => 1,
                "studentId" => 1, "image" => 1, "admissionNumber" => 1, "class" => 1, "section" => 1, "rollNumber" => 1, "languages" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end



  def checkOfflineTestExamMarksCardAlreadyCreated(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_markscard_db_col, filter, [projection: project])
  end



  def insertNewOfflineTestExamTimeTableForTeam(groupObjectId, teamObjectId, changeset) do
    insertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
      "testExamSchedules" => [changeset]
    }
    Mongo.insert_one(@conn, @school_offline_testexam_timetable_col, insertDoc)
  end



  def updateNewOfflineTestExamTimeTableForTeam(groupObjectId, teamObjectId, changeset) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{
      "$push" => %{"testExamSchedules" => changeset}
    }
    Mongo.update_one(@conn, @school_offline_testexam_timetable_col, filter, update)
  end


  def updateNewOfflineTestExamTimeTableForTeamEdit(groupObjectId, teamObjectId, offlineTestExamId, changeset) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "testExamSchedules.offlineTestExamId" => offlineTestExamId,
      "isActive" => true
    }
    update = %{
      "$set" => %{"testExamSchedules.$" => changeset}
    }
    Mongo.update_one(@conn, @school_offline_testexam_timetable_col, filter, update)
  end




  def insertNewOfflineTestExamMarksCardToStudent(studentMarksCardDoc, groupObjectId, teamObjectId) do
    studentMarksCardDoc = studentMarksCardDoc
                          |> update_map_with_key_value("groupId", groupObjectId)
                          |> update_map_with_key_value("teamId", teamObjectId)
    Mongo.insert_one(@conn, @school_markscard_db_col, studentMarksCardDoc)
  end



  def updateNewOfflineTestExamMarksCardToStudent(studentMarksCardDoc, marksCardDoc, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentMarksCardDoc["userId"],
      "isActive" => true
    }
    update = %{
      "$push" => %{
        "marksCardDetails" => marksCardDoc
      }
    }
    Mongo.update_one(@conn, @school_markscard_db_col, filter, update)
  end


  def getOldExamDetails(groupObjectId, teamObjectId, offlineTestExamId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "marksCardDetails.$" => 1,
    }
    Mongo.find_one(@conn, @school_markscard_db_col, filter, [projection: project])
  end


  def updateNewOfflineTestExamMarksCardToStudentEdit(studentMarksCardDoc, marksCardDoc, groupObjectId, teamObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentMarksCardDoc["userId"],
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true
    }
    update = %{
      "$set" => %{
        "marksCardDetails.$" => marksCardDoc
      }
    }
    Mongo.update_one(@conn, @school_markscard_db_col, filter, update)
  end




  def checkOfflineTestExamTimeTableAlreadyForThisTeam(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_offline_testexam_timetable_col, filter, [projection: project])
  end


  def getOfflineTestOrExamList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "testExamSchedules" => 1}
    Mongo.find_one(@conn, @school_offline_testexam_timetable_col, filter, [projection: project])
    #|> Enum.to_list
  end


  def getStudentsForClass(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "name" => 1, "rollNumber" => 1, "fatherName" => 1, "languages" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getIndividualStudentDetailFromDb(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    # project = %{"_id" => 0, "name" => 1, "rollNumber" => 1}
    Mongo.find_one(@conn, @student_db_col, filter)
  end



  def removeOfflineTestExamScheduledTimeTable(groupObjectId, teamObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "testExamSchedules.offlineTestExamId" => offlineTestExamId,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    update = %{
      "$pull" => %{
        "testExamSchedules" => %{ "offlineTestExamId" => offlineTestExamId }
      }
    }
    Mongo.update_one(@conn, @school_offline_testexam_timetable_col, filter, update)
  end


  def removeOfflineTestExamMarksCard(groupObjectId, teamObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    update = %{
      "$pull" => %{
        "marksCardDetails" => %{ "offlineTestExamId" => offlineTestExamId }
      }
    }
    Mongo.update_one(@conn, @school_markscard_db_col, filter, update)
  end


  def getOfflineTestExamStudentMarksCardList(groupObjectId, teamObjectId, offlineTestExamId, studentUserIds) do
    #fetch all the user/studentId for offline testexam created
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{
        "$in" => studentUserIds,
      },
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true,
    }
    project = %{
      "marksCardDetails.offlineTestExamId.$" => 1,
      "marksCardDetails.subjectMarksDetails" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "rollNumber" => 1,
      # "name" => 1,
      "marksCardDetails.title" => 1,
      "userId" => 1,
      "marksCardDetails.duration" => 1,
      "marksCardDetails.rank" => 1,
    }
    Mongo.find(@conn, @school_markscard_db_col, filter, [projection: project])
    |> Enum.to_list()
  end


  def getOfflineTestExamStudentMarksCardListForSelectedStudent(groupObjectId, teamObjectId, offlineTestExamId, studentUserIds) do
    #fetch all the user/studentId for offline testexam created
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentUserIds,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "marksCardDetails.isApproved" => true,
      "isActive" => true,
    }
    project = %{
      "marksCardDetails.offlineTestExamId" => 1,
      "marksCardDetails.subjectMarksDetails" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "rollNumber" => 1,
      "name" => 1,
      "marksCardDetails.title" => 1,
      "userId" => 1,
      "marksCardDetails.duration" => 1,
      "marksCardDetails.rank" => 1,
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @view_school_markscard_db_col, pipeline)
    |> Enum.to_list()
    # IO.puts "#{list}"
  end


  # def getOfflineTestExamSelectedStudentMarksCardListByUser123(groupObjectId, teamObjectId, userObjectId, offlineTestExamId) do
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "userId" => userObjectId,
  #     "marksCardDetails.offlineTestExamId" => offlineTestExamId,
  #     "isActive" => true,
  #     "marksCardDetails.isApproved" => true,
  #   }
  #   project = %{"_id" => 0, "isActive" => 0 }
  #   pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 1}]
  #   Mongo.aggregate(@conn, @view_school_markscard_db_col, pipeline)
  # end


  def approveResultForTestExam(groupObjectId, teamObjectId, offlineTestExam_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "testExamSchedules.offlineTestExamId" => offlineTestExam_id,
      "isActive" => true
    }
    update = %{"$set" => %{"testExamSchedules.$.isApproved" => true}}
    Mongo.update_one(@conn, @school_offline_testexam_timetable_col, filter, update)
  end


  def approveResultForStudent(groupObjectId, teamObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "marksCardDetails.$.isApproved" => true,
      }
    }
    Mongo.update_many(@conn, @school_markscard_db_col, filter, update)
  end


  def notApproveResultForTestExam(groupObjectId, teamObjectId, offlineTestExam_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "testExamSchedules.offlineTestExamId" => offlineTestExam_id,
      "isActive" => true
    }
    update = %{"$set" => %{"testExamSchedules.$.isApproved" => false}}
    Mongo.update_one(@conn, @school_offline_testexam_timetable_col, filter, update)
  end


  def notApproveResultForStudent(groupObjectId, teamObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "marksCardDetails.$.isApproved" => false,
      }
    }
    Mongo.update_many(@conn, @school_markscard_db_col, filter, update)
  end


  def getStudentParentsName(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "fatherName" => 1, "motherName" => 1, "name" => 1, "rollNumber" => 1, "image" => 1}
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
  end



  def addOfflineTestExamMarksToStudent(changeset, groupObjectId, teamObjectId, userObjectId, offlineTestExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "marksCardDetails.offlineTestExamId" => offlineTestExamId,
      #"marksCardDetails" => %{"offlineTestExamId" => offlineTestExamId},
      #"marksCardDetails.subjectMarks.subjectId" => changeset["subjectId"],
      #"marksCardDetails" => %{"subjectMarks" => %{"subjectId" => changeset["subjectId"]}},
      "isActive" => true
    }
    #IO.puts "#{changeset}"
    update = %{
      "$set" => %{
        "marksCardDetails.$.subjectMarksDetails" => changeset
      }
    }

    Mongo.update_one(@conn, @school_markscard_db_col, filter, update)
  end



  def getSubjectById(subject_id) do
    subjectObjectId = decode_object_id(subject_id)
    filter = %{
      "_id" => subjectObjectId,
      "isActive" => true
    }
    hd(Enum.to_list(Mongo.find(@conn, @subject_staff_db_col, filter)))
  end


  # def addSubjectsWithStaff(changeset, groupObjectId, teamObjectId) do
  #   changeset = changeset
  #               |> update_map_with_key_value(:groupId, groupObjectId)
  #               |> update_map_with_key_value(:teamId, teamObjectId)
  #   Mongo.insert_one(@conn, @subject_staff_db_col, changeset)
  # end

  def addSubjectsWithStaff(changeset, groupObjectId, teamObjectId) do
    changeset = changeset
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:teamId, teamObjectId)
    Mongo.insert_one(@conn, @subject_staff_db_col, changeset)
  end


  # def getStaffUserId(groupObjectId, staffObjectId) do
  #   filter = %{
  #     "_id" => staffObjectId,
  #     "groupId" => groupObjectId
  #   }
  #   project = %{"_id" => 0, "userId" => 1}
  #   Mongo.find(@conn, @staff_db_col, filter, [projection: project])
  #   |> Enum.to_list
  #   |> hd
  # end

  def getStaffUserId(groupObjectId, staffUserObjectId) do
    filter = %{
      "userId" => staffUserObjectId,
      "groupId" => groupObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1}
    Mongo.find(@conn, @staff_db_col, filter, [projection: project])
    |> Enum.to_list
    |> hd
  end


  def updateSubjectsWithStaff(changeset, groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    update = %{
      "$set" => %{
        "subjectName" => changeset.subjectName,
        "staffId" => changeset.staffId
      }
    }
    Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end


  def checkTimeTableAddedForThisTeam(groupObjectId, teamObjectId)   do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_year_timetable_col, filter, [projection: project])
  end


  def getSubjectsWithStaffFromTimeTable(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "staffDetails.groupId" => groupObjectId,
      "isActive" => true,
    }
    project = %{ "_id" => 0, "subjectWithStaffId" => 1, "staffId" => 1,  "staffName" => "$staffDetails.name",
                 "subjectName" => "$subjectStaffDetails.subjectName"}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    #Enum.to_list(Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project]))
    Mongo.aggregate(@conn, @view_team_year_time_table_col, pipeline)
    |> Enum.to_list
    |> Enum.uniq
  end


  def getSubjectsWithStaffForTeacher(loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "staffDetails.userId" => loginUserId,
      "staffDetails.groupId" => groupObjectId,
      "isActive" => true
    }
    #IO.pu "#{filter}"
    project = %{ "_id" => 0, "subjectWithStaffId" => 1, "staffId" => 1,  "staffName" => "$staffDetails.name",
                 "subjectName" => "$subjectStaffDetails.subjectName"}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    #Enum.to_list(Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project]))
    Mongo.aggregate(@conn, @view_team_year_time_table_col, pipeline)
    |> Enum.to_list
    |> Enum.uniq
  end


  def getSubjectsWithStaff(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{ "_id" => 1, "staffId" => 1,  "subjectName" => 1}
    Enum.to_list(Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project]))
  end


  def getSubjectsWithStaffById(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{ "_id" => 1, "staffId" => 1,  "subjectName" => 1}
    Enum.to_list(Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project]))
  end


  def addFeeToClass(changeset, groupObjectId, teamObjectId) do
    #### First insert fee created detail in school_class_fees col then insert/update to each students of that class ############
    changesetClassFees = changeset
                          |> update_map_with_key_value(:groupId, groupObjectId)
                          |> update_map_with_key_value(:teamId, teamObjectId)
    #check fee already added/created for this team/class
    filterClassFees = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, alreadyClassFeeExist} = Mongo.count(@conn, @school_class_fees_col, filterClassFees, [projection: project])
    if alreadyClassFeeExist == 0 do
      Mongo.insert_one(@conn, @school_class_fees_col, changesetClassFees)
    else
      #update class fee
      updateClassFee = %{"$set" => changesetClassFees}
      Mongo.update_one(@conn, @school_class_fees_col, filterClassFees, updateClassFee)
    end
  end


  def updateFeeToClass(changeset, groupObjectId, teamObjectId) do
    changeset = changeset
    |> update_map_with_key_value(:groupId, groupObjectId)
    |> update_map_with_key_value(:teamId, teamObjectId)
     #check fee already added/created for this team/class
     filterClassFees = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{
      "_id" => 1
    }
    {:ok, alreadyClassFeeExist} = Mongo.count(@conn, @school_class_fees_col, filterClassFees, [projection: project])
    if alreadyClassFeeExist == 0 do
      Mongo.insert_one(@conn, @school_class_fees_col, changeset)
    else
      #update class fee
      updateClassFee = %{"$set" => changeset}
      Mongo.update_one(@conn, @school_class_fees_col, filterClassFees, updateClassFee)
    end
  end



  def getStudentDbId(groupObjectId, teamObjectId) do
    filter = %{ "groupId" => groupObjectId, "teamId" => teamObjectId, "isActive" => true }
    project = %{"_id" => 1, "userId" => 1}
    Enum.to_list(Mongo.find(@conn, @student_db_col, filter, [projection: project]))
  end


  #this is to add the fee format skin to all the students (only duedates)
  def addFeeForEachStudentInClass(studentDbObjectId, studentDbUserObjectId, changeset, groupObjectId, teamObjectId) do
    #### Second update fees details to all the students ################################
    changeset = changeset
                  |> update_map_with_key_value(:userId, studentDbUserObjectId)
                  |> update_map_with_key_value(:studentDbId, studentDbObjectId)
                  |> update_map_with_key_value(:groupId, groupObjectId)
                  |> update_map_with_key_value(:teamId, teamObjectId)
                  |> update_map_with_key_value(:totalBalance, changeset.totalFee)
                  |> update_map_with_key_value(:totalAmountPaid, 0)
    #find already inserted
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentDbUserObjectId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    {:ok, alreadyExist} = Mongo.count(@conn, @school_fee_db_col, filter, [projection: project])
    if alreadyExist == 0 do
      #if not found then insert newly
      Mongo.insert_one(@conn, @school_fee_db_col, changeset)
    else
      #update fee
      updateFee = %{"$set" => changeset}
      #IO.puts "#{updateFee}"
      Mongo.update_one(@conn, @school_fee_db_col, filter, updateFee)
    end
  end


  def updateFeeForEachStudentInClass(studentDbObjectId, studentDbUserObjectId, changeset, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentDbUserObjectId,
      "isActive" => true
    }
    project = %{
      "_id" => 0
    }
    findMap = Mongo.find_one(@conn, @school_fee_db_col, filter, [projection: project])
    if !findMap  do
      changeset = changeset
      |> update_map_with_key_value(:userId, studentDbUserObjectId)
      |> update_map_with_key_value(:studentDbId, studentDbObjectId)
      |> update_map_with_key_value(:groupId, groupObjectId)
      |> update_map_with_key_value(:teamId, teamObjectId)
      |> update_map_with_key_value(:totalBalance, changeset.totalFee)
      |> update_map_with_key_value(:totalAmountPaid, 0)
      Mongo.insert_one(@conn, @school_fee_db_col, changeset)
    else
      if Map.has_key?(findMap, "totalAmountPaid") do
        totalBalance = changeset.totalFee - findMap["totalAmountPaid"]
        changeset = changeset
        |> Map.put(:totalBalance, totalBalance)
        filter = %{
          "groupId" => groupObjectId,
          "teamId" => teamObjectId,
          "userId" => studentDbUserObjectId,
          "isActive" => true
        }
        update = %{
          "$set" => changeset
        }
        Mongo.update_one(@conn, @school_fee_db_col, filter, update)
      else
        changeset = changeset
        |> Map.put(:totalBalance, changeset.totalFee)
        |> Map.put(:totalAmountPaid, 0)
        filter = %{
          "groupId" => groupObjectId,
          "teamId" => teamObjectId,
          "userId" => studentDbUserObjectId,
          "isActive" => true
        }
        update = %{
          "$set" => changeset
        }
        Mongo.update_one(@conn, @school_fee_db_col, filter, update)
      end
    end
  end


  def updateFeeStructureForIndividualStudentUpdated(changeset, groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{
      "_id" => 0,
    }
    findMap = Mongo.find_one(@conn, @school_fee_db_col, filter, [projection: project])
    if !findMap  do
      changeset = changeset
      |> update_map_with_key_value(:userId, userObjectId)
      |> update_map_with_key_value(:groupId, groupObjectId)
      |> update_map_with_key_value(:teamId, teamObjectId)
      |> update_map_with_key_value(:totalBalance, changeset.totalFee)
      |> update_map_with_key_value(:totalAmountPaid, 0)
      Mongo.insert_one(@conn, @school_fee_db_col, changeset)
    else
      if Map.has_key?(findMap, "totalAmountPaid") do
        totalBalance = changeset.totalFee - findMap["totalAmountPaid"]
        changeset = changeset
        |> Map.put(:totalBalance, totalBalance)
        filter = %{
          "groupId" => groupObjectId,
          "teamId" => teamObjectId,
          "userId" => userObjectId,
          "isActive" => true
        }
        update = %{
          "$set" => changeset
        }
        Mongo.update_one(@conn, @school_fee_db_col, filter, update)
      else
        changeset = changeset
        |> Map.put(:totalBalance, changeset.totalFee)
        |> Map.put(:totalAmountPaid, 0)
        filter = %{
          "groupId" => groupObjectId,
          "teamId" => teamObjectId,
          "userId" => userObjectId,
          "isActive" => true
        }
        update = %{
          "$set" => changeset
        }
        Mongo.update_one(@conn, @school_fee_db_col, filter, update)
      end
    end
  end



  #update fee structure like above for individual student
  def updateFeeStructureForIndividualStudent(changeset, groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    changeset = changeset
                |> update_map_with_key_value(:userId, userObjectId)
                |> update_map_with_key_value(:groupId, groupObjectId)
                |> update_map_with_key_value(:teamId, teamObjectId)
                |> update_map_with_key_value(:totalBalance, changeset.totalFee)
                |> update_map_with_key_value(:totalAmountPaid, 0)
    #update fee
    updateFee = %{"$set" => changeset, "$unset" => %{"feePaidDetails" => ""}}
    #IO.puts "#{updateFee}"
    Mongo.update_one(@conn, @school_fee_db_col, filter, updateFee)
  end



  def getFeeForClass(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    #projection = %{"_id" => 0, "studentDbId" => 0, "paidDates" => 0, "totalAmountPaid" => 0, "totalBalanceAmount" => 0}
    Mongo.find_one(@conn, @school_class_fees_col, filter)
  end


  def getStudentsFeeDetails(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "studentDbDetails.isActive" => true,
      "isActive" => true
    }
    project = %{
      "_id" => 1,
      #"studentDbId" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "userId" => 1,
      "totalFee" => 1,
      "feeDetails" => 1,
      "dueDates" => 1,
      "feePaidDetails" => 1,
      "totalAmountPaid" => 1,
      "totalBalance" => 1,
      "studentDbDetails.name" => 1,
      "studentDbDetails.userId" => 1,
      "studentDbDetails.rollNumber" => 1,
      "studentDbDetails.image" => 1
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$limit" => 100}]
    Mongo.aggregate(@conn, @view_school_fee_db_col, pipeline)
    |>Enum.to_list()
    #IO.puts "#{Enum.to_list(Mongo.aggregate(@conn, @view_school_fee_db_col, pipeline))}"
  end


  def getClassStudentUserIdAndDetailsForFees(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "image" => 1, "name" => 1, "rollNumber" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getFeeStudentListForClass(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{
      "_id" => 1,
      "userId" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "totalFee" => 1,
      "feeDetails" => 1,
      "dueDates" => 1,
      "feePaidDetails" => 1,
      "totalAmountPaid" => 1,
      "totalBalance" => 1,
    }
    Mongo.find(@conn, @school_fee_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getIndividualStudentFeeDetails(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      #"studentDbDetails.userId" => userObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    #IO.puts "#{filter}"
    project = %{
      "_id" => 0,
      #"studentDbId" => 1,
      "groupId" => 1,
      "teamId" => 1,
      "totalFee" => 1,
      "feeDetails" => 1,
      "dueDates" => 1,
      "feePaidDetails" => 1,
      #"paidDates" => 1,
      "totalAmountPaid" => 1,
      "totalBalance" => 1,
      "studentDbDetails.name" => 1,
      "studentDbDetails.userId" => 1,
      "studentDbDetails.rollNumber" => 1,
      "studentDbDetails.image" => 1
    }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    find = Mongo.aggregate(@conn, @view_school_fee_db_col, pipeline)
    |> Enum.to_list
    if length(find) > 0 do
      hd(find)
    else
      []
    end

    # IO.puts "#{find}"
  end



  def addFeePaidDetailsByStudent(changeset, groupObjectId, team, studentDb) do
    changeset = changeset
                |> Map.put_new(:studentName, studentDb["name"])
                |> Map.put_new(:className, team["name"])
                |> Map.put_new(:paymentId, encode_object_id(new_object_id()))
                |> Map.put_new(:status, "notApproved")
                |> Map.put_new(:paidAtTime, bson_time())
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => team["_id"],
      "userId" => studentDb["userId"],
      "isActive" => true
    }
    update = %{
      "$push" => %{
        "feePaidDetails" => changeset
      }
    }
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end






  # # this is to add fee paid details to each student
  # def addFeePaidDetailsForStudent123(changeset, groupObjectId, teamObjectId, studentDbObjectId) do
  #   #IO.puts "#{changeset}"
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "studentDbId" => studentDbObjectId,
  #     "isActive" => true
  #   }
  #   updateDoc = %{
  #     "totalFee" => changeset.totalFee,
  #     "paidDates" => changeset.paidDates,
  #     "totalAmountPaid" => changeset.totalAmountPaid,
  #     "totalBalanceAmount" => changeset.totalBalanceAmount
  #   }
  #   # check request doc (changeset) has dueDates
  #   if Map.has_key?(changeset, :dueDates) do
  #     updateDoc = Map.put_new(updateDoc, "dueDates", changeset.dueDates)
  #   else
  #     updateDoc = Map.put_new(updateDoc, "dueDates", [])
  #   end
  #   #check request doc has feeDetails
  #   if Map.has_key?(changeset, :feeDetails) do
  #     updateDoc = Map.put_new(updateDoc, "feeDetails", changeset.feeDetails)
  #   end
  #   update = %{"$set" => updateDoc}
  #   #IO.puts "#{update}"
  #   Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  # end



  def getStudentFeeStatusList(groupObjectId, status) do
    filter = %{
      "groupId" => groupObjectId,
      "feePaidDetails.status" => status,
      "isActive" => true
    }
    projection = %{"_id" => 0, "dueDates" => 1, "totalFee" => 1, "userId" => 1, "studentDbId" => 1, "feePaidDetails" => 1, "groupId" => 1, "teamId" => 1,
                  "paymentId" => 1, "totalAmountPaid" => 1, "totalBalance" => 1, "paidUserId" => 1, "paidAtTime" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => projection}, %{"$sort" => %{"feePaidDetails.paymentId" => 1}}, %{"$limit" => 100}]
    Mongo.aggregate(@conn, @view_school_fee_paid_details, pipeline)
  end


  def getStudentFeeStatusListBasedOnTeam(groupObjectId, teamObjectId, status) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "feePaidDetails.status" => status,
      "isActive" => true
    }
    projection = %{"_id" => 0, "dueDates" => 1, "totalFee" => 1, "userId" => 1, "studentDbId" => 1, "feePaidDetails" => 1, "groupId" => 1, "teamId" => 1,
                  "paymentId" => 1, "totalAmountPaid" => 1, "totalBalance" => 1, "paidUserId" => 1, "paidAtTime" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => projection}, %{"$sort" => %{"feePaidDetails.paymentId" => 1}}, %{"$limit" => 100}]
    Mongo.aggregate(@conn, @view_school_fee_paid_details, pipeline)
  end


  def checkThisPaymentIsAlreadyApproved(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id,
      "feePaidDetails.status" => "approved"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_school_fee_paid_details, filter, [projection: project])
  end


  def getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id
    }
    pipeline = [%{"$match" => filter}]
    Mongo.aggregate(@conn, @view_school_fee_paid_details, pipeline)
    |> Enum.to_list
    |> hd
  end



  def dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, dueDate, status) do
    #update status "completed" for dueDatesCompleted
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.date" => dueDate
    }
    update = if status == "completed" do
      %{"$set" => %{"dueDates.$.status" => "completed"}}
    else
      %{"$unset" => %{"dueDates.$.status" => "completed"}}
    end
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end



  def approveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance, loginUserId, approverName) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id
    }
    #update changeset
    updateChangeset = %{"$set" =>  %{
      "totalAmountPaid" => totalAmountPaid,
      "totalBalance" => totalBalance,
      "feePaidDetails.$.status" => "approved",
      "feePaidDetails.$.approvedUserId" => encode_object_id(loginUserId),
      "feePaidDetails.$.approvedTime" => bson_time(),
      "feePaidDetails.$.approverName" => approverName,
    }}
    Mongo.update_one(@conn, @school_fee_db_col, filter, updateChangeset)
  end



  def holdFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id
    }
    #update changeset
    updateChangeset = %{"$set" =>  %{
      "feePaidDetails.$.status" => "onHold"
    }}
    Mongo.update_one(@conn, @school_fee_db_col, filter, updateChangeset)
  end


  def notApproveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id
    }
    #update changeset
    updateChangeset = %{"$set" =>  %{
      "totalAmountPaid" => totalAmountPaid,
      "totalBalance" => totalBalance,
      "feePaidDetails.$.status" => "notApproved"
    }}
    Mongo.update_one(@conn, @school_fee_db_col, filter, updateChangeset)
  end


  def checkThisPaymentIsAlreadyNotApproved(groupObjectId, teamObjectId, userObjectId, payment_id) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "feePaidDetails.paymentId" => payment_id,
      "feePaidDetails.status" => "notApproved"
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_school_fee_paid_details, filter, [projection: project])
  end



  def addCompletedOrNotStatusForFeeDueDates(groupObjectId, teamObjectId, userObjectId, params) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "dueDates.date" => params["dueDate"],
      "isActive" => true
    }
    update = if params["status"] == "completed" do
      #update completed status
      %{
        "$set" => %{
          "dueDates.$.status" => "completed"
        }
      }
    else
      #pull back / unset completed status
      %{
        "$unset" => %{
          "dueDates.$.status" => "completed"
        }
      }
    end
    Mongo.update_one(@conn, @school_fee_db_col, filter, update)
  end


  def addDayPeriodForTimeTable(objectId, changeset, groupObjectId, teamObjectId) do
    changeset = changeset
                |> Map.put_new(:_id, objectId)
                |> Map.put_new(:groupId, groupObjectId)
                |> Map.put_new(:teamId, teamObjectId)
    Mongo.insert_one(@conn, @team_year_timetable_col, changeset)
  end



  def checkAlreadyDayPeriodAdded(changeset, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
      "day" => changeset.day,
      "period" => changeset.period,
      # "startTime" => changeset.startTime,
      # "endTime" => changeset.startTime
    }
    # if Map.has_key?(changeset, :startTime) do
    #   filter = Map.put(filter, "startTime", changeset.startTime)
    # end
    # if Map.has_key?(changeset, :endTime) do
    #   filter = Map.put(filter, "endTime", changeset.endTime)
    # end
    Enum.to_list(Mongo.find(@conn, @team_year_timetable_col, filter))
  end



  def updateSubjectStaffToYearTimeTable(subjectStaffObjectId, staffObjectId, changeset, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
      "day" => changeset.day,
      "period" => changeset.period,
      # "startTime" => changeset.startTime,
      # "endTime" => changeset.startTime
    }
    updateMap = %{"subjectWithStaffId" => subjectStaffObjectId, "staffId" => staffObjectId}
    updateMap = if Map.has_key?(changeset, :startTime) do
      Map.put(updateMap, "startTime", changeset.startTime)
    else
      updateMap
    end
    updateMap = if Map.has_key?(changeset, :endTime) do
      Map.put(updateMap, "endTime", changeset.endTime)
    else
      updateMap
    end
    update = %{"$set" => updateMap}
    Mongo.update_one(@conn, @team_year_timetable_col, filter, update)
  end


  # def getStaffDetailsById(groupObjectId, teamObjectId, staffId) do
  #   #IO.puts "#{staffId}"
  #   staffObjectId = decode_object_id(staffId)
  #   filter = %{
  #     "_id" => staffObjectId,
  #     "groupId" => groupObjectId
  #   }
  #   project = %{"_id" => 0, "name" => 1}
  #   hd(Enum.to_list(Mongo.find(@conn, @staff_db_col, filter, [projection: project])))
  # end


  def getStaffDetailsById(groupObjectId, staffId) do
    #IO.puts "#{staffId}"
    staffUserObjectId = decode_object_id(staffId)
    filter = %{
      #"_id" => staffObjectId,
      "groupId" => groupObjectId,
      "userId" => staffUserObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "name" => 1}
    hd(Enum.to_list(Mongo.find(@conn, @staff_db_col, filter, [projection: project, limit: 1])))
  end


  def getStaffNameByDb(groupObjectId, staffUserObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => staffUserObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "name" => 1}
    Mongo.find_one(@conn, @staff_db_col, filter, [projection: project])
  end



  def removeStaffFromSubject(groupObjectId, teamObjectId, subjectObjectId, staffId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId
    }
    update = %{"$pull" => %{"staffId" => staffId}}
    Mongo.update_one(@conn, @subject_staff_db_col, filter, update)
  end


  def removeCompleteSubjectStaff(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "_id" => subjectObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId
    }
    Mongo.delete_one(@conn, @subject_staff_db_col, filter)
  end



  def getAllSubjectListToAddTimeTable(groupObjectId, teamObjectId) do
    getSubjectsWithStaff(groupObjectId, teamObjectId)
  end


  #to check staff already added to day, period
  def findSubjectWithStaffById(changeset, _subjectWithStaffId, staffObjectId, groupObjectId, _teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "staffId" => staffObjectId,
      "day" => changeset.day,
      "period" => changeset.period,
      #"subjectWithStaffId" => subjectWithStaffId,
      #"teamId" => teamObjectId
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_year_timetable_col, filter, [projection: project])
  end



  def getSubjectSessionCountForTimeTable(groupObjectId, teamObjectId, subjectStaffId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectWithStaffId" => subjectStaffId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    #IO.puts "#{filter}"
    Mongo.count(@conn, @team_year_timetable_col, filter, [projection: project])
  end



  def getStaffSessionCountForTimeTable(groupObjectId, staffObjectId, day) do
    filter = %{
      "groupId" => groupObjectId,
      "staffId" => staffObjectId,
      "day" => day,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_year_timetable_col, filter, [projection: project])
  end



  def getYearTimeTableByDays(groupObjectId, teamObjectId, day) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "day" => day,
      "staffId" => %{"$exists" => true},
      "isActive" => true
    }
    # project = %{"day" => 1, "period" => 1, "startTime" => 1, "endTime" => 1, "staffDetails.name" => 1, "subjectStaffDetails.subjectName" => 1, "_id" => 0}
    # pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"day" => 1}}]
    # Enum.to_list(Mongo.aggregate(@conn, @view_team_year_time_table_col, pipeline))
    project = %{"day" => 1, "period" => 1, "startTime" => 1, "endTime" => 1, "staffId" => 1, "subjectWithStaffId" => 1, "_id" => 0}
    Mongo.find(@conn, @team_year_timetable_col, filter, [projection: project])
  end



  def getYearTimeTable(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "staffId" => %{"$exists" => true},
      "isActive" => true
    }
    # project = %{"day" => 1, "period" => 1, "startTime" => 1, "endTime" => 1, "staffDetails.name" => 1, "subjectStaffDetails.subjectName" => 1, "_id" => 0}
    # pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"day" => 1}}]
    # Enum.to_list(Mongo.aggregate(@conn, @view_team_year_time_table_col, pipeline))
    project = %{"day" => 1, "period" => 1, "startTime" => 1, "endTime" => 1, "staffId" => 1, "subjectWithStaffId" => 1, "_id" => 0}
    Mongo.find(@conn, @team_year_timetable_col, filter, [projection: project])
  end


  def removeYearTimeTable(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    Mongo.delete_many(@conn, @team_year_timetable_col,filter)
  end


  def removeYearTimeTableByDays(groupObjectId, teamObjectId, day) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "day" => day,
      "isActive" => true
    }
    Mongo.delete_many(@conn, @team_year_timetable_col,filter)
  end

  #def getSubjectListToAddTimeTable(changeset, groupObjectId, teamObjectId) do
  #  IO.puts "#{changeset.day}"
  #  filter = %{
  #    "groupId" => groupObjectId,
  #    "teamId" => teamObjectId,
  #    "day" => changeset.day,
  #    "period" => changeset.period,
  #    "subjectWithStaffId" =>
  #  }
  #end


  def getTeamTimeTable(teamIdList, groupObjectId, loginUserId) do
    #update gallery last seen time in group_team_members
    filterUpdate = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    update = %{ "$set" => %{ "timeTableLastSeen" => bson_time() } }
    Mongo.update_one(@conn, @group_team_members_col, filterUpdate, update)
    #get time table
    filter = %{ "groupId" => groupObjectId, "teamId" => %{ "$in" => teamIdList }, "isActive" => true  }
    pipeline = [%{ "$match" => filter }, %{ "$sort" => %{ "_id" => -1 } }]
    Mongo.aggregate(@conn, @view_team_time_table_col, pipeline)
  end


  def getTimeTableUnseenCount(loginUserId, groupObjectId) do
    #get teamId's list for login user
    filter = %{ "groupId" => groupObjectId, "userId" => loginUserId, "isActive" => true }
    project = %{ "_id" => 0, "teams.teamId" => 1 }
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    cursor = Mongo.aggregate(@conn, @view_team_col, pipeline)
    teamIdList = Enum.reduce(cursor, [], fn k, acc ->
      acc ++ [k["teams"]["teamId"]]
    end)
    #get time table last seen time for user
    # filter1 = %{"groupId" => groupObjectId, "userId" => loginUserId}
    projection = %{ "_id" => 0, "timeTableLastSeen" => 1 }
    lastSeenTime = hd(Enum.to_list(Mongo.find(@conn, @group_team_members_col, filter, [projection: projection])))
    #get timetable count greater the last seen count
    filterPost = %{
      "groupId" => groupObjectId,
      "insertedAt" => %{ "$gt" => lastSeenTime["timeTableLastSeen"] },
      "teamId" => %{ "$in" => teamIdList },
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @team_time_table_col, filterPost, [projection: project])
  end


  def getTeamTimeTableById(groupObjectId, timetableObjectId) do
    filter = %{ "_id" => timetableObjectId, "groupId" => groupObjectId, "isActive" => true }
    hd(Enum.to_list(Mongo.find(@conn, @team_time_table_col, filter)))
  end


  def deleteTimeTable(groupObjectId, timetableObjectId) do
    filter = %{ "_id" => timetableObjectId, "groupId" => groupObjectId, "isActive" => true }
    update = %{ "$set" => %{ "isActive" => false } }
    Mongo.update_one(@conn, @team_time_table_col, filter, update)
  end




  def getTeacherClassTeamsList(loginUserId, groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUserId,
      "isActive" => true,
      "teamDetails.class" => true,
      "teams.allowedToAddPost" => true
    }
    project = %{"_id" => 0, "teamDetails" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_team_col, pipeline)
  end



  def addAssignment(loginUserId, changeset, groupObjectId, teamObjectId, subjectObjectId) do
    changeset = changeset
                |> Map.put_new(:createdById, loginUserId)
                |> Map.put_new(:groupId, groupObjectId)
                |> Map.put_new(:teamId, teamObjectId)
                |> Map.put_new(:subjectId, subjectObjectId)
                |> Map.put_new(:submittedStudents, [])
    #IO.puts "#{changeset}"
    Mongo.insert_one(@conn, @school_assignment_col, changeset)
  end


  def addTestExam(loginUserId, changeset, groupObjectId, teamObjectId, subjectObjectId) do
    changeset = changeset
                |> Map.put_new(:createdById, loginUserId)
                |> Map.put_new(:groupId, groupObjectId)
                |> Map.put_new(:teamId, teamObjectId)
                |> Map.put_new(:subjectId, subjectObjectId)
                |> Map.put_new(:submittedStudents, [])
    #IO.puts "#{changeset}"
    Mongo.insert_one(@conn, @school_testexam_col, changeset)
  end


  def getAssignments(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    project = %{"submittedStudents" => 0, "updatedAt" => 0}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{_id: -1}}]
    Mongo.aggregate(@conn, @view_school_assignment_col, pipeline)
    |>Enum.to_list
  end


  def getTestExam(groupObjectId, teamObjectId, subjectObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    project = %{"submittedStudents" => 0, "updatedAt" => 0}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{_id: -1}}]
    Mongo.aggregate(@conn, @view_school_testexam_col, pipeline)
    |>Enum.to_list
  end


  def deleteAssignment(groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId) do
    filter = %{
      "_id" => assignmentObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"isActive" => false}}
    Mongo.update_one(@conn, @school_assignment_col, filter, update)
  end


  def deleteTestExam(groupObjectId, teamObjectId, subjectObjectId, testExamObjectId) do
    filter = %{
      "_id" => testExamObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    update = %{"$set" => %{"isActive" => false}}
    Mongo.update_one(@conn, @school_testexam_col, filter, update)
  end


  def studentSubmitAssignment(loginUserId, changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId) do
    #IO.puts "#{changeset}"
    changeset = changeset
                |> Map.put_new(:submittedById, loginUserId)
                |> Map.put_new(:assignmentVerified, false)
                |> Map.put_new(:assignmentReassigned, false)
                |> Map.put_new(:studentAssignmentId, new_object_id())
    filter = %{
      "_id" => assignmentObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    update = %{"$push" => %{"submittedStudents" => changeset}}
    Mongo.update_one(@conn, @school_assignment_col, filter, update)
  end


  def studentSubmitTestExam(loginUserId, changeset, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    #IO.puts "#{changeset}"
    changeset = changeset
                |> Map.put_new(:submittedById, loginUserId)
                |> Map.put_new(:testexamVerified, false)
                #|> Map.put_new(:assignmentReassigned, false)
                |> Map.put_new(:studentTestExamId, new_object_id())
    filter = %{
      "_id" => testexamObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    update = %{"$push" => %{"submittedStudents" => changeset}}
    Mongo.update_one(@conn, @school_testexam_col, filter, update)
  end



  def checkAssignmentCreatedByLoginUser(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId) do
    filter = %{
      "_id" => assignmentObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "createdById" => loginUserId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_assignment_col, filter, [projection: project])
  end


  def checkTestExamCreatedByLoginUser(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId) do
    filter = %{
      "_id" => testexamObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "createdById" => loginUserId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_testexam_col, filter, [projection: project])
  end


  def checkTestexamCreatedByLoginUser(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testExamObjectId) do
    filter = %{
      "_id" => testExamObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "createdById" => loginUserId,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @school_testexam_col, filter, [projection: project])
  end



  def getNotVerifiedAssignmentList(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.assignmentVerified" => false
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_assignment_col, pipeline)
    |> Enum.to_list
  end


  def getNotVerifiedTestExamList(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.testexamVerified" => false
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_testexam_col, pipeline)
    |> Enum.to_list
  end



  def getVerifiedAssignmentList(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.assignmentVerified" => true
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_assignment_col, pipeline)
    |> Enum.to_list
  end


  def getVerifiedTestExamList(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.testexamVerified" => true
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_testexam_col, pipeline)
    |> Enum.to_list
  end



  def getStudentDbDetailById(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"attendance" => 0}
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
    #|> Enum.to_list
    #|> hd
  end



  def verifyStudentSubmittedAssignment(changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId, studentAssignmentObjectId, verified) do
    filter = %{
      "_id" => assignmentObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.studentAssignmentId" => studentAssignmentObjectId
    }
    update = if verified == "true" do
      updateDoc = %{
        "submittedStudents.$.assignmentVerified" => true,
        "submittedStudents.$.verifiedAt" => changeset.insertedAt,
      }
      updateDoc = if Map.has_key?(changeset, :text) do
        Map.put_new(updateDoc, "submittedStudents.$.verifiedComment", changeset.text)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileName) do
        Map.put_new(updateDoc, "submittedStudents.$.fileName", changeset.fileName)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileType) do
        Map.put_new(updateDoc, "submittedStudents.$.fileType", changeset.fileType)
      end
      %{"$set" => updateDoc}
    else
      %{"$set" =>
        %{
          "submittedStudents.$.assignmentVerified" => false,
          "submittedStudents.$.verifiedComment" => "",
          "submittedStudents.$.verifiedAt" => ""
        }
      }
    end
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @school_assignment_col, filter, update)
  end



  def verifyStudentSubmittedTestExam(changeset, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId, studentTestExamObjectId, verified) do
    filter = %{
      "_id" => testexamObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.studentTestExamId" => studentTestExamObjectId
    }
    #IO.puts "#{filter}"
    update = if verified == "true" do
      updateDoc = %{
        "submittedStudents.$.testexamVerified" => true,
        "submittedStudents.$.verifiedAt" => changeset.insertedAt,
      }
      updateDoc = if Map.has_key?(changeset, :text) do
        Map.put_new(updateDoc, "submittedStudents.$.verifiedComment", changeset.text)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileName) do
        Map.put_new(updateDoc, "submittedStudents.$.fileName", changeset.fileName)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileType) do
        Map.put_new(updateDoc, "submittedStudents.$.fileType", changeset.fileType)
      else
        updateDoc
      end
      %{"$set" => updateDoc}
    else
      %{"$set" =>
        %{
          "submittedStudents.$.testexamVerified" => false,
          "submittedStudents.$.verifiedComment" => "",
          "submittedStudents.$.verifiedAt" => ""
        }
      }
    end
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @school_testexam_col, filter, update)
  end



  def reassignStudentSubmittedAssignment(changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId, studentAssignmentObjectId, reassigned) do
    filter = %{
      "_id" => assignmentObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.studentAssignmentId" => studentAssignmentObjectId
    }
    update = if reassigned == "true" do
      updateDoc = %{
        "submittedStudents.$.assignmentReassigned" => true,
        "submittedStudents.$.reassignedAt" => changeset.insertedAt,
      }
      updateDoc = if Map.has_key?(changeset, :text) do
        Map.put_new(updateDoc, "submittedStudents.$.reassignComment", changeset.text)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileName) do
        Map.put_new(updateDoc, "submittedStudents.$.fileName", changeset.fileName)
      else
        updateDoc
      end
      updateDoc = if Map.has_key?(changeset, :fileType) do
        Map.put_new(updateDoc, "submittedStudents.$.fileType", changeset.fileType)
      else
        updateDoc
      end
      %{"$set" => updateDoc}
    else
      %{"$set" =>
        %{
          "submittedStudents.$.assignmentReassigned" => false,
          "submittedStudents.$.reassignComment" => "",
          "submittedStudents.$.reassignedAt" => ""
        }
      }
    end
    Mongo.update_one(@conn, @school_assignment_col, filter, update)
  end


  def getAssignmentSubmittedStudentsId(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "submittedStudents.submittedById" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_school_student_assignment_col, pipeline)
    |>Enum.to_list
  end


  def getTestExamSubmittedStudentsId(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "submittedStudents.submittedById" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_school_student_testexam_col, pipeline)
    |>Enum.to_list
  end



  def getAssignmentNotSubmittedStudentsList(groupObjectId, teamObjectId, studentsSubmittedIds) do
    #first get list of stubmitted student
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$nin" => studentsSubmittedIds},
      "isActive" => true
    }
    #IO.puts"#{filter}"
    project = %{"_id" => 1, "name" => 1, "rollNumber" => 1, "image" => 1, "userId" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}]
    #IO.puts "#{pipeline}"
    Mongo.aggregate(@conn, @student_db_col, pipeline)
    |>Enum.to_list
  end



  def getLoginStudentAssignmentList(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.submittedById" => loginUserId
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_assignment_col, pipeline)
    |> Enum.to_list
  end


  def getLoginStudentTestExamList(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.submittedById" => loginUserId
    }
    project = %{"_id" => 0, "submittedStudents" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"submittedStudents.submittedById" => 1}}]
    Mongo.aggregate(@conn, @view_school_student_testexam_col, pipeline)
    |> Enum.to_list
  end



  def checkThisAssignmentIsNotReassignedOrVerified(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId, studentAssignmentObjectId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.submittedById" => loginUserId,
      "submittedStudents.studentAssignmentId" => studentAssignmentObjectId,
      "$or" => [%{"submittedStudents.assignmentVerified" => true},
                %{"submittedStudents.assignmentReassigned" => true}]
    }
    project = %{"_id" => 1}
    #IO.puts "#{filter}"
    Mongo.count(@conn, @view_school_student_assignment_col, filter, [projection: project])
  end


  def checkThisTestExamIsNotVerified(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId, studentTestExamObjectId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      "submittedStudents.submittedById" => loginUserId,
      "submittedStudents.studentTestExamId" => studentTestExamObjectId,
      "submittedStudents.testexamVerified" => true
    }
    project = %{"_id" => 1}
    #IO.puts "#{filter}"
    Mongo.count(@conn, @view_school_student_testexam_col, filter, [projection: project])
  end



  def deleteStudentSubmittedAssignment(_loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId, studentAssignmentObjectId) do
    filter = %{
      "_id" => assignmentObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId,
      #"submittedStudents.submittedById" => loginUserId,
      #"submittedStudents.studentAssignmentId" => studentAssignmentObjectId
    }
    update = %{"$pull" => %{"submittedStudents" => %{ "studentAssignmentId" => studentAssignmentObjectId }}}
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @school_assignment_col, filter, update)
  end


  def deleteStudentSubmittedTestExam(_loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId, studentTestExamObjectId) do
    filter = %{
      "_id" => testexamObjecttId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "subjectId" => subjectObjectId
    }
    update = %{"$pull" => %{"submittedStudents" => %{ "studentTestExamId" => studentTestExamObjectId }}}
    #IO.puts "#{update}"
    Mongo.update_one(@conn, @school_testexam_col, filter, update)
  end



  def findTeamPostIsLiked(loginUserId, groupObjectId, teamObjectId, postObjectId) do
    filter = %{ "_id" => postObjectId, "groupId" => groupObjectId, "teamId" => teamObjectId, "type" => "teamPost", "likedUsers.userId" => loginUserId }
    project = %{"_id" => 1}
    Mongo.count(@conn, @post_col, filter, [projection: project])
  end



  def getPostReadUsersList(loginUserId, groupObjectId, teamObjectId, post) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => %{ "$nin" => [loginUserId] },
      "teams.teamId" => teamObjectId,
      "teams.teamPostLastSeen" => %{ "$gt" => post["insertedAt"] }
    }
    projection = %{ "_id" => 0, "userId" => 1, "name" => "$$CURRENT.userDetails.name",
                    "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image", "postSeenTime" => "$$CURRENT.teams.teamPostLastSeen" }
    pipeline = [%{"$match" => filter}, %{"$project" => projection}, %{ "$sort" => %{ "postSeenTime" => -1 } }]
    Mongo.aggregate(@conn, @view_team_col, pipeline)
  end


  def getPostUnreadUsersList(loginUserId, groupObjectId, teamObjectId, post) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => %{ "$nin" => [loginUserId] },
      "teams.teamId" => teamObjectId,
      "teams.teamPostLastSeen" => %{ "$lt" => post["insertedAt"] },
    }
    projection = %{ "_id" => 0, "userId" => 1, "name" => "$$CURRENT.userDetails.name", "phone" => "$$CURRENT.userDetails.phone", "image" => "$$CURRENT.userDetails.image" }
    pipeline = [%{"$match" => filter}, %{"$project" => projection}, %{ "$sort" => %{ "name" => 1 } } ]
    Mongo.aggregate(@conn, @view_team_col, pipeline)
  end



  def getLeaveRequestForm(loginUserId, groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => loginUserId,
    }
    projection = %{ "_id" => 0, "name" => 1, "userId" => 1 }
    pipeline = [%{"$match" => filter}, %{"$project" => projection}]
    Mongo.aggregate(@conn, @view_student_db_col, pipeline)
  end



  def addMarksCard(groupObjectId, teamObjectId, userObjectId, _rollNumber, changeset) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    update = %{ "$push" => %{ "marksCard" => %{ "title" => changeset.title, "fileType" => changeset.fileType,
                "fileName" => changeset.fileName, "insertedAt" => bson_time(), "id" => new_object_id()} } }
    Mongo.update_one(@conn, @student_db_col, filter, update)
  end



  def getMarksCard(groupObjectId, teamObjectId, userObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    project = %{ "_id" => 0, "marksCard" => 1 }
    #marksCardList = hd(Enum.to_list(Mongo.find(@conn, @student_db_col, filter, [projection: project])))
    marksCardList = Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
    marksCardList["marksCard"]
  end


  def deleteMarksCard(groupObjectId, teamObjectId, userObjectId, marksCardObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    update = %{ "$pull" => %{ "marksCard" => %{ "id" => marksCardObjectId } } }
    Mongo.update_one(@conn, @student_db_col, filter, update)
  end


  def createMarksCard(changeset, groupObjectId, teamObjectId, totalMarks) do
    changesetNew = changeset
                   |> update_map_with_key_value(:groupId, groupObjectId)
                   |> update_map_with_key_value(:teamId, teamObjectId)
                   |> update_map_with_key_value(:isActive, true)
                   |> update_map_with_key_value(:maxMarksTotal, totalMarks["maxMarks"])
                   |> update_map_with_key_value(:minMarksTotal, totalMarks["minMarks"])
    Mongo.insert_one(@conn, @marks_card_col, changesetNew)
  end


  def getMarksCardList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    Mongo.find(@conn, @marks_card_col, filter, [sort: %{ "_id" => -1 }])
  end

  def getMarksCardListWeb(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    Mongo.find(@conn, @marks_card_col, filter)
  end



  def checkMarksAlreadyUploadedForThisStudent(userObjectId, _rollNo, groupObjectId, teamObjectId, marksCardId) do
    filter = %{
      ##"rollNumber" => rollNo,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "marksCard.markscardId" => marksCardId
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @student_db_col, filter, [projection: project])
  end



  def getMarksCardSubjects(groupObjectId, teamObjectId, markscardObjectId) do
    filter = %{
      "_id" => markscardObjectId,
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{ "_id" => 0, "subjects" => 1, "duration" => 1 }
    hd(Enum.to_list(Mongo.find(@conn, @marks_card_col, filter, [projection: project])))
  end



  def addMarksToStudent(changeset, groupObjectId, teamObjectId, marksCardObjectId, studentObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    #get total marks
    totalMarks = Enum.reduce(hd(changeset.subjectMarks), [], fn k, acc ->
      {_subject, marks} = k
      if is_integer(marks) do
        acc ++ [marks]
      else
        acc ++ [0]
      end
    end)
    changesetSet = changeset
                   |> update_map_with_key_value(:markscardId, marksCardObjectId)
                   |> update_map_with_key_value(:totalMarks, Enum.sum(totalMarks))
    update = %{ "$push" => %{ "marksCard" =>  changesetSet  } }
    Mongo.update_one(@conn, @student_db_col, filter, update)
  end



  def updateMarksToStudent(changeset, groupObjectId, teamObjectId, marksCardObjectId, studentObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentObjectId,
      "isActive" => true
      ##"rollNumber" => rollNumber
    }
    #1st remove already uploaded
    removeUploaded = %{ "$pull" => %{ "marksCard" => %{ "markscardId" => marksCardObjectId } } }
    Mongo.update_many(@conn, @student_db_col, filter, removeUploaded)
    #get total marks
    totalMarks = Enum.reduce(hd(changeset.subjectMarks), [], fn k, acc ->
      {_subject, marks} = k
      if is_integer(marks) do
        acc ++ [marks]
      else
        acc ++ [0]
      end
    end)
    ###now add new updated data
    changesetSet = changeset
                   |> update_map_with_key_value(:markscardId, marksCardObjectId)
                   |> update_map_with_key_value(:totalMarks, Enum.sum(totalMarks))
    update = %{ "$push" => %{ "marksCard" =>  changesetSet  } }
    Mongo.update_one(@conn, @student_db_col, filter, update)
  end



  def getMarksCardForStudent(groupObjectId, teamObjectId, studentObjectId, marksCardObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentObjectId,
      ##"rollNumber" => rollNumber,
      "marksCard.markscardId" => marksCardObjectId
    }
    #IO.puts "#{filter}"
    project = %{ "marksCard.$" => 1, "_id" => 0  }
    #markscardList = Enum.to_list(Mongo.find(@conn, @student_db_col, filter, [projection: project]))
    markscardList = Enum.to_list(Mongo.find_one(@conn, @student_db_col, filter, [projection: project]))
    if length(markscardList) > 0 do
      hd(markscardList)
    end
  end



  def findMaxMarksForSubjects(markscardObjectId) do
    filter = %{ "_id" => markscardObjectId }
  #  IO.puts "#{filter}"
    project = %{ "_id" => 0, "subjects" => 1 }
    hd(Enum.to_list(Mongo.find(@conn, @marks_card_col, filter, [projection: project])))
  end



  def removeUploadedMarksForStudent(groupObjectId, teamObjectId, studentObjectId, marksCardObjectId, _rollNumber) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentObjectId,
      ##"rollNumber" => rollNumber,
      "marksCard.markscardId" => marksCardObjectId
    }
    # project = %{ "marksCard.$" => 1, "_id" => 0  }
    update = %{ "$pull" => %{ "marksCard" => %{ "markscardId" => marksCardObjectId } } }
    Mongo.update_one(@conn, @student_db_col, filter, update)
  end



  def checkThisMonthAttendanceReportAlreadyExistForStudent(groupObjectId, teamObjectId, userObjectId, month, year) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "month" => month,
      "year" => year,
      "isActive" => true
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @offline_class_attendance_col, filter, [projection: project])
  end


  def addThismonthOfflineAttendanceForStudent(groupObjectId, teamObjectId, userObjectId, month, year) do
    insertDoc = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "month" => month,
      "year" => year,
      "isActive" => true,
      #"attendance" => []
    }
    Mongo.insert_one(@conn, @offline_class_attendance_col, insertDoc)
  end


  def checkAttendanceTakenForToday(groupObjectId, teamObjectId, reverseDateString, month, year) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "year" => year,
      "month" => month,
      "isActive" => true,
      "offlineAttendance.dateString" => %{
        "$eq" => Integer.to_string(reverseDateString)
      }
    }
    fields = %{
      "offlineAttendance" => %{
        "$filter" => %{
          "input" => "$offlineAttendance",
          "cond" => %{
            "$eq" => [
              "$$this.dateString", Integer.to_string(reverseDateString)
            ]
          }
        }
      }
    }
    project = %{
      "_id" => 0,
      "offlineAttendance" => 1,
    }
    pipeline = [%{"$match" => filter}, %{"$addFields" => fields}, %{"$project" => project}, %{"$limit" => 1}]
    Mongo.aggregate(@conn, @offline_class_attendance_col, pipeline)
    |>Enum.to_list
  end



  def takeAttendanceAndReportParentsAlongWithSubject(groupObjectId, teamObjectId, loginUser, subjectObjectId, subjectName, absentStudentIds,
                                                     leaveListIds, dateTimeMap, currentTime) do
    #check in staff database for staff name
    nameExists = staffName(groupObjectId, loginUser)
    name = if nameExists do
      nameExists["name"]
    else
      loginUser["name"]
    end
    #convert UK timing to Indian time
    timeUK = NaiveDateTime.utc_now
    timeIndia = NaiveDateTime.add(timeUK, 19800)    # to IST +5:30hrs = 19800 seconds , Add 19800 sec to time1
    hourIndia = String.slice("0"<>""<>to_string(timeIndia.hour), -2, 2)
    minuteIndia = String.slice("0"<>""<>to_string(timeIndia.minute), -2, 2)
    day = String.slice("0"<>""<>to_string(dateTimeMap["day"]), -2, 2)
    month = String.slice("0"<>""<>to_string(dateTimeMap["month"]), -2, 2)
    attendanceId = encode_object_id(new_object_id())
    #update / push absent for absentees students selected
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => absentStudentIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
    #update / push present for present students
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$nin" => absentStudentIds ++ leaveListIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
    #update/ push leave Students
    filterLeave = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => leaveListIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
    pushAbsent = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "absent",
      ##"attendanceStatus" => "absent",
      "day" => dateTimeMap["day"],
      "subjectName" => subjectName,
      "attendanceId" => attendanceId,
      "subjectId" => encode_object_id(subjectObjectId),
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    pushPresent = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "present",
      ##"attendanceStatus" => "present",
      "day" => dateTimeMap["day"],
      "subjectName" => subjectName,
      "attendanceId" => attendanceId,
      "subjectId" => encode_object_id(subjectObjectId),
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    pushLeave = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "leave",
      "day" => dateTimeMap["day"],
      "subjectName" => subjectName,
      "attendanceId" => attendanceId,
      "subjectId" => encode_object_id(subjectObjectId),
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    updateAbsentStudents = %{"$push" => %{"offlineAttendance" => pushAbsent}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterAbsent, updateAbsentStudents)
    updatePresentStudents = %{"$push" => %{"offlineAttendance" => pushPresent}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterPresent, updatePresentStudents)
    updateLeaveStudents =  %{"$push" => %{"offlineAttendance" => pushLeave}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterLeave, updateLeaveStudents)
  end


  def checkLeaveForToday(groupObjectId, teamObjectId , userObjectId ,reverseDateString, year) do
    filter = %{
      "userId" => userObjectId,
      "teamId" => teamObjectId,
      "groupId" => groupObjectId,
      "year" => year,
      "isActive" => true,
      "leaveApplies.fromDateString" => %{
        "$lte" => reverseDateString
      },
      "leaveApplies.toDateString" => %{
        "$gte" => reverseDateString
      }
    }
    project = %{"_id" => 1}
    Mongo.count(@conn, @view_student_leave_apply_col, filter, [projection: project, sort: %{"leaveApplies.fromDateString" => -1}, limit: 1])
  end



  def takeAttendanceAndReportParentsWithoutSubject(groupObjectId, teamObjectId, loginUser, absentStudentIds, leaveListIds, dateTimeMap, currentTime) do
    #check in staff database for staff name
    nameExists = staffName(groupObjectId, loginUser)
    name = if nameExists do
      nameExists["name"]
    else
      loginUser["name"]
    end
    #convert UK timing to Indian time
    timeUK = NaiveDateTime.utc_now
    timeIndia = NaiveDateTime.add(timeUK, 19800)    # to IST +5:30hrs = 19800 seconds , Add 19800 sec to time1
    hourIndia = String.slice("0"<>""<>to_string(timeIndia.hour), -2, 2)
    minuteIndia = String.slice("0"<>""<>to_string(timeIndia.minute), -2, 2)
    day = String.slice("0"<>""<>to_string(dateTimeMap["day"]), -2, 2)
    month = String.slice("0"<>""<>to_string(dateTimeMap["month"]), -2, 2)
    attendanceId = encode_object_id(new_object_id())
    #update / push absent for absentees students selected
    filterAbsent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => absentStudentIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
    #update / push present for present students
    filterPresent = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$nin" => absentStudentIds ++ leaveListIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
     #update/ push leave Students
     filterLeave = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => leaveListIds},
      "month" => dateTimeMap["month"],
      "year" => dateTimeMap["year"],
      "isActive" => true
    }
    pushAbsent = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "absent",
      ##"attendanceStatus" => "absent",
      "day" => dateTimeMap["day"],
      "attendanceId" => attendanceId,
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    pushPresent = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "present",
      ##"attendanceStatus" => "present",
      "day" => dateTimeMap["day"],
      "attendanceId" => attendanceId,
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    pushLeave = %{
      "attendanceAt" => currentTime,
      "date" => day<>"-"<>month<>"-"<>to_string(dateTimeMap["year"]),
      "dateString" => to_string(dateTimeMap["year"])<>month<>day,
      "time" => hourIndia<>":"<>minuteIndia,
      "attendance" => "leave",
      "day" => dateTimeMap["day"],
      "attendanceId" => attendanceId,
      "teacherName" => name,
      "teacherId" => encode_object_id(loginUser["_id"])
    }
    updateAbsentStudents = %{"$push" => %{"offlineAttendance" => pushAbsent}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterAbsent, updateAbsentStudents)
    updatePresentStudents = %{"$push" => %{"offlineAttendance" => pushPresent}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterPresent, updatePresentStudents)
    updateLeaveStudents =  %{"$push" => %{"offlineAttendance" => pushLeave}}
    Mongo.update_many(@conn, @offline_class_attendance_col, filterLeave, updateLeaveStudents)
  end


  defp staffName(groupObjectId, loginUser) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => loginUser["_id"],
      "isActive" => true,
    }
    project = %{
      "name" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @staff_db_col, filter, [projection: project])
  end


  def getClassStudentDetailsByUserId(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "name" => 1, "rollNumber" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project, limit: 1])
    |> Enum.to_list
  end

  def getOfflineAttendanceReportByUserId(groupObjectId, teamObjectId, userObjectId, month, year) do
    {monthInteger, ""} = Integer.parse(month)
    {yearInteger, ""} = Integer.parse(year)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "month" => monthInteger,
      "year" => yearInteger,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1,
                "offlineAttendance.date" => 1, "offlineAttendance.day" => 1, "offlineAttendance.attendance" => 1}
    Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project, limit: 1])
    |>Enum.to_list
  end

  # def getOfflineAttendanceReport(groupObjectId, teamObjectId, month, year) do
  #   {monthInteger, ""} = Integer.parse(month)
  #   {yearInteger, ""} = Integer.parse(year)
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "month" => monthInteger,
  #     "year" => yearInteger,
  #     "isActive" => true
  #   }
  #   project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1,
  #               "offlineAttendance.date" => 1, "offlineAttendance.day" => 1, "offlineAttendance.attendance" => 1, "offlineAttendance.dateString" => 1}
  #   list = Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project])
  #   |>Enum.to_list
  # end


  def getClassStudentUserIds(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "name" => 1, "rollNumber" => 1, "image" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getClassStudentUserIdAndDetailsForMarkscard(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "image" => 1, "fatherName" => 1, "motherName" => 1, "name" => 1}
    Mongo.find(@conn, @student_db_col, filter, [projection: project])
    |> Enum.to_list
  end


  def getSelectedClassStudentUserIdAndDetailsForMarkscard(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "image" => 1, "fatherName" => 1, "motherName" => 1, "name" => 1}
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
  end


  def getStudentOfflineAttendanceReport(groupObjectId, teamObjectId, studentdUserIds, month, year) do
    {monthInteger, ""} = Integer.parse(month)
    {yearInteger, ""} = Integer.parse(year)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => studentdUserIds},
      "month" => monthInteger,
      "year" => yearInteger,
      "isActive" => true
    }
    project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1,
                "offlineAttendance.date" => 1, "offlineAttendance.day" => 1, "offlineAttendance.attendance" => 1, "offlineAttendance.dateString" => 1}
    Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project])
    |>Enum.to_list
  end


  def getStudentOfflineAttendanceTakenDaysInMonth(groupObjectId, teamObjectId, studentdUserIds, month, year) do
    {monthInteger, ""} = Integer.parse(month)
    {yearInteger, ""} = Integer.parse(year)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => studentdUserIds},
      "month" => monthInteger,
      "year" => yearInteger,
      "isActive" => true
    }
    project = %{"_id" => 0, "attendanceDay" => "$$CURRENT.offlineAttendance.day"}
    Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project])
    |>Enum.to_list
  end


  # def getStudentOfflineAttendanceReportOnDateWise123(groupObjectId, teamObjectId, studentdUserIds, month, year, startDate, endDate) do
  #   {monthInteger, ""} = Integer.parse(month)
  #   {yearInteger, ""} = Integer.parse(year)
  #   {startDateInteger, ""} = Integer.parse(startDate)
  #   {endDateInteger, ""} = Integer.parse(endDate)
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "userId" => %{"$in" => studentdUserIds},
  #     "month" => monthInteger,
  #     "year" => yearInteger,
  #     "offlineAttendance" => %{"$elemMatch" => %{"day" => %{"$gte" => startDateInteger, "$lte" => endDateInteger}}},
  #     "isActive" => true
  #   }
  #   project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1,
  #               "offlineAttendance.date" => 1, "offlineAttendance.day" => 1, "offlineAttendance.attendance" => 1}
  #   # project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1,
  #   #             "offlineAttendance.subjectName" => "$$current.offlineAttendance.teacherName", "offlineAttendance.date" => 1, "offlineAttendance.day" => 1,
  #   #             "offlineAttendance.attendance" => 1}
  #   Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project])
  #   |>Enum.to_list
  # end


  def getStudentOfflineAttendanceReportOnDateWise(groupObjectId, teamObjectId, studentdUserIds, month, year, startDate, endDate) do
    {monthInteger, ""} = Integer.parse(month)
    {yearInteger, ""} = Integer.parse(year)
    {startDateInteger, ""} = Integer.parse(startDate)
    {endDateInteger, ""} = Integer.parse(endDate)
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => %{"$in" => studentdUserIds},
      "month" => monthInteger,
      "year" => yearInteger,
      "isActive" => true,
      "$and" => [
        %{"offlineAttendance.day" => %{"$gte" => startDateInteger}},
        %{"offlineAttendance.day" => %{"$lte" => endDateInteger}}
      ]
    }
    fields = %{
        "offlineAttendance" => %{
          "$filter" => %{
            "input" => "$offlineAttendance",
            "cond" => %{
              "$and" => [ %{"$gte" => ["$$this.day", startDateInteger]}, %{"$lte" => ["$$this.day",endDateInteger]} ]
            }
          }
        }
      }
    project = %{
      "_id" => 0,
      "offlineAttendance" => 1,
      "userId" => 1,
    }
   pipeline = [%{"$match" => filter}, %{"$addFields" => fields}, %{"$project" => project}]
    Mongo.aggregate(@conn, @offline_class_attendance_col, pipeline)
    |>Enum.to_list
  end

  # User.aggregate([
  #   {$match:{_id: ObjectID("5feb7b1b5438fcda7401f306")}},
  #   { $project: {
  #       days: {
  #         $filter: {
  #           input: "$days", // le tableau à limiter
  #           as: "index", // un alias
  #           cond: {$and: [
  #             { $gte: [ "$$index.day", new Date("2020-12-29T00:00:00.000Z") ] },
  #             { $lte: [ "$$index.day", new Date("2020-12-31T00:00:00.000Z") ] }
  #           ]}
  #         }
  #       }
  #   }}
  # ])
  # .project({'days.day':1, 'days.data':1})


  # def getOfflineAttendanceReportOnDateWise(groupObjectId, teamObjectId, month, year, startDate, endDate) do
  #   {monthInteger, ""} = Integer.parse(month)
  #   {yearInteger, ""} = Integer.parse(year)
  #   {startDateInteger, ""} = Integer.parse(startDate)
  #   {endDateInteger, ""} = Integer.parse(endDate)
  #   filter = %{
  #     "groupId" => groupObjectId,
  #     "teamId" => teamObjectId,
  #     "month" => monthInteger,
  #     "year" => yearInteger,
  #     "offlineAttendance" => %{"$elemMatch" => %{"day" => %{"$gte" => startDateInteger, "$lte" => endDateInteger}}},
  #     "isActive" => true
  #   }
  #   project = %{"_id" => 0, "userId" => 1, "offlineAttendance.time" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1,
  #               "offlineAttendance.date" => 1, "offlineAttendance.day" => 1, "offlineAttendance.attendance" => 1}
  #   Mongo.find(@conn, @offline_class_attendance_col, filter, [projection: project])
  #   |>Enum.to_list
  # end


  def getLastFiveAttendanceForStudent(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true
    }
    project = %{"_id" => 0, "offlineAttendance.attendanceId" => 1, "offlineAttendance.attendance" => 1, "offlineAttendance.time" => 1,
                "offlineAttendance.date" => 1, "offlineAttendance.teacherId" => 1, "offlineAttendance.teacherName" => 1, "offlineAttendance.subjectName" => 1}
    pipeline = [%{"$match" => filter}, %{"$project" => project}, %{"$sort" => %{"offlineAttendance.attendanceId" => -1}}, %{"$limit" => 5}]
    # project = %{"_id" => 0, "recentFiveAttendance" => %{"$slice" => ["offlineAttendance", -5]}}
    # pipeline = [%{"$match" => filter}, %{"$project" => project}]
    Mongo.aggregate(@conn, @view_offline_class_attendance_col, pipeline)
    |> Enum.to_list
  end



  defp insertBusTrackDetail(groupObjectId, teamObjectId, loginUserId, latitude, longitude, currentTime) do
    insertMap = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => loginUserId,
      "latitude" => latitude,
      "longitude" => longitude,
      "insertedAt" => currentTime,
      "updatedAt" => currentTime,
    }
    Mongo.insert_one(@conn, @vehicle_track_col, insertMap)
  end


  def incrementSubBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalSubBoothDiscussion" => 1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end


  def incrementBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalBoothsDiscussion" => 1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end


  def decrementBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalBoothsDiscussion" => -1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end


  def decrementSubBoothDiscussionCount(groupObjectId) do
    filter = %{
      "_id" => groupObjectId,
      "isActive" => true,
    }
    update = %{
      "$inc" => %{
        "feederMap.totalSubBoothDiscussion" => -1,
      }
    }
    Mongo.update_one(@conn, @groups_col, filter, update)
  end


  def updateTeamPostEvent(groupObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "type" => "teamPost",
      "isActive" => true,
    }
    update = %{
      "$set" => %{
        "updatedAt" => bson_time()
      }
    }
    Mongo.update_one(@conn, @post_col, filter, update)
  end


  def checkUserStaff(groupObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 1,
    }
    Mongo.count(@conn, @staff_db_col, filter, [projection: project])
  end

  def checkUserStudent(groupObjectId, teamObjectId, userObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => userObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "languages" => 1,
    }
    Mongo.find_one(@conn, @student_db_col, filter, [projection: project])
  end


  def getSubjectList(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "subjectPriority" => 1,
      "_id" => 1,
    }
    Mongo.find(@conn, @subject_staff_db_col, filter, [projection: project])
    |> Enum.to_list()
  end

  def getSubjectListExams(groupObjectId, teamObjectId, offlineExamId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
      "testExamSchedules.offlineTestExamId" => offlineExamId
    }
    project = %{
      "testExamSchedules.subjectMarksDetails.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @school_offline_testexam_timetable_col, filter, [projection: project])
  end


  def getMarksCardList(groupObjectId, teamObjectId, offlineExamId, studentUserId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "userId" => studentUserId,
      "isActive" => true,
      "marksCardDetails.offlineTestExamId" => offlineExamId,
    }
    project = %{
      "marksCardDetails.subjectMarksDetails.$" => 1,
      "_id" => 0,
    }
    Mongo.find_one(@conn, @school_markscard_db_col, filter, [projection: project])
  end


  def getSectionLatest(groupObjectId, teamObjectId) do
    filter = %{
      "groupId" => groupObjectId,
      "teamId" => teamObjectId,
      "isActive" => true,
    }
    project = %{
      "_id" => 0,
      "testExamSchedules" => 1,
    }
    Mongo.find_one(@conn, @school_offline_testexam_timetable_col, filter, [projection: project])
  end
end
