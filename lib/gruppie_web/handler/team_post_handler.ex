defmodule GruppieWeb.Handler.TeamPostHandler do
  alias GruppieWeb.Post
  alias GruppieWeb.Repo.TeamPostRepo
  alias GruppieWeb.Repo.TeamRepo
  alias GruppieWeb.Repo.GroupRepo
  import GruppieWeb.Repo.RepoHelper
  import GruppieWeb.Handler.TimeNow


  def getTeamPostReadMore(groupObjectId, teamObjectId, post_id) do
    postObjectId = decode_object_id(post_id)
    TeamPostRepo.getTeamPostReadMore(groupObjectId, teamObjectId, postObjectId)
  end


  def add(changeset, conn, group_id, teamObjectId) do
    login_user = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    TeamPostRepo.add(changeset, login_user["_id"], groupObjectId, teamObjectId)
  end



  def updateJitsiTokenStartOrStop(loginUser, group, team, startOrStop, params) do
    #get new token to update
    # groupName = String.trim(group["name"], "-")
    # teamName = team["name"]
    if startOrStop == "start" do
      #create meeting ID manually to get student attendance for the same meeting joining students
      TeamPostRepo.updateJitsiTokenOnStart(loginUser["_id"], group["_id"], team["_id"], params)
      #add online attendance report
      #######*****TeamPostRepo.createOnlineClassAttendanceForTeam(loginUser["_id"], group["_id"], team["_id"], meetingOnLiveId = params)
    else
      #check body params containing meetingOnLiveId and subjectId
      if params["meetingOnLiveId"] && params["subjectId"] do
        #submit online_attendance after pressing end button along with subject
        # subjectObjectId = decode_object_id(params["subjectId"])
        meetingOnLiveId = decode_object_id(params["meetingOnLiveId"])
        #convert to ISO Date and get all parameters of date
        # currentTime = bson_time()
        # {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
        #time = DateTime.to_time(datetime)
        # dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
        #              "minute" => datetime.minute,"seconds" => datetime.second}
        ######*****TeamPostRepo.submitOnlineClassAttendanceForTeam(loginUser["_id"], group["_id"], team["_id"], subjectObjectId, meetingOnLiveId, dateTimeMap)
        TeamPostRepo.updateJitsiTokenOnStop(loginUser["_id"], group["_id"], team["_id"], meetingOnLiveId)
      else
        #IO.puts "#{"just stop live"}"
        TeamPostRepo.updateJitsiTokenOnStop(loginUser["_id"], group["_id"], team["_id"], "null")
      end
    end
  end


  def liveClassEnd(loginUserId, groupObjectId, teamObjectId, params) do
    #check body params containing meetingOnLiveId and subjectId
    if params["meetingOnLiveId"] && params["subjectId"] do
      #submit online_attendance after pressing end button along with subject
      subjectObjectId = decode_object_id(params["subjectId"])
      getSubjectName = TeamPostRepo.getSubjectNameForMeeting(groupObjectId, subjectObjectId)
      meetingSubjectName = getSubjectName["subjectName"]
      meetingOnLiveId = decode_object_id(params["meetingOnLiveId"])
      #convert to ISO Date and get all parameters of date
      currentTime = bson_time()
      {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
      #time = DateTime.to_time(datetime)
      dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                   "minute" => datetime.minute,"seconds" => datetime.second}
      TeamPostRepo.submitAttendanceForLiveClass(loginUserId, groupObjectId, teamObjectId, subjectObjectId, meetingOnLiveId, dateTimeMap, meetingSubjectName)
      TeamPostRepo.endLiveClassEvent(loginUserId, groupObjectId, teamObjectId)
    else
      #IO.puts "#{"just stop live"}"
      TeamPostRepo.endLiveClassEvent(loginUserId, groupObjectId, teamObjectId)
    end
  end



  def updateMeetingOnLiveIdOnStart(loginUser, groupObjectId, teamObjectId, meetingIdOnLive) do
    #first create attendance document for this meeting
    TeamPostRepo.addAttendanceDocumentForThiMeetingId(loginUser, groupObjectId, teamObjectId, meetingIdOnLive)
    #secondly create event for this meetingId
    #check this liveCalss event for this team is already exist
    {:ok, count} = GroupRepo.checkLiveClassEvent(groupObjectId, teamObjectId)
    if count == 0 do
      GroupRepo.addLiveClassEvent(loginUser, groupObjectId, teamObjectId, meetingIdOnLive)
    else
      #update time for the existing event
      GroupRepo.updateLiveClassEvent(loginUser, groupObjectId, teamObjectId, meetingIdOnLive)
    end
  end


  def addStudentOnlineAttendance(studentDetailFromDb, params) do
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    meetingOnLiveId = decode_object_id(params["meetingOnLiveId"])
    #get only required date from studentDb
    studentDetail = %{
      #"studentName" => studentDetailFromDb["name"],
      #"rollNumber" => studentDetailFromDb["rollNumber"],
      "userId" => studentDetailFromDb["userId"],
      "studentDbId" => studentDetailFromDb["_id"]
    }
    #find student is previously joined to same meeting and left
    TeamPostRepo.findStudentAlreadyJoinedMeeting(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId)
  end


  def addStudentLiveClassAttendance(studentDetailFromDb, params) do
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    meetingOnLiveId = decode_object_id(params["meetingOnLiveId"])
    #get only required data from studentDb
    studentDetail = %{
      "userId" => studentDetailFromDb["userId"],
      "studentDbId" => studentDetailFromDb["_id"]
    }
    #find student is previously joined to same meeting and left
    ##TeamPostRepo.addStudentLiveClassAttendance(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId)
    TeamPostRepo.findStudentAlreadyJoinedThisMeeting(studentDetail, groupObjectId, teamObjectId, meetingOnLiveId)
  end



  def pushOnlineAttendance(changeset, groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.pushOnlineAttendance(changeset, groupObjectId, teamObjectId)
  end


  def getOnlineAttendanceReport(groupObjectId, team_id, month) do
    {month, _ok} = Integer.parse(month)
    teamObjectId = decode_object_id(team_id)
    #get all students of class to check student present or absent for online meetingId
    getStudentsForTeamList = TeamPostRepo.getAllStudentsForOnlineClassAttendance(groupObjectId, teamObjectId)
    Enum.reduce(getStudentsForTeamList, [], fn k, acc ->
      #IO.puts "#{k}"
      studentDbObjectId = k["_id"]
      userObjectId = k["userId"]
      #now get list of meeting conducted in month coming from params
      meetingIdList = TeamPostRepo.getOnlineClassConductedListForMonth(groupObjectId, teamObjectId, month)
      #now check student from db is present to particulau meetingId or not
      list = Enum.reduce(meetingIdList, [], fn v, acc ->
        #IO.puts "#{v}"
        meetingObjectId = v["_id"]
        #meetingCreatedByName
        #####getMeetingCreatedByName = TeamPostRepo.getStaffMeetingCreatedByName(groupObjectId, v["meetingCreatedBy"])
        #####meetingCreatedByName = getMeetingCreatedByName["name"]
        meetingCreatedByName = v["meetingCreatedByName"]
        #get subjectName
        #####getSubjectName = TeamPostRepo.getSubjectNameForMeeting(groupObjectId, v["subjectId"])
        #####meetingSubjectName = getSubjectName["subjectName"]
        meetingSubjectName = v["subjectName"]
        #get date and time of meeting created
        meetingCreatedBsonTime = v["meetingCreatedAtTime"]
        {:ok, naiveDateTime} = NaiveDateTime.from_iso8601(meetingCreatedBsonTime)
        indianCurrentTime = NaiveDateTime.add(naiveDateTime, 19800)
        time = if indianCurrentTime.hour > 12 do
          %{
            indianHour: to_string(indianCurrentTime.hour - 12),
            zone:  "PM"
          }
        else
          %{
            indianHour: to_string(indianCurrentTime.hour - 12),
            zone:  "AM"
          }
        end
        indianMinute = to_string(indianCurrentTime.minute)
        indianTime = time.indianHour<>":"<>indianMinute<>time.zone
        indianDate = to_string(indianCurrentTime.day)<>"-"<>to_string(indianCurrentTime.month)<>"-"<>to_string(indianCurrentTime.year)
        #date, teacherName, subjectName, meetingTime, meetingDate concatenate
        concateMeetingDetail = indianDate<>","<>indianTime<>" ("<>meetingSubjectName<>"-"<>meetingCreatedByName<>")"
        #IO.puts "#{concateMeetingDetail}"
        #map = %{
        #  "studentName" => k["name"],
          #"studentRollNumber" => k["rollNumber"],
        #}
        {:ok, checkStudentPresent} = TeamPostRepo.checkStudentIsPresentForMeetingId(studentDbObjectId, userObjectId, meetingObjectId)
        map = if checkStudentPresent > 0 do
          #present. so, get join time for this particular student
          #getStudentJoinTime = TeamPostRepo.getStudentJoinTimeForMeeting(studentDbObjectId, userObjectId, meetingObjectId)
          #IO.puts "#{getStudentJoinTime}"
          #student is present for this meeting, so add to map
          #map = Map.put_new(map, concateMeetingDetail, "P")
          %{concateMeetingDetail => "P"}
        else
          #absent
          #map = Map.put_new(map, concateMeetingDetail, "A")
          %{concateMeetingDetail => "A"}
        end
        #IO.puts "#{map}"
        acc ++ [map]
      end)
      #IO.puts "#{list}"
      withNameList = list ++ [%{"studentName" => k["name"]}]
      acc ++ [withNameList]
    end)
    #IO.puts "#{checkStudentIsPresentForClassList}"
    ##{month, ok} = Integer.parse(month)
    #get present students list for attendance (for month provided get subjectId, meetingId, studentName and list of all details)
    ##getPresentStudentsListForMonth = TeamPostRepo.getPresentStudentsListForMonth(groupObjectId, teamObjectId, month)
    #IO.puts "#{getPresentStudentsListForMonth}"
    ##presentStudentList = Enum.reduce(getPresentStudentsListForMonth["attendance"], [], fn k, acc ->
    ##  IO.puts "#{k}"
      #meetingJoinedAtTime
    ##end)
  end


  def getAll(conn, group_id, team_id, limit) do
    # query_params = conn.query_params
    # loginUser = Guardian.Plug.current_resource(conn)
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    #check this team is created by login user or not
    #{:ok, checkTeamAdmin} = TeamRepo.isLoginUserTeam(groupObjectId, teamObjectId, loginUser["_id"])
    #TeamPostRepo.getAllPostsOfTeam(conn, groupObjectId, teamObjectId, limit, checkTeamAdmin)
    TeamPostRepo.getAllPostsOfTeam(conn, groupObjectId, teamObjectId, limit)
  end


  def deleteTeamPost(conn, group, team_id, post_id) do
    loginUser = Guardian.Plug.current_resource(conn)
    team = TeamRepo.get(team_id)
    postObjectId = decode_object_id(post_id)
    getTeamPost = TeamPostRepo.findTeamPostById(group["_id"], team["_id"], postObjectId)
    if loginUser["_id"] == getTeamPost["userId"] || group["adminId"] == loginUser["_id"] || team["adminId"] == loginUser["_id"] do
      TeamPostRepo.deleteTeamPost(group["_id"], team["_id"], postObjectId)
    else
      {:changeset_error, "You cannot Delete This Post"}
    end
  end


  def startTrip(conn, loc_params, groupObjectId, team) do
    latitude = loc_params["lat"]
    longitude = loc_params["long"]
    loginUser = Guardian.Plug.current_resource(conn)
    #check already trip started. If started then update only latitude, longitude and updated_at time
    TeamPostRepo.checkAlreadyTripExist(groupObjectId, team, loginUser, latitude, longitude)
  end


  def endTrip(conn, groupObjectId, team) do
    loginUser = Guardian.Plug.current_resource(conn)
    TeamPostRepo.endTrip(groupObjectId, team, loginUser)
  end


  def getTripLocation(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    #get trip location
    TeamPostRepo.getTripLocation(groupObjectId, teamObjectId)
  end


  def addSubjectsWithStaff(changeset, groupObjectId, teamObjectId) do
    TeamPostRepo.addSubjectsWithStaff(changeset, groupObjectId, teamObjectId)
  end


  def checkTimeTableAddedForThisTeam(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.checkTimeTableAddedForThisTeam(groupObjectId, teamObjectId)
  end


  def getSubjectsWithStaffFromTimeTable(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    getSubjectStaffFromTimeTable = TeamPostRepo.getSubjectsWithStaffFromTimeTable(groupObjectId, teamObjectId)
    #IO.puts "#{getSubjectStaffFromTimeTable}"
    #get unique subjectStaffId
    uniqueSubjectStaffList = Enum.reduce(getSubjectStaffFromTimeTable, [], fn k, acc ->
      #IO.puts "#{k["subjectWithStaffId"]}"
      acc ++ [%{"subjectStaffId" => k["subjectWithStaffId"], "subjectName" => k["subjectName"]}]
    end)
    subjectStaffIdList = Enum.uniq(uniqueSubjectStaffList)
    #add staffDetails to subjectStaffIdList
    list = Enum.reduce(subjectStaffIdList, [], fn k, acc ->
      #IO.puts "#{k}"
      list2 = Enum.reduce(getSubjectStaffFromTimeTable, [], fn v, acc ->
        if k["subjectStaffId"] == v["subjectWithStaffId"] do
          acc ++ [%{"staffName" => v["staffName"], "staffId" => encode_object_id(v["staffId"])}]
        else
          acc ++ []
        end
      end)
      #IO.puts "#{list2}"
      staffDetailMap = %{"staffDetail" => list2}
      mergeStaffDetailAndSubject = Map.merge(k, staffDetailMap)
      #IO.puts "#{staffDetailMap}"
      acc ++ [mergeStaffDetailAndSubject]
    end)
    #IO.puts "#{list}"
    list
    |> Enum.sort_by(& String.downcase(&1["subjectName"]))
  end


  def getSubjectsWithStaffForTeacher(loginUserId, group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    getSubjectStaffFromTimeTableForTeacher = TeamPostRepo.getSubjectsWithStaffForTeacher(loginUserId, groupObjectId, teamObjectId)
    #get unique subjectStaffId
    uniqueSubjectStaffList = Enum.reduce(getSubjectStaffFromTimeTableForTeacher, [], fn k, acc ->
      #IO.puts "#{k["subjectWithStaffId"]}"
      acc ++ [%{"subjectStaffId" => k["subjectWithStaffId"], "subjectName" => k["subjectName"]}]
    end)
    subjectStaffIdList = Enum.uniq(uniqueSubjectStaffList)
    #add staffDetails to subjectStaffIdList
    list = Enum.reduce(subjectStaffIdList, [], fn k, acc ->
      #IO.puts "#{k}"
      list2 = Enum.reduce(getSubjectStaffFromTimeTableForTeacher, [], fn v, acc ->
        if k["subjectStaffId"] == v["subjectWithStaffId"] do
          acc ++ [%{"staffName" => v["staffName"], "staffId" => encode_object_id(v["staffId"])}]
        else
          acc ++ []
        end
      end)
      #IO.puts "#{list2}"
      staffDetailMap = %{"staffDetail" => list2}
      mergeStaffDetailAndSubject = Map.merge(k, staffDetailMap)
      #IO.puts "#{staffDetailMap}"
      acc ++ [mergeStaffDetailAndSubject]
    end)
    #IO.puts "#{list}"
    list
    |> Enum.sort_by(& String.downcase(&1["subjectName"]))
  end


  def getSubjectsWithStaff(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    getSubjectStaff = TeamPostRepo.getSubjectsWithStaff(groupObjectId, teamObjectId)
    Enum.reduce(getSubjectStaff, [], fn k, acc ->
      #get details of staff using staffId
      staffName = Enum.reduce(k["staffId"], [], fn v, acc ->
        #getStaffDetails = TeamPostRepo.getStaffDetailsById(groupObjectId, teamObjectId, v)
        getStaffDetails = TeamPostRepo.getStaffDetailsById(groupObjectId, v)
        #IO.puts "#{decode_object_id(v)}"
        staffMap = %{"staffId" => v, staffName: getStaffDetails["name"]}
        acc ++ [staffMap]
      end)
      putNew = Map.put_new(k, "staffName", staffName)
      acc ++ [putNew]
    end)
  end



  def getSubjectsWithStaffById(group_id, team_id, subject_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    getSubjectStaff = TeamPostRepo.getSubjectsWithStaffById(groupObjectId, teamObjectId, subjectObjectId)
    Enum.reduce(getSubjectStaff, [], fn k, acc ->
      #get details of staff using staffId
      staffName = Enum.reduce(k["staffId"], [], fn v, acc ->
        getStaffDetails = TeamPostRepo.getStaffDetailsById(groupObjectId, v)
        #IO.puts "#{decode_object_id(v)}"
        staffMap = %{"staffId" => v, staffName: getStaffDetails["name"]}
        acc ++ [staffMap]
      end)
      putNew = Map.put_new(k, "staffName", staffName)
      acc ++ [putNew]
    end)
  end


  def removeSubjectWithStaff(groupObjectId, teamId, subjectId, params) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    if params["staffId"] do
      #remove only staff from subject
      TeamPostRepo.removeStaffFromSubject(groupObjectId, teamObjectId, subjectObjectId, params["staffId"])
    else
      #remove complete subject with all staffs added
      TeamPostRepo.removeCompleteSubjectStaff(groupObjectId, teamObjectId, subjectObjectId)
    end
  end



  def updateStaffToSubject(changeset, groupObjectId, team_id, subject_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    TeamPostRepo.updateSubjectsWithStaff(changeset, groupObjectId, teamObjectId, subjectObjectId)
  end



  def createFeeForClass(changeset, groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    #update due dates with date reverse reminder dates(future) installment no private Function
    dueDateList = dueDatesUpdate(changeset)
    changeset = changeset
    |> Map.put(:dueDates, dueDateList.dueDates)
    |> Map.delete(:reminder)
    ##Firstly check student exists in  student collection
    getStudentDbUserId = TeamPostRepo.getStudentDbId(groupObjectId, teamObjectId)
    if getStudentDbUserId != [] do
      TeamPostRepo.addFeeToClass(changeset, groupObjectId, teamObjectId)
      Enum.reduce(getStudentDbUserId, [], fn studentDbId, _acc ->
        #update fee for each student
        TeamPostRepo.addFeeForEachStudentInClass(studentDbId["_id"], studentDbId["userId"], changeset, groupObjectId, teamObjectId)
      end)
    else
      {:studentError, "No Students Found"}
    end
  end


  def updateFeeForClass(changeset, groupObjectId, teamObjectId, params) do
    #update due dates with date reverse reminder dates(future) installment no private Function
    dueDateList = dueDatesUpdate(changeset)
    changeset = changeset
    |> Map.put(:dueDates, dueDateList.dueDates)
    |> Map.delete(:reminder)
    if params["userId"] do
      userObjectId = decode_object_id(params["userId"])
      TeamPostRepo.updateFeeStructureForIndividualStudentUpdated(changeset, groupObjectId, teamObjectId, userObjectId)
    else
      #Firstly check student exists in  student collection
      getStudentDbUserId = TeamPostRepo.getStudentDbId(groupObjectId, teamObjectId)
      Enum.reduce(getStudentDbUserId, [], fn studentDbId, _acc ->
        TeamPostRepo.updateFeeToClass(changeset, groupObjectId, teamObjectId)
        #update fee for each student
        TeamPostRepo.updateFeeForEachStudentInClass(studentDbId["_id"], studentDbId["userId"], changeset, groupObjectId, teamObjectId)
      end)
    end
  end

  #due dates logics
  defp dueDatesUpdate(changeset) do
    Enum.reduce(changeset.dueDates, %{ installmentNo: 1, dueDates: []}, fn k, acc ->
      reverse = String.split(k["date"],"-")
      reverseStringDate = Enum.at(reverse, 2) <>"-"<>Enum.at(reverse, 1) <>"-"<>  Enum.at(reverse, 0)
      if Map.has_key?(changeset, :reminder) do
        reminderList = for days <- changeset.reminder do
          reverse  = String.split(Date.to_string(NaiveDateTime.add(NaiveDateTime.from_iso8601!(reverseStringDate<>" 00:00:00.000000"), -(days*24*60*60))),"-")
          Enum.at(reverse, 2) <>"-"<>Enum.at(reverse, 1) <>"-"<>  Enum.at(reverse, 0)
        end
        k = k
        |> Map.put("reminderDateList", reminderList)
        |> Map.put("dateReverse", reverseStringDate)
        |> Map.put("installmentNo", acc.installmentNo)
        |> Map.put("balance", String.to_integer(k["minimumAmount"]))
        %{ installmentNo: acc.installmentNo + 1, dueDates: acc.dueDates ++ [k] }
      else
        k = k
        |> Map.put("dateReverse", reverseStringDate)
        |> Map.put("installmentNo", acc.installmentNo)
        |> Map.put("balance",  String.to_integer(k["minimumAmount"]))
        %{ installmentNo: acc.installmentNo + 1, dueDates: acc.dueDates ++ [k] }
      end
    end)
  end


  def updateFeeStructureForIndividualStudent(changeset, groupObjectId, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #update fee for individual student
    TeamPostRepo.updateFeeStructureForIndividualStudent(changeset, groupObjectId, teamObjectId, userObjectId)
  end


  def getFeeForClass(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getFeeForClass(groupObjectId, teamObjectId)
  end


  # def getStudentsFeeDetails(groupObjectId, team_id) do
  #   teamObjectId = decode_object_id(team_id)
  #   TeamPostRepo.getStudentsFeeDetails(groupObjectId, teamObjectId)
  # end


  def getStudentsFeeDetails(groupObjectId, team_id) do
    #get list of students in class with userId
    teamObjectId = decode_object_id(team_id)
    # 1. get all the student userIds and details for class
    classStudentsMap = TeamPostRepo.getClassStudentUserIdAndDetailsForFees(groupObjectId, teamObjectId)
    for studentId <- classStudentsMap do
      studentId["userId"]
    end
    #2. get fees list for student userIds
    studentsFeeList = TeamPostRepo.getFeeStudentListForClass(groupObjectId, teamObjectId)
    #merge classStudentsMap and offlineTestExamStudentMarksCardListMap by userId in list
    mergeTwoListOfClassFees(classStudentsMap, studentsFeeList)
  end

  defp mergeTwoListOfClassFees(classStudentsMap, studentsFeeList) do
    #merge  classStudentsMap and reportMap by userId in list
    listMap = Enum.map(classStudentsMap, fn k ->
      userFeeReport = Enum.find(studentsFeeList, fn v -> v["userId"] == k["userId"] end)
      # IO.puts "#{userMarkscardReport == %{}}"
      if userFeeReport do
        Map.merge(k, userFeeReport)
      else
        Map.merge(k, %{})
      end
    end)
    listMap
  end


  def getIndividualStudentFeeDetails(groupObjectId, team_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamPostRepo.getIndividualStudentFeeDetails(groupObjectId, teamObjectId, userObjectId)
  end


  def getStudentFeeStatusList(groupObjectId, status) do
    TeamPostRepo.getStudentFeeStatusList(groupObjectId, status)
    #IO.puts "#{Enum.to_list(feeStatus)}"
  end


  def getStudentFeeStatusListBasedOnTeam(groupObjectId, team_id, status) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getStudentFeeStatusListBasedOnTeam(groupObjectId, teamObjectId, status)
    #IO.puts "#{Enum.to_list(feeStatus)}"
  end


  def approveOrHoldFeePaidByStudent(groupObjectId, team_id, user_id, payment_id, status, loginUserId, approverName) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    if status == "approve" do
      #check this paymentId is already approved
      {:ok, checkAlreadyApproved} = TeamPostRepo.checkThisPaymentIsAlreadyApproved(groupObjectId, teamObjectId, userObjectId, payment_id)
      #IO.puts "#{checkAlreadyApproved}"
      if checkAlreadyApproved == 0 do
        #get this student payment details to approve
        studentPaymentDetail = TeamPostRepo.getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id)
        amountPaidNow = studentPaymentDetail["feePaidDetails"]["amountPaid"]
        totalBalance = studentPaymentDetail["totalBalance"] - amountPaidNow #totalBalance - amountPaidNow
        totalAmountPaid = studentPaymentDetail["totalAmountPaid"] + amountPaidNow #totalAmountPaid + amountPaidNow
        #to add previous due amount to current
        {list, _} = Enum.reduce(studentPaymentDetail["dueDates"], {[], 0}, fn %{"minimumAmount" => ma_str} = x, {l, sum} ->
          new_sum = sum + String.to_integer(ma_str)
          {[%{x | "minimumAmount" => to_string(new_sum)} | l], new_sum}
        end)  #Here i will get due amount with previous sum in list

        #check if due minimum amount is less than amount paid to send status = completed
        Enum.reduce(list, [], fn k, _acc ->
          if totalAmountPaid >= String.to_integer(k["minimumAmount"]) do
            #update status = completed for this date
            TeamPostRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], "completed")
          else
            #unset status=completed if exist for this date
            TeamPostRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], "notCompleted")
          end
        end)
        #IO.puts "#{checkDueAmountStatusList}"

        #update approve and balance, amountPaid details for this student
        TeamPostRepo.approveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance, loginUserId, approverName)
      else
        {:ok, "already approved"}
      end
    else
      if status == "hold" do
        #update on hold
        TeamPostRepo.holdFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id)
      else
        #status == "notApprove"
        #check this paymentId is already not approved
        {:ok, checkAlreadyNotApproved} = TeamPostRepo.checkThisPaymentIsAlreadyNotApproved(groupObjectId, teamObjectId, userObjectId, payment_id)
        if checkAlreadyNotApproved == 0 do
          #get this student payment details to not approve (It is a reverse for approve because not approve will be done only for approved fees so we have to reduce amountPaid and increase balanceAmount)
          studentPaymentDetail = TeamPostRepo.getIndividualStudentFeeDetailsByPaymentId(groupObjectId, teamObjectId, userObjectId, payment_id)
          amountPaidNow = studentPaymentDetail["feePaidDetails"]["amountPaid"]
          totalBalance = studentPaymentDetail["totalBalance"] + amountPaidNow #totalBalance - amountPaidNow
          totalAmountPaid = studentPaymentDetail["totalAmountPaid"] - amountPaidNow #totalAmountPaid + amountPaidNow

          #to add previous due amount to current
          {list, _} = Enum.reduce(studentPaymentDetail["dueDates"], {[], 0}, fn %{"minimumAmount" => ma_str} = x, {l, sum} ->
            new_sum = sum + String.to_integer(ma_str)
            {[%{x | "minimumAmount" => to_string(new_sum)} | l], new_sum}
          end)  #Here i will get due amount with previous sum in list
          #check if due minimum amount is less than amount paid to send status = completed
          Enum.reduce(list, [], fn k, _acc ->
            if totalAmountPaid >= String.to_integer(k["minimumAmount"]) do
              #update status = completed for this date
              TeamPostRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], "completed")
            else
              #unset status=completed if exist for this date
              TeamPostRepo.dueDateStatusUpdate(groupObjectId, teamObjectId, userObjectId, k["date"], "notCompleted")
            end
          end)

          #update approve and balance, amountPaid details for this student
          TeamPostRepo.notApproveFeePaidByStudent(groupObjectId, teamObjectId, userObjectId, payment_id, totalAmountPaid, totalBalance)
        else
          {:ok, "already Not approved"}
        end
      end
    end
  end



  def createOfflineTestExam(groupObjectId, team_id, changeset) do
    teamObjectId = decode_object_id(team_id)
    offlineTestExamId = encode_object_id(new_object_id())
    #get all student of class to add or update markscard
    getStudentDetails = TeamPostRepo.getStudentListToAddmarksCard(groupObjectId, teamObjectId)
    if getStudentDetails == [] do
      {:noStudentError, "No Students Found"}
    else
      #checking whether min and max marks are valid
      changeset = checkFunction(changeset)
      #checking whether part b is there or not
      if Map.has_key?(changeset, :section) do
        sectionMap = Enum.reduce(changeset.section, %{}, fn k, acc ->
          acc
          |> Map.put(k, "")
        end)
        changeset =  Map.put(changeset, :section, sectionMap)
        subjectMarksDetailsLength = length(changeset.subjectMarksDetails)
        #marksCard Doc for student
        marksCardDoc = %{
          "offlineTestExamId" => offlineTestExamId,
          "title" => changeset.title,
          "isApproved" => false,
          "duration" => Enum.at(changeset.subjectMarksDetails, 0)["date"]<>" to "<>Enum.at(changeset.subjectMarksDetails, subjectMarksDetailsLength - 1)["date"],
          "section" => sectionMap
        }
        #marks card logic in private function
        marksCardLogics(getStudentDetails, groupObjectId, teamObjectId, offlineTestExamId, changeset, marksCardDoc)
      else
        subjectMarksDetailsLength = length(changeset.subjectMarksDetails)
        #marksCard Doc for student
        marksCardDoc = %{
          "offlineTestExamId" => offlineTestExamId,
          "title" => changeset.title,
          "isApproved" => false,
          "duration" => Enum.at(changeset.subjectMarksDetails, 0)["date"]<>" to "<>Enum.at(changeset.subjectMarksDetails, subjectMarksDetailsLength - 1)["date"]
        }
        #marks card logic in private function
        marksCardLogics(getStudentDetails, groupObjectId, teamObjectId, offlineTestExamId, changeset, marksCardDoc)
      end
    end
  end


  #Check for null values in data
  defp checkFunction(changeset) do
    subjectMarksDetails =  for subject <- changeset.subjectMarksDetails do
      if Map.has_key?(subject, "maxMarks") do
        if !Regex.match?(~r/^\d+$/, subject["maxMarks"])  do
          subject
          |> Map.put("maxMarks", "0")
        else
          subject
        end
      else
        subject
      end
      if Map.has_key?(subject, "minMarks") do
        if !Regex.match?(~r/^\d+$/, subject["minMarks"])  do
          subject
          |> Map.put("minMarks", "0")
        else
          subject
        end
      else
        subject
      end
    end
    Map.put(changeset, :subjectMarksDetails, subjectMarksDetails)
  end

  #Marks Card and test exam Schedule Logics
  defp marksCardLogics(getStudentDetails, groupObjectId, teamObjectId, offlineTestExamId, changeset, marksCardDoc) do
    ### Firstly create timetable for this offline test/exam ###
    #check exam time table in this class is already exist
    {:ok, checkOfflineTestExamTimeTableAlready} = TeamPostRepo.checkOfflineTestExamTimeTableAlreadyForThisTeam(groupObjectId, teamObjectId)
    if checkOfflineTestExamTimeTableAlready == 0 do
      #insert new offline testexam timetable for this team
      changeset = update_map_with_key_value(changeset, :offlineTestExamId, offlineTestExamId)
      TeamPostRepo.insertNewOfflineTestExamTimeTableForTeam(groupObjectId, teamObjectId, changeset)
    else
      #update new test exam schedule to team
      changeset = update_map_with_key_value(changeset, :offlineTestExamId, offlineTestExamId)
      TeamPostRepo.updateNewOfflineTestExamTimeTableForTeam(groupObjectId, teamObjectId, changeset)
    end
    ###Secondly create markscard and add that markscard to all the students off class from marks card doc in above function###
    Enum.reduce(getStudentDetails, [], fn k, _acc ->
      #check markscard already created for this student
      {:ok, checkMarksCardAlreadyForStudent} = TeamPostRepo.checkOfflineTestExamMarksCardAlreadyCreated(groupObjectId, teamObjectId, k["userId"])
      if checkMarksCardAlreadyForStudent == 0 do
        #check Language In StudentDb and arrange accondingly and update to mark doc
        subjectMarksDetails = checkLanguageInStudentDb(k, changeset)
        marksCardDoc = Map.put(marksCardDoc, "subjectMarksDetails", subjectMarksDetails)
        # #insert new markscard to school_markscard_database
        k = k
        |> Map.put_new("marksCardDetails", [marksCardDoc])
        |> Map.put_new("isActive", true)
        TeamPostRepo.insertNewOfflineTestExamMarksCardToStudent(k, groupObjectId, teamObjectId)
      else
        subjectMarksDetails = checkLanguageInStudentDb(k, changeset)
        marksCardDoc = Map.put(marksCardDoc, "subjectMarksDetails", subjectMarksDetails)
        TeamPostRepo.updateNewOfflineTestExamMarksCardToStudent(k, marksCardDoc, groupObjectId, teamObjectId)
      end
    end)
  end

  #subject Arrangement function
  defp checkLanguageInStudentDb(k, changeset) do
    for subject <- changeset.subjectMarksDetails do
      if Map.has_key?(k, "languages") do
        if subject["isLanguage"] == true && Enum.find(k["languages"], fn v -> v["subjectId"] == decode_object_id(subject["subjectId"]) end) do
          subject
        else
          if !Map.has_key?(subject, "isLanguage") do
            subject
          end
        end
      else
        subject
      end
    end
    |> Enum.reject(&is_nil/1)
  end


  def editOfflineTestOrExam(groupObjectId, teamObjectId, offlineTestExamId, changeset) do
    getStudentDetails = TeamPostRepo.getStudentListToAddmarksCard(groupObjectId, teamObjectId)
    #checking whether min and max marks are valid
    changeset = checkFunction(changeset)
    |> update_map_with_key_value(:offlineTestExamId, offlineTestExamId)
    if Map.has_key?(changeset, :section) do
      sectionMap = Enum.reduce(changeset.section, %{}, fn k, acc ->
        acc
        |> Map.put(k, "")
      end)
      changeset = Map.put(changeset, :section, sectionMap)
      #update new test exam schedule to team
      TeamPostRepo.updateNewOfflineTestExamTimeTableForTeamEdit(groupObjectId, teamObjectId, offlineTestExamId, changeset)
      subjectMarksDetailsLength = length(changeset.subjectMarksDetails)
      ### Secondly create Updated markscard and add that markscard to all the students off class without changeing obtained marks ###
      marksCardDoc = %{
        "offlineTestExamId" => offlineTestExamId,
        "title" => changeset.title,
        "isApproved" => false,
        "duration" => Enum.at(changeset.subjectMarksDetails, 0)["date"]<>" to "<>Enum.at(changeset.subjectMarksDetails, subjectMarksDetailsLength - 1)["date"],
        "section" => sectionMap
      }
      updateMarksCardLogics(getStudentDetails, groupObjectId, teamObjectId, marksCardDoc, changeset, offlineTestExamId)
    else
      #update new test exam schedule to team
      TeamPostRepo.updateNewOfflineTestExamTimeTableForTeamEdit(groupObjectId, teamObjectId, offlineTestExamId, changeset)
      subjectMarksDetailsLength = length(changeset.subjectMarksDetails)
      marksCardDoc = %{
        "offlineTestExamId" => offlineTestExamId,
        "title" => changeset.title,
        "isApproved" => false,
        "duration" => Enum.at(changeset.subjectMarksDetails, 0)["date"]<>" to "<>Enum.at(changeset.subjectMarksDetails, subjectMarksDetailsLength - 1)["date"]
      }
      updateMarksCardLogics(getStudentDetails, groupObjectId, teamObjectId, marksCardDoc, changeset, offlineTestExamId)
    end
  end

  #update logics
  defp updateMarksCardLogics(getStudentDetails, groupObjectId, teamObjectId, marksCardDoc, changeset, offlineTestExamId) do
    Enum.reduce(getStudentDetails, [], fn k, _acc ->
      #check markscard already created for this student
      {:ok, checkMarksCardAlreadyForStudent} = TeamPostRepo.checkOfflineTestExamMarksCardAlreadyCreated(groupObjectId, teamObjectId, k["userId"])
      if checkMarksCardAlreadyForStudent == 0 do
        #insert new markscard to school_markscard_database
        subjectMarksDetails = checkLanguageInStudentDb(k, changeset)
        marksCardDoc = Map.put( marksCardDoc, "subjectMarksDetails", subjectMarksDetails)
        k = k
        |> Map.put_new("marksCardDetails", [marksCardDoc])
        |> Map.put_new("isActive", true)
        TeamPostRepo.insertNewOfflineTestExamMarksCardToStudent(k, groupObjectId, teamObjectId)
      else
        #update markscard to already existed student
        # get subject marks details of previous  before edit and set
        changeset = oldMarksExisted(groupObjectId, teamObjectId, offlineTestExamId, k, changeset)
        subjectMarksDetails = checkLanguageInStudentDb(k, changeset)
        marksCardDoc = Map.put(marksCardDoc, "subjectMarksDetails", subjectMarksDetails)
        TeamPostRepo.updateNewOfflineTestExamMarksCardToStudentEdit(k, marksCardDoc, groupObjectId, teamObjectId, offlineTestExamId)
      end
    end)
  end

  #old marks logics
  defp oldMarksExisted(groupObjectId, teamObjectId, offlineTestExamId, k, changeset) do
    #get old marks details if existed
    oldMarksList = TeamPostRepo.getOldExamDetails(groupObjectId, teamObjectId, offlineTestExamId, k["userId"])
    if oldMarksList do
      subjectMarksDetails = for subject <- changeset.subjectMarksDetails do
        newSubjectMap = Enum.find(hd(oldMarksList["marksCardDetails"])["subjectMarksDetails"], fn v -> v["subjectId"] == subject["subjectId"] end)
        if newSubjectMap do
          Map.merge(newSubjectMap, subject)
        else
          subject
        end
      end
      |> Enum.reject(&is_nil/1)
      Map.put(changeset, :subjectMarksDetails, subjectMarksDetails)
    else
      changeset
    end
  end


  def approveResult(groupObjectId, teamId, offlineTestExam_id) do
    teamObjectId = decode_object_id(teamId)
    # update approve result both in testExam timetable schedule and student markscard collection
    TeamPostRepo.approveResultForTestExam(groupObjectId, teamObjectId, offlineTestExam_id)
    TeamPostRepo.approveResultForStudent(groupObjectId, teamObjectId, offlineTestExam_id)
  end


  def notApproveResult(groupObjectId, teamId, offlineTestExam_id) do
    teamObjectId = decode_object_id(teamId)
    # update approve result both in testExam timetable schedule and student markscard collection
    TeamPostRepo.notApproveResultForTestExam(groupObjectId, teamObjectId, offlineTestExam_id)
    TeamPostRepo.notApproveResultForStudent(groupObjectId, teamObjectId, offlineTestExam_id)
  end


  def getOfflineTestOrExamList(group, team_id, userObjectId) do
    teamObjectId = decode_object_id(team_id)
    offlineTestExam = TeamPostRepo.getOfflineTestOrExamList(group["_id"], teamObjectId)
    #check user is staff or student
    {:ok, userCheck} = TeamPostRepo.checkUserStaff(group["_id"], userObjectId)
    ##IO.puts "#{offlineTestExam["testExamSchedules"]}"  ## It will list all test exam list for team/class
    cond do
      group["adminId"] == userObjectId || userCheck > 0 ->
        if offlineTestExam do
          #now iterate all testexam one by one and get totalMaxMarks, totalMinMarks  for each
          Enum.reduce(offlineTestExam["testExamSchedules"], [], fn k, acc ->
            #Marks Logic
            acc ++ [marksLogic(k)]
          end)
        else
          []
        end
      true ->
        ##get students languages form db
        getStudentLanguages =  TeamPostRepo.checkUserStudent(group["_id"], teamObjectId, userObjectId)
        #getting subject db from db for subject priority
        getSubjectList = TeamPostRepo.getSubjectList(group["_id"], teamObjectId)
        if offlineTestExam do
          #now iterate all testexam one by one and get totalMaxMarks, totalMinMarks  for eac
          Enum.reduce(offlineTestExam["testExamSchedules"], [], fn k, acc ->
            #arrange subject according to student opted language priority
            subjectMarksDetails = subjectArrangement(k, getStudentLanguages, getSubjectList)
            k = Map.put(k, "subjectMarksDetails", subjectMarksDetails)
            acc ++ [marksLogic(k)]
          end)
        else
          []
        end
    end
  end


  defp subjectArrangement(k, getStudentLanguages, getSubjectList) do
    for subject <- k["subjectMarksDetails"] do
      #checking whether have update languages
      if Map.has_key?(getStudentLanguages, "languages") do
        #comparing languages of student opted with offline test exam schedule with language true
        if subject["isLanguage"] == true && Enum.find(getStudentLanguages["languages"], fn v -> v["subjectId"] == decode_object_id(subject["subjectId"]) end) do
          # check the subjectId details from subject_staff and append subject priority if existed else appending static value
          subjectPriority = Enum.find(getSubjectList, fn v -> v["_id"] == decode_object_id(subject["subjectId"]) end)
          if subjectPriority do
            if Map.has_key?(subjectPriority, "subjectPriority") do
              Map.put(subject, "subjectPriority", subjectPriority["subjectPriority"])
            else
              Map.put(subject, "subjectPriority", 25)
            end
          end
        else
          # for isLanguage key does not exists
          if !Map.has_key?(subject, "isLanguage") do
            # check the subjectId details from subject_staff and append subject priority if existed else appending static value
            subjectPriority = Enum.find(getSubjectList, fn v -> v["_id"] == decode_object_id(subject["subjectId"]) end)
            if subjectPriority do
              if Map.has_key?(subjectPriority, "subjectPriority") do
                Map.put(subject, "subjectPriority", subjectPriority["subjectPriority"])
              else
                Map.put(subject, "subjectPriority", 25)
              end
            end
          end
        end
      else
        Map.put(subject, "subjectPriority", 25)
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& (&1["subjectPriority"]), &<=/2)
  end


  defp marksLogic(k) do
    #get totalMaxMarks
    totalMaxMarks = k["subjectMarksDetails"]
    |> Enum.map(fn item ->
      if Map.has_key?(item, "type") do
        if item["type"] != "grades" do
          if Regex.match?(~r/^\d+$/, item["maxMarks"]) do
            String.to_integer(item["maxMarks"])
          else
            0
          end
        end
      else
        if Regex.match?(~r/^\d+$/, item["maxMarks"]) do
          String.to_integer(item["maxMarks"])
        else
          0
        end
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
    #get totalMinMarks
    totalMinMarks = k["subjectMarksDetails"]
    |> Enum.map(fn item ->
      if Map.has_key?(item, "type") do
        if item["type"] != "grades" do
          if Regex.match?(~r/^\d+$/, item["maxMarks"]) do
            String.to_integer(item["minMarks"])
          else
            0
          end
        end
      else
        if Regex.match?(~r/^\d+$/, item["maxMarks"]) do
          String.to_integer(item["minMarks"])
        else
          0
        end
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
    k
    |> Map.put_new("totalMaxMarks", Integer.to_string(totalMaxMarks))
    |> Map.put_new("totalMinMarks", Integer.to_string(totalMinMarks))
  end


  def getOfflineTestExamHallTicketListForStudents(groupObjectId, team_id, offlineTestExamId) do
    teamObjectId = decode_object_id(team_id)
    #getting subject db from db for subject priority
    getSubjectList = TeamPostRepo.getSubjectList(groupObjectId, teamObjectId)
    #1. get test exam list for team
    offlineTestExamForTeam = TeamPostRepo.getOfflineTestOrExamList(groupObjectId, teamObjectId)
    if offlineTestExamForTeam do
      filterOfflineTestExamForTeam = Enum.filter(offlineTestExamForTeam["testExamSchedules"], fn k ->
        k["offlineTestExamId"] == offlineTestExamId
      end)
      #test exam schedule time table for selected test/exam
      offlineTestExamScheduleMap = hd(filterOfflineTestExamForTeam)
      #2. Now get list of students for this class to add name, rollNumber of students
      classStudentsList = TeamPostRepo.getStudentsForClass(groupObjectId, teamObjectId)
      #3. Add offlineTestExamSchedule for each student in list
      Enum.reduce(classStudentsList, [], fn k, acc ->
        #subject arrangement logics
        subjectMarksDetails = subjectArrangement(offlineTestExamScheduleMap, k, getSubjectList)
        offlineTestExamScheduleMap = Map.put(offlineTestExamScheduleMap, "subjectMarksDetails", subjectMarksDetails)
        k = Map.merge(k, offlineTestExamScheduleMap)
        acc ++ [k]
      end)
      |> Enum.sort_by(& String.downcase(&1["name"]))
    end
  end


  def getOfflineTestExamScheduleListForStudents(groupObjectId, team_id, offlineTestExamId) do
    teamObjectId = decode_object_id(team_id)
    #offlineTestExamObjectId = decode_object_id(offlineTestExam_id)
    #1. get test exam list for team
    offlineTestExamForTeam = TeamPostRepo.getOfflineTestOrExamList(groupObjectId, teamObjectId)
    if offlineTestExamForTeam do
      filterOfflineTestExamForTeam = Enum.filter(offlineTestExamForTeam["testExamSchedules"], fn k ->
        k["offlineTestExamId"] == offlineTestExamId
      end)
      #test exam schedule time table for selected test/exam
      offlineTestExamScheduleMap = hd(filterOfflineTestExamForTeam)
      #2. Now get list of students for this class to add name, rollNumber of students
      classStudentsList = TeamPostRepo.getStudentsForClass(groupObjectId, teamObjectId)
      #3. Add offlineTestExamSchedule for each student in list
      offlineTestExamScheduleForStudent = Enum.reduce(classStudentsList, [], fn k, acc ->
        k = Map.merge(k, offlineTestExamScheduleMap)
        acc ++ [k]
      end)
      offlineTestExamScheduleForStudent
      |> Enum.sort_by(& String.downcase(&1["name"]))
    else
      []
    end
  end


  def removeCreatedOfflineTestOrExam(groupObjectId, team_id, offlineTestExam_id) do
    teamObjectId = decode_object_id(team_id)
    ##### Firstly remove time table scheduled for offline test/exam
    TeamPostRepo.removeOfflineTestExamScheduledTimeTable(groupObjectId, teamObjectId, offlineTestExam_id)
    #### Secondly remove markscard from each student
    TeamPostRepo.removeOfflineTestExamMarksCard(groupObjectId, teamObjectId, offlineTestExam_id)
  end


  def getOfflineTestExamStudentMarksCardList(groupObjectId, team_id, offlineTestExam_id) do
    teamObjectId = decode_object_id(team_id)
    # 1. get all the student userIds and details for class
    classStudentsMap = TeamPostRepo.getClassStudentUserIdAndDetailsForMarkscard(groupObjectId, teamObjectId)
    studentdUserIds = for studentId <- classStudentsMap do
      [] ++ studentId["userId"]
    end
    #2. get offline test exam list for student userIds
    offlineTestExamStudentMarksCard = TeamPostRepo.getOfflineTestExamStudentMarksCardList(groupObjectId, teamObjectId, offlineTestExam_id, studentdUserIds)
    offlineTestExamStudentMarksCardListMap = Enum.reduce(offlineTestExamStudentMarksCard, [], fn k, acc ->
      marksCardDetails = hd(k["marksCardDetails"])
      #get totalMaxMarks and total min marks from marks logic
      totalMaxAndMinMarks = marksLogic(marksCardDetails)
      #get totalObtainedMarks
      totalObtainedMarks = marksCardDetails["subjectMarksDetails"]
      |>Enum.map(fn item ->
          if Map.has_key?(item, "type") do
            if item["type"] != "grades" do
              if item["obtainedMarks"] do
                if String.downcase(item["obtainedMarks"]) != "absent" do
                  String.to_integer(item["obtainedMarks"])
                end
              else
                0  #obtained marks not uploaded
              end
            end
          else
            if item["obtainedMarks"] do
              if String.downcase(item["obtainedMarks"]) != "absent" do
                String.to_integer(item["obtainedMarks"])
              end
            else
              0  #obtained marks not uploaded
            end
          end
        end)
        |> Enum.reject(&is_nil/1)
        |> Enum.sum()
        percentage =  Float.to_string((totalObtainedMarks*100)/ String.to_integer(totalMaxAndMinMarks["totalMaxMarks"]), decimals: 2)
        k = k
        |> Map.put_new("totalMaxMarks", totalMaxAndMinMarks["totalMaxMarks"])
        |> Map.put_new("totalMinMarks", totalMaxAndMinMarks["totalMinMarks"])
        |> Map.put_new("totalObtainedMarks", totalObtainedMarks)
        |> Map.put("percentage", String.to_float(percentage))
        # |> Map.put("passClass", classLogics(percentage))
        # |> Map.put("grade", gradeLogics(percentage))
        acc ++ [k]
    end)
    #merge classStudentsMap and offlineTestExamStudentMarksCardListMap by userId in list
    mergeTwoListOfMarkscardReport(classStudentsMap, offlineTestExamStudentMarksCardListMap)
  end


  # defp gradeLogics(percentage) do
  #   cond do
  #     String.to_float(percentage) >= 80 ->
  #       "O(Outstanding)"
  #     String.to_float(percentage) < 80 &&   String.to_float(percentage) >= 75  ->
  #       "A"
  #     String.to_float(percentage) < 75 &&   String.to_float(percentage) >= 70 ->
  #       "B"
  #     String.to_float(percentage) < 70 &&   String.to_float(percentage) >= 60 ->
  #      "C"
  #     String.to_float(percentage) < 60 &&   String.to_float(percentage) >= 50 ->
  #      "D"
  #     String.to_float(percentage) < 50 &&   String.to_float(percentage) >= 45 ->
  #      "E"
  #     String.to_float(percentage) < 45 &&   String.to_float(percentage) >= 35 ->
  #      "P(Pass)"
  #     true ->
  #       "F(Fail)"
  #   end
  # end


  # defp classLogics(percentage) do
  #   cond do
  #     String.to_float(percentage) >= 85 ->
  #       "DISTINCTION"
  #     String.to_float(percentage) < 85 &&  String.to_float(percentage) >= 60  ->
  #       "FIRST CLASS"
  #     String.to_float(percentage) < 60 &&  String.to_float(percentage) >= 50 ->
  #       "SECOND CLASS"
  #     String.to_float(percentage) < 50 &&  String.to_float(percentage) >= 35 ->
  #       "THIRD CLASS"
  #     true ->
  #       "FAIL"
  #   end
  # end


  def getOfflineTestExamSelectedStudentMarksCardList(groupObjectId, team_id, user_id, offlineTestExam_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    # 1. get all the student userIds and details for class
    classStudentsMap = TeamPostRepo.getSelectedClassStudentUserIdAndDetailsForMarkscard(groupObjectId, teamObjectId, userObjectId)
    studentdUserId = classStudentsMap["userId"]
    #2. get offline test exam list for student userIds
    offlineTestExamStudentMarksCard = TeamPostRepo.getOfflineTestExamStudentMarksCardListForSelectedStudent(groupObjectId, teamObjectId, offlineTestExam_id, studentdUserId)
    if offlineTestExamStudentMarksCard != [] do
      k = hd(offlineTestExamStudentMarksCard)
      #get totalMaxMarks
      marksCardDetails = k["marksCardDetails"]
      #get totalMaxMarks and total min marks from marks logic
      totalMaxAndMinMarks = marksLogic(marksCardDetails)
      #get totalObtainedMarks
      totalObtainedMarks = marksCardDetails["subjectMarksDetails"]
        |>Enum.map(fn item ->
            if Map.has_key?(item, "type") do
              if item["type"] != "grades" do
                if item["obtainedMarks"] do
                  if String.downcase(item["obtainedMarks"]) != "absent" do
                    String.to_integer(item["obtainedMarks"])
                  end
                else
                  0  #obtained marks not uploaded
                end
              end
            else
              if item["obtainedMarks"] do
                if String.downcase(item["obtainedMarks"]) != "absent" do
                  String.to_integer(item["obtainedMarks"])
                end
              else
                0  #obtained marks not uploaded
              end
            end
          end)
        |> Enum.reject(&is_nil/1)
        |> Enum.sum()
        percentage =  Float.to_string((totalObtainedMarks*100)/ String.to_integer(totalMaxAndMinMarks["totalMaxMarks"]), decimals: 2)
        k = k
        |> Map.put_new("totalMaxMarks", totalMaxAndMinMarks["totalMaxMarks"])
        |> Map.put_new("totalMinMarks", totalMaxAndMinMarks["totalMinMarks"])
        |> Map.put_new("totalObtainedMarks", totalObtainedMarks)
        |> Map.put("percentage", String.to_float(percentage))
        # |> Map.put("passClass", classLogics(percentage))
        # |> Map.put("grade", gradeLogics(percentage))
      #merge two maps
      [Map.merge(classStudentsMap, k)]
    else
      []
    end
  end


  defp mergeTwoListOfMarkscardReport(classStudentsMap, offlineTestExamStudentMarksCardListMap) do
    #merge  classStudentsMap and reportMap by userId in list
    listMap = Enum.map(classStudentsMap, fn k ->
      userMarkscardReport = Enum.find(offlineTestExamStudentMarksCardListMap, fn v -> v["userId"] == k["userId"] end)
      # IO.puts "#{userMarkscardReport == %{}}"
      if userMarkscardReport do
        Map.merge(k, userMarkscardReport)
      else
        Map.merge(k, %{})
      end
    end)
    listMap
  end


  def addOfflineTestExamMarksToStudent(changeset, groupObjectId, team_id, offlineTestExam_id, user_id) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamPostRepo.addOfflineTestExamMarksToStudent(changeset.subjectMarksDetails, groupObjectId, teamObjectId, userObjectId, offlineTestExam_id)

    ##subjectMarksList = Enum.reduce(changeset.subjectMarksDetails, [], fn k, acc ->
    ##  #update subject wise marks one by one
    ##  TeamPostRepo.addOfflineTestExamMarksToStudent(k, groupObjectId, teamObjectId, userObjectId, offlineTestExam_id)
    ##end)
  end




  def addCompletedOrNotStatusForFeeDueDates(groupObjectId, team_id, user_id, params) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamPostRepo.addCompletedOrNotStatusForFeeDueDates(groupObjectId, teamObjectId, userObjectId, params)
  end



  def addToSubjectToMasterSyllabusAndNotes(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId) do
    syllabusInsertDoc = if Map.has_key?(changeset, :topicName) do
      %{
        chapterName: changeset.chapterName,
        chapterId: encode_object_id(new_object_id()),
        topicsList: [
          %{
            topicName: changeset.topicName,
            topicId: encode_object_id(new_object_id()),
          }
        ],
        totalTopicsCount: 1,
      }
    else
      %{
        chapterName: changeset.chapterName,
        chapterId: encode_object_id(new_object_id()),
        topicsList: [
          %{
            topicName: changeset.chapterName,
            topicId: encode_object_id(new_object_id()),
          }
        ],
        totalTopicsCount: 1,
      }
    end
    TeamPostRepo.addToSubjectToMasterSyllabus(groupObjectId, teamObjectId, subjectObjectId, syllabusInsertDoc)
    addSubjectVicePostsForTeam(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId, syllabusInsertDoc)
  end


  defp addSubjectVicePostsForTeam(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId, syllabusInsertDoc) do
    topicMap = hd(syllabusInsertDoc.topicsList)
    chapterObjectId = decode_object_id(syllabusInsertDoc.chapterId)
    TeamPostRepo.addSubjectVicePostsForTeam(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId, topicMap, chapterObjectId)
  end


  def getSubjectVicePosts(groupObjectId, teamId, subjectId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    TeamPostRepo.getSubjectVicePosts(groupObjectId, teamObjectId, subjectObjectId)
  end



  def addTopicsToChapterNotesAndSyllabus(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapter_id, changeset) do
    chapterObjectId = decode_object_id(chapter_id)
    if Map.has_key?(changeset, :topicId) do
      topicMap = %{
        topicName:  changeset.topicName,
        topicId: changeset.topicId
      }
      addToNotesAndVideos(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, topicMap, chapter_id)
    else
      insertTopicDoc = %{
        topicName:  changeset.topicName,
        topicId: encode_object_id(new_object_id())
      }
      TeamPostRepo.topicAddToExistingChapterMaster(groupObjectId,teamObjectId, subjectObjectId, chapter_id, insertTopicDoc)
      addToNotesAndVideos(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, insertTopicDoc, chapter_id)
    end
    # addToNotesAndVideos(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, insertTopicDoc, chapter_id)
  end


  defp  addToNotesAndVideos(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, topicMap, chapter_id) do
    #checking whether chapter is created in subject_post repo
    {:ok, count} = TeamPostRepo.checkWhetherChapterIsCreatedForId(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId)
    if count == 0 do
      #get chapterName
      chapterNameDetails = TeamPostRepo.getChapterNameFromMaster(groupObjectId, teamObjectId, subjectObjectId, chapter_id)
      chapterName = hd(chapterNameDetails["syllabus"])
      topicMap = Map.put(topicMap, :chapterName, chapterName["chapterName"])
      TeamPostRepo.addSubjectVicePostsForTeam(changeset, loginUser, groupObjectId, teamObjectId, subjectObjectId, topicMap, chapterObjectId)
    else
      TeamPostRepo.addTopicsToChapter(loginUser, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, changeset, topicMap.topicId)
    end
  end


  def addStatusCompletedToTopicsByStudent(loginUserId, groupObjectId, team_id, subject_id, chapter_id, topic_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    chapterObjectId = decode_object_id(chapter_id)
    TeamPostRepo.addStatusCompletedToTopicsByStudent(loginUserId, groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topic_id)
  end



  def removeChapterFromSubject(groupObjectId, team_id, subject_id, chapter_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    chapterObjectId = decode_object_id(chapter_id)
    TeamPostRepo.removeChapterFromSubject(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId)
  end



  def removeTopicFromChapter(groupObjectId, team_id, subject_id, chapter_id, topicId) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    chapterObjectId = decode_object_id(chapter_id)
    TeamPostRepo.removeTopicFromChapter(groupObjectId, teamObjectId, subjectObjectId, chapterObjectId, topicId)
  end


  def addDayPeriodForTimeTable(changeset, groupObjectId, teamObjectId) do
    #check day period already added for the selected class
    checkAlreadyExist = TeamPostRepo.checkAlreadyDayPeriodAdded(changeset, groupObjectId, teamObjectId)
    if length(checkAlreadyExist) > 0 do
      #already exist, just return subjects to select
      #show list of subjects to select where staffs are available
      #1. Get list of all subjects for this teamId
      getAllSubjectList = TeamPostRepo.getAllSubjectListToAddTimeTable(groupObjectId, teamObjectId)
      #2. Get list of subects where staffId count = 0 means where teachers are null
      #need to check with the subjectWithStaffId and staffId allotted to team_year_time_table day, period
      Enum.reduce(getAllSubjectList, [], fn k, acc ->
        staffList = Enum.reduce(k["staffId"], [], fn staff_id, acc ->
          #check this staff with subject is already allotted to day, period
          {:ok, findSubjectWithStaffById} = TeamPostRepo.findSubjectWithStaffById(changeset, k["_id"], decode_object_id(staff_id), groupObjectId, teamObjectId)
          if findSubjectWithStaffById > 0 do
            #already staff exist so dont add into list
            acc ++ []
          else
            acc ++ [staff_id]
          end
        end)
        k = Map.put_new(k, "staffIdNew", staffList)
        acc ++ [k]
      end)
      #IO.puts "#{subjectsList}"
    #Newly add day, period
    else
      #insert day and period for the class time table
      objectId = new_object_id()
      TeamPostRepo.addDayPeriodForTimeTable(objectId, changeset, groupObjectId, teamObjectId)
      #after insert please find subjects and teachers to allot
      #show list of subjects to select where staffs are available
      #1. Get list of all subjects for this teamId
      getAllSubjectList = TeamPostRepo.getAllSubjectListToAddTimeTable(groupObjectId, teamObjectId)
      #2. Get list of subects where staffId count = 0 means where teachers are null
      #need to check with the subjectWithStaffId and staffId allotted to team_year_time_table day, period
      Enum.reduce(getAllSubjectList, [], fn k, acc ->
        staffList = Enum.reduce(k["staffId"], [], fn staff_id, acc ->
          #check this staff with subject is already allotted to day, period
          {:ok, findSubjectWithStaffById} = TeamPostRepo.findSubjectWithStaffById(changeset, k["_id"], decode_object_id(staff_id), groupObjectId, teamObjectId)
          if findSubjectWithStaffById > 0 do
            #already staff exist so dont add into list
            acc ++ []
          else
            acc ++ [staff_id]
          end
        end)
        k = Map.put_new(k, "staffIdNew", staffList)
        acc ++ [k]
      end)
    end
  end



  def addYearTimeTableWithStaffAndSubject(changeset, group_id, team_id, subjectStaffId, staff_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    subjectStaffObjectId = decode_object_id(subjectStaffId)
    staffObjectId = decode_object_id(staff_id)
    #check day, period already exist for team to set subject and staff
    checkAlreadyExist = TeamPostRepo.checkAlreadyDayPeriodAdded(changeset, groupObjectId, teamObjectId)
    if length(checkAlreadyExist) > 0 do
      #update subject with staff
      TeamPostRepo.updateSubjectStaffToYearTimeTable(subjectStaffObjectId, staffObjectId, changeset, groupObjectId, teamObjectId)
    end
  end


  def getYearTimeTableByDays(group_id, team_id, day) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getYearTimeTableByDays(groupObjectId, teamObjectId, day)
  end



  def removeYearTimeTable(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.removeYearTimeTable(groupObjectId, teamObjectId)
  end


  def removeYearTimeTableByDays(group_id, team_id, day) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.removeYearTimeTableByDays(groupObjectId, teamObjectId, day)
  end



  def getYearTimeTable(group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getYearTimeTable(groupObjectId, teamObjectId)
  end



  def getTimeTable(loginUserId, groupObjectId) do
    #get all teams id for login user
    teamIdList = TeamPostRepo.getAllTeamsIdForLoginUser(loginUserId, groupObjectId)
    #get time table belongs to teamIdList (belongs to team found above)
    TeamPostRepo.getTeamTimeTable(teamIdList, groupObjectId, loginUserId)
  end


  def deleteTimeTable(loginUserId, group, timetable_id) do
    timetableObjectId = decode_object_id(timetable_id)
    timetable = TeamPostRepo.getTeamTimeTableById(group["_id"], timetableObjectId)
    if group["adminId"] == loginUserId || loginUserId == timetable["userId"] do
      #delete timetable
      TeamPostRepo.deleteTimeTable(group["_id"], timetableObjectId)
    else
      #user cannot delete this post
      {:error_message, "You cannot delete this post"}
    end
  end



  def getTeacherClassTeamsList(conn, groupObjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    TeamPostRepo.getTeacherClassTeamsList(loginUser["_id"], groupObjectId)
  end



  def addAssignment(conn, changeset, groupObjectId, teamId, subjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    TeamPostRepo.addAssignment(loginUser["_id"], changeset, groupObjectId, teamObjectId, subjectObjectId)
  end


  def addTestExam(conn, changeset, groupObjectId, teamId, subjectId) do
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    TeamPostRepo.addTestExam(loginUser["_id"], changeset, groupObjectId, teamObjectId, subjectObjectId)
  end


  def getAssignments(groupObjectId, team_id, subject_id) do
    #loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    TeamPostRepo.getAssignments(groupObjectId, teamObjectId, subjectObjectId)
  end


  def getTestExam(groupObjectId, team_id, subject_id) do
    #loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    TeamPostRepo.getTestExam(groupObjectId, teamObjectId, subjectObjectId)
  end


  def deleteAssignment(groupObjectId, team_id, subject_id, assignment_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    assignmentObjectId = decode_object_id(assignment_id)
    TeamPostRepo.deleteAssignment(groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId)
  end


  def deleteTestExam(groupObjectId, team_id, subject_id, testExam_id) do
    teamObjectId = decode_object_id(team_id)
    subjectObjectId = decode_object_id(subject_id)
    testExamObjectId = decode_object_id(testExam_id)
    TeamPostRepo.deleteTestExam(groupObjectId, teamObjectId, subjectObjectId, testExamObjectId)
  end


  def studentSubmitAssignment(conn, changeset, groupObjectId, teamId, subjectId, assignmentId) do
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    assignmentObjectId = decode_object_id(assignmentId)
    TeamPostRepo.studentSubmitAssignment(loginUser["_id"], changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId)
  end


  def studentSubmitTestExam(conn, changeset, groupObjectId, teamId, subjectId, testexamId) do
    loginUser = Guardian.Plug.current_resource(conn)
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    testexamObjectId = decode_object_id(testexamId)
    TeamPostRepo.studentSubmitTestExam(loginUser["_id"], changeset, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId)
  end


  def checkAssignmentCreatedByLoginUser(loginUserId, groupObjectId, teamId, subjectId, assignmentId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    assignmentObjectId = decode_object_id(assignmentId)
    TeamPostRepo.checkAssignmentCreatedByLoginUser(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId)
  end


  def checkTestexamCreatedByLoginUser(loginUserId, groupObjectId, teamId, subjectId, testExamId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    testExamObjectId = decode_object_id(testExamId)
    TeamPostRepo.checkTestExamCreatedByLoginUser(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testExamObjectId)
  end


  def getStudentSubmittedAssignmentList(params, groupObjectId, teamId, subjectId, assignmentId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    assignmentObjecttId = decode_object_id(assignmentId)
    if params == "notVerified" do
      #get not verified students assignment list
      TeamPostRepo.getNotVerifiedAssignmentList(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId)
    else
      if params == "verified" do
        #get verified assignment list
        TeamPostRepo.getVerifiedAssignmentList(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId)
      else
        if params == "notSubmitted" do
          #get not submitted student list
          #First get submitted students id
          submittedStudentsId = TeamPostRepo.getAssignmentSubmittedStudentsId(groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId)
          #convert [%{"submittedStudents" => %{"submittedById" => #BSON.ObjectId<5f5617d6a0ccf76914dd129d>}}] to [#BSON.ObjectId<5f5617d6a0ccf76914dd129d>]
          submittedStudentsIdList = Enum.reduce(submittedStudentsId, [], fn k, acc ->
            studentId = k["submittedStudents"]["submittedById"]
            acc ++ [studentId]
          end)
          #Now get not submitted students details by passing not exist in student submitted ids list
          TeamPostRepo.getAssignmentNotSubmittedStudentsList(groupObjectId, teamObjectId, Enum.uniq(submittedStudentsIdList))
        end
      end
    end
  end


  def getStudentSubmittedTestExamList(params, groupObjectId, teamId, subjectId, testexamId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    testexamObjecttId = decode_object_id(testexamId)
    if params == "notVerified" do
      #get not verified students assignment list
      TeamPostRepo.getNotVerifiedTestExamList(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId)
    else
      if params == "verified" do
        #get verified assignment list
        TeamPostRepo.getVerifiedTestExamList(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId)
      else
        if params == "notSubmitted" do
          #get not submitted student list
          #First get submitted students id
          submittedStudentsId = TeamPostRepo.getTestExamSubmittedStudentsId(groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId)
          #convert [%{"submittedStudents" => %{"submittedById" => #BSON.ObjectId<5f5617d6a0ccf76914dd129d>}}] to [#BSON.ObjectId<5f5617d6a0ccf76914dd129d>]
          submittedStudentsIdList = Enum.reduce(submittedStudentsId, [], fn k, acc ->
            studentId = k["submittedStudents"]["submittedById"]
            acc ++ [studentId]
          end)
          #Now get not submitted students details by passing not exist in student submitted ids list (assignment/testesam)
          TeamPostRepo.getAssignmentNotSubmittedStudentsList(groupObjectId, teamObjectId, Enum.uniq(submittedStudentsIdList))
        end
      end
    end
  end



  def getLoginStudentAssignmentList(loginUserId, groupObjectId, teamId, subjectId, assignmentId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    assignmentObjecttId = decode_object_id(assignmentId)
    TeamPostRepo.getLoginStudentAssignmentList(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId)
  end


  def getLoginStudentTestExamList(loginUserId, groupObjectId, teamId, subjectId, testexamId) do
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    testexamObjecttId = decode_object_id(testexamId)
    TeamPostRepo.getLoginStudentTestExamList(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId)
  end



  def deleteStudentSubmittedAssignment(loginUserId, groupObjectId, teamId, subjectId, assignmentId, studentAssignmentId) do
    # First check this assignment is not "verified" or "reassigned" assignment
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    assignmentObjecttId = decode_object_id(assignmentId)
    studentAssignmentObjectId = decode_object_id(studentAssignmentId)
    {:ok, checkThisAssignmentIsNotReassignedOrVerified} = TeamPostRepo.checkThisAssignmentIsNotReassignedOrVerified(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId, studentAssignmentObjectId)
    #IO.puts "#{checkThisAssignmentIsNotReassignedOrVerified}"
    if checkThisAssignmentIsNotReassignedOrVerified < 1 do
      #can delete
      TeamPostRepo.deleteStudentSubmittedAssignment(loginUserId, groupObjectId, teamObjectId, subjectObjectId, assignmentObjecttId, studentAssignmentObjectId)
    else
      #throw error
      {:error, "You cannot delete this post"}
    end
  end


  def deleteStudentSubmittedTestExam(loginUserId, groupObjectId, teamId, subjectId, testexamId, studentTestExamId) do
    # First check this assignment is not "verified" or "reassigned" assignment
    teamObjectId = decode_object_id(teamId)
    subjectObjectId = decode_object_id(subjectId)
    testexamObjecttId = decode_object_id(testexamId)
    studentTestExamObjectId = decode_object_id(studentTestExamId)
    {:ok, checkThisTestExamIsNotVerified} = TeamPostRepo.checkThisTestExamIsNotVerified(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId, studentTestExamObjectId)
    #IO.puts "#{checkThisAssignmentIsNotReassignedOrVerified}"
    if checkThisTestExamIsNotVerified < 1 do
      #can delete
      TeamPostRepo.deleteStudentSubmittedTestExam(loginUserId, groupObjectId, teamObjectId, subjectObjectId, testexamObjecttId, studentTestExamObjectId)
    else
      #throw error
      {:error, "You cannot delete this post"}
    end
  end



  def verifyStudentSubmittedAssignment(params, changeset, groupObjectId) do
    teamObjectId = decode_object_id(params["team_id"])
    subjectObjectId = decode_object_id(params["subject_id"])
    assignmentObjectId = decode_object_id(params["assignment_id"])
    studentAssignmentObjectId = decode_object_id(params["studentAssignment_id"])
    TeamPostRepo.verifyStudentSubmittedAssignment(changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId, studentAssignmentObjectId, params["verify"])
  end


  def verifyStudentSubmittedTestExam(params, changeset, groupObjectId) do
    #IO.puts "#{params}"
    teamObjectId = decode_object_id(params["team_id"])
    subjectObjectId = decode_object_id(params["subject_id"])
    testexamObjectId = decode_object_id(params["testexam_id"])
    studentTestExamObjectId = decode_object_id(params["studentTestExam_id"])
    TeamPostRepo.verifyStudentSubmittedTestExam(changeset, groupObjectId, teamObjectId, subjectObjectId, testexamObjectId, studentTestExamObjectId, params["verify"])
  end



  def reassignStudentSubmittedAttendance(params, changeset, groupObjectId) do
    teamObjectId = decode_object_id(params["team_id"])
    subjectObjectId = decode_object_id(params["subject_id"])
    assignmentObjectId = decode_object_id(params["assignment_id"])
    studentAssignmentObjectId = decode_object_id(params["studentAssignment_id"])
    TeamPostRepo.reassignStudentSubmittedAssignment(changeset, groupObjectId, teamObjectId, subjectObjectId, assignmentObjectId, studentAssignmentObjectId, params["reassign"])
  end



  #share group post to team
  def sharePostToTeam(conn, params, post) do
  #if fileType is image
      if post["fileType"] == "image"  do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "fileName" => fileName, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToTeamPost(conn, post_params, params)
    end
    #if file type is pdf/video
    if post["fileType"] == "pdf" || post["fileType"] == "video" do
      fileName = post["fileName"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "fileName" => fileName, "fileType" => fileType,
                       "thumbnailImage" => post["thumbnailImage"] }
      #calling private func to validate and add
      validateWhenSharingAndAddToTeamPost(conn, post_params, params)
    end
    #if file type is youtube
    if post["fileType"] == "youtube" do
      #making valid youtube link
      video = "https://www.youtube.com/watch?v="<>post["video"]
      fileType = post["fileType"]
      post_params = %{ "title" => post["title"], "text" => post["text"], "video" => video, "fileType" => fileType }
      #calling private func to validate and add
      validateWhenSharingAndAddToTeamPost(conn, post_params, params)
    end
    #if sharing post contains no image or video
    if is_nil(post["fileType"]) do
       post_params = %{ "title" => post["title"], "text" => post["text"] }
       #calling private func to validate and add
       validateWhenSharingAndAddToTeamPost(conn, post_params, params)
    end
  end


  def getPostReadUsers(loginUserId, groupObjectId, teamObjectId, post) do
    #post read users (get users whose teamPostLastSeen time is greater that post["insertedAt"])
    TeamPostRepo.getPostReadUsersList(loginUserId, groupObjectId, teamObjectId, post)
  end

  def getPostUnreadUsers(loginUserId, groupObjectId, teamObjectId, post) do
    #post read users (get users whose teamPostLastSeen time is greater that post["insertedAt"])
    TeamPostRepo.getPostUnreadUsersList(loginUserId, groupObjectId, teamObjectId, post)
  end



  def getLeaveRequestForm(loginUser, group_id, team_id) do
    groupObjectId = decode_object_id(group_id)
    teamObjectId = decode_object_id(team_id)
    #get student name for this login user
    TeamPostRepo.getLeaveRequestForm(loginUser["_id"], groupObjectId, teamObjectId)
  end



  def addMarksCard(groupObjectId, team_id, user_id, rollNumber, changeset) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    #add marks card to the selected student
    TeamPostRepo.addMarksCard(groupObjectId, teamObjectId, userObjectId, rollNumber, changeset)
  end


  def getMarksCard(groupObjectId, team_id, user_id, rollNumber) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    TeamPostRepo.getMarksCard(groupObjectId, teamObjectId, userObjectId, rollNumber)
  end


  def deleteMarksCard(groupObjectId, team_id, user_id, markscard_id, rollNumber) do
    teamObjectId = decode_object_id(team_id)
    userObjectId = decode_object_id(user_id)
    marksCardObjectId = decode_object_id(markscard_id)
    TeamPostRepo.deleteMarksCard(groupObjectId, teamObjectId, userObjectId, marksCardObjectId, rollNumber)
  end



  def createMarksCard(changeset, group, team_id) do
    teamObjectId = decode_object_id(team_id)
    #get minimum marks total
    marksTotal = Enum.reduce(hd(changeset.subjects), %{"max" => [], "min" => []}, fn k, acc ->
      {_subject, marks} = k
      maxMarks = acc["max"] ++ [marks["max"]]
      minMarks = acc["min"] ++ [marks["min"]]
      %{ "max" => maxMarks, "min" => minMarks }
    end)
    #check iteams in list is only integer
    checkIntegerForMaxMarks = Enum.reduce(marksTotal["max"], [], fn k, acc ->
      if is_integer(k) == true do
        acc ++ [k]
      else
        acc ++ [0]
      end
    end)
    checkIntegerForMinMarks = Enum.reduce(marksTotal["min"], [], fn k, acc ->
      if is_integer(k) == true do
        acc ++ [k]
      else
        acc ++ [0]
      end
    end)
    maxMarksTotal = Enum.sum(checkIntegerForMaxMarks)
    minMarksTotal = Enum.sum(checkIntegerForMinMarks)
    total = %{ "maxMarks" => maxMarksTotal, "minMarks" => minMarksTotal }
    TeamPostRepo.createMarksCard(changeset, group["_id"], teamObjectId, total)
  end



  def getMarksCardList(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getMarksCardList(groupObjectId, teamObjectId)
  end


  def getMarksCardListWeb(groupObjectId, team_id) do
    teamObjectId = decode_object_id(team_id)
    TeamPostRepo.getMarksCardListWeb(groupObjectId, teamObjectId)
  end



  def addMarksToStudent(changeset, group, team_id, markscard_id, student_id, rollNumber) do
    teamObjectId = decode_object_id(team_id)
    marksCardObjectId = decode_object_id(markscard_id)
    studentObjectId = decode_object_id(student_id)
    #check marks card already uploaded (if already then just update)
    {:ok, marksUploaded} = TeamPostRepo.checkMarksAlreadyUploadedForThisStudent(studentObjectId, rollNumber, group["_id"], teamObjectId, marksCardObjectId)
    if marksUploaded > 0 do
      #already uploaded, just update
      TeamPostRepo.updateMarksToStudent(changeset, group["_id"], teamObjectId, marksCardObjectId, studentObjectId, rollNumber)
    else
      #add freshly
      TeamPostRepo.addMarksToStudent(changeset, group["_id"], teamObjectId, marksCardObjectId, studentObjectId, rollNumber)
    end
  end



  def getMarksCardForStudent(group, team_id, student_id, markscard_id, rollNumber) do
    teamObjectId = decode_object_id(team_id)
    marksCardObjectId = decode_object_id(markscard_id)
    studentObjectId = decode_object_id(student_id)
    TeamPostRepo.getMarksCardForStudent(group["_id"], teamObjectId, studentObjectId, marksCardObjectId, rollNumber)
  end



  def removeUploadedMarksForStudent(group, team_id, student_id, markscard_id, rollNumber) do
    teamObjectId = decode_object_id(team_id)
    marksCardObjectId = decode_object_id(markscard_id)
    studentObjectId = decode_object_id(student_id)
    TeamPostRepo.removeUploadedMarksForStudent(group["_id"], teamObjectId, studentObjectId, marksCardObjectId, rollNumber)
  end



  def takeAttendanceAndReportParents(params, group, teamObjectId, loginUser) do
    #convert to ISO Date and get all parameters of date
    currentTime = bson_time()
    {_ok, datetime, 0} = DateTime.from_iso8601(currentTime)
    # time = DateTime.to_time(datetime)
    dateTimeMap = %{"year" => datetime.year,"month" => datetime.month,"day" => datetime.day,"hour" => datetime.hour,
                  "minute" => datetime.minute,"seconds" => datetime.second}
     #to get date string
     day = String.slice("0"<>""<>to_string(dateTimeMap["day"]), -2, 2)
     month = String.slice("0"<>""<>to_string(dateTimeMap["month"]), -2, 2)
     reverseDateString = to_string(dateTimeMap["year"])<>month<>day
     |> String.to_integer
    #get list of students belongs to this class/team
    getClassStudents = TeamPostRepo.getStudentDbId(group["_id"], teamObjectId)
    Enum.reduce(getClassStudents, [], fn k, acc ->
      userObjectId = k["userId"]
      #check this month offline_attendance_report is added for this student userId
      {:ok, checkAlreadyAdded} = TeamPostRepo.checkThisMonthAttendanceReportAlreadyExistForStudent(group["_id"], teamObjectId,
                          userObjectId, dateTimeMap["month"], dateTimeMap["year"])
      if checkAlreadyAdded == 0 do
        #Not Exist, add newly for offline_attendance_report on monthly wise for this userId or student
        TeamPostRepo.addThismonthOfflineAttendanceForStudent(group["_id"], teamObjectId, userObjectId, dateTimeMap["month"], dateTimeMap["year"])
      end
      acc ++ [k["userId"]]
    end)
    ##IO.puts "#{classStudentsIdList}"
    #add attendance to particular month for students
    if params["subjectId"] do
      #add attendance along with subjectId and subjectName
      subjectObjectId = decode_object_id(params["subjectId"])
      #get subject name for subjectId
      getSubjectName = TeamPostRepo.getSubjectNameForMeeting(group["_id"], subjectObjectId)
      subjectName = getSubjectName["subjectName"]
      #absent student Ids
      absentStudentIds = params["absentStudentIds"]
      absentStudentLeaveObjectIds = Enum.reduce(absentStudentIds, [], fn k, acc ->
        userObjectId = decode_object_id(k)
        #to check leave in leave database
        {:ok, checkLeaveToday} = TeamPostRepo.checkLeaveForToday(group["_id"], teamObjectId , userObjectId ,reverseDateString, dateTimeMap["year"])
        map = if checkLeaveToday == 1 do
          %{
            "leaveList" => userObjectId
          }
        else
          %{
            "absentList" => userObjectId
          }
        end
        acc ++ [map]
      end)
      leaveListIds = for leaveIds <- absentStudentLeaveObjectIds do
          [] ++ leaveIds["leaveList"]
      end
      leaveListIds = leaveListIds
      |> Enum.reject(&is_nil/1)
      absentStudentObjectIds = for absentIds <- absentStudentLeaveObjectIds do
          [] ++ absentIds["absentList"]
      end
      absentStudentObjectIds = absentStudentObjectIds
      |> Enum.reject(&is_nil/1)
      if group["subCategory"] == "school" || group["subCategory"] == "School"  do
        attendanceExistedToday = TeamPostRepo.checkAttendanceTakenForToday(group["_id"], teamObjectId, reverseDateString, dateTimeMap["month"], dateTimeMap["year"])
        #taking head of the attendance
        if attendanceExistedToday == [] do
          TeamPostRepo.takeAttendanceAndReportParentsWithoutSubject(group["_id"], teamObjectId, loginUser, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
        else
          list = hd(attendanceExistedToday)
          #checking the length of the list for todays attendance
          length  = Enum.count(list["offlineAttendance"])
          if length < 2 do
            TeamPostRepo.takeAttendanceAndReportParentsWithoutSubject(group["_id"], teamObjectId, loginUser, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
          else
            {:attendance, "Already Attendance Taken"}
          end
        end
      else
        TeamPostRepo.takeAttendanceAndReportParentsAlongWithSubject(group["_id"], teamObjectId, loginUser, subjectObjectId,
                                                                 subjectName, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
      end
    else
      #add attendance without subjectName subjectId
      #absent student Ids
      absentStudentIds = params["absentStudentIds"]
      absentStudentLeaveObjectIds = Enum.reduce(absentStudentIds, [], fn k, acc ->
        userObjectId = decode_object_id(k)
        #to check leave in leave database
        {:ok, checkLeaveToday} = TeamPostRepo.checkLeaveForToday(group["_id"], teamObjectId, userObjectId, reverseDateString, dateTimeMap["year"])
        map = if checkLeaveToday > 0 do
          %{
            "leaveList" => userObjectId
          }
        else
          %{
            "absentList" => userObjectId
          }
        end
        acc ++ [map]
      end)
      leaveListIds = for leaveIds <- absentStudentLeaveObjectIds do
          [] ++ leaveIds["leaveList"]
      end
      leaveListIds = leaveListIds
      |> Enum.reject(&is_nil/1)
      absentStudentObjectIds = for absentIds <- absentStudentLeaveObjectIds do
          [] ++ absentIds["absentList"]
      end
      absentStudentObjectIds = absentStudentObjectIds
      |> Enum.reject(&is_nil/1)
      if  group["subCategory"] == "school" || group["subCategory"] == "School" do
        #checking attendance for today existed or not school only
        attendanceExistedToday = TeamPostRepo.checkAttendanceTakenForToday(group["_id"], teamObjectId, reverseDateString, dateTimeMap["month"], dateTimeMap["year"])
        #taking head of the attendance
        if attendanceExistedToday == [] do
          TeamPostRepo.takeAttendanceAndReportParentsWithoutSubject(group["_id"], teamObjectId, loginUser, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
        else
          list = hd(attendanceExistedToday)
          #checking the length of the list for todays attendance
          length  = Enum.count(list["offlineAttendance"])
          if length < 2 do
            TeamPostRepo.takeAttendanceAndReportParentsWithoutSubject(group["_id"], teamObjectId, loginUser, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
          else
            {:attendance, "Already Attendance Taken"}
          end
        end
      else
        TeamPostRepo.takeAttendanceAndReportParentsWithoutSubject(group["_id"], teamObjectId, loginUser, absentStudentObjectIds, leaveListIds, dateTimeMap, currentTime)
      end
    end
  end



  def getStudentOfflineAttendanceReport(params) do
    groupObjectId = decode_object_id(params["group_id"])
    teamObjectId = decode_object_id(params["team_id"])
    month = params["month"]
    year = params["year"]
    #Get all students offline attendance report
    cond do
      # get report for selected student for month and year
      params["userId"] ->
        #1. get report for selected userId for month and year
        userObjectId = decode_object_id(params["userId"])
        studentDetailsMap = TeamPostRepo.getClassStudentDetailsByUserId(groupObjectId, teamObjectId, userObjectId)
        # 2. get selected studen attendance report
        reportMap = TeamPostRepo.getOfflineAttendanceReportByUserId(groupObjectId, teamObjectId, userObjectId, month, year)
        #merge  classStudentsMap and reportMap by userId in list
        mergeTwoListOfAttendanceReport(studentDetailsMap, reportMap)
      # get all students of class attendance report for selected month
      ####is_nil(params["startDate"]) ->  ## temporary to get all the month report if start date and end date is coming
      !is_nil(params["startDate"]) ->
        #1. first get all the class students userIds and details
        classStudentsMap = TeamPostRepo.getClassStudentUserIds(groupObjectId, teamObjectId)
        studentdUserIds = for studentId <- classStudentsMap do
          [] ++ studentId["userId"]
        end
        #2. get report for particular selected month
        reportMap = TeamPostRepo.getStudentOfflineAttendanceReport(groupObjectId, teamObjectId, studentdUserIds, month, year)
        #merge  classStudentsMap and reportMap by userId in list
        mergeTwoListOfAttendanceReport(classStudentsMap, reportMap)
      true ->
        #get all students of class attendance report for selected month and date
        #1. first get all the class students userIds and details
        classStudentsMap = TeamPostRepo.getClassStudentUserIds(groupObjectId, teamObjectId)
        studentdUserIds = for studentId <- classStudentsMap do
          [] ++ studentId["userId"]
        end
        #2. get report based on start date and end date
        startDate = params["startDate"]
        endDate = params["endDate"]
        #get report for particular selected month and date
        reportMap = TeamPostRepo.getStudentOfflineAttendanceReportOnDateWise(groupObjectId, teamObjectId, studentdUserIds, month, year, startDate, endDate)
        #merge  classStudentsMap and reportMap by userId in list
        mergeList = mergeTwoListOfAttendanceReport(classStudentsMap, reportMap)
        mergeList ++ [%{"name" => "zzzzzz", "userId" => decode_object_id("5ce4e9564e51ba4b3683e540")}]
    end
  end



  defp mergeTwoListOfAttendanceReport(classStudentsMap, reportMap) do
    #merge  classStudentsMap and reportMap by userId in list
    Enum.map(classStudentsMap, fn k ->
      userReport = Enum.find(reportMap, fn v -> v["userId"] == k["userId"] end)
      if userReport do
        Map.merge(k, userReport)
      else
        k
      end
    end)
  end


  def getClassStudentUserIds(groupObjectId, teamId) do
    teamObjectId = decode_object_id(teamId)
    TeamPostRepo.getClassStudentUserIds(groupObjectId, teamObjectId)
  end



  #private function to validate and share when sharing team post
  defp validateWhenSharingAndAddToTeamPost(conn, post_params, params) do
    login_user = Guardian.Plug.current_resource(conn)
    changeset = Post.changeset(%Post{}, post_params)
    if changeset.valid? do
      group_id = params["groupId"]
      team_ids = params["teamId"]
      teamIdList = String.split(team_ids, ",")
      Enum.reduce(teamIdList, [], fn team_id, _acc ->
        TeamPostRepo.add(changeset.changes, login_user["_id"], decode_object_id(group_id), decode_object_id(team_id))
      end)
    else
      {:changesetError, changeset.errors}
    end
  end

  # #marksCard report
  def getMarksCardReport(groupObjectId, teamObjectId, offlineExamId) do
    #getting students list
    studentsList = TeamPostRepo.getStudentListToAddmarksCard(groupObjectId, teamObjectId)
    #getting Schedule Exam Subject List
    getSubjectList = TeamPostRepo.getSubjectListExams(groupObjectId, teamObjectId, offlineExamId)
    scheduleSubjectMarksArray = hd(getSubjectList["testExamSchedules"])["subjectMarksDetails"]
    scheduleSubjectIds = for subjectId <- scheduleSubjectMarksArray do
      %{
        "subjectId" => subjectId["subjectId"],
        "subjectName" => subjectId["subjectName"]
      }
    end
    list = Enum.reduce(studentsList, [], fn k, acc ->
      getSubjectListStudent = TeamPostRepo.getMarksCardList(groupObjectId, teamObjectId, offlineExamId, k["userId"])
      studentMarksReport = if getSubjectListStudent do
        studentSubjectMarksArray = hd(getSubjectListStudent["marksCardDetails"])["subjectMarksDetails"]
        studentSubjectList = for subjectIdStudent <- studentSubjectMarksArray do
          %{
            "subjectId" => subjectIdStudent["subjectId"],
            "subjectName" => subjectIdStudent["subjectName"]
          }
        end
        for id <- scheduleSubjectIds do
          if id not in studentSubjectList do
            studentSubjectMarksArray ++ [id]
          end
        end
        |> Enum.reject(&is_nil/1)
        %{
          "name" => k["name"],
          "rollNumber" => k["rollNumber"],
          "subjectMarksDetails" => studentSubjectMarksArray,
        }
      end
      acc ++ [studentMarksReport]
    end)
    list
    |> Enum.reject(&is_nil/1)
  end


  def getSectionLatest(groupObjectId, teamObjectId) do
    sectionList = TeamPostRepo.getSectionLatest(groupObjectId, teamObjectId)
    sectionMap = Enum.at(sectionList["testExamSchedules"], length(sectionList["testExamSchedules"])-1)
    if Map.has_key?(sectionMap, "section") do
      [sectionMap["section"]]
    else
      []
    end
  end
end
